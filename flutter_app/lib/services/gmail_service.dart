// lib/services/gmail_service.dart
// ==================================
// Gmail OAuth integration service
// Handles Google Sign-In and fetching emails via Gmail API

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

/// Represents a fetched email message
class EmailMessage {
  final String id;
  final String subject;
  final String from;
  final String body;
  final String snippet;
  final DateTime? date;
  bool isSelected;

  EmailMessage({
    required this.id,
    required this.subject,
    required this.from,
    required this.body,
    required this.snippet,
    this.date,
    this.isSelected = false,
  });

  /// Get combined content for scanning (subject + body)
  String get contentForScanning => '$subject\n\n$body';
}

/// Gmail OAuth Service - Singleton
class GmailService {
  static final GmailService _instance = GmailService._internal();
  factory GmailService() => _instance;
  GmailService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [gmail.GmailApi.gmailReadonlyScope],
  );

  GoogleSignInAccount? _currentUser;
  gmail.GmailApi? _gmailApi;

  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null;

  /// Get current user email
  String? get userEmail => _currentUser?.email;

  /// Get current user display name
  String? get userName => _currentUser?.displayName;

  /// Get current user photo URL
  String? get userPhotoUrl => _currentUser?.photoUrl;

  /// Sign in with Google
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        debugPrint('❌ Google Sign-In cancelled by user');
        return false;
      }

      _currentUser = account;

      // Get authenticated HTTP client
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        debugPrint('❌ Failed to get authenticated client');
        return false;
      }

      // Initialize Gmail API
      _gmailApi = gmail.GmailApi(httpClient);

      debugPrint('✅ Google Sign-In successful: ${account.email}');
      return true;
    } catch (e) {
      debugPrint('❌ Google Sign-In error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _gmailApi = null;
    debugPrint('✅ Signed out from Google');
  }

  /// Check if already signed in (silent sign in)
  Future<bool> trySilentSignIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        _currentUser = account;
        final httpClient = await _googleSignIn.authenticatedClient();
        if (httpClient != null) {
          _gmailApi = gmail.GmailApi(httpClient);
          debugPrint('✅ Silent sign-in successful: ${account.email}');
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
      return false;
    }
  }

  /// Fetch recent emails from inbox
  Future<List<EmailMessage>> fetchRecentEmails({int maxResults = 20}) async {
    if (_gmailApi == null) {
      throw Exception('Not authenticated. Please sign in first.');
    }

    try {
      // Fetch message list from inbox
      final messageList = await _gmailApi!.users.messages.list(
        'me',
        maxResults: maxResults,
        q: 'in:inbox', // Only inbox messages
      );

      if (messageList.messages == null || messageList.messages!.isEmpty) {
        debugPrint('No messages found in inbox');
        return [];
      }

      List<EmailMessage> emails = [];

      // Fetch full details for each message
      for (var msg in messageList.messages!) {
        try {
          final fullMsg = await _gmailApi!.users.messages.get(
            'me',
            msg.id!,
            format: 'full',
          );
          emails.add(_parseMessage(fullMsg));
        } catch (e) {
          debugPrint('Error fetching message ${msg.id}: $e');
        }
      }

      debugPrint('✅ Fetched ${emails.length} emails');
      return emails;
    } catch (e) {
      debugPrint('❌ Error fetching emails: $e');
      throw Exception('Failed to fetch emails: $e');
    }
  }

  /// Parse Gmail message into EmailMessage object
  EmailMessage _parseMessage(gmail.Message msg) {
    String subject = '(No Subject)';
    String from = 'Unknown';
    String body = '';
    DateTime? date;

    // Extract headers
    if (msg.payload?.headers != null) {
      for (var header in msg.payload!.headers!) {
        switch (header.name?.toLowerCase()) {
          case 'subject':
            subject = header.value ?? '(No Subject)';
            break;
          case 'from':
            from = header.value ?? 'Unknown';
            break;
          case 'date':
            if (header.value != null) {
              try {
                date = _parseEmailDate(header.value!);
              } catch (e) {
                // Ignore date parsing errors
              }
            }
            break;
        }
      }
    }

    // Extract body
    body = _extractBody(msg.payload);

    return EmailMessage(
      id: msg.id ?? '',
      subject: subject,
      from: _cleanFromField(from),
      body: body,
      snippet: msg.snippet ?? '',
      date: date,
    );
  }

  /// Extract plain text body from message payload
  String _extractBody(gmail.MessagePart? payload) {
    if (payload == null) return '';

    // Check if this part has plain text body
    if (payload.mimeType == 'text/plain' && payload.body?.data != null) {
      return _decodeBase64(payload.body!.data!);
    }

    // Check for HTML body as fallback
    if (payload.mimeType == 'text/html' && payload.body?.data != null) {
      final html = _decodeBase64(payload.body!.data!);
      // Strip HTML tags for plain text
      return _stripHtmlTags(html);
    }

    // Recursively check parts
    if (payload.parts != null) {
      for (var part in payload.parts!) {
        // Prefer plain text
        if (part.mimeType == 'text/plain' && part.body?.data != null) {
          return _decodeBase64(part.body!.data!);
        }
      }
      // Fallback to HTML
      for (var part in payload.parts!) {
        if (part.mimeType == 'text/html' && part.body?.data != null) {
          final html = _decodeBase64(part.body!.data!);
          return _stripHtmlTags(html);
        }
      }
      // Check nested parts
      for (var part in payload.parts!) {
        final body = _extractBody(part);
        if (body.isNotEmpty) return body;
      }
    }

    return '';
  }

  /// Decode Gmail's URL-safe base64 encoding
  String _decodeBase64(String encoded) {
    try {
      // Gmail uses URL-safe base64
      String normalized = encoded.replaceAll('-', '+').replaceAll('_', '/');
      // Add padding if needed
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      return utf8.decode(base64.decode(normalized));
    } catch (e) {
      debugPrint('Base64 decode error: $e');
      return '';
    }
  }

  /// Strip HTML tags from string
  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Clean the "From" field to show just name or email
  String _cleanFromField(String from) {
    // Format: "Name <email@example.com>" -> "Name"
    final match = RegExp(r'^(.+?)\s*<.+>$').firstMatch(from);
    if (match != null) {
      return match.group(1)?.trim() ?? from;
    }
    return from;
  }

  /// Parse email date string
  DateTime? _parseEmailDate(String dateStr) {
    try {
      // Remove timezone name if present (e.g., "(PST)")
      dateStr = dateStr.replaceAll(RegExp(r'\s*\([^)]+\)\s*$'), '');
      return DateTime.parse(dateStr);
    } catch (e) {
      // Try alternative parsing
      try {
        return DateTime.tryParse(dateStr);
      } catch (e) {
        return null;
      }
    }
  }
}
