// lib/screens/logs_screen.dart
// ==============================
// Screen showing alert history/logs

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allLogs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await ApiService.getAlerts(userId: 'default_user');
      setState(() {
        _allLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _spamLogs =>
      _allLogs.where((log) => log['alert_type'] == 'spam').toList();

  List<Map<String, dynamic>> get _dlpLogs =>
      _allLogs.where((log) => log['alert_type'] == 'dlp').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All (${_allLogs.length})'),
            Tab(text: 'Spam (${_spamLogs.length})'),
            Tab(text: 'DLP (${_dlpLogs.length})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLogs,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLogList(_allLogs),
                      _buildLogList(_spamLogs),
                      _buildLogList(_dlpLogs),
                    ],
                  ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadLogs,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No alerts yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final alertType = log['alert_type'] ?? 'unknown';
    final source = log['source'] ?? 'unknown';
    final timestamp = log['timestamp'] ?? '';
    final preview = log['message_preview'] ?? 'No preview available';

    // Determine card style based on alert type
    IconData icon;
    Color color;
    String title;

    if (alertType == 'spam') {
      final isSpam = log['is_spam'] ?? false;
      final riskLevel = log['spam_risk_level'] ?? 'low';

      if (isSpam) {
        switch (riskLevel) {
          case 'high':
            icon = Icons.dangerous;
            color = Colors.red;
            title = 'High Risk Spam';
            break;
          case 'medium':
            icon = Icons.warning;
            color = Colors.orange;
            title = 'Medium Risk Spam';
            break;
          default:
            icon = Icons.info;
            color = Colors.amber;
            title = 'Low Risk Spam';
        }
      } else {
        icon = Icons.check;
        color = Colors.green;
        title = 'Safe Message';
      }
    } else {
      // DLP
      final hasSensitive = log['has_sensitive_data'] ?? false;
      final level = log['dlp_sensitivity_level'] ?? 'none';

      if (hasSensitive) {
        switch (level) {
          case 'critical':
            icon = Icons.dangerous;
            color = Colors.red;
            title = 'Critical DLP Alert';
            break;
          case 'high':
            icon = Icons.warning;
            color = Colors.deepOrange;
            title = 'High DLP Alert';
            break;
          default:
            icon = Icons.info;
            color = Colors.orange;
            title = 'DLP Warning';
        }
      } else {
        icon = Icons.check;
        color = Colors.green;
        title = 'Safe to Send';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(_getSourceIcon(source), size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  source.toUpperCase(),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(timestamp),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showLogDetail(log),
      ),
    );
  }

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'sms':
        return Icons.sms;
      case 'email':
        return Icons.email;
      case 'telegram':
        return Icons.telegram;
      default:
        return Icons.message;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return timestamp;
    }
  }

  void _showLogDetail(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Alert Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              _buildDetailItem(
                  'Type', log['alert_type']?.toUpperCase() ?? 'N/A'),
              _buildDetailItem('Source', log['source']?.toUpperCase() ?? 'N/A'),
              _buildDetailItem('Direction', log['direction'] ?? 'N/A'),
              _buildDetailItem('Time', log['timestamp'] ?? 'N/A'),
              const Divider(),
              const Text('Message Preview:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(log['message_preview'] ?? 'No preview'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
