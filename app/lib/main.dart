import 'package:flutter/material.dart';
import 'package:laporin/core/routing/app_router.dart'; 

void main() {
  runApp(const LaporInApp());
}

class LaporInApp extends StatelessWidget {
  const LaporInApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the router from your app_router.dart file
    final appRouter = createRouter();

    // Use MaterialApp.router instead of the standard MaterialApp
    return MaterialApp.router(
      title: 'LaporIn Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Pass the router configuration to the app
      routerConfig: appRouter,
      
      // Optional: hide the debug banner
      debugShowCheckedModeBanner: false, 
    );
  }
}