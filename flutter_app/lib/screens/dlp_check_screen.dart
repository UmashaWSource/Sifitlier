// lib/screens/dlp_check_screen.dart
// ===================================
// REDESIGNED: Outgoing Message Guard
// Checks messages BEFORE sending and asks user to confirm or cancel
// Logs user decisions (proceed/cancel)

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
  String _selectedSource = 'sms';
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;

  // Track user decisions for logging
  final List<Map<String, dynamic>> _decisionLog = [];

  final _sources = [
    {'value': 'sms', 'label': 'SMS', 'icon': Icons.sms},
    {'value': 'email', 'label': 'Email', 'icon': Icons.email},
    {'value': 'telegram', 'label': 'Telegram', 'icon': Icons.telegram},
  ];

  Future<void> _checkBeforeSending() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your message')),
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
        userId: 'device_user',
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

      // If sensitive data found, show warning dialog
      if (result['has_sensitive_data'] == true) {
        _showWarningDialog(result);
      } else {
        // Safe to send
        _showSafeDialog();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Show warning dialog when sensitive data is detected
  void _showWarningDialog(Map<String, dynamic> result) {
    final sensitivityLevel = result['sensitivity_level'] ?? 'medium';
    final categories = List<String>.from(result['categories'] ?? []);
    final totalMatches = result['total_matches'] ?? 0;
    final recommendation =
        result['recommendation'] ?? 'Review your message before sending.';

    Color headerColor;
    IconData headerIcon;
    String headerTitle;

    switch (sensitivityLevel) {
      case 'critical':
        headerColor = Colors.red;
        headerIcon = Icons.dangerous;
        headerTitle = '🛑 CRITICAL WARNING';
        break;
      case 'high':
        headerColor = Colors.deepOrange;
        headerIcon = Icons.warning;
        headerTitle = '⚠️ HIGH RISK WARNING';
        break;
      case 'medium':
        headerColor = Colors.orange;
        headerIcon = Icons.info;
        headerTitle = '⚡ MEDIUM RISK';
        break;
      default:
        headerColor = Colors.amber;
        headerIcon = Icons.info_outline;
        headerTitle = 'ℹ️ LOW RISK';
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Force user to make a choice
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(headerIcon, color: Colors.white, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Sensitive data detected in your message',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // What was found
                  const Text(
                    'What was found:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories
                        .map((cat) => Chip(
                              avatar: Icon(
                                _getCategoryIcon(cat),
                                size: 18,
                                color: headerColor,
                              ),
                              label: Text(
                                cat.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: headerColor.withOpacity(0.1),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  Text('Items detected: $totalMatches'),
                  const SizedBox(height: 12),

                  // Recommendation
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recommendation,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Are you sure you want to send this message?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Cancel Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _logDecision(
                  action: 'cancelled',
                  sensitivityLevel: sensitivityLevel,
                  categories: categories,
                );
                _showDecisionConfirmation(false);
              },
              icon: const Icon(Icons.cancel, color: Colors.green),
              label: const Text(
                'Cancel Send',
                style: TextStyle(color: Colors.green),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Colors.green),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Proceed Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _logDecision(
                  action: 'proceeded',
                  sensitivityLevel: sensitivityLevel,
                  categories: categories,
                );
                _showDecisionConfirmation(true);
              },
              icon: const Icon(Icons.send),
              label: const Text('Send Anyway'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  /// Show safe to send dialog
  void _showSafeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              '✅ Safe to Send!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No sensitive data detected in your message. You can safely send it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Great!'),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  /// Show confirmation after user makes a decision
  void _showDecisionConfirmation(bool proceeded) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              proceeded ? Icons.warning : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(proceeded
                ? 'Message sent. Action logged for your records.'
                : 'Message cancelled. Your data is safe!'),
          ],
        ),
        backgroundColor: proceeded ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Log user's decision to the backend
  Future<void> _logDecision({
    required String action,
    required String sensitivityLevel,
    required List<String> categories,
  }) async {
    final logEntry = {
      'action': action,
      'sensitivity_level': sensitivityLevel,
      'categories': categories,
      'source': _selectedSource,
      'recipient': _recipientController.text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Add to local log
    setState(() {
      _decisionLog.insert(0, logEntry);
    });

    // Log to backend via alert action
    if (_result != null && _result!['alert_id'] != null) {
      try {
        await ApiService.updateAlertAction(
          alertId: _result!['alert_id'],
          userId: 'device_user',
          action: action == 'proceeded' ? 'allowed' : 'blocked',
        );
        debugPrint("✅ Decision logged: $action");
      } catch (e) {
        debugPrint("Error logging decision: $e");
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'credit_card':
        return Icons.credit_card;
      case 'password':
        return Icons.lock;
      case 'phone_number':
        return Icons.phone;
      case 'email_address':
        return Icons.email;
      case 'bank_account':
        return Icons.account_balance;
      case 'nric':
      case 'ssn':
        return Icons.badge;
      default:
        return Icons.warning;
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
        title: const Text('Outgoing Message Guard'),
        actions: [
          if (_decisionLog.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: _showDecisionHistory,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              color: Colors.orange[50],
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.shield, color: Colors.orange, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Message Safety Check',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Paste your message here before sending to check for sensitive data like credit cards, passwords, or personal IDs.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Destination Selection
            const Text(
              'Sending via',
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
                labelText: 'Recipient',
                hintText: 'Who are you sending this to?',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Message Field
            TextField(
              controller: _messageController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Your Message',
                hintText: 'Paste the message you are about to send...',
                prefixIcon: Icon(Icons.message),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            // Check Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkBeforeSending,
              icon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.security),
              label: const Text('Check Before Sending'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Error Display
            if (_error != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Error: $_error')),
                    ],
                  ),
                ),
              ),

            // Result Summary (after check)
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildResultSummary(),
            ],

            // Decision History
            if (_decisionLog.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Recent Decisions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._decisionLog.take(5).map((log) => _buildDecisionCard(log)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSummary() {
    final hasSensitive = _result!['has_sensitive_data'] ?? false;
    final level = _result!['sensitivity_level'] ?? 'none';
    final categories = List<String>.from(_result!['categories'] ?? []);

    if (!hasSensitive) {
      return Card(
        color: Colors.green[50],
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Sensitive Data Found',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text(
                      'This message is safe to send.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Color color;
    switch (level) {
      case 'critical':
        color = Colors.red;
        break;
      case 'high':
        color = Colors.deepOrange;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      default:
        color = Colors.amber;
    }

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: color, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${level.toUpperCase()} - Sensitive Data Found',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    'Categories: ${categories.join(", ")}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionCard(Map<String, dynamic> log) {
    final action = log['action'] as String;
    final categories = List<String>.from(log['categories'] ?? []);
    final timestamp = log['timestamp'] as String;
    final proceeded = action == 'proceeded';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: proceeded
              ? Colors.red.withOpacity(0.2)
              : Colors.green.withOpacity(0.2),
          child: Icon(
            proceeded ? Icons.send : Icons.cancel,
            color: proceeded ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          proceeded ? 'Sent despite warning' : 'Cancelled (data protected)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          'Categories: ${categories.join(", ")}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Text(
          _formatTime(timestamp),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } catch (e) {
      return '';
    }
  }

  void _showDecisionHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Decision History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _decisionLog.length,
                itemBuilder: (context, index) =>
                    _buildDecisionCard(_decisionLog[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
