// lib/screens/dlp_check_screen.dart
// ===================================
// Screen to check outgoing messages for sensitive data

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DLPCheckScreen extends StatefulWidget {
  const DLPCheckScreen({super.key});

  @override
  State<DLPCheckScreen> createState() => _DLPCheckScreenState();
}

class _DLPCheckScreenState extends State<DLPCheckScreen> {
  final _messageController = TextEditingController();
  final _recipientController = TextEditingController();
  String _selectedSource = 'email';
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  final _sources = [
    {'value': 'sms', 'label': 'SMS', 'icon': Icons.sms},
    {'value': 'email', 'label': 'Email', 'icon': Icons.email},
    {'value': 'telegram', 'label': 'Telegram', 'icon': Icons.telegram},
  ];

  Future<void> _checkDLP() async {
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
      final result = await ApiService.checkDLP(
        userId: 'default_user',
        message: _messageController.text,
        source: _selectedSource,
        recipient: _recipientController.text.isNotEmpty
            ? _recipientController.text
            : null,
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
    _recipientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DLP Protection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Check your message for sensitive data like credit cards, passwords, or personal IDs before sending.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Destination Selection
            const Text(
              'Send via',
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

            // Recipient Field
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(
                labelText: 'Recipient (optional)',
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
                labelText: 'Your Message',
                hintText: 'Type or paste the message you plan to send...',
                prefixIcon: Icon(Icons.message),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            // Check Button
            ElevatedButton(
              onPressed: _isLoading ? null : _checkDLP,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
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
                  : const Text('Check for Sensitive Data'),
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
                      Text('Error: $_error', textAlign: TextAlign.center),
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
    final hasSensitiveData = _result!['has_sensitive_data'] ?? false;
    final sensitivityLevel = _result!['sensitivity_level'] ?? 'none';
    final categories = List<String>.from(_result!['categories'] ?? []);
    final recommendation = _result!['recommendation'] ?? '';
    final totalMatches = _result!['total_matches'] ?? 0;

    Color cardColor;
    IconData icon;
    String title;

    if (!hasSensitiveData) {
      cardColor = Colors.green;
      icon = Icons.check_circle;
      title = '✅ SAFE TO SEND';
    } else {
      switch (sensitivityLevel) {
        case 'critical':
          cardColor = Colors.red;
          icon = Icons.dangerous;
          title = '🛑 CRITICAL - DO NOT SEND';
          break;
        case 'high':
          cardColor = Colors.deepOrange;
          icon = Icons.warning;
          title = '⚠️ HIGH RISK';
          break;
        case 'medium':
          cardColor = Colors.orange;
          icon = Icons.info;
          title = '⚡ MEDIUM RISK';
          break;
        default:
          cardColor = Colors.amber;
          icon = Icons.info_outline;
          title = 'ℹ️ LOW RISK';
      }
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
                      fontSize: 18,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                    'Sensitivity Level', sensitivityLevel.toUpperCase()),
                _buildDetailRow('Items Detected', '$totalMatches'),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Detected Categories:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories
                        .map((cat) => Chip(
                              label: Text(cat),
                              backgroundColor: cardColor.withOpacity(0.2),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          recommendation,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
