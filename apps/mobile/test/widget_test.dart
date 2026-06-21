import 'package:flutter_test/flutter_test.dart';

import 'package:glicoo_mobile/main.dart';

void main() {
  testWidgets('Glico app renders theme preview', (WidgetTester tester) async {
    await tester.pumpWidget(const GlicoApp());
    await tester.pumpAndSettle();

    expect(find.text('Glico'), findsOneWidget);
    expect(find.text('Design System'), findsOneWidget);
    expect(find.text('Primary Button'), findsOneWidget);
  });
}
