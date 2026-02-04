// lib/services/notification_service.dart
// ========================================
// Handles local notifications for spam and DLP alerts

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _isInitialized = true;
    debugPrint("✅ Notification service initialized");
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    const spamChannel = AndroidNotificationChannel(
      'spam_alerts',
      'Spam Alerts',
      description: 'Notifications for detected spam messages',
      importance: Importance.high,
      playSound: true,
    );

    const dlpChannel = AndroidNotificationChannel(
      'dlp_alerts',
      'DLP Alerts',
      description: 'Notifications for sensitive data warnings',
      importance: Importance.high,
      playSound: true,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(spamChannel);
    await androidPlugin?.createNotificationChannel(dlpChannel);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint("Notification tapped: ${response.payload}");
    // You can navigate to specific screen based on payload
  }

  /// Show spam alert notification
  Future<void> showSpamAlert({
    required String title,
    required String body,
    required String sender,
    required String riskLevel,
  }) async {
    if (!_isInitialized) await initialize();

    // Choose icon color based on risk level
    Color? color;
    switch (riskLevel) {
      case 'high':
        color = const Color(0xFFD32F2F); // Red
        break;
      case 'medium':
        color = const Color(0xFFF57C00); // Orange
        break;
      default:
        color = const Color(0xFFFFA000); // Amber
    }

    final androidDetails = AndroidNotificationDetails(
      'spam_alerts',
      'Spam Alerts',
      channelDescription: 'Notifications for detected spam messages',
      importance: Importance.high,
      priority: Priority.high,
      color: color,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'From: $sender',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      details,
      payload: 'spam:$sender',
    );
  }

  /// Show DLP alert notification
  Future<void> showDLPAlert({
    required String title,
    required String body,
    required String sensitivityLevel,
    required List<String> categories,
  }) async {
    if (!_isInitialized) await initialize();

    Color? color;
    switch (sensitivityLevel) {
      case 'critical':
        color = const Color(0xFFD32F2F); // Red
        break;
      case 'high':
        color = const Color(0xFFE64A19); // Deep Orange
        break;
      case 'medium':
        color = const Color(0xFFF57C00); // Orange
        break;
      default:
        color = const Color(0xFFFFA000); // Amber
    }

    final androidDetails = AndroidNotificationDetails(
      'dlp_alerts',
      'DLP Alerts',
      channelDescription: 'Notifications for sensitive data warnings',
      importance: Importance.high,
      priority: Priority.high,
      color: color,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Categories: ${categories.join(", ")}',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: 'dlp:${categories.join(",")}',
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
