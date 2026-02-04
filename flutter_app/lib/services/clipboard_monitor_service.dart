// lib/services/clipboard_monitor_service.dart
// =============================================
// REDESIGNED: Monitors outgoing messages for sensitive data
// Only triggers when user is composing/sending messages
// NOT passive clipboard watching

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'notification_service.dart';

class ClipboardMonitorService {
  static final ClipboardMonitorService _instance =
      ClipboardMonitorService._internal();
  factory ClipboardMonitorService() => _instance;
  ClipboardMonitorService._internal();

  Timer? _timer;
  String? _lastClipboardContent;
  bool _isMonitoring = false;
  bool _isAppInForeground = true;

  // Callbacks
  Function(String content, Map<String, dynamic> result)?
      onSensitiveDataDetected;
  Function(String content)? onClipboardChanged;

  bool get isMonitoring => _isMonitoring;

  /// Set app foreground state - monitoring only active when app is in foreground
  void setAppForegroundState(bool inForeground) {
    _isAppInForeground = inForeground;
  }

  /// Start monitoring clipboard (only active when Sifitlier app is open)
  void startMonitoring({Duration interval = const Duration(seconds: 3)}) {
    if (_isMonitoring) return;

    _isMonitoring = true;
    debugPrint("✅ Clipboard monitoring started (app-focused mode)");

    _timer = Timer.periodic(interval, (_) {
      if (_isAppInForeground) {
        _checkClipboard();
      }
    });
  }

  /// Stop monitoring clipboard
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    _isMonitoring = false;
    _lastClipboardContent = null;
    debugPrint("Clipboard monitoring stopped");
  }

  /// Check clipboard content
  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final content = data?.text;

      // Skip if empty or same as last check
      if (content == null ||
          content.isEmpty ||
          content == _lastClipboardContent) {
        return;
      }

      _lastClipboardContent = content;

      // Skip very short content (less likely to be sensitive)
      if (content.length < 8) return;

      // Check for sensitive data
      await _checkForSensitiveData(content);
    } catch (e) {
      debugPrint("Clipboard access error: $e");
    }
  }

  /// Check clipboard content for sensitive data
  Future<void> _checkForSensitiveData(String content) async {
    try {
      final result = await ApiService.checkDLP(
        userId: 'device_user',
        message: content,
        source: 'sms',
      );

      if (result['has_sensitive_data'] == true) {
        final sensitivityLevel = result['sensitivity_level'] ?? 'medium';
        final categories = List<String>.from(result['categories'] ?? []);

        debugPrint("⚠️ Sensitive data in clipboard: $categories");

        // Only notify for high/critical
        if (sensitivityLevel == 'high' || sensitivityLevel == 'critical') {
          await NotificationService().showDLPAlert(
            title: '🛡️ Sensitive Data Copied!',
            body:
                'Be careful where you paste this. Categories: ${categories.join(", ")}',
            sensitivityLevel: sensitivityLevel,
            categories: categories,
          );
        }

        // Notify UI
        onSensitiveDataDetected?.call(content, result);
      }
    } catch (e) {
      debugPrint("Error checking clipboard: $e");
    }
  }

  /// Manually check any text for sensitive data (used by DLP check screen)
  Future<Map<String, dynamic>?> checkText(String content) async {
    if (content.isEmpty) return null;

    try {
      final result = await ApiService.checkDLP(
        userId: 'device_user',
        message: content,
        source: 'sms',
      );
      return {
        'content': content,
        'result': result,
      };
    } catch (e) {
      debugPrint("Error checking text: $e");
      return null;
    }
  }
}
