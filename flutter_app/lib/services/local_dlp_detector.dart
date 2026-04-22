// lib/services/local_dlp_detector.dart
// ======================================
// On-device DLP detector — runs entirely offline
// Port of backend/dlp_detector.py regex patterns to Dart
//
// All sensitive data detection happens on-device.
// Messages never leave the phone for DLP checks.

import 'package:flutter/foundation.dart';

/// Sensitivity levels matching the backend
enum SensitivityLevel {
  none,
  low,
  medium,
  high,
  critical;

  int get rank {
    switch (this) {
      case SensitivityLevel.none:
        return 0;
      case SensitivityLevel.low:
        return 1;
      case SensitivityLevel.medium:
        return 2;
      case SensitivityLevel.high:
        return 3;
      case SensitivityLevel.critical:
        return 4;
    }
  }
}

class _PatternDef {
  final RegExp regex;
  final String description;
  final SensitivityLevel sensitivity;
  final double confidence;

  _PatternDef(this.regex, this.description, this.sensitivity, this.confidence);
}

class LocalDLPDetector {
  static final LocalDLPDetector _instance = LocalDLPDetector._internal();
  factory LocalDLPDetector() => _instance;
  LocalDLPDetector._internal() {
    _initPatterns();
  }

  late final Map<String, List<_PatternDef>> _patterns;

