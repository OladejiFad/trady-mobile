import 'package:flutter/material.dart';

class ProductsWidget extends StatelessWidget {
  const ProductsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Products'),
        subtitle: Text('Manage product listings and stock.'),
      ),
    );
  }
}
