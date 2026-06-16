import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets('shows student auth screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SREduNovaStudentApp());
    await tester.pump();

    expect(find.text('Login'), findsWidgets);
    expect(find.text('Sign up'), findsWidgets);
  });
}
