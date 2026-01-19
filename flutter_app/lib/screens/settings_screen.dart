// lib/screens/settings_screen.dart
// ==================================
// App settings and configuration

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _spamAlertsEnabled = true;
  bool _dlpAlertsEnabled = true;
  bool _isCheckingConnection = false;
  bool? _isConnected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Server Connection
          _buildSectionHeader('Server Connection'),
          ListTile(
            leading: const Icon(Icons.cloud),
            title: const Text('Backend Server'),
            subtitle: Text(ApiService.baseUrl),
            trailing: _isCheckingConnection
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isConnected == null
                        ? Icons.help_outline
                        : _isConnected!
                            ? Icons.check_circle
                            : Icons.error,
                    color: _isConnected == null
                        ? Colors.grey
                        : _isConnected!
                            ? Colors.green
                            : Colors.red,
                  ),
            onTap: _checkConnection,
          ),

          const Divider(),

          // Notifications
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive alerts for detected threats'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.email),
            title: const Text('Spam Alerts'),
            subtitle: const Text('Notify when spam is detected'),
            value: _spamAlertsEnabled,
            onChanged: _notificationsEnabled
                ? (value) => setState(() => _spamAlertsEnabled = value)
                : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.security),
            title: const Text('DLP Alerts'),
            subtitle: const Text('Notify for sensitive data warnings'),
            value: _dlpAlertsEnabled,
            onChanged: _notificationsEnabled
                ? (value) => setState(() => _dlpAlertsEnabled = value)
                : null,
          ),

          const Divider(),

          // About
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('About Sifitlier'),
            subtitle: const Text('AI-powered security for your messages'),
            onTap: () => _showAboutDialog(context),
          ),

          const Divider(),

          // Data
          _buildSectionHeader('Data'),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Clear Local Data'),
            subtitle: const Text('Remove cached data from this device'),
            onTap: () => _showClearDataDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isCheckingConnection = true;
      _isConnected = null;
    });

    final connected = await ApiService.healthCheck();

    setState(() {
      _isCheckingConnection = false;
      _isConnected = connected;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(connected
              ? '✅ Connected to server'
              : '❌ Cannot connect to server'),
          backgroundColor: connected ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shield, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Sifitlier'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI-Powered Security Assistant',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Sifitlier helps protect you from spam, phishing, and accidental data leaks across SMS, Email, and Telegram.',
            ),
            SizedBox(height: 16),
            Text('Features:'),
            Text('• Spam Detection (Email, SMS, Telegram)'),
            Text('• Data Loss Prevention (DLP)'),
            Text('• Real-time Notifications'),
            Text('• Security Handbook'),
            SizedBox(height: 16),
            Text(
              'Final Year Project',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Local Data?'),
        content: const Text(
          'This will remove all cached data from your device. Your alert history on the server will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Local data cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
