import 'package:flutter_test/flutter_test.dart';
import 'package:pet_emarket_user_app/main.dart';

void main() {
  testWidgets('Pet-Emarket user app starts', (tester) async {
    await tester.pumpWidget(const PetEmarketApp());

    expect(find.text('欢迎来到 Pet-Emarket'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
  });
}
