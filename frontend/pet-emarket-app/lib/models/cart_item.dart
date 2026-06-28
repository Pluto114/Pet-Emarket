import 'product.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.subtotal,
    required this.product,
  });

  final String id;
  final String productId;
  final int quantity;
  final double subtotal;
  final Product product;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      quantity: NumberParser.toInt(json['quantity']),
      subtotal: NumberParser.toDouble(json['subtotal']),
      product: Product.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
    );
  }
}
