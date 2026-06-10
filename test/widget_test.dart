import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:njangi_trust/main.dart';

void main() {
  testWidgets('App builds and shows splash then onboarding', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: NjangiTrustApp()),
    );
    expect(find.text('NJANGI TRUST'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.textContaining('Save Together'), findsOneWidget);
  });
}
