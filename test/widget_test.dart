import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gopal_studio_pro/app.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GopalStudioApp(),
      ),
    );
    expect(find.byType(GopalStudioApp), findsOneWidget);
  });
}
