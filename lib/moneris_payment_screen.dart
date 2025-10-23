// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
//
// class MonerisPaymentScreen extends StatefulWidget {
//   final double amount;
//   const MonerisPaymentScreen({super.key, required this.amount});
//
//   @override
//   State<MonerisPaymentScreen> createState() => _MonerisPaymentScreenState();
// }
//
// class _MonerisPaymentScreenState extends State<MonerisPaymentScreen> {
//   late final WebViewController _controller;
//   bool _isLoading = true;
//   String? _checkoutUrl;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialize the WebViewController once
//     final params = const PlatformWebViewControllerCreationParams();
//     _controller = WebViewController.fromPlatformCreationParams(params)
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageFinished: (_) {
//             if (mounted) setState(() => _isLoading = false);
//           },
//           onNavigationRequest: (request) {
//             if (request.url.contains("http://192.168.68.116:5000/payment/complete")) {
//               final uri = Uri.parse(request.url);
//               final token = uri.queryParameters['token'];
//               if (token != null) Navigator.pop(context, token);
//               return NavigationDecision.prevent;
//             }
//             return NavigationDecision.navigate;
//           },
//         ),
//       );
//
//     _createCheckoutSession();
//   }
//
//   Future<void> _createCheckoutSession() async {
//     try {
//       final response = await http.post(
//         Uri.parse('http://192.168.68.116:5000/create-checkout'),
//         body: jsonEncode({'amount': widget.amount}),
//         headers: {'Content-Type': 'application/json'},
//       );
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final checkoutId = data['checkout_id'];
//         setState(() {
//           _checkoutUrl =
//           'https://gateway.moneris.com/chkt/display/qm.php?id=$checkoutId';
//         });
//
//         // Load URL once
//         _controller.loadRequest(Uri.parse(_checkoutUrl!));
//       } else {
//         throw Exception('Failed to create checkout');
//       }
//     } catch (e) {
//       debugPrint('Checkout error: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_checkoutUrl == null) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(title: const Text("Complete Payment")),
//       body: Stack(
//         children: [
//           WebViewWidget(controller: _controller),
//           if (_isLoading) const Center(child: CircularProgressIndicator()),
//         ],
//       ),
//     );
//   }
// }
//


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class MonerisPaymentScreen extends StatefulWidget {
  final double amount;
  const MonerisPaymentScreen({super.key, required this.amount});

  @override
  State<MonerisPaymentScreen> createState() => _MonerisPaymentScreenState();
}

class _MonerisPaymentScreenState extends State<MonerisPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _checkoutUrl;

  @override
  void initState() {
    super.initState();
    final params = const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);

            // Check if this is your payment-complete URL
            if (uri.path.contains("/payment/complete")) {
              print("Complete hurray");
              final token = uri.queryParameters['token'];
              final checkoutId = uri.queryParameters['checkout_id'];
              print("Complete hurray: ${token} ${checkoutId}");

              if (token != null && checkoutId != null) {
                // Close WebView and return token + checkoutId
                Navigator.pop(context, {'token': token, 'checkout_id': checkoutId});
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _createCheckoutSession();
  }

  Future<void> _createCheckoutSession() async {
    try {
      final payload = {
        "store_id": "store5",
        "api_token": "yesguy",
        "checkout_id": "checkout_${DateTime.now().millisecondsSinceEpoch}",
        "txn_total": widget.amount.toStringAsFixed(2),
        "environment": "qa",
        "order_no": "ORDER1001",
        "cust_id": "USER001",
        "dynamic_descriptor": "Test Purchase",
      };

      final response = await http.post(
        Uri.parse('http://192.168.68.116:5000/create-checkout'),
        body: jsonEncode(payload),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final checkoutId = data['checkout_id'];

        // ✅ For local testing, directly go to "payment complete" page
        setState(() {
          _checkoutUrl =
          'http://192.168.68.116:5000/payment/complete?token=yesguy&checkout_id=$checkoutId';
        });
        // setState(() {
        //   _checkoutUrl =
        //   'https://gateway.moneris.com/chkt/display/qm.php?id=$checkoutId';
        // });

        _controller.loadRequest(Uri.parse(_checkoutUrl!));
      } else {
        throw Exception('Failed to create checkout');
      }
    } catch (e) {
      debugPrint('Checkout error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Payment")),
      body: _checkoutUrl == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.blueAccent,
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
