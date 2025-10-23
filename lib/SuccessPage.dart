import 'package:flutter/material.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Success")),
      body: const Center(
        child: Text(
          "🎉 Payment Successful!",
          style: TextStyle(fontSize: 24, color: Colors.green),
        ),
      ),
    );
  }
}

class FailedPage extends StatelessWidget {
  const FailedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Failed")),
      body: const Center(
        child: Text(
          "❌ Payment Failed or Token Invalid",
          style: TextStyle(fontSize: 24, color: Colors.red),
        ),
      ),
    );
  }
}
