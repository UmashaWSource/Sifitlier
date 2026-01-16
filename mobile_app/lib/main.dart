import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const SifitlierApp());
}

class SifitlierApp extends StatelessWidget {
  const SifitlierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sifitlier',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String statusMessage = "System Secure";
  int threatsDetected = 0;
  int messagesScanned = 0;

  //New Frontend testing section
  @override
  void initState() {
    super.initState();
    testConnection(); // This runs automatically when the app opens
  }

  void testConnection() async {
    print('Testing connection to backend...');
    try {
      // Using 10.0.2.2 because you are likely on Android Emulator
      final url = Uri.parse('http://10.0.2.2:8000');

      // We use a short timeout so the app doesn't freeze
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          statusMessage = "Backend Connected!"; // Updates the UI
        });
      }
    } catch (e) {
      print('Connection Error: $e');
      setState(() {
        statusMessage = "Offline Mode"; // Optional: Show if offline
      });
    }
  }

  // basic code for the dashoard page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Sifitlier Security"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              // Security Status Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.security, size: 80, color: Colors.green),
                      const SizedBox(height: 20),
                      Text(
                        statusMessage,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your device is protected',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Statistics Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Messages Scanned',
                      messagesScanned.toString(),
                      Icons.message,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      'Threats Blocked',
                      threatsDetected.toString(),
                      Icons.block,
                      Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action Buttons
              _buildActionButton(
                context,
                'Compose & Scan Message',
                Icons.edit,
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessageComposePage(
                        onMessageScanned: () {
                          setState(() {
                            messagesScanned++;
                          });
                        },
                        onThreatDetected: () {
                          setState(() {
                            threatsDetected++;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              _buildActionButton(
                context,
                'DLP Manual Scan',
                Icons.search,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DLPManualScanPage(
                        onMessageScanned: () {
                          setState(() {
                            messagesScanned++;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              _buildActionButton(
                context,
                'View Scan History',
                Icons.history,
                Colors.green,
                () {
                  // TODO: Navigate to history page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('History feature coming soon!'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// ============================================================================
// MESSAGE COMPOSE PAGE - SIMULATES SENDING MESSAGE WITH DLP CHECK
// ============================================================================

class MessageComposePage extends StatefulWidget {
  final VoidCallback onMessageScanned;
  final VoidCallback onThreatDetected;

  const MessageComposePage({
    super.key,
    required this.onMessageScanned,
    required this.onThreatDetected,
  });

  @override
  State<MessageComposePage> createState() => _MessageComposePageState();
}

class _MessageComposePageState extends State<MessageComposePage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  bool _isScanning = false;

  // CHANGE THIS TO YOUR BACKEND URL
  // For Android Emulator: http://10.0.2.2:8000
  // For Physical Device: http://YOUR_PC_IP:8000
  final String apiUrl = 'http://10.0.2.2:8000/api/dlp/scan';

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      _showSnackBar('Please enter a message', Colors.orange);
      return;
    }

    if (_recipientController.text.trim().isEmpty) {
      _showSnackBar('Please enter recipient', Colors.orange);
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      // Scan message for sensitive data
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _messageController.text,
          'source': 'sms',
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        widget.onMessageScanned();

        // Check if sensitive data detected
        if (result['total_detections'] > 0) {
          widget.onThreatDetected();
          // Show warning dialog - BLOCK SENDING
          _showDLPWarningDialog(result);
        } else {
          // Safe to send
          _showSuccessDialog();
        }
      } else {
        throw Exception('Failed to scan: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error connecting to security service: $e', Colors.red);
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  void _showDLPWarningDialog(Map<String, dynamic> scanResult) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red[50],
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 60,
          ),
          title: const Text(
            '⚠️ SENSITIVE DATA DETECTED!',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risk Level: ${scanResult['risk_level']}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getRiskColor(scanResult['risk_level']),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Risk Score: ${scanResult['risk_score']}/100',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    scanResult['message'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Detected sensitive data:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ...((scanResult['detections'] as List).map((detection) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shield,
                                size: 16,
                                color: _getSensitivityColor(
                                    detection['sensitivity']),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  detection['type'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Found: ${detection['masked_value']}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            detection['recommendation'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sending this message may compromise your security or privacy.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear message for safety
                _messageController.clear();
                _showSnackBar(
                  '✓ Message cancelled for your safety',
                  Colors.green,
                );
              },
              child: const Text(
                'CANCEL SENDING',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showConfirmSendDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'SEND ANYWAY',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmSendDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ Final Warning'),
          content: const Text(
            'Are you absolutely sure you want to send this message containing sensitive data?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _messageController.clear();
                _recipientController.clear();
                _showSnackBar('Message cancelled', Colors.green);
              },
              child: const Text('NO, CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _simulateSendMessage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('YES, SEND'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.green[50],
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 60,
          ),
          title: const Text(
            '✓ Safe to Send',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No sensitive data detected in your message.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Your message is safe to send!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _simulateSendMessage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('SEND MESSAGE'),
            ),
          ],
        );
      },
    );
  }

  void _simulateSendMessage() {
    // In real app, this would send via SMS API
    _showSnackBar(
      '✓ Message sent to ${_recipientController.text}',
      Colors.green,
    );
    _messageController.clear();
    _recipientController.clear();
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.deepOrange;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.yellow[700]!;
      default:
        return Colors.green;
    }
  }

  Color _getSensitivityColor(String sensitivity) {
    switch (sensitivity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Message'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Your message will be scanned for sensitive data before sending',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(
                labelText: 'To',
                hintText: 'Enter recipient phone number',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Type your message here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _sendMessage,
              icon: _isScanning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isScanning ? 'Scanning...' : 'Send Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quick test examples:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickFillChip('Safe: Meet at 3pm tomorrow'),
                _buildQuickFillChip('Credit Card: 4532-1234-5678-9010'),
                _buildQuickFillChip('NIC: 199512345678, Phone: 0771234567'),
                _buildQuickFillChip('Password: SecretPass123!'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFillChip(String text) {
    return ActionChip(
      label: Text(
        text.length > 30 ? '${text.substring(0, 30)}...' : text,
        style: const TextStyle(fontSize: 10),
      ),
      onPressed: () {
        _messageController.text = text.replaceFirst(RegExp(r'^[^:]+:\s*'), '');
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recipientController.dispose();
    super.dispose();
  }
}

// ============================================================================
// DLP MANUAL SCAN PAGE - FOR TESTING
// ============================================================================

class DLPManualScanPage extends StatefulWidget {
  final VoidCallback onMessageScanned;

  const DLPManualScanPage({
    super.key,
    required this.onMessageScanned,
  });

  @override
  State<DLPManualScanPage> createState() => _DLPManualScanPageState();
}

class _DLPManualScanPageState extends State<DLPManualScanPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _scanResult;

  final String apiUrl = 'http://10.0.2.2:8000/api/dlp/scan';
  // For Chrome (or Windows)

  Future<void> _scanText() async {
    if (_textController.text.trim().isEmpty) {
      _showSnackBar('Please enter some text to scan', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _scanResult = null;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _textController.text,
          'source': 'manual',
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        widget.onMessageScanned();
        setState(() {
          _scanResult = result;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to scan: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.deepOrange;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.yellow[700]!;
      default:
        return Colors.green;
    }
  }

  Color _getSensitivityColor(String sensitivity) {
    switch (sensitivity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DLP Manual Scan'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Text to Scan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Type or paste text here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _scanText,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: Text(
                              _isLoading
                                  ? 'Scanning...'
                                  : 'Scan for Sensitive Data',
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            _textController.clear();
                            setState(() {
                              _scanResult = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_scanResult != null) _buildScanResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanResults() {
    if (_scanResult == null) return const SizedBox.shrink();

    final riskLevel = _scanResult!['risk_level'];
    final riskScore = _scanResult!['risk_score'];
    final detections = _scanResult!['detections'] as List;

    return Card(
      elevation: 4,
      color: _getRiskColor(riskLevel).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  riskLevel == 'SAFE'
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  color: _getRiskColor(riskLevel),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Risk Level: $riskLevel',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getRiskColor(riskLevel),
                        ),
                      ),
                      Text(
                        'Score: $riskScore/100',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: riskScore / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getRiskColor(riskLevel),
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            Text(
              _scanResult!['message'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (detections.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Detected Sensitive Data:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...detections.map((detection) => _buildDetectionCard(detection)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionCard(Map<String, dynamic> detection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getSensitivityColor(detection['sensitivity']),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    detection['sensitivity'].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detection['type'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Detected: ${detection['masked_value']}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detection['recommendation'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
