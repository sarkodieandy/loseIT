import 'package:flutter_test/flutter_test.dart';

import 'package:discipline/app/discipline_app.dart';

void main() {
  testWidgets('Shows onboarding welcome', (WidgetTester tester) async {
    await tester.pumpWidget(const DisciplineApp());
    await tester.pumpAndSettle();

    expect(find.text('Take Back Control.'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
  });
}
