import 'package:flutter_test/flutter_test.dart';
import 'package:si_eja/main.dart';

void main() {
  testWidgets('SiEjaApp initialization test', (WidgetTester tester) async {
    // Membangun aplikasi SiEjaApp
    await tester.pumpWidget(const SiEjaApp());
    await tester.pumpAndSettle();

    // Memastikan aplikasi berhasil diinisialisasi
    expect(find.byType(SiEjaApp), findsOneWidget);
  });
}
