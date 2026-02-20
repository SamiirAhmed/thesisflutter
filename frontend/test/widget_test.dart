// Widget tests for the University Portal app.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    await tester.pumpWidget(const UniversityPortalApp());
    expect(find.byType(UniversityPortalApp), findsOneWidget);
  });
}
