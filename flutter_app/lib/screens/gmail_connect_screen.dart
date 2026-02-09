// lib/screens/gmail_connect_screen.dart
// ======================================
// Gmail OAuth integration screen
// Allows users to connect Gmail, fetch emails, and scan them for spam/DLP

import 'package:flutter/material.dart';
import '../services/gmail_service.dart';
import '../services/api_service.dart';

class GmailConnectScreen extends StatefulWidget {
  const GmailConnectScreen({super.key});

  @override
  State<GmailConnectScreen> createState() => _GmailConnectScreenState();
}

class _GmailConnectScreenState extends State<GmailConnectScreen> {
  final GmailService _gmailService = GmailService();

  bool _isLoading = false;
  bool _isFetchingEmails = false;
  bool _isScanning = false;
  String? _error;

  List<EmailMessage> _emails = [];
  Map<String, Map<String, dynamic>> _scanResults = {}; // email_id -> result

  @override
  void initState() {
    super.initState();
    _checkExistingSignIn();
  }

  /// Check if user is already signed in
  Future<void> _checkExistingSignIn() async {
    setState(() => _isLoading = true);
    await _gmailService.trySilentSignIn();
    setState(() => _isLoading = false);
  }

  /// Sign in with Google
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await _gmailService.signIn();

    setState(() {
      _isLoading = false;
      if (!success) {
        _error = 'Failed to sign in with Google. Please try again.';
      }
    });
  }

  /// Sign out
  Future<void> _signOut() async {
    await _gmailService.signOut();
    setState(() {
      _emails = [];
      _scanResults = {};
    });
  }

  /// Fetch emails from Gmail
  Future<void> _fetchEmails() async {
    setState(() {
      _isFetchingEmails = true;
      _error = null;
      _emails = [];
      _scanResults = {};
    });

    try {
      final emails = await _gmailService.fetchRecentEmails(maxResults: 20);
      setState(() {
        _emails = emails;
        _isFetchingEmails = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isFetchingEmails = false;
      });
    }
  }

  /// Toggle email selection
  void _toggleEmailSelection(int index) {
    setState(() {
      _emails[index].isSelected = !_emails[index].isSelected;
    });
  }

  /// Select all emails
  void _selectAll() {
    setState(() {
      for (var email in _emails) {
        email.isSelected = true;
      }
    });
  }

  /// Deselect all emails
  void _deselectAll() {
    setState(() {
      for (var email in _emails) {
        email.isSelected = false;
      }
    });
  }

  /// Get selected emails
  List<EmailMessage> get _selectedEmails =>
      _emails.where((e) => e.isSelected).toList();

  /// Scan selected emails for spam
  Future<void> _scanForSpam() async {
    if (_selectedEmails.isEmpty) {
      _showSnackBar('Please select at least one email to scan', Colors.orange);
      return;
    }

    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      for (var email in _selectedEmails) {
        final result = await ApiService.checkSpam(
          userId: 'device_user',
          message: email.contentForScanning,
          source: 'email',
          sender: email.from,
        );

        setState(() {
          _scanResults[email.id] = {
            'type': 'spam',
            'result': result,
          };
        });
      }

      _showSnackBar(
        'Scanned ${_selectedEmails.length} emails for spam',
        Colors.green,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isScanning = false);
    }
  }

  /// Scan selected emails for sensitive data (DLP)
  Future<void> _scanForDLP() async {
    if (_selectedEmails.isEmpty) {
      _showSnackBar('Please select at least one email to scan', Colors.orange);
      return;
    }

    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      for (var email in _selectedEmails) {
        final result = await ApiService.checkDLP(
          userId: 'device_user',
          message: email.contentForScanning,
          source: 'email',
        );

        setState(() {
          _scanResults[email.id] = {
            'type': 'dlp',
            'result': result,
          };
        });
      }

      _showSnackBar(
        'Scanned ${_selectedEmails.length} emails for sensitive data',
        Colors.green,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isScanning = false);
    }
  }

  /// Scan for both spam and DLP
  Future<void> _scanBoth() async {
    if (_selectedEmails.isEmpty) {
      _showSnackBar('Please select at least one email to scan', Colors.orange);
      return;
    }

    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      for (var email in _selectedEmails) {
        final results = await Future.wait([
          ApiService.checkSpam(
            userId: 'device_user',
            message: email.contentForScanning,
            source: 'email',
            sender: email.from,
          ),
          ApiService.checkDLP(
            userId: 'device_user',
            message: email.contentForScanning,
            source: 'email',
          ),
        ]);

        setState(() {
          _scanResults[email.id] = {
            'type': 'both',
            'spam': results[0],
            'dlp': results[1],
          };
        });
      }

      _showSnackBar(
        'Completed full scan on ${_selectedEmails.length} emails',
        Colors.green,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isScanning = false);
    }
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
        title: const Text('Gmail Connect'),
        actions: [
          if (_gmailService.isSignedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
              tooltip: 'Sign Out',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _gmailService.isSignedIn
              ? _buildSignedInView()
              : _buildSignInView(),
    );
  }

  /// Build view when not signed in
  Widget _buildSignInView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Gmail Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.email,
              size: 64,
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Connect Your Gmail',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Sign in with Google to scan your emails for spam and sensitive data. We only request read-only access.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 32),

          // Sign In Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _signIn,
              icon: Image.network(
                'https://www.google.com/favicon.ico',
                height: 24,
                width: 24,
                errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata),
              ),
              label: const Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 2,
                side: const BorderSide(color: Colors.grey),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!)),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Privacy Notice
          Card(
            color: Colors.blue[50],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.privacy_tip, color: Colors.blue),
                  SizedBox(height: 8),
                  Text(
                    'Privacy Notice',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sifitlier only reads email content for scanning. We do not store, share, or modify your emails.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build view when signed in
  Widget _buildSignedInView() {
    return Column(
      children: [
        // User Info Card
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.withOpacity(0.1),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: _gmailService.userPhotoUrl != null
                    ? NetworkImage(_gmailService.userPhotoUrl!)
                    : null,
                child: _gmailService.userPhotoUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _gmailService.userName ?? 'Gmail User',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _gmailService.userEmail ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),

        // Error Display
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.red[50],
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(_error!, style: const TextStyle(fontSize: 12))),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _error = null),
                ),
              ],
            ),
          ),

        // Fetch Emails Button or Email List
        Expanded(
          child:
              _emails.isEmpty ? _buildFetchEmailsView() : _buildEmailListView(),
        ),
      ],
    );
  }

  /// View to fetch emails
  Widget _buildFetchEmailsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Fetch your recent emails to scan them for spam and sensitive data.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isFetchingEmails ? null : _fetchEmails,
              icon: _isFetchingEmails
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(
                  _isFetchingEmails ? 'Fetching...' : 'Fetch Recent Emails'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// View with email list
  Widget _buildEmailListView() {
    return Column(
      children: [
        // Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_emails.length} emails',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: _selectAll,
                child: const Text('Select All'),
              ),
              TextButton(
                onPressed: _deselectAll,
                child: const Text('Clear'),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isFetchingEmails ? null : _fetchEmails,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // Email List
        Expanded(
          child: ListView.builder(
            itemCount: _emails.length,
            itemBuilder: (context, index) =>
                _buildEmailTile(_emails[index], index),
          ),
        ),

        // Scan Buttons
        if (_selectedEmails.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '${_selectedEmails.length} email(s) selected',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isScanning ? null : _scanForSpam,
                        icon: const Icon(Icons.security, size: 18),
                        label: const Text('Spam'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isScanning ? null : _scanForDLP,
                        icon: const Icon(Icons.shield, size: 18),
                        label: const Text('DLP'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isScanning ? null : _scanBoth,
                        icon: _isScanning
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.verified_user, size: 18),
                        label: const Text('Both'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build individual email tile
  Widget _buildEmailTile(EmailMessage email, int index) {
    final scanResult = _scanResults[email.id];
    final hasResult = scanResult != null;

    // Determine result status
    bool? isSpam;
    bool? hasSensitiveData;

    if (hasResult) {
      if (scanResult['type'] == 'spam') {
        isSpam = scanResult['result']?['is_spam'] == true;
      } else if (scanResult['type'] == 'dlp') {
        hasSensitiveData = scanResult['result']?['has_sensitive_data'] == true;
      } else if (scanResult['type'] == 'both') {
        isSpam = scanResult['spam']?['is_spam'] == true;
        hasSensitiveData = scanResult['dlp']?['has_sensitive_data'] == true;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => _toggleEmailSelection(index),
        onLongPress: () => _showEmailDetails(email, scanResult),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: email.isSelected,
                onChanged: (_) => _toggleEmailSelection(index),
              ),

              // Email Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email.from,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.subject,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.snippet,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Result Indicators
              if (hasResult) ...[
                const SizedBox(width: 8),
                Column(
                  children: [
                    if (isSpam != null)
                      Icon(
                        isSpam ? Icons.warning : Icons.check_circle,
                        color: isSpam ? Colors.red : Colors.green,
                        size: 20,
                      ),
                    if (hasSensitiveData != null)
                      Icon(
                        hasSensitiveData ? Icons.shield : Icons.shield_outlined,
                        color: hasSensitiveData ? Colors.orange : Colors.green,
                        size: 20,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Show email details in bottom sheet
  void _showEmailDetails(EmailMessage email, Map<String, dynamic>? scanResult) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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

              // From
              Text(
                'From: ${email.from}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Subject
              Text(
                'Subject: ${email.subject}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Body
              const Text(
                'Content:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  email.body.isEmpty ? email.snippet : email.body,
                  style: const TextStyle(fontSize: 13),
                ),
              ),

              // Scan Results
              if (scanResult != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Scan Results:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildScanResultCard(scanResult),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build scan result card for bottom sheet
  Widget _buildScanResultCard(Map<String, dynamic> scanResult) {
    final type = scanResult['type'];

    if (type == 'spam') {
      final result = scanResult['result'];
      final isSpam = result['is_spam'] == true;
      return Card(
        color: isSpam ? Colors.red[50] : Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isSpam ? Icons.warning : Icons.check_circle,
                color: isSpam ? Colors.red : Colors.green,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpam ? 'Spam Detected' : 'Not Spam',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSpam ? Colors.red : Colors.green,
                      ),
                    ),
                    Text(
                      'Confidence: ${((result['confidence'] ?? 0) * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (type == 'dlp') {
      final result = scanResult['result'];
      final hasSensitive = result['has_sensitive_data'] == true;
      final categories = List<String>.from(result['categories'] ?? []);
      return Card(
        color: hasSensitive ? Colors.orange[50] : Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasSensitive ? Icons.shield : Icons.shield_outlined,
                    color: hasSensitive ? Colors.orange : Colors.green,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    hasSensitive ? 'Sensitive Data Found' : 'No Sensitive Data',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: hasSensitive ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: categories
                      .map((c) => Chip(
                            label:
                                Text(c, style: const TextStyle(fontSize: 11)),
                            backgroundColor: Colors.orange[100],
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      );
    } else if (type == 'both') {
      final spamResult = scanResult['spam'];
      final dlpResult = scanResult['dlp'];
      final isSpam = spamResult?['is_spam'] == true;
      final hasSensitive = dlpResult?['has_sensitive_data'] == true;

      return Column(
        children: [
          // Spam Result
          Card(
            color: isSpam ? Colors.red[50] : Colors.green[50],
            child: ListTile(
              leading: Icon(
                isSpam ? Icons.warning : Icons.check_circle,
                color: isSpam ? Colors.red : Colors.green,
              ),
              title: Text(isSpam ? 'Spam Detected' : 'Not Spam'),
              subtitle: Text(
                'Confidence: ${((spamResult?['confidence'] ?? 0) * 100).toStringAsFixed(1)}%',
              ),
            ),
          ),
          const SizedBox(height: 8),
          // DLP Result
          Card(
            color: hasSensitive ? Colors.orange[50] : Colors.green[50],
            child: ListTile(
              leading: Icon(
                hasSensitive ? Icons.shield : Icons.shield_outlined,
                color: hasSensitive ? Colors.orange : Colors.green,
              ),
              title: Text(
                  hasSensitive ? 'Sensitive Data Found' : 'No Sensitive Data'),
              subtitle: hasSensitive
                  ? Text(
                      'Categories: ${(dlpResult?['categories'] ?? []).join(", ")}')
                  : null,
            ),
          ),
        ],
      );
    }

    return const SizedBox();
  }
}
