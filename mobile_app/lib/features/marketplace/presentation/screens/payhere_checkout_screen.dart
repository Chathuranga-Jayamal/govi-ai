import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/payhere_checkout.dart';

/// Opens PayHere's hosted sandbox checkout in a WebView.
///
/// PayHere's Checkout API expects a standard form POST, not a GET with
/// query params — this loads a hidden auto-submitting HTML form rather
/// than navigating directly to the checkout URL, so the request the
/// WebView actually issues is a real POST.
///
/// Pops `true` once navigation reaches [PayHereCheckoutData.returnUrl]
/// (payment completed — PayHere's own notify webhook is the source of
/// truth for whether it actually succeeded, this is just "the flow
/// finished"), or `false` on [PayHereCheckoutData.cancelUrl].
class PayHereCheckoutScreen extends StatefulWidget {
  const PayHereCheckoutScreen({required this.checkout, super.key});

  final PayHereCheckoutData checkout;

  @override
  State<PayHereCheckoutScreen> createState() => _PayHereCheckoutScreenState();
}

class _PayHereCheckoutScreenState extends State<PayHereCheckoutScreen> {
  late final WebViewController _controller;
  bool _hasResolved = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _onNavigationRequest),
      )
      ..loadHtmlString(_buildAutoSubmitFormHtml(widget.checkout));
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
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}

String _htmlEscape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String _buildAutoSubmitFormHtml(PayHereCheckoutData checkout) {
  final String fields = checkout.toFormFields().entries
      .map(
        (entry) =>
            '<input type="hidden" name="${_htmlEscape(entry.key)}" '
            'value="${_htmlEscape(entry.value)}">',
      )
      .join();

  return '''
<!DOCTYPE html>
<html>
  <body onload="document.forms[0].submit()">
    <form method="POST" action="${_htmlEscape(checkout.checkoutUrl)}">
      $fields
    </form>
  </body>
</html>
''';
}
