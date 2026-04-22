// lib/services/local_inference_service.dart
// ==========================================
// Unified inference service — local first, API fallback
//
// Architecture:
// 1. Spam detection and DLP run on-device (no network needed)
// 2. If backend is available, results are synced for logging/analytics
// 3. App works fully offline for core security features

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'local_spam_classifier.dart';
import 'local_dlp_detector.dart';
import 'api_service.dart';

class LocalInferenceService {
  static final LocalInferenceService _instance =
      LocalInferenceService._internal();
  factory LocalInferenceService() => _instance;
  LocalInferenceService._internal();

  final _spamClassifier = LocalSpamClassifier();
  final _dlpDetector = LocalDLPDetector();

  bool _initialized = false;
  String? _userId;

  bool get isReady => _initialized && _spamClassifier.isLoaded;
  String get userId => _userId ?? 'device_user';

  /// Initialize local models and generate device user ID
  Future<void> initialize() async {
    if (_initialized) return;

    // Generate or load persistent device user ID
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('device_user_id');
    if (_userId == null) {
      _userId = 'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      await prefs.setString('device_user_id', _userId!);
      debugPrint('Generated new device user ID: $_userId');
    }

    // Load spam model
    final loaded = await _spamClassifier.loadModel();
    if (loaded) {
      debugPrint('Local inference ready (user: $_userId)');
    } else {
      debugPrint('Local spam model failed to load — will use API fallback');
    }

    _initialized = true;
  }

  /// Check message for spam — local first, API fallback
  Future<Map<String, dynamic>> checkSpam({
    required String message,
    required String source,
    String? sender,
  }) async {
    // Try local inference first
    if (_spamClassifier.isLoaded) {
      try {
        final result = _spamClassifier.predict(message);

        // Try to sync to backend in background (non-blocking)
        _syncSpamToBackend(
          message: message,
          source: source,
          sender: sender,
          result: result,
        );

        return result;
      } catch (e) {
        debugPrint('Local spam prediction failed: $e');
      }
    }

    // Fallback to API
    try {
      return await ApiService.checkSpam(
        userId: userId,
        message: message,
        source: source,
        sender: sender,
      );
    } catch (e) {
      // Both failed — return safe default
      debugPrint('Both local and API spam check failed: $e');
      return {
        'is_spam': false,
        'label': 'unknown',
        'confidence': 0.0,
        'spam_probability': 0.0,
        'risk_level': 'unknown',
        'error': 'Detection unavailable offline',
      };
    }
  }

  /// Check message for sensitive data — always local (no network needed)
  Map<String, dynamic> checkDLP({required String message}) {
    return _dlpDetector.analyze(message);
  }

  /// Redact sensitive data from text
  String redactText(String text) {
    return _dlpDetector.redactText(text);
  }

  /// Check if backend is reachable
  Future<bool> isBackendAvailable() async {
    try {
      return await ApiService.healthCheck();
    } catch (e) {
      return false;
    }
  }

  /// Sync spam result to backend for logging (fire-and-forget)
  Future<void> _syncSpamToBackend({
    required String message,
    required String source,
    String? sender,
    required Map<String, dynamic> result,
  }) async {
    try {
      await ApiService.checkSpam(
        userId: userId,
        message: message,
        source: source,
        sender: sender,
      );
    } catch (e) {
      // Backend unavailable — that's fine, local detection still worked
    }
  }
}
