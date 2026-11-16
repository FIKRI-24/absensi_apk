import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/main.dart';
import 'package:mobile/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('AbsensiApp shows LoginScreen initially when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AbsensiApp(),
      ),
    );

    // Initial state without stored token should display login screen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Sistem Absensi SPG'), findsOneWidget);
    expect(find.text('Silakan masuk untuk melanjutkan'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
