import 'package:flutter_test/flutter_test.dart';
import 'package:steering_analyzer/main.dart';

void main() {
  testWidgets('Steering Analyzer app renders without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const SteeringAnalyzerApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('DRIVE'), findsOneWidget);
  });
}
