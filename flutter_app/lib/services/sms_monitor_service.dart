// lib/services/sms_monitor_service.dart
// =======================================
// Monitors incoming SMS and checks for spam automatically
// Works on Android only

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'local_inference_service.dart';
import 'notification_service.dart';

// This function runs in background when SMS arrives
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) async {
  // Note: Background handling is limited
  // Full processing happens when app is in foreground
  debugPrint("SMS received in background from: ${message.address}");
}

class SmsMonitorService {
  static final SmsMonitorService _instance = SmsMonitorService._internal();
  factory SmsMonitorService() => _instance;
  SmsMonitorService._internal();

  final Telephony _telephony = Telephony.instance;

  bool _isMonitoring = false;
  bool _hasPermission = false;

  // Callbacks for UI updates
  Function(SmsMessage message, Map<String, dynamic> result)? onSpamDetected;
  Function(SmsMessage message)? onSmsReceived;
  Function(String error)? onError;

  // Getters
  bool get isMonitoring => _isMonitoring;
  bool get hasPermission => _hasPermission;

  /// Request SMS permissions
  Future<bool> requestPermissions() async {
    // Request SMS permission
    final smsStatus = await Permission.sms.request();

    // Request phone permission (needed for some SMS features)
    final phoneStatus = await Permission.phone.request();

    // Request notification permission (for alerts)
    final notificationStatus = await Permission.notification.request();

    _hasPermission = smsStatus.isGranted && phoneStatus.isGranted;

    if (!_hasPermission) {
      debugPrint("SMS Permissions denied: SMS=$smsStatus, Phone=$phoneStatus");
    }

    return _hasPermission;
  }

  /// Check if permissions are granted
  Future<bool> checkPermissions() async {
    final smsGranted = await Permission.sms.isGranted;
    final phoneGranted = await Permission.phone.isGranted;
    _hasPermission = smsGranted && phoneGranted;
    return _hasPermission;
  }

  /// Start monitoring incoming SMS
  Future<bool> startMonitoring() async {
    if (_isMonitoring) {
      debugPrint("SMS monitoring already active");
      return true;
    }

    // Check permissions first
    if (!await checkPermissions()) {
      final granted = await requestPermissions();
      if (!granted) {
        onError?.call("SMS permissions not granted");
        return false;
      }
    }

    try {
      // Start listening for incoming SMS
      _telephony.listenIncomingSms(
        onNewMessage: _handleIncomingSms,
        onBackgroundMessage: backgroundMessageHandler,
        listenInBackground: true,
      );

      _isMonitoring = true;
      debugPrint("✅ SMS monitoring started");
      return true;
    } catch (e) {
      debugPrint("❌ Failed to start SMS monitoring: $e");
      onError?.call("Failed to start SMS monitoring: $e");
      return false;
    }
  }

  /// Stop monitoring SMS
  void stopMonitoring() {
    _isMonitoring = false;
    debugPrint("SMS monitoring stopped");
  }

  /// Handle incoming SMS — uses LOCAL inference (works offline, no network needed)
  Future<void> _handleIncomingSms(SmsMessage message) async {
    debugPrint("SMS received from: ${message.address}");

    // Notify UI that SMS was received
    onSmsReceived?.call(message);

    // Check if message body exists
    if (message.body == null || message.body!.isEmpty) {
      return;
    }

    try {
      // Use local inference — no network required
      final inference = LocalInferenceService();
      final result = await inference.checkSpam(
        message: message.body!,
        source: 'sms',
        sender: message.address ?? 'Unknown',
      );

      debugPrint(
          "   Spam check result: ${result['is_spam']} (${result['risk_level']})");

      // If spam detected, notify user
      if (result['is_spam'] == true) {
        // Show local notification
        await NotificationService().showSpamAlert(
          title: 'Spam Detected!',
          body: 'Suspicious SMS from ${message.address}',
          sender: message.address ?? 'Unknown',
          riskLevel: result['risk_level'] ?? 'medium',
        );

        // Notify UI
        onSpamDetected?.call(message, result);
      }

      // Also check for sensitive data (DLP) locally
      final dlpResult = inference.checkDLP(message: message.body!);
      if (dlpResult['has_sensitive_data'] == true) {
        await NotificationService().showDLPAlert(
          title: 'Sensitive Data in SMS!',
          body: 'Incoming SMS contains ${dlpResult['sensitivity_level']} sensitivity data',
          sensitivityLevel: dlpResult['sensitivity_level'] ?? 'medium',
          categories: List<String>.from(dlpResult['categories'] ?? []),
        );
      }
    } catch (e) {
      debugPrint("Error checking SMS: $e");
      onError?.call("Error checking SMS: $e");
    }
  }

  /// Get all SMS messages (inbox)
  Future<List<SmsMessage>> getAllSms({int limit = 50}) async {
    if (!await checkPermissions()) {
      return [];
    }

    try {
      final messages = await _telephony.getInboxSms(
        columns: [
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
          SmsColumn.TYPE,
        ],
        sortOrder: [
          OrderBy(SmsColumn.DATE, sort: Sort.DESC),
        ],
      );

      return messages.take(limit).toList();
    } catch (e) {
      debugPrint("Error fetching SMS: $e");
      return [];
    }
  }

  /// Scan existing SMS messages for spam
  Future<List<Map<String, dynamic>>> scanExistingSms({int limit = 20}) async {
    final messages = await getAllSms(limit: limit);
    final results = <Map<String, dynamic>>[];

    final inference = LocalInferenceService();

    for (final message in messages) {
      if (message.body == null || message.body!.isEmpty) continue;

      try {
        // Local inference — no network delay, no server needed
        final result = await inference.checkSpam(
          message: message.body!,
          source: 'sms',
          sender: message.address ?? 'Unknown',
        );

        results.add({
          'message': message,
          'result': result,
        });
      } catch (e) {
        debugPrint("Error scanning SMS: $e");
      }
    }

    return results;
  }
}
