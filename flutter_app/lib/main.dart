import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/alert_provider.dart';
import '../providers/settings_provider.dart';
import '../models/alert_model.dart';
import '../utils/app_theme.dart';
import '../widgets/alert_card.dart';
import '../widgets/stat_card.dart';
import '../services/sms_listener_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupSmsListener();
  }

  void _setupSmsListener() {
    SmsListenerService.instance.onSpamDetected = (message, result) {
      // Show snackbar when spam is detected
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Spam detected from ${message.address}'),
            backgroundColor: AppTheme.dangerColor,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/alert/${result.alertId}');
              },
            ),
          ),
        );

        // Refresh alerts
        context.read<AlertProvider>().fetchAlerts(refresh: true);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardTab(),
          _AlertsTab(),
          _ProtectionTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Consumer<AlertProvider>(
                builder: (context, provider, _) {
                  return Text('${provider.unreadCount}');
                },
              ),
              isLabelVisible: context.watch<AlertProvider>().unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            activeIcon: const Icon(Icons.notifications),
            label: 'Alerts',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield),
            label: 'Protection',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Dashboard tab with stats and recent alerts
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.fetchAlerts(refresh: true);
            await provider.fetchStats();
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.security,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Sifitlier'),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.book_outlined),
                    onPressed: () => Navigator.pushNamed(context, '/handbook'),
                    tooltip: 'Safety Handbook',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Protection Status Card
                    _buildProtectionStatusCard(context),
                    const SizedBox(height: 20),

                    // Stats Grid
                    if (provider.stats != null) ...[
                      const Text(
                        'Last 30 Days',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatsGrid(context, provider),
                      const SizedBox(height: 20),
                    ],

                    // Recent Alerts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Alerts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/history'),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (provider.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (provider.recentAlerts.isEmpty)
                      _buildNoAlertsCard()
                    else
                      ...provider.recentAlerts.take(5).map(
                            (alert) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AlertCard(
                                alert: alert,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/alert/${alert.id}',
                                ),
                              ),
                            ),
                          ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProtectionStatusCard(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final isProtected =
            settings.smsMonitoringEnabled || settings.emailMonitoringEnabled;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isProtected
                  ? [
                      AppTheme.accentColor,
                      AppTheme.accentColor.withOpacity(0.8)
                    ]
                  : [Colors.grey, Colors.grey.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isProtected ? AppTheme.accentColor : Colors.grey)
                    .withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isProtected ? Icons.shield : Icons.shield_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isProtected ? 'Protected' : 'Protection Off',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isProtected
                          ? 'Your messages are being monitored'
                          : 'Enable protection in settings',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isProtected ? Icons.check_circle : Icons.warning,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(BuildContext context, AlertProvider provider) {
    final stats = provider.stats!;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          title: 'Spam Blocked',
          value: '${stats.spam.detected}',
          icon: Icons.block,
          color: AppTheme.dangerColor,
        ),
        StatCard(
          title: 'DLP Alerts',
          value: '${stats.dlp.withSensitiveData}',
          icon: Icons.privacy_tip,
          color: AppTheme.warningColor,
        ),
        StatCard(
          title: 'Messages Scanned',
          value: '${stats.totalAlerts}',
          icon: Icons.search,
          color: AppTheme.primaryColor,
        ),
        StatCard(
          title: 'Detection Rate',
          value: '${stats.spam.detectionRate.toStringAsFixed(0)}%',
          icon: Icons.trending_up,
          color: AppTheme.accentColor,
        ),
      ],
    );
  }

  Widget _buildNoAlertsCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: AppTheme.accentColor,
          ),
          const SizedBox(height: 12),
          const Text(
            'All Clear!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No suspicious activity detected recently',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Alerts tab
class _AlertsTab extends StatelessWidget {
  const _AlertsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              final provider = context.read<AlertProvider>();
              if (value == 'all') {
                provider.clearFilters();
              } else if (value == 'spam' || value == 'dlp') {
                provider.setAlertTypeFilter(value);
              } else {
                provider.setSourceFilter(value);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Alerts')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'spam', child: Text('Spam Only')),
              const PopupMenuItem(value: 'dlp', child: Text('DLP Only')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'sms', child: Text('SMS')),
              const PopupMenuItem(value: 'email', child: Text('Email')),
              const PopupMenuItem(value: 'telegram', child: Text('Telegram')),
            ],
          ),
        ],
      ),
      body: Consumer<AlertProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.alerts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.filteredAlerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No alerts found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchAlerts(refresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount:
                  provider.filteredAlerts.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.filteredAlerts.length) {
                  // Load more indicator
                  provider.loadMore();
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final alert = provider.filteredAlerts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AlertCard(
                    alert: alert,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/alert/${alert.id}',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Protection settings tab
class _ProtectionTab extends StatelessWidget {
  const _ProtectionTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Protection'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // SMS Protection
              _buildProtectionCard(
                context,
                title: 'SMS Protection',
                subtitle: 'Monitor incoming SMS for spam and phishing',
                icon: Icons.sms,
                color: AppTheme.smsColor,
                enabled: settings.smsMonitoringEnabled,
                onChanged: (value) => settings.setSmsMonitoringEnabled(value),
              ),
              const SizedBox(height: 16),

              // Email Protection (Coming Soon)
              _buildProtectionCard(
                context,
                title: 'Email Protection',
                subtitle: 'Coming soon - Monitor email for threats',
                icon: Icons.email,
                color: AppTheme.emailColor,
                enabled: false,
                onChanged: null,
                comingSoon: true,
              ),
              const SizedBox(height: 16),

              // Telegram Protection (Coming Soon)
              _buildProtectionCard(
                context,
                title: 'Telegram Protection',
                subtitle: 'Coming soon - Monitor Telegram messages',
                icon: Icons.send,
                color: AppTheme.telegramColor,
                enabled: false,
                onChanged: null,
                comingSoon: true,
              ),
              const SizedBox(height: 24),

              // DLP Section
              const Text(
                'Data Loss Prevention',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildProtectionCard(
                context,
                title: 'Outgoing SMS Check',
                subtitle: 'Warn before sending sensitive data via SMS',
                icon: Icons.privacy_tip,
                color: AppTheme.warningColor,
                enabled: settings.dlpCheckOutgoingSms,
                onChanged: (value) => settings.setDlpCheckOutgoingSms(value),
              ),
              const SizedBox(height: 16),

              // Sensitivity Threshold
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sensitivity Threshold',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Minimum sensitivity level to trigger alerts',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'low', label: Text('Low')),
                          ButtonSegment(value: 'medium', label: Text('Medium')),
                          ButtonSegment(value: 'high', label: Text('High')),
                        ],
                        selected: {settings.dlpSensitivityThreshold},
                        onSelectionChanged: (selected) {
                          settings.setDlpSensitivityThreshold(selected.first);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProtectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool enabled,
    required void Function(bool)? onChanged,
    bool comingSoon = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (comingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Soon',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile tab
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sifitlier User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Free Plan',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Menu Items
          _buildMenuItem(
            context,
            icon: Icons.history,
            title: 'Alert History',
            onTap: () => Navigator.pushNamed(context, '/history'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.book,
            title: 'Safety Handbook',
            onTap: () => Navigator.pushNamed(context, '/handbook'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings,
            title: 'Settings',
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
          ),
          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
