// lib/screens/protection_screen.dart
// ====================================
// UPDATED: Protection screen with improved DLP monitoring
// SMS monitoring: auto-scan incoming SMS
// Clipboard: only monitors within app context

import 'package:flutter/material.dart';
import '../services/sms_monitor_service.dart';
import '../services/clipboard_monitor_service.dart';
import '../services/notification_service.dart';
import 'dlp_check_screen.dart';

class ProtectionScreen extends StatefulWidget {
  const ProtectionScreen({super.key});

  @override
  State<ProtectionScreen> createState() => _ProtectionScreenState();
}

class _ProtectionScreenState extends State<ProtectionScreen>
    with WidgetsBindingObserver {
  final _smsMonitor = SmsMonitorService();
  final _clipboardMonitor = ClipboardMonitorService();

  bool _smsMonitoringEnabled = false;
  bool _clipboardMonitoringEnabled = false;
  bool _isLoading = false;

  List<Map<String, dynamic>> _recentAlerts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Track app lifecycle for clipboard monitoring
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _clipboardMonitor.setAppForegroundState(
      state == AppLifecycleState.resumed,
    );
  }

  Future<void> _initializeServices() async {
    await NotificationService().initialize();

    setState(() {
      _smsMonitoringEnabled = _smsMonitor.isMonitoring;
      _clipboardMonitoringEnabled = _clipboardMonitor.isMonitoring;
    });

    // SMS spam detection callback
    _smsMonitor.onSpamDetected = (message, result) {
      setState(() {
        _recentAlerts.insert(0, {
          'type': 'spam',
          'sender': message.address ?? 'Unknown',
          'preview': message.body?.substring(
                  0, message.body!.length > 50 ? 50 : message.body!.length) ??
              '',
          'risk_level': result['risk_level'],
          'time': DateTime.now(),
        });
        if (_recentAlerts.length > 20) _recentAlerts.removeLast();
      });
    };

    // Clipboard sensitive data callback
    _clipboardMonitor.onSensitiveDataDetected = (content, result) {
      setState(() {
        _recentAlerts.insert(0, {
          'type': 'dlp_clipboard',
          'content':
              content.substring(0, content.length > 50 ? 50 : content.length),
          'categories': result['categories'],
          'sensitivity': result['sensitivity_level'],
          'time': DateTime.now(),
        });
        if (_recentAlerts.length > 20) _recentAlerts.removeLast();
      });
    };
  }

  Future<void> _toggleSmsMonitoring(bool enable) async {
    setState(() => _isLoading = true);

    if (enable) {
      final success = await _smsMonitor.startMonitoring();
      setState(() {
        _smsMonitoringEnabled = success;
        _isLoading = false;
      });

      if (!success) {
        _showSnackBar(
            'Failed to start SMS monitoring. Check permissions.', Colors.red);
      } else {
        _showSnackBar('SMS monitoring enabled ✅', Colors.green);
      }
    } else {
      _smsMonitor.stopMonitoring();
      setState(() {
        _smsMonitoringEnabled = false;
        _isLoading = false;
      });
      _showSnackBar('SMS monitoring disabled', Colors.grey);
    }
  }

  void _toggleClipboardMonitoring(bool enable) {
    if (enable) {
      _clipboardMonitor.startMonitoring();
      _showSnackBar('Clipboard monitoring enabled ✅', Colors.green);
    } else {
      _clipboardMonitor.stopMonitoring();
      _showSnackBar('Clipboard monitoring disabled', Colors.grey);
    }

    setState(() => _clipboardMonitoringEnabled = enable);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Protection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),

            const SizedBox(height: 24),

            // Protection Options
            const Text(
              'Inbound Protection (Automatic)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Automatically scans incoming messages for threats',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // SMS Monitoring
            _buildProtectionTile(
              title: 'SMS Monitoring',
              subtitle: 'Auto-scan incoming SMS for spam & phishing',
              icon: Icons.sms,
              color: Colors.blue,
              enabled: _smsMonitoringEnabled,
              onChanged: _isLoading ? null : _toggleSmsMonitoring,
            ),

            const SizedBox(height: 24),

            // Outbound Protection
            const Text(
              'Outbound Protection',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Checks your messages for sensitive data before sending',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Clipboard Monitoring (less aggressive)
            _buildProtectionTile(
              title: 'Clipboard Monitoring',
              subtitle: 'Alerts when you copy sensitive data (in-app only)',
              icon: Icons.content_paste,
              color: Colors.orange,
              enabled: _clipboardMonitoringEnabled,
              onChanged: _toggleClipboardMonitoring,
            ),

            const SizedBox(height: 12),

            // Check Before Sending Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DLPCheckScreen()),
                ),
                icon: const Icon(Icons.security),
                label: const Text('Check Message Before Sending'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Scan Existing SMS
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _scanExistingSms,
                icon: const Icon(Icons.search),
                label: const Text('Scan Existing SMS Inbox'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recent Alerts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Alerts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (_recentAlerts.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _recentAlerts.clear()),
                    child:
                        const Text('Clear All', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_recentAlerts.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.shield, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No alerts yet',
                            style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 4),
                        Text(
                          'Enable protection and alerts will appear here',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ..._recentAlerts.map((alert) => _buildAlertCard(alert)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isProtected = _smsMonitoringEnabled || _clipboardMonitoringEnabled;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isProtected
                ? [Colors.green, Colors.green.shade700]
                : [Colors.grey, Colors.grey.shade700],
          ),
        ),
        child: Row(
          children: [
            Icon(
              isProtected ? Icons.shield : Icons.shield_outlined,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isProtected ? 'Protection Active' : 'Protection Disabled',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isProtected
                        ? 'Your device is being monitored for threats'
                        : 'Enable protection to start monitoring',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtectionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool enabled,
    required Function(bool)? onChanged,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Switch(
          value: enabled,
          onChanged: onChanged,
          activeColor: color,
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final type = alert['type'] as String;
    final isSpam = type == 'spam';
    final color = isSpam ? Colors.red : Colors.orange;

    String title;
    String subtitle;

    if (isSpam) {
      title = 'Spam SMS Detected';
      subtitle = 'From: ${alert['sender']}';
    } else {
      final categories = alert['categories'] as List? ?? [];
      title = 'Sensitive Data Copied';
      subtitle = 'Categories: ${categories.join(", ")}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(
            isSpam ? Icons.sms : Icons.content_paste,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: Text(
          _formatTime(alert['time']),
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _scanExistingSms() async {
    _showSnackBar('Scanning existing SMS...', Colors.blue);

    setState(() => _isLoading = true);

    try {
      final results = await _smsMonitor.scanExistingSms(limit: 10);

      int spamCount = 0;
      for (final result in results) {
        if (result['result']['is_spam'] == true) {
          spamCount++;
          // Add to recent alerts
          final msg = result['message'];
          setState(() {
            _recentAlerts.insert(0, {
              'type': 'spam',
              'sender': msg.address ?? 'Unknown',
              'preview': msg.body?.substring(
                      0, msg.body!.length > 50 ? 50 : msg.body!.length) ??
                  '',
              'risk_level': result['result']['risk_level'],
              'time': DateTime.now(),
            });
          });
        }
      }

      _showSnackBar(
        'Scan complete: $spamCount spam found in ${results.length} messages',
        spamCount > 0 ? Colors.orange : Colors.green,
      );
    } catch (e) {
      _showSnackBar('Error scanning SMS: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
