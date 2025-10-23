import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';

class ProductList extends StatelessWidget {
  final List<Product> products;

  const ProductList({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text('\$${product.price.toInt()}'),
            ),
            title: Text(product.name),
            subtitle: Text(product.description),
            trailing: IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {
                Provider.of<CartProvider>(context, listen: false).addItem(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${product.name} to cart')),
                );
              },
            ),
          ),
        );
      },
    );
  }
}