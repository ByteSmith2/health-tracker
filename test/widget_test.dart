import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const HealthTrackerApp());
    expect(find.text('Health Tracker'), findsOneWidget);
  });
}
