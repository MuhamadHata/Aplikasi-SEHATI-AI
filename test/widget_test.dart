// Basic smoke test for SehatiAIApp
import 'package:flutter_test/flutter_test.dart';
import 'package:sehati_ai/main.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sehati_ai/penyedia/penyedia_tema.dart';

void main() {
  testWidgets('SehatiAIApp smoke test - app renders without crashing',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(initialDark: false),
        child: const SehatiAIApp(),
      ),
    );

    // Verify the app builds without crashing by checking the MaterialApp is present.
    expect(find.byType(SehatiAIApp), findsOneWidget);

    // Fast-forward past splash timer to flush all scheduled work
    await tester.pump(const Duration(milliseconds: 5000));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
