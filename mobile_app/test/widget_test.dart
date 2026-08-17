import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/app.dart';

void main() {
  testWidgets('App boots to Dashboard screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GoviApp());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsWidgets);
  });
}
