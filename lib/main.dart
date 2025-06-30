import 'package:flutter/material.dart';
import 'package:happy_shop/screens/splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://bimcblnxusqypatncifl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJpbWNibG54dXNxeXBhdG5jaWZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMxMTQwOTQsImV4cCI6MjA0ODY5MDA5NH0.RaGi1LCgeAKEMeE-cBZ-577jTvQOUzwx794itxOfv5I',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Intro to Supabase',
      builder: FlutterSmartDialog.init(),
      home: Splash(), // Start with the splash screen
    );
  }
}

