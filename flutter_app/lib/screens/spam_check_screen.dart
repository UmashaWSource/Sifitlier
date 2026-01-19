// lib/screens/spam_check_screen.dart
// ====================================
// Screen to manually check messages for spam

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SpamCheckScreen extends StatefulWidget {
  const SpamCheckScreen({super.key});

  @override
  State<SpamCheckScreen> createState() => _SpamCheckScreenState();
}

class _SpamCheckScreenState extends State<SpamCheckScreen> {
  final _messageController = TextEditingController();
  final _senderController = TextEditingController();
  String _selectedSource = 'sms';
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  final _sources = [
    {'value': 'sms', 'label': 'SMS', 'icon': Icons.sms},
    {'value': 'email', 'label': 'Email', 'icon': Icons.email},
    {'value': 'telegram', 'label': 'Telegram', 'icon': Icons.telegram},
  ];

  Future<void> _checkSpam() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message to check')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      final result = await ApiService.checkSpam(
        userId: 'default_user',
        message: _messageController.text,
        source: _selectedSource,
        sender:
            _senderController.text.isNotEmpty ? _senderController.text : null,
      );

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spam Detection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Source Selection
            const Text(
              'Message Source',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: _sources
                  .map((s) => ButtonSegment(
                        value: s['value'] as String,
                        label: Text(s['label'] as String),
                        icon: Icon(s['icon'] as IconData),
                      ))
                  .toList(),
              selected: {_selectedSource},
              onSelectionChanged: (selected) {
                setState(() => _selectedSource = selected.first);
              },
            ),

            const SizedBox(height: 16),

            // Sender Field
            TextField(
              controller: _senderController,
              decoration: const InputDecoration(
                labelText: 'Sender (optional)',
                hintText: 'Phone number or email',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Message Field
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Paste the message you want to check...',
                prefixIcon: Icon(Icons.message),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            // Check Button
            ElevatedButton(
              onPressed: _isLoading ? null : _checkSpam,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Check for Spam'),
            ),

            const SizedBox(height: 24),

            // Results
            if (_error != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Error',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[900],
                        ),
                      ),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),
              ),

            if (_result != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final isSpam = _result!['is_spam'] ?? false;
    final confidence = (_result!['confidence'] ?? 0.0) * 100;
    final spamProbability = (_result!['spam_probability'] ?? 0.0) * 100;
    final riskLevel = _result!['risk_level'] ?? 'unknown';

    Color cardColor;
    IconData icon;
    String title;

    if (isSpam) {
      switch (riskLevel) {
        case 'high':
          cardColor = Colors.red;
          icon = Icons.dangerous;
          title = '⚠️ HIGH RISK SPAM';
          break;
        case 'medium':
          cardColor = Colors.orange;
          icon = Icons.warning;
          title = '⚡ MEDIUM RISK SPAM';
          break;
        default:
          cardColor = Colors.amber;
          icon = Icons.info;
          title = '⚠️ POSSIBLE SPAM';
      }
    } else {
      cardColor = Colors.green;
      icon = Icons.check_circle;
      title = '✅ LOOKS SAFE';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(
                    'Classification', isSpam ? 'SPAM' : 'HAM (Safe)'),
                _buildDetailRow('Spam Probability',
                    '${spamProbability.toStringAsFixed(1)}%'),
                _buildDetailRow(
                    'Confidence', '${confidence.toStringAsFixed(1)}%'),
                _buildDetailRow('Risk Level', riskLevel.toUpperCase()),
                if (_result!['alert_id'] != null)
                  _buildDetailRow('Alert ID', '#${_result!['alert_id']}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