  void _initPatterns() {
    _patterns = {
      // ============== FINANCIAL ==============
      'credit_card': [
        _PatternDef(RegExp(r'\b4[0-9]{3}[-\s]?[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}\b'), 'Visa card', SensitivityLevel.critical, 0.95),
        _PatternDef(RegExp(r'\b5[1-5][0-9]{2}[-\s]?[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}\b'), 'MasterCard', SensitivityLevel.critical, 0.95),
        _PatternDef(RegExp(r'\b3[47][0-9]{2}[-\s]?[0-9]{6}[-\s]?[0-9]{5}\b'), 'American Express', SensitivityLevel.critical, 0.95),
        _PatternDef(RegExp(r'\b6(?:011|5[0-9]{2})[-\s]?[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}\b'), 'Discover card', SensitivityLevel.critical, 0.95),
        _PatternDef(RegExp(r'(?:card|credit|debit)[\s:#]*\b[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}\b', caseSensitive: false), 'Credit card number', SensitivityLevel.critical, 0.75),
      ],
      'bank_account': [
        _PatternDef(RegExp(r'\b[A-Z]{2}[0-9]{2}[A-Z0-9]{4}[0-9]{7}([A-Z0-9]?){0,16}\b'), 'IBAN', SensitivityLevel.high, 0.95),
        _PatternDef(RegExp(r'(?:account|acct|a/c|acc)\s*(?:no|number|num|#)?[\s:#]*([0-9]{8,17})', caseSensitive: false), 'Bank account', SensitivityLevel.high, 0.85),
        _PatternDef(RegExp(r'(?:bank\s+)?(?:account|acct|a/c|acc)\s*(?:no|number|num|#)?\s+is\s+([0-9]{8,17})', caseSensitive: false), 'Bank account', SensitivityLevel.high, 0.85),
        _PatternDef(RegExp(r'(?:swift|bic|bank\s*code)[\s:#]*[A-Z]{4}[A-Z]{2}[A-Z0-9]{2}([A-Z0-9]{3})?', caseSensitive: false), 'SWIFT/BIC code', SensitivityLevel.high, 0.85),
      ],
      'cvv': [
        _PatternDef(RegExp(r'(?:cvv|cvc|cvv2|cvc2|security\s*code)[\s:]*([0-9]{3,4})', caseSensitive: false), 'CVV', SensitivityLevel.critical, 0.95),
        _PatternDef(RegExp(r'(?:cvv|cvc|cvv2|cvc2|security\s*code)\s+is\s+([0-9]{3,4})\b', caseSensitive: false), 'CVV', SensitivityLevel.critical, 0.95),
      ],

      // ============== IDENTITY ==============
      'ssn': [
        _PatternDef(RegExp(r'\b[0-9]{3}[-\s][0-9]{2}[-\s][0-9]{4}\b'), 'SSN', SensitivityLevel.critical, 0.95),
        _PatternDef(RegExp(r'(?:ssn|social\s*security)[\s:#]*([0-9]{3}[-\s]?[0-9]{2}[-\s]?[0-9]{4})', caseSensitive: false), 'SSN', SensitivityLevel.critical, 0.98),
      ],
      'nric': [
        _PatternDef(RegExp(r'\b[STFGM][0-9]{7}[A-Z]\b'), 'Singapore NRIC', SensitivityLevel.critical, 0.95),
      ],
      'nic': [
        _PatternDef(RegExp(r'\b[0-9]{9}[VvXx]\b'), 'Sri Lankan NIC (old)', SensitivityLevel.critical, 0.95),
        _PatternDef(RegExp(r'(?:nic|national\s*id|identity\s*card)[\s:#]*([0-9]{12})\b', caseSensitive: false), 'Sri Lankan NIC (new)', SensitivityLevel.critical, 0.90),
        _PatternDef(RegExp(r'\b(?:19|20)[0-9]{10}\b'), 'Sri Lankan NIC (new)', SensitivityLevel.critical, 0.75),
      ],

      // ============== AUTHENTICATION ==============
      'password': [
        _PatternDef(RegExp(r'password[\s]*[:=]+[\s]*\S+', caseSensitive: false), 'Password', SensitivityLevel.critical, 0.95),
        _PatternDef(RegExp(r'password\s+is\s+(\S*[0-9!@#$%^&*_]+\S*)', caseSensitive: false), 'Password', SensitivityLevel.critical, 0.90),
        _PatternDef(RegExp(r'password\s+is\s+([A-Za-z0-9!@#$%^&*_]{6,})', caseSensitive: false), 'Password', SensitivityLevel.critical, 0.70),
        _PatternDef(RegExp(r'(?:pwd|passwd)[\s]*[:=]+[\s]*\S+', caseSensitive: false), 'Password', SensitivityLevel.critical, 0.90),
        _PatternDef(RegExp(r'(?:pwd|passwd)\s+is\s+\S+', caseSensitive: false), 'Password', SensitivityLevel.critical, 0.85),
        _PatternDef(RegExp(r'\bpass\s+is\s+\S{6,}', caseSensitive: false), 'Password', SensitivityLevel.critical, 0.75),
        _PatternDef(RegExp(r'(?:my|ur|your)\s+pass\s+is\s+\S+', caseSensitive: false), 'Password', SensitivityLevel.critical, 0.80),
        _PatternDef(RegExp(r'(?:wifi|wi-fi)\s+password\s+is\s+\S+', caseSensitive: false), 'Password', SensitivityLevel.critical, 0.90),
      ],
      'pin': [
        _PatternDef(RegExp(r'(?:pin|pin\s*code|pin\s*number)[\s]*[:=]+[\s]*[0-9]{4,6}', caseSensitive: false), 'PIN', SensitivityLevel.critical, 0.95),
        _PatternDef(RegExp(r'(?:pin|pin\s*code|pin\s*number)\s+is\s+[0-9]{4,6}\b', caseSensitive: false), 'PIN', SensitivityLevel.critical, 0.95),
      ],
      'otp': [
        _PatternDef(RegExp(r'(?:otp|one[\s-]?time[\s-]?(?:password|code|pin)|verification\s*code)[\s]*[:=]+[\s]*[0-9]{4,8}', caseSensitive: false), 'OTP', SensitivityLevel.high, 0.95),
        _PatternDef(RegExp(r'(?:otp|one[\s-]?time[\s-]?(?:password|code|pin)|verification\s*code)\s+is\s+[0-9]{4,8}\b', caseSensitive: false), 'OTP', SensitivityLevel.high, 0.95),
        _PatternDef(RegExp(r'(?:your\s+)?(?:otp|code)\s+(?:is\s+)?[0-9]{4,8}\b', caseSensitive: false), 'OTP', SensitivityLevel.high, 0.80),
        _PatternDef(RegExp(r'\bOTP\s+(?:\w+\s+){0,4}(?:is\s+)?[0-9]{4,8}\b', caseSensitive: false), 'OTP', SensitivityLevel.high, 0.75),
      ],
      'api_key': [
        _PatternDef(RegExp(r'api[_-]?key[\s:=]+[A-Za-z0-9_\-]{16,}', caseSensitive: false), 'API Key', SensitivityLevel.critical, 0.95),
        _PatternDef(RegExp(r'secret[_-]?key[\s:=]+[A-Za-z0-9_\-]{16,}', caseSensitive: false), 'Secret Key', SensitivityLevel.critical, 0.95),
        _PatternDef(RegExp(r'bearer[\s]+[A-Za-z0-9_\-\.]{20,}', caseSensitive: false), 'Bearer Token', SensitivityLevel.critical, 0.90),
        _PatternDef(RegExp(r'AKIA[0-9A-Z]{16}'), 'AWS Key', SensitivityLevel.critical, 0.98),
      ],

      // ============== PERSONAL ==============
      'phone': [
        _PatternDef(RegExp(r'\+94[-\s]?[0-9]{2}[-\s]?[0-9]{3}[-\s]?[0-9]{4}'), 'Phone (Sri Lankan)', SensitivityLevel.medium, 0.90),
        _PatternDef(RegExp(r'\b07[0-9]{8}\b'), 'Phone (Sri Lankan local)', SensitivityLevel.medium, 0.85),
        _PatternDef(RegExp(r'\+[1-9][0-9]{0,2}[-\s]?[0-9]{2,4}[-\s]?[0-9]{3,4}[-\s]?[0-9]{3,4}'), 'Phone (international)', SensitivityLevel.medium, 0.85),
        _PatternDef(RegExp(r'\b\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}\b'), 'Phone (US)', SensitivityLevel.medium, 0.80),
      ],
      'email': [
        _PatternDef(RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'), 'Email', SensitivityLevel.low, 0.95),
      ],
      'dob': [
        _PatternDef(RegExp(r'(?:dob|date\s*of\s*birth|born|birthday)[\s:]+[0-9]{1,2}[/\-][0-9]{1,2}[/\-][0-9]{2,4}', caseSensitive: false), 'Date of birth', SensitivityLevel.medium, 0.90),
        _PatternDef(RegExp(r'(?:dob|date\s*of\s*birth|born|birthday)\s+is\s+[0-9]{1,2}[/\-][0-9]{1,2}[/\-][0-9]{2,4}', caseSensitive: false), 'Date of birth', SensitivityLevel.medium, 0.90),
      ],
      'ip_address': [
        _PatternDef(RegExp(r'\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'), 'IPv4 address', SensitivityLevel.medium, 0.90),
      ],
    };
  }

  /// Analyze text for sensitive data (runs entirely on-device)
  Map<String, dynamic> analyze(String text) {
    final matches = <Map<String, dynamic>>[];
    final categoriesFound = <String>{};
    var highestSensitivity = SensitivityLevel.none;

    for (final entry in _patterns.entries) {
      final category = entry.key;
      for (final pattern in entry.value) {
        for (final match in pattern.regex.allMatches(text)) {
          final matchedText = match.group(0) ?? '';
          var confidence = pattern.confidence;

          // Luhn validation for credit cards
          if (category == 'credit_card' && !_validateLuhn(matchedText)) {
            confidence *= 0.5;
            if (confidence < 0.5) continue;
          }

          final masked = _maskText(matchedText, category);

          matches.add({
            'category': category,
            'description': pattern.description,
            'matched_text': matchedText,
            'masked_text': masked,
            'sensitivity': pattern.sensitivity.name,
            'confidence': double.parse(confidence.toStringAsFixed(2)),
            'position': {'start': match.start, 'end': match.end},
          });

          categoriesFound.add(category);

          if (pattern.sensitivity.rank > highestSensitivity.rank) {
            highestSensitivity = pattern.sensitivity;
          }
        }
      }
    }

    // Deduplicate by position
    final deduped = _deduplicateMatches(matches);

    // Recommendation
    final recommendation = _generateRecommendation(
        highestSensitivity, categoriesFound.toList());

    return {
      'has_sensitive_data': deduped.isNotEmpty,
      'sensitivity_level': highestSensitivity.name,
      'total_matches': deduped.length,
      'categories': categoriesFound.toList(),
      'matches': deduped,
      'recommendation': recommendation,
    };
  }

  /// Return text with sensitive data replaced by masks
  String redactText(String text) {
    final result = analyze(text);
    if (result['has_sensitive_data'] != true) return text;

    final matches = result['matches'] as List<Map<String, dynamic>>;
    final sorted = List<Map<String, dynamic>>.from(matches)
      ..sort((a, b) => (b['position']['start'] as int)
          .compareTo(a['position']['start'] as int));

    var redacted = text;
    for (final match in sorted) {
      final start = match['position']['start'] as int;
      final end = match['position']['end'] as int;
      redacted = redacted.substring(0, start) +
          (match['masked_text'] as String) +
          redacted.substring(end);
    }
    return redacted;
  }

  bool _validateLuhn(String cardNumber) {
    final digits = cardNumber.replaceAll(RegExp(r'[-\s]'), '');
    if (!RegExp(r'^\d+$').hasMatch(digits) || digits.length < 13) return false;

    var total = 0;
    final reversed = digits.split('').reversed.toList();
    for (var i = 0; i < reversed.length; i++) {
      var n = int.parse(reversed[i]);
      if (i % 2 == 1) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      total += n;
    }
    return total % 10 == 0;
  }

  String _maskText(String text, String category) {
    final clean = text.replaceAll(RegExp(r'[-\s]'), '');
    switch (category) {
      case 'credit_card':
        return '****-****-****-${clean.substring(clean.length - 4)}';
      case 'phone':
        return '***-***-${clean.substring(clean.length - 4)}';
      case 'ssn':
        return '***-**-${clean.substring(clean.length - 4)}';
      case 'email':
        final parts = text.split('@');
        if (parts.length == 2) return '${parts[0][0]}***@${parts[1]}';
        return '****';
      case 'password':
      case 'pin':
      case 'api_key':
      case 'cvv':
      case 'otp':
        return '*' * (text.length > 12 ? 12 : text.length);
      default:
        if (text.length > 4) {
          return '${text.substring(0, 2)}${'*' * (text.length - 4)}${text.substring(text.length - 2)}';
        }
        return '*' * text.length;
    }
  }

  List<Map<String, dynamic>> _deduplicateMatches(
      List<Map<String, dynamic>> matches) {
    matches.sort(
        (a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final m in matches) {
      final key = '${m['position']['start']}-${m['position']['end']}';
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(m);
      }
    }
    return unique;
  }

  String _generateRecommendation(
      SensitivityLevel level, List<String> categories) {
    switch (level) {
      case SensitivityLevel.none:
        return 'No sensitive data detected. Safe to send.';
      case SensitivityLevel.low:
        return 'Low sensitivity data detected. Consider if the recipient needs this.';
      case SensitivityLevel.medium:
        return 'Medium sensitivity data detected. Verify you trust the recipient.';
      case SensitivityLevel.high:
        return 'High sensitivity data detected! Only send if absolutely necessary.';
      case SensitivityLevel.critical:
        final cats = categories.take(3).join(', ');
        return 'CRITICAL: Highly sensitive data detected ($cats)! Strongly recommend NOT sending.';
    }
  }
}
