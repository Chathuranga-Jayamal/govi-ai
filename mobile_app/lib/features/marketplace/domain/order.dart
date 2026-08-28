import 'product.dart';

const List<String> _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime date) =>
    '${date.day} ${_monthAbbreviations[date.month - 1]} ${date.year}';

enum OrderStatus {
  delivered,
  processing,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class OrderItemEntry {
  const OrderItemEntry({
    required this.product,
    required this.quantity,
    required this.priceAtPurchase,
  });

  factory OrderItemEntry.fromJson(Map<String, dynamic> json) => OrderItemEntry(
    product: Product.fromJson(json['product'] as Map<String, dynamic>),
    quantity: json['quantity'] as int,
    priceAtPurchase: (json['priceAtPurchase'] as num).toDouble(),
  );

  final Product product;
  final int quantity;
  final double priceAtPurchase;
}

/// Result of a GET/POST /orders call.
class Order {
  const Order({
    required this.orderNumber,
    required this.dateLabel,
    required this.itemCount,
    required this.total,
    required this.status,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final List<OrderItemEntry> items = (json['items'] as List<dynamic>)
        .map((entry) => OrderItemEntry.fromJson(entry as Map<String, dynamic>))
        .toList();
    final String? placedAtRaw = json['placedAt'] as String?;
    final DateTime? placedAt = placedAtRaw != null
        ? DateTime.parse(placedAtRaw)
        : null;

    return Order(
      orderNumber: json['orderNumber'] as String,
      dateLabel: placedAt != null ? _formatDate(placedAt) : '',
      itemCount: items.length,
      total: (json['totalAmount'] as num).toDouble(),
      status: OrderStatus.values.byName(json['status'] as String),
      items: items,
    );
  }

  final String orderNumber;
  final String dateLabel;
  final int itemCount;
  final double total;
  final OrderStatus status;
  final List<OrderItemEntry> items;

  String get totalLabel => 'Rs. ${total.toStringAsFixed(0)}';

  String get itemCountLabel => itemCount == 1 ? '1 item' : '$itemCount items';
}
