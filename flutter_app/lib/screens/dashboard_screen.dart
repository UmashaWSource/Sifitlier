// =============================================================================
// DASHBOARD SCREEN
// =============================================================================
// Main dashboard with navigation to all Sifitlier features.
// Displays security stats, quick actions, and feature grid.
//
// Features:
// - Security overview (spam blocked, DLP warnings, total alerts)
// - Quick action buttons for common tasks
// - Secure channels integration (Gmail, Telegram)
// - Feature grid for navigation
//
// Author: Umasha Wijenayake
// =============================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/local_inference_service.dart';
import 'spam_check_screen.dart';
import 'dlp_check_screen.dart';
import 'logs_screen.dart';
import 'handbook_screen.dart';
import 'settings_screen.dart';
import 'protection_screen.dart';
import 'gmail_connect_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // =============================================================================
  // STATE VARIABLES
  // =============================================================================
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String? _error;

  // =============================================================================
  // LIFECYCLE METHODS
  // =============================================================================

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // =============================================================================
  // DATA LOADING
  // =============================================================================
  // Fetches security statistics from the backend API

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats =
          await ApiService.getStats(userId: LocalInferenceService().userId);

      // Check mounted after await
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      // Check mounted after await
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // =============================================================================
  // BUILD METHOD
  // =============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sifitlier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========== WELCOME CARD ===========
              _buildWelcomeCard(),

              const SizedBox(height: 24),

              // =========== STATS SECTION ===========
              const Text(
                'Security Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildStatsSection(),

              const SizedBox(height: 24),

              // =========== QUICK ACTIONS ===========
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(),

              const SizedBox(height: 24),

              // =========== SECURE CHANNELS ===========
              const Text(
                'Secure Your Channels',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildSecureChannelsCard(),

              const SizedBox(height: 24),

              // =========== FEATURES GRID ===========
              const Text(
                'Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildFeaturesGrid(),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================================
  // WELCOME CARD
  // =============================================================================
  // Displays app branding and welcome message

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
          ),
        ),
        child: Row(
          children: [
            // Sifitlier logo
            Image.asset(
              'assets/images/logo.png',
              width: 48,
              height: 48,
              // Adding an errorBuilder ,if the image is missing to prevent crashes and show a placeholder icon instead
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.shield, size: 48, color: Colors.white);
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to Sifitlier',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your AI security assistant',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // =============================================================================
  // STATS SECTION
  // =============================================================================
  // Displays security statistics: spam blocked, DLP warnings, total alerts

  Widget _buildStatsSection() {
    // Show loading indicator
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Show error state with retry button
    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('Could not load stats'),
              TextButton(
                onPressed: _loadStats,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Extract stats from API response
    final spamDetected = _stats?['spam']?['detected'] ?? 0;
    final dlpWarnings = _stats?['dlp']?['with_sensitive_data'] ?? 0;
    final totalAlerts = _stats?['total_alerts'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Spam Blocked',
            spamDetected.toString(),
            Icons.block,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'DLP Warnings',
            dlpWarnings.toString(),
            Icons.warning,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Alerts',
            totalAlerts.toString(),
            Icons.notifications,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  /// Individual stat card widget
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // QUICK ACTIONS
  // =============================================================================
  // Buttons for frequently used features: Spam Check, DLP Check, Real-Time Protection

  Widget _buildQuickActions() {
    return Column(
      children: [
        // First row: Check Spam & Check DLP
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SpamCheckScreen()),
                ),
                icon: const Icon(Icons.search),
                label: const Text('Check Spam'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[900],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DLPCheckScreen()),
                ),
                icon: const Icon(Icons.security),
                label: const Text('Check DLP'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange[100],
                  foregroundColor: Colors.orange[900],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Real-Time Protection Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProtectionScreen()),
            ),
            icon: const Icon(Icons.shield),
            label: const Text('Real-Time Protection'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green[100],
              foregroundColor: Colors.green[900],
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================================
  // SECURE CHANNELS CARD
  // =============================================================================
  // Integration buttons for Gmail and Telegram protection

  Widget _buildSecureChannelsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========== HEADER ===========
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.lock, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protect Your Messaging Channels',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Connect and scan your email & messaging apps',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // =========== CHANNEL BUTTONS ===========
            Row(
              children: [
                // Gmail Button
                Expanded(
                  child: _buildChannelButton(
                    label: 'Scan My Gmail',
                    icon: Icons.email,
                    iconColor: Colors.red,
                    backgroundColor: Colors.red.withOpacity(0.1),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GmailConnectScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Telegram Button - Opens Sifitlier Bot
                Expanded(
                  child: _buildChannelButton(
                    label: 'Secure Telegram',
                    icon: Icons.telegram,
                    iconColor: Colors.blue,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    onTap: () => _showTelegramDialog(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Channel button widget
  Widget _buildChannelButton({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: iconColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: iconColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // TELEGRAM BOT INTEGRATION
  // =============================================================================
  // Opens Sifitlier Telegram bot for real-time message protection

  /// Opens the Telegram bot using url_launcher
  Future<void> _openTelegramBot() async {
    final Uri telegramUrl = Uri.parse('https://t.me/Sifitlier_bot');

    try {
      if (await canLaunchUrl(telegramUrl)) {
        await launchUrl(
          telegramUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback: Show snackbar if can't open
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not open Telegram. Search for @SifitlierSecurityBot in Telegram.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Shows dialog with Telegram bot information
  void _showTelegramDialog() {
    if (!mounted) return;

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
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.telegram, color: Colors.blue, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Telegram Protection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chat with our Telegram bot for real-time spam and sensitive data protection.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '@SifitlierSecurityBot',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openTelegramBot();
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open Bot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  // =============================================================================
  // FEATURES GRID
  // =============================================================================
  // Grid of all app features with navigation

  Widget _buildFeaturesGrid() {
    final features = [
      {
        'title': 'Spam Detection',
        'subtitle': 'Check messages for spam',
        'icon': Icons.email,
        'color': Colors.red,
        'screen': const SpamCheckScreen(),
      },
      {
        'title': 'DLP Protection',
        'subtitle': 'Check for sensitive data',
        'icon': Icons.lock,
        'color': Colors.orange,
        'screen': const DLPCheckScreen(),
      },
      {
        'title': 'Real-Time Guard',
        'subtitle': 'Auto-scan SMS & clipboard',
        'icon': Icons.shield,
        'color': Colors.green,
        'screen': const ProtectionScreen(),
      },
      {
        'title': 'Alert Logs',
        'subtitle': 'View detection history',
        'icon': Icons.history,
        'color': Colors.blue,
        'screen': const LogsScreen(),
      },
      {
        'title': 'Security Handbook',
        'subtitle': 'Learn about security',
        'icon': Icons.menu_book,
        'color': Colors.purple,
        'screen': const HandbookScreen(),
      },
      {
        'title': 'Settings',
        'subtitle': 'App configuration',
        'icon': Icons.settings,
        'color': Colors.grey,
        'screen': const SettingsScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(
          title: feature['title'] as String,
          subtitle: feature['subtitle'] as String,
          icon: feature['icon'] as IconData,
          color: feature['color'] as Color,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => feature['screen'] as Widget),
          ),
        );
      },
    );
  }

  /// Individual feature card widget
  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
