import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/state/cart_controller.dart';
import '../../../../core/state/current_user_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/order_repository.dart';
import '../../data/payment_repository.dart';
import '../../domain/cart_item.dart';
import '../../domain/order.dart';
import '../../domain/payhere_checkout.dart';

const List<String> _sriLankaDistricts = [
  'Colombo',
  'Gampaha',
  'Kalutara',
  'Kandy',
  'Matale',
  'Nuwara Eliya',
  'Galle',
  'Matara',
  'Hambantota',
  'Jaffna',
  'Kilinochchi',
  'Mannar',
  'Vavuniya',
  'Mullaitivu',
  'Batticaloa',
  'Ampara',
  'Trincomalee',
  'Kurunegala',
  'Puttalam',
  'Anuradhapura',
  'Polonnaruwa',
  'Badulla',
  'Monaragala',
  'Ratnapura',
  'Kegalle',
];

enum _PaymentMethod {
  cashOnDelivery,
  cardPayment,
  payHere;

  String get label {
    switch (this) {
      case _PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case _PaymentMethod.cardPayment:
        return 'Card Payment';
      case _PaymentMethod.payHere:
        return 'PayHere';
    }
  }

  IconData get icon {
    switch (this) {
      case _PaymentMethod.cashOnDelivery:
        return Icons.local_shipping_outlined;
      case _PaymentMethod.cardPayment:
        return Icons.credit_card;
      case _PaymentMethod.payHere:
        return Icons.account_balance_wallet_outlined;
    }
  }

  // Matches the backend's orders.payment_method CHECK constraint
  // ('cod'/'card'/'payhere') — the enum member names don't match those
  // values, so this can't just be `.name`.
  String get apiValue {
    switch (this) {
      case _PaymentMethod.cashOnDelivery:
        return 'cod';
      case _PaymentMethod.cardPayment:
        return 'card';
      case _PaymentMethod.payHere:
        return 'payhere';
    }
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedDistrict;

  final OrderRepository _orderRepository = OrderRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();

  CurrentUserController? _userController;
  bool _didPrefillPhone = false;

  _PaymentMethod _selectedMethod = _PaymentMethod.cashOnDelivery;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    // Keeps the "Place Order" button's enabled state (see _isFormValid)
    // reactive as the user types, without a Form/validator setup — this
    // app doesn't use Form elsewhere either (see RegisterScreen).
    _streetController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final CurrentUserController userController = CurrentUserScope.of(context);
    if (_userController != userController) {
      _userController?.removeListener(_onUserChanged);
      _userController = userController..addListener(_onUserChanged);
      // Checkout may be the first screen reached this session before
      // Dashboard/Profile ever triggered a fetch — this is a no-op if the
      // user is already loaded or a fetch is already in flight.
      Future.microtask(userController.load);
      _maybePrefillPhone();
    }
  }

  void _onUserChanged() {
    _maybePrefillPhone();
    setState(() {});
  }

  // Prefills the phone field exactly once, so it doesn't overwrite
  // anything the user already typed if the user fetch resolves late.
  void _maybePrefillPhone() {
    if (_didPrefillPhone) return;
    final String? phone = _userController?.user?.phoneNumber;
    if (phone == null || phone.isEmpty) return;
    _phoneController.text = phone;
    _didPrefillPhone = true;
  }

  bool get _isFormValid =>
      _streetController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty &&
      _selectedDistrict != null &&
      _phoneController.text.trim().isNotEmpty;

  String _buildDeliveryAddress() {
    final String street = _streetController.text.trim();
    final String city = _cityController.text.trim();
    final String district = _selectedDistrict!;
    final String postalCode = _postalCodeController.text.trim();
    final String phone = _phoneController.text.trim();

    final String base = postalCode.isEmpty
        ? '$street, $city, $district District'
        : '$street, $city, $district District, $postalCode';
    return '$base. Contact: $phone';
  }

  @override
  void dispose() {
    _userController?.removeListener(_onUserChanged);
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(CartController controller) async {
    setState(() => _isPlacingOrder = true);
    try {
      final Order order = await _orderRepository.placeOrder(
        deliveryAddress: _buildDeliveryAddress(),
        paymentMethod: _selectedMethod.apiValue,
      );
      if (!mounted) return;
      // The server already cleared cart_items as part of placing the
      // order — this just resets local state to match.
      controller.clear();

      if (_selectedMethod == _PaymentMethod.payHere) {
        final PayHereCheckoutData checkout = await _paymentRepository.initiate(
          orderId: order.id,
        );
        if (!mounted) return;
        final bool? paymentCompleted = await context.push<bool>(
          '/marketplace/payhere-checkout',
          extra: (checkout: checkout, orderId: order.id),
        );
        if (!mounted) return;
        if (paymentCompleted != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment was cancelled.')),
          );
          return;
        }
      }

      context.pushReplacement(
        '/marketplace/order-confirmation',
        extra: order.orderNumber,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.alertRed,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: AppColors.alertRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CartController controller = CartScope.of(context);
    final List<CartItem> items = controller.items;
    final String recipientName =
        _userController?.user?.fullName ?? 'Loading…';

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Order Summary', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.product.name} × ${item.quantity}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                'Rs. ${item.lineTotal.toStringAsFixed(0)}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: theme.textTheme.titleMedium),
                          Text(
                            'Rs. ${controller.totalPrice.toStringAsFixed(0)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.paddyGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('Delivery Address', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            color: AppColors.paddyGreen,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(recipientName, style: theme.textTheme.titleSmall),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _streetController,
                        decoration: const InputDecoration(
                          labelText: 'House/Building No. & Street *',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City/Town *',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDistrict,
                        decoration: const InputDecoration(
                          labelText: 'District *',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        items: _sriLankaDistricts
                            .map(
                              (district) => DropdownMenuItem(
                                value: district,
                                child: Text(district),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedDistrict = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _postalCodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Postal Code',
                          prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact Phone for this Delivery *',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('Payment Method', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              for (final method in _PaymentMethod.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _PaymentMethodCard(
                    method: method,
                    selected: _selectedMethod == method,
                    onTap: () => setState(() => _selectedMethod = method),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              FilledButton(
                onPressed: items.isEmpty || _isPlacingOrder || !_isFormValid
                    ? null
                    : () => _placeOrder(controller),
                child: _isPlacingOrder
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Place Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final _PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.paddyGreenContainer
                : AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.paddyGreen : AppColors.hairline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                method.icon,
                color: selected
                    ? AppColors.paddyGreenOnContainer
                    : AppColors.soilInkSoft,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(method.label, style: theme.textTheme.titleSmall),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.paddyGreen : AppColors.soilInkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
