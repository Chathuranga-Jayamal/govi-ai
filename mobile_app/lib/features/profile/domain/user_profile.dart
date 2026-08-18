/// Mock persona shared by the profile preview sheet and the full Profile
/// screen — single source of truth so both stay in sync. Matches the
/// same "Kumara Silva" persona used on Register and Checkout.
const String mockUserName = 'Kumara Silva';
const String mockUserEmail = 'kumara.silva@example.com';
const String mockUserPhone = '077 123 4567';
const String mockMemberSince = 'January 2026';

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

class Order {
  const Order({
    required this.orderNumber,
    required this.dateLabel,
    required this.itemCount,
    required this.total,
    required this.status,
  });

  final String orderNumber;
  final String dateLabel;
  final int itemCount;
  final double total;
  final OrderStatus status;

  String get totalLabel => 'Rs. ${total.toStringAsFixed(0)}';

  String get itemCountLabel => itemCount == 1 ? '1 item' : '$itemCount items';
}

const List<Order> mockOrders = [
  Order(
    orderNumber: 'GOVI-4821',
    dateLabel: '12 Jul 2026',
    itemCount: 3,
    total: 4200,
    status: OrderStatus.delivered,
  ),
  Order(
    orderNumber: 'GOVI-4790',
    dateLabel: '28 Jun 2026',
    itemCount: 1,
    total: 2450,
    status: OrderStatus.delivered,
  ),
  Order(
    orderNumber: 'GOVI-4756',
    dateLabel: '15 Jun 2026',
    itemCount: 2,
    total: 3130,
    status: OrderStatus.processing,
  ),
  Order(
    orderNumber: 'GOVI-4701',
    dateLabel: '30 May 2026',
    itemCount: 1,
    total: 1180,
    status: OrderStatus.cancelled,
  ),
  Order(
    orderNumber: 'GOVI-4650',
    dateLabel: '10 May 2026',
    itemCount: 4,
    total: 6800,
    status: OrderStatus.delivered,
  ),
];
