import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_user/main.dart';

void main() {
  testWidgets('App loads LoginScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MeridianHealthApp());

    // Verify that Meridian Health title is displayed.
    expect(find.text('Meridian Health'), findsOneWidget);
  });
}
