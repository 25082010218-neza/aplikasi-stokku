import "package:flutter_test/flutter_test.dart";
import "package:stokku_mobile/main.dart";

void main() {
  testWidgets("StokkuApp builds and displays brand", (WidgetTester tester) async {
    await tester.pumpWidget(const StokkuApp());
    expect(find.text("Stokku"), findsWidgets);
  });
}
