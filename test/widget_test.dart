import 'package:flutter_test/flutter_test.dart';
import 'package:mama_segura/app.dart';

void main() {
  testWidgets('Salud Prenatal smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login screen is presented first and brand is visible
    expect(find.text('Salud Prenatal'), findsAtLeastNWidgets(1));
    expect(find.text('Correo electrónico'), findsOneWidget);
  });
}
