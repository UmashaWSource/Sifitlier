// lib/screens/splash_screen.dart
// ================================
// Splash screen - checks backend connection and navigates to dashboard

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Initializing...';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Step 1: Show loading
    setState(() => _status = 'Checking server connection...');

    await Future.delayed(const Duration(seconds: 1));

    // Step 2: Check backend connection
    final isConnected = await ApiService.healthCheck();

    if (!isConnected) {
      setState(() {
        _status = 'Cannot connect to server.\nMake sure backend is running.';
        _isError = true;
      });
      return;
    }

    setState(() => _status = 'Connected! Loading app...');
    await Future.delayed(const Duration(milliseconds: 500));

    // Step 3: Navigate to Dashboard
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF2196F3),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield,
                    size: 80,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                // App Name
                const Text(
                  'SIFITLIER',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'AI-Powered Security',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 48),

                // Loading indicator or error
                if (!_isError) ...[
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                ],

                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _isError ? Colors.red[100] : Colors.white70,
                  ),
                ),

                // Retry button if error
                if (_isError) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isError = false;
                        _status = 'Retrying...';
                      });
                      _initializeApp();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const DashboardScreen()),
                      );
                    },
                    child: const Text(
                      'Continue Offline',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
