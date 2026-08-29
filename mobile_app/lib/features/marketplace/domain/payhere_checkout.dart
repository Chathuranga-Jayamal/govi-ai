/// Everything needed to POST PayHere's Checkout API form from a WebView.
///
/// The `hash` is computed server-side from PAYHERE_MERCHANT_SECRET — this
/// app never sees or generates it, per PayHere's own security requirement.
class PayHereCheckoutData {
  const PayHereCheckoutData({
    required this.checkoutUrl,
    required this.merchantId,
    required this.returnUrl,
    required this.cancelUrl,
    required this.notifyUrl,
    required this.orderId,
    required this.items,
    required this.currency,
    required this.amount,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.country,
    required this.hash,
  });

  factory PayHereCheckoutData.fromJson(Map<String, dynamic> json) =>
      PayHereCheckoutData(
        checkoutUrl: json['checkoutUrl'] as String,
        merchantId: json['merchantId'] as String,
        returnUrl: json['returnUrl'] as String,
        cancelUrl: json['cancelUrl'] as String,
        notifyUrl: json['notifyUrl'] as String,
        orderId: json['orderId'] as String,
        items: json['items'] as String,
        currency: json['currency'] as String,
        amount: json['amount'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        address: json['address'] as String,
        city: json['city'] as String,
        country: json['country'] as String,
        hash: json['hash'] as String,
      );

  final String checkoutUrl;
  final String merchantId;
  final String returnUrl;
  final String cancelUrl;
  final String notifyUrl;
  final String orderId;
  final String items;
  final String currency;
  final String amount;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String country;
  final String hash;

  /// Field names PayHere's Checkout API expects, in POST-form form.
  Map<String, String> toFormFields() => {
    'merchant_id': merchantId,
    'return_url': returnUrl,
    'cancel_url': cancelUrl,
    'notify_url': notifyUrl,
    'order_id': orderId,
    'items': items,
    'currency': currency,
    'amount': amount,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
    'address': address,
    'city': city,
    'country': country,
    'hash': hash,
  };
}
