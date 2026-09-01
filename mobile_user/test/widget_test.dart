import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_user/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App loads and displays Meridian Health', (WidgetTester tester) async {
    await tester.pumpWidget(const MeridianHealthApp());
    await tester.pumpAndSettle();

    expect(find.text('Meridian Health'), findsOneWidget);
  });
}
