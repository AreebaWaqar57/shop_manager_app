import 'package:flutter/material.dart';

import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: product.thumbnail.isEmpty
            ? const Icon(Icons.image_not_supported, size: 40)
            : Image.network(
          product.thumbnail,
          width: 56,
          height: 56,
          errorBuilder: (context, error, stack) =>
          const Icon(Icons.image_not_supported),
        ),
        title: Text(
          product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          product.category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text('\$${product.price.toStringAsFixed(2)}'),
      ),
    );
  }
}