import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final String message;
  final String? transactionId;
  final double amount;

  const PaymentResultScreen({
    super.key,
    required this.success,
    required this.message,
    this.transactionId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Result'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              success ? 'Payment Successful!' : 'Payment Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: success ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (transactionId != null)
              Text(
                'Transaction ID: $transactionId',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Text(
              'Amount: \$${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text('Continue Shopping'),
                  ),
                ),
                const SizedBox(width: 16),
                if (success)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        cart.clear();
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: const Text('Done'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}