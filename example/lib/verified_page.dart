import 'package:flutter/material.dart';

class OTPResultScreen extends StatelessWidget {
  final String otpCode;

  const OTPResultScreen({super.key, required this.otpCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verified'),
      ),
      body: Center(
        child: Text(
          'OTP Code is : $otpCode',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
