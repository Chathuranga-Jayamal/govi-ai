import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/network/api_config.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/payhere_checkout.dart';

/// Opens PayHere's hosted sandbox checkout in a WebView.
///
/// The auto-submitting checkout form is rendered by the backend
/// (GET /payments/checkout-form) rather than built locally with
/// `loadHtmlString` — PayHere's Checkout API expects the request to come
/// from a real page origin, and a `loadHtmlString` document has none at
/// all. Loading the real backend page here means the POST to PayHere
/// carries a genuine https://govi-ai.fly.dev origin.
///
/// Pops `true` once navigation reaches [PayHereCheckoutData.returnUrl]
/// (payment completed — PayHere's own notify webhook is the source of
/// truth for whether it actually succeeded, this is just "the flow
/// finished"), or `false` on [PayHereCheckoutData.cancelUrl].
class PayHereCheckoutScreen extends StatefulWidget {
  const PayHereCheckoutScreen({
    required this.checkout,
    required this.orderId,
    super.key,
  });

  final PayHereCheckoutData checkout;
  final int orderId;

  @override
  State<PayHereCheckoutScreen> createState() => _PayHereCheckoutScreenState();
}

class _PayHereCheckoutScreenState extends State<PayHereCheckoutScreen> {
  late final WebViewController _controller;
  bool _hasResolved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _onNavigationRequest),
      );
    _loadCheckoutForm();
  }

  Future<void> _loadCheckoutForm() async {
    final String? token = await TokenStorage().readToken();
    final Uri uri = Uri.parse(
      '${ApiConfig.baseUrl}/payments/checkout-form',
    ).replace(queryParameters: {'order_id': widget.orderId.toString()});

    await _controller.loadRequest(
      uri,
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (mounted) setState(() => _isLoading = false);
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (request.url.startsWith(widget.checkout.returnUrl)) {
      _resolve(true);
      return NavigationDecision.prevent;
    }
    if (request.url.startsWith(widget.checkout.cancelUrl)) {
      _resolve(false);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  void _resolve(bool success) {
    if (_hasResolved || !mounted) return;
    _hasResolved = true;
    Navigator.of(context).pop(success);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _resolve(false);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('PayHere Checkout')),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
