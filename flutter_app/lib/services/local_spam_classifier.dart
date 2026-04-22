// lib/services/local_spam_classifier.dart
// ==========================================
// On-device spam classifier — runs entirely offline
// Loads exported TF-IDF + Logistic Regression model from assets
//
// This eliminates the need for a backend server for spam detection.
// The model is ~470KB and inference takes <5ms per message.

import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

class LocalSpamClassifier {
  static final LocalSpamClassifier _instance = LocalSpamClassifier._internal();
  factory LocalSpamClassifier() => _instance;
  LocalSpamClassifier._internal();

  // Model data
  Map<String, int>? _vocabulary;
  List<double>? _idf;
  List<double>? _coef; // Logistic regression coefficients
  double _intercept = 0.0;
  List<String>? _classes;
  List<int>? _ngramRange;
  bool _sublinearTf = true;

  // Thresholds
  double _highThreshold = 0.8;
  double _mediumThreshold = 0.5;
  double _lowThreshold = 0.3;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// Load model from assets
  Future<bool> loadModel() async {
    if (_isLoaded) return true;

    try {
      final jsonStr = await rootBundle.loadString('assets/spam_model.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;

      // Load TF-IDF
      final tfidf = data['tfidf'] as Map<String, dynamic>;
      final vocabRaw = tfidf['vocabulary'] as Map<String, dynamic>;
      _vocabulary = vocabRaw.map((k, v) => MapEntry(k, (v as num).toInt()));
      _idf = (tfidf['idf'] as List).map((e) => (e as num).toDouble()).toList();
      _ngramRange = (tfidf['ngram_range'] as List).map((e) => (e as num).toInt()).toList();
      _sublinearTf = tfidf['sublinear_tf'] ?? true;

      // Load classifier
      final classifier = data['classifier'] as Map<String, dynamic>;
      final coefList = classifier['coef'] as List;
      // coef is [[...]] for binary classification — take first (and only) row
      _coef = (coefList[0] as List).map((e) => (e as num).toDouble()).toList();
      _intercept = (classifier['intercept'] as List)[0].toDouble();
      _classes = (classifier['classes'] as List).map((e) => e.toString()).toList();

      // Load thresholds
      final thresholds = data['thresholds'] as Map<String, dynamic>?;
      if (thresholds != null) {
        _highThreshold = (thresholds['high'] as num?)?.toDouble() ?? 0.8;
        _mediumThreshold = (thresholds['medium'] as num?)?.toDouble() ?? 0.5;
        _lowThreshold = (thresholds['low'] as num?)?.toDouble() ?? 0.3;
      }

      _isLoaded = true;
      debugPrint('Local spam classifier loaded: ${_vocabulary!.length} features');
      return true;
    } catch (e) {
      debugPrint('Failed to load local spam model: $e');
      return false;
    }
  }

  /// Predict if a message is spam (runs entirely on-device)
  Map<String, dynamic> predict(String text) {
    if (!_isLoaded) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    // 1. Preprocess
    final processed = _preprocess(text);

    // 2. Generate n-grams
    final tokens = _generateNgrams(processed);

    // 3. Compute TF-IDF vector
    final tfidfVector = _computeTfidf(tokens);

    // 4. Logistic regression: score = dot(tfidf, coef) + intercept
    double score = _intercept;
    for (final entry in tfidfVector.entries) {
      score += entry.value * _coef![entry.key];
    }

    // 5. Sigmoid to get probability
    final spamProbability = _sigmoid(score);
    final isSpam = spamProbability >= 0.5;
    final confidence = isSpam ? spamProbability : (1.0 - spamProbability);

    // 6. Risk level
    String riskLevel;
    if (spamProbability >= _highThreshold) {
      riskLevel = 'high';
    } else if (spamProbability >= _mediumThreshold) {
      riskLevel = 'medium';
    } else if (spamProbability >= _lowThreshold) {
      riskLevel = 'low';
    } else {
      riskLevel = 'safe';
    }

    return {
      'is_spam': isSpam,
      'label': isSpam ? 'spam' : 'ham',
      'confidence': double.parse(confidence.toStringAsFixed(4)),
      'spam_probability': double.parse(spamProbability.toStringAsFixed(4)),
      'risk_level': riskLevel,
    };
  }

  /// Preprocess text (mirrors Python TextPreprocessor)
  String _preprocess(String text) {
    var t = text.toLowerCase();

    // Replace URLs
    t = t.replaceAll(RegExp(r'http\S+|www\.\S+'), ' urllink ');
    // Replace emails
    t = t.replaceAll(RegExp(r'\S+@\S+'), ' emailaddr ');
    // Replace phone numbers
    t = t.replaceAll(RegExp(r'\b\d{10,}\b'), ' phonenumber ');
    t = t.replaceAll(RegExp(r'\+\d{1,3}[-.\s]?\d+'), ' phonenumber ');
    // Replace currency
    t = t.replaceAll(RegExp(r'[\$£€]\s*\d+[,.]?\d*'), ' moneysymbol ');
    t = t.replaceAll(RegExp(r'\d+\s*(?:dollars?|pounds?|euros?)'), ' moneysymbol ');
    // Replace numbers
    t = t.replaceAll(RegExp(r'\b\d+\b'), ' number ');
    // Replace repeated punctuation
    t = t.replaceAll(RegExp(r'[!]{2,}'), ' multiplebang ');
    t = t.replaceAll(RegExp(r'[?]{2,}'), ' multiplequestion ');
    t = t.replaceAll(RegExp(r'[.]{2,}'), ' ellipsis ');
    // Remove punctuation
    t = t.replaceAll(RegExp(r'[^\w\s]'), '');
    // Normalize whitespace
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();

    return t;
  }

  /// Generate n-grams from preprocessed text
  List<String> _generateNgrams(String text) {
    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    final ngrams = <String>[];
    final minN = _ngramRange![0];
    final maxN = _ngramRange![1];

    for (var n = minN; n <= maxN; n++) {
      for (var i = 0; i <= words.length - n; i++) {
        ngrams.add(words.sublist(i, i + n).join(' '));
      }
    }
    return ngrams;
  }

  /// Compute TF-IDF sparse vector
  Map<int, double> _computeTfidf(List<String> tokens) {
    // Count term frequencies
    final tf = <int, int>{};
    for (final token in tokens) {
      final idx = _vocabulary![token];
      if (idx != null) {
        tf[idx] = (tf[idx] ?? 0) + 1;
      }
    }

    // Apply TF-IDF weighting
    final tfidfVector = <int, double>{};
    for (final entry in tf.entries) {
      var tfValue = entry.value.toDouble();
      if (_sublinearTf) {
        tfValue = 1.0 + log(tfValue);
      }
      tfidfVector[entry.key] = tfValue * _idf![entry.key];
    }

    // L2 normalize
    double norm = 0.0;
    for (final v in tfidfVector.values) {
      norm += v * v;
    }
    norm = sqrt(norm);

    if (norm > 0) {
      for (final key in tfidfVector.keys.toList()) {
        tfidfVector[key] = tfidfVector[key]! / norm;
      }
    }

    return tfidfVector;
  }

  double _sigmoid(double x) => 1.0 / (1.0 + exp(-x));
}
