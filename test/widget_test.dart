import 'package:flutter_test/flutter_test.dart';
import 'package:ver/app/app.dart';

void main() {
  testWidgets('SmartBuffetApp inicializa e renderiza tela inicial V.E.R.', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartBuffetApp());
    await tester.pumpAndSettle();

    expect(find.text('SmartBuffet'), findsWidgets);
    expect(find.text('V.E.R.'), findsWidgets);
    expect(find.text('Conhecer o projeto'), findsOneWidget);
  });
}
