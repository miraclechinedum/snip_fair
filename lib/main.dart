import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/version_checker.dart';
import 'features/onboarding/force_update_screen.dart';
import 'firebase_options.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  developer.log('📱 Initializing Firebase...', name: 'Main');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  developer.log('✅ Firebase Initialized', name: 'Main');
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool? _forceUpdate;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    developer.log('🔍 Starting version check...', name: 'Main');
    final updateRequired = await VersionChecker.isUpdateRequired();
    developer.log('✅ Version check completed. Update required: $updateRequired', name: 'Main');
    setState(() {
      _forceUpdate = updateRequired;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_forceUpdate == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    if (_forceUpdate == true) {
      return const MaterialApp(
        home: ForceUpdateScreen(updateUrl: ''), // URL is handled in the screen
      );
    }
    // ...existing app home...
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}
