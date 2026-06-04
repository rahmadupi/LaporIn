import 'package:flutter/material.dart';
import 'features/officer/screens/officer_home_screen.dart'; // Import diubah ke Home

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaporIn',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Set home kembali mengarah ke Beranda
      home: const OfficerHomeScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}