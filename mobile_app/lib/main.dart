import 'package:flutter/material.dart';

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
        colorScheme:
            ColorScheme.fromSeed(seedColor: Colors.red), // Red for security!
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Sifitlier Security"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.security, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              statusMessage,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // We will connect this to your Python Backend later!
                print("Scanning for threats...");
              },
              icon: const Icon(Icons.search),
              label: const Text("Run Manual Scan"),
            ),
          ],
        ),
      ),
    );
  }
}
