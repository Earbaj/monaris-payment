// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'moneris_payment_screen.dart';
// import 'SuccessPage.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Moneris Demo',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const HomePage(),
//     );
//   }
// }
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   final TextEditingController _amountController = TextEditingController(text: "10");
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Moneris Demo")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _amountController,
//               keyboardType: TextInputType.numberWithOptions(decimal: true),
//               decoration: const InputDecoration(
//                 labelText: "Amount",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () async {
//                 final amount = double.tryParse(_amountController.text);
//                 if (amount == null || amount <= 0) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Enter a valid amount")),
//                   );
//                   return;
//                 }
//
//                 final result = await Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => MonerisPaymentScreen(amount: 10.0),
//                   ),
//                 );
//
//                 if (result != null) {
//                   final token = result['token'];
//                   final checkoutId = result['checkout_id'];
//
//                   final verified = await verifyToken(token, checkoutId);
//                   if (verified) {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const SuccessPage()),
//                     );
//                   } else {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const FailedPage()),
//                     );
//                   }
//                 }
//               },
//               child: const Text("Pay"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<bool> verifyToken(String token,String checkoutId) async {
//     try {
//       final response = await http.post(
//         Uri.parse('http://192.168.68.116:5000/verify-token'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "token": token,
//           "checkout_id": checkoutId, // Or dynamically if your backend generates it
//         }),
//       );
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['success'] == true;
//       }
//       return false;
//     } catch (e) {
//       debugPrint("Verification error: $e");
//       return false;
//     }
//   }
// }


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: MaterialApp(
        title: 'Moneris Checkout App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}