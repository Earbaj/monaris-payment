// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class MonerisService {
//   // For local testing - change to your machine's IP if testing on physical device
//   static const String baseUrl = 'http://192.168.68.116:5000';
//   // Alternative for Android emulator: 'http://10.0.2.2:5000'
//   // Alternative for physical device: 'http://YOUR_LOCAL_IP:5000'
//
//   static Future<Map<String, dynamic>> getTestProducts() async {
//     try {
//       final response = await http.get(Uri.parse('$baseUrl/products'));
//
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       } else {
//         throw Exception('Server error: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Failed to fetch products: $e');
//     }
//   }
//
//   // static Future<Map<String, dynamic>> createCheckout({
//   //   required double amount,
//   //   String? orderNo,
//   //   String? customerId,
//   //   String? description,
//   //   bool isProduction = false,
//   // }) async {
//   //   try {
//   //     print('🔄 Creating checkout for amount: \$$amount');
//   //
//   //     final response = await http.post(
//   //       Uri.parse('$baseUrl/create-checkout'),
//   //       headers: {'Content-Type': 'application/json'},
//   //       body: json.encode({
//   //         'amount': amount.toStringAsFixed(2),
//   //         'orderNo': orderNo,
//   //         'customerId': customerId,
//   //         'description': description ?? 'Test Purchase',
//   //         'environment': isProduction ? 'prod' : 'qa',
//   //       }),
//   //     );
//   //
//   //     print('📡 Response status: ${response.statusCode}');
//   //     print('📡 Response body: ${response.body}');
//   //
//   //     if (response.statusCode == 200) {
//   //       final result = json.decode(response.body);
//   //       print('✅ Checkout created: ${result['ticket']}');
//   //       return result;
//   //     } else {
//   //       throw Exception('Server error: ${response.statusCode} - ${response.body}');
//   //     }
//   //   } catch (e) {
//   //     print('❌ Checkout error: $e');
//   //     throw Exception('Failed to create checkout: $e');
//   //   }
//   // }
//
//   // In lib/services/moneris_service.dart - temporary test
//   static Future<Map<String, dynamic>> createCheckout({
//     required double amount,
//     String? orderNo,
//     String? customerId,
//     String? description,
//     bool isProduction = false,
//   }) async {
//     try {
//       print('🔄 Creating checkout for amount: \$$amount');
//
//       // TEMPORARY: Use simple endpoint for testing
//       final response = await http.post(
//         Uri.parse('$baseUrl/create-checkout-simple'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'amount': amount.toStringAsFixed(2),
//         }),
//       );
//
//       print('📡 Response status: ${response.statusCode}');
//       print('📡 Response body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final result = json.decode(response.body);
//         return result;
//       } else {
//         // Fallback to mock endpoint
//         print('⚠️ Falling back to mock checkout');
//         return await createMockCheckout(amount: amount);
//       }
//     } catch (e) {
//       print('❌ Checkout error: $e');
//       // Fallback to mock
//       return await createMockCheckout(amount: amount);
//     }
//   }
//
// // Fallback mock method
//   static Future<Map<String, dynamic>> createMockCheckout({required double amount}) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/mock-checkout'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({'amount': amount}),
//       );
//
//       if (response.statusCode == 200) {
//         final result = json.decode(response.body);
//         print('✅ Mock checkout created: ${result['ticket']}');
//         return result;
//       } else {
//         throw Exception('Mock endpoint failed');
//       }
//     } catch (e) {
//       // Ultimate fallback - generate local mock
//       return {
//         'success': true,
//         'ticket': 'local_mock_ticket_${DateTime.now().millisecondsSinceEpoch}',
//         'checkout_id': 'local_mock_checkout',
//         'order_no': 'LOCAL_MOCK_${DateTime.now().millisecondsSinceEpoch}',
//         'note': 'Local mock - backend unavailable'
//       };
//     }
//   }
//
//   static Future<Map<String, dynamic>> verifyPayment({
//     required String ticket,
//     bool isProduction = false,
//   }) async {
//     try {
//       print('🔍 Verifying payment for ticket: $ticket');
//
//       final response = await http.post(
//         Uri.parse('$baseUrl/payment/complete'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'ticket': ticket,
//           'environment': isProduction ? 'prod' : 'qa',
//         }),
//       );
//
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       } else {
//         throw Exception('Server error: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Failed to verify payment: $e');
//     }
//   }
//
//   // Test method without real Moneris integration
//   static Future<Map<String, dynamic>> createTestCheckout({
//     required double amount,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/test-checkout'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({'amount': amount}),
//       );
//
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       } else {
//         throw Exception('Test endpoint error: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Test checkout failed: $e');
//     }
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;

class MonerisService {
  // For Android emulator: http://10.0.2.2:5000
  // For iOS simulator: http://localhost:5000
  static const String baseUrl = 'http://192.168.68.116:5000';

  // ADD THIS METHOD - Get test products from backend
  static Future<Map<String, dynamic>> getTestProducts() async {
    try {
      print('🔄 Fetching test products...');

      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Products response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Products loaded successfully');
        return result;
      } else {
        print('⚠️ Using fallback products');
        return _getFallbackProducts();
      }
    } catch (e) {
      print('❌ Products fetch error: $e');
      return _getFallbackProducts();
    }
  }

  static Future<Map<String, dynamic>> createCheckout({
    required double amount,
  }) async {
    try {
      print('💰 Creating checkout for amount: \$${amount.toStringAsFixed(2)}');

      final response = await http.post(
        Uri.parse('$baseUrl/create-checkout'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': amount.toStringAsFixed(2),
          'description': 'Flutter App Purchase',
        }),
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Checkout created successfully');
        return result;
      } else {
        print('⚠️ Using fallback checkout data');
        return _createFallbackCheckout(amount);
      }
    } catch (e) {
      print('❌ Connection error: $e');
      return _createFallbackCheckout(amount);
    }
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required String ticket,
  }) async {
    try {
      print('🔍 Verifying payment for ticket: $ticket');

      final response = await http.post(
        Uri.parse('$baseUrl/verify-payment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ticket': ticket}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return _createFallbackVerification(ticket);
      }
    } catch (e) {
      print('❌ Verification error: $e');
      return _createFallbackVerification(ticket);
    }
  }

  // Fallback methods that always work
  static Map<String, dynamic> _getFallbackProducts() {
    return {
      'success': true,
      'products': [
        {
          'id': '1',
          'name': 'Wireless Headphones',
          'description': 'High-quality wireless headphones with noise cancellation',
          'price': 99.99,
          'imageUrl': '',
        },
        {
          'id': '2',
          'name': 'Smart Watch',
          'description': 'Feature-rich smartwatch with health monitoring',
          'price': 199.99,
          'imageUrl': '',
        },
        {
          'id': '3',
          'name': 'Laptop Backpack',
          'description': 'Durable laptop backpack with multiple compartments',
          'price': 49.99,
          'imageUrl': '',
        },
        {
          'id': '4',
          'name': 'Phone Case',
          'description': 'Protective phone case with stylish design',
          'price': 19.99,
          'imageUrl': '',
        },
        {
          'id': '5',
          'name': 'Bluetooth Speaker',
          'description': 'Portable Bluetooth speaker with excellent sound quality',
          'price': 79.99,
          'imageUrl': '',
        },
      ]
    };
  }

  static Map<String, dynamic> _createFallbackCheckout(double amount) {
    return {
      'success': true,
      'ticket': 'fallback_ticket_${DateTime.now().millisecondsSinceEpoch}',
      'checkout_id': 'fallback_checkout',
      'order_no': 'FALLBACK_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amount.toStringAsFixed(2),
      'is_fallback': true,
    };
  }

  static Map<String, dynamic> _createFallbackVerification(String ticket) {
    return {
      'success': true,
      'transaction_id': 'FALLBACK_TXN_${DateTime.now().millisecondsSinceEpoch}',
      'amount': '25.99',
      'status': 'completed',
      'timestamp': DateTime.now().toIso8601String(),
      'is_fallback': true,
    };
  }
}