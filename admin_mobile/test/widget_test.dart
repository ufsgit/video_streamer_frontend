import 'package:flutter_test/flutter_test.dart';
import 'package:admin_mobile/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CarePulseAdminApp(initialLoggedIn: false));
    expect(find.byType(CarePulseAdminApp), findsOneWidget);
  });
}
