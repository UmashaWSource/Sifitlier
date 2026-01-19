// lib/services/api_service.dart
// ================================
// Handles all communication with the Sifitlier backend

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ============================================================
  // CONFIGURATION - UPDATE THIS BASED ON YOUR SETUP
  // ============================================================

  // For Android Emulator (localhost):
  // static const String baseUrl = 'http://10.0.2.2:8000';

  // For Physical Device (use your computer's IP):
  // static const String baseUrl = 'http://172.18.48.1:8000';

  // Default: Android Emulator
  static const String baseUrl = 'http://10.0.2.2:8000';

  // ============================================================
  // SPAM DETECTION
  // ============================================================

  /// Check if a message is spam
  ///
  /// Returns a Map with:
  /// - is_spam: bool
  /// - label: "spam" or "ham"
  /// - confidence: double (0-1)
  /// - spam_probability: double (0-1)
  /// - risk_level: "high", "medium", "low", or "safe"
  /// - alert_id: int
  static Future<Map<String, dynamic>> checkSpam({
    required String userId,
    required String message,
    required String source, // "sms", "email", "telegram"
    String? sender,
    String? deviceToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/spam/check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'message': message,
          'source': source,
          'sender': sender,
          'device_token': deviceToken,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to check spam: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // ============================================================
  // DLP (Data Loss Prevention)
  // ============================================================

  /// Check outgoing message for sensitive data
  ///
  /// Returns a Map with:
  /// - has_sensitive_data: bool
  /// - sensitivity_level: "critical", "high", "medium", "low", "none"
  /// - total_matches: int
  /// - categories: List<String>
  /// - matches: List<Map>
  /// - recommendation: String
  /// - alert_id: int
  static Future<Map<String, dynamic>> checkDLP({
    required String userId,
    required String message,
    required String source, // "sms", "email", "telegram"
    String? recipient,
    String? deviceToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/dlp/check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'message': message,
          'source': source,
          'recipient': recipient,
          'device_token': deviceToken,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to check DLP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // ============================================================
  // DEVICE REGISTRATION (for push notifications)
  // ============================================================

  /// Register device for push notifications
  static Future<bool> registerDevice({
    required String userId,
    required String deviceToken,
    String platform = 'android',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/device/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'device_token': deviceToken,
          'platform': platform,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error registering device: $e');
      return false;
    }
  }

  // ============================================================
  // ALERTS / LOGS
  // ============================================================

  /// Get alert history for a user
  static Future<List<Map<String, dynamic>>> getAlerts({
    required String userId,
    String? alertType, // "spam" or "dlp"
    String? source, // "sms", "email", "telegram"
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'user_id': userId,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (alertType != null) queryParams['alert_type'] = alertType;
      if (source != null) queryParams['source'] = source;

      final uri = Uri.parse('$baseUrl/api/v1/alerts')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to get alerts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching alerts: $e');
    }
  }

  /// Get detailed information about a specific alert
  static Future<Map<String, dynamic>> getAlertDetail({
    required int alertId,
    required String userId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/alerts/$alertId').replace(
        queryParameters: {'user_id': userId},
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get alert detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching alert detail: $e');
    }
  }

  /// Update user action on an alert (allow, block, report)
  static Future<bool> updateAlertAction({
    required int alertId,
    required String userId,
    required String action, // "allowed", "blocked", "reported"
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/alerts/$alertId').replace(
        queryParameters: {'user_id': userId},
      );

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': action}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating alert: $e');
      return false;
    }
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// Get statistics for a user
  static Future<Map<String, dynamic>> getStats({
    required String userId,
    int days = 30,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/stats/$userId').replace(
        queryParameters: {'days': days.toString()},
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stats: $e');
    }
  }

  // ============================================================
  // HEALTH CHECK
  // ============================================================

  /// Check if backend is reachable
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
