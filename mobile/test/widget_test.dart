import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/app.dart';

void main() {
  testWidgets('MedStudy App launches splash screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MedStudyApp());
    await tester.pumpAndSettle();

    expect(find.text('MedStudy'), findsOneWidget);
    expect(find.text('Medical Education Platform'), findsOneWidget);
  });
}
