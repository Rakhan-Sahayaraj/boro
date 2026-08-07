import 'package:flutter_test/flutter_test.dart';
import 'package:boro_app/main.dart';

void main() {
  testWidgets('BoroApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BoroApp());
    // Verify the app builds without errors
    expect(find.byType(BoroApp), findsOneWidget);
  });
}
