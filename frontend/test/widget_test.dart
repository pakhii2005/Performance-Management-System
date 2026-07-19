import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('EPMS app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EpmsApp());

    // Verify that splash screen content is rendered
    expect(find.textContaining('Enterprise Performance'), findsOneWidget);
  });
}
