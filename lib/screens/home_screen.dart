import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_list.dart';
import '../widgets/cart_screen.dart';
import '../services/moneris_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await MonerisService.getTestProducts();
      if (response['success'] == true) {
        setState(() {
          _products = (response['products'] as List)
              .map((item) => Product(
            id: item['id'],
            name: item['name'],
            description: item['description'],
            price: (item['price'] as num).toDouble(),
            imageUrl: '',
          ))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Failed to load products: $e');
      // Fallback to default products
      setState(() {
        _products = [
          Product(
            id: '1',
            name: 'Test Product 1',
            description: 'Perfect for local testing - \$25.99',
            price: 25.99,
            imageUrl: '',
          ),
          Product(
            id: '2',
            name: 'Test Product 2',
            description: 'Great for development - \$15.50',
            price: 15.50,
            imageUrl: '',
          ),
          Product(
            id: '3',
            name: 'Premium Test',
            description: 'Premium testing product - \$49.99',
            price: 49.99,
            imageUrl: '',
          ),
        ];
        _isLoading = false;
      });
    }
  }

  final List<Widget> _screens = [];

  @override
  Widget build(BuildContext context) {
    _screens.clear();
    _screens.add(_isLoading
        ? const Center(child: CircularProgressIndicator())
        : ProductList(products: _products));
    _screens.add(const CartScreen());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moneris Local Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Reload products',
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shop),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
        ],
      ),
    );
  }
}