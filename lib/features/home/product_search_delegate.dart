import 'package:flutter/material.dart';

class ProductSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> products = [
    {'name': 'Producto Elegante 1', 'price': 'S/ 89.90'},
    {'name': 'Producto Elegante 2', 'price': 'S/ 89.90'},
    {'name': 'Producto Elegante 3', 'price': 'S/ 89.90'},
    {'name': 'Producto Elegante 4', 'price': 'S/ 89.90'},
    {'name': 'Producto Elegante 5', 'price': 'S/ 89.90'},
    {'name': 'Producto Elegante 6', 'price': 'S/ 89.90'},
    {'name': 'Producto Elegante 7', 'price': 'S/ 89.90'},
  ];

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = products.where((p) => 
      p['name']!.toLowerCase().contains(query.toLowerCase())
    ).toList();

    if (results.isEmpty) {
      return const Center(child: Text('No se encontraron productos'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ListTile(
          title: Text(product['name']!),
          subtitle: Text(product['price']!),
          onTap: () => close(context, product),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = products.where((p) => 
      p['name']!.toLowerCase().contains(query.toLowerCase())
    ).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final product = suggestions[index];
        return ListTile(
          title: Text(product['name']!),
          subtitle: Text(product['price']!),
          onTap: () {
            showResults(context);
          },
        );
      },
    );
  }
}