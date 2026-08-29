/// The PayHere return/cancel URLs for one checkout attempt, used by
/// [PayHereCheckoutScreen] to detect when the WebView flow has finished.
///
/// The rest of PayHere's Checkout API fields (merchant_id, hash, amount,
/// etc.) are built and submitted entirely server-side by
/// GET /payments/checkout-form — the app never sees or handles them.
class PayHereCheckoutData {
  const PayHereCheckoutData({required this.returnUrl, required this.cancelUrl});

  factory PayHereCheckoutData.fromJson(Map<String, dynamic> json) =>
      PayHereCheckoutData(
        returnUrl: json['returnUrl'] as String,
        cancelUrl: json['cancelUrl'] as String,
      );

  final String returnUrl;
  final String cancelUrl;
}
