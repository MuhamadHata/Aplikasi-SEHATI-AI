// Basic unit and smoke test for SehatiAI
import 'package:flutter_test/flutter_test.dart';
import 'package:sehati_ai/penyedia/penyedia_tema.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ThemeProvider initial state and toggle', () {
    final provider = ThemeProvider(initialDark: false);
    expect(provider.isDarkMode, false);
    provider.toggleTheme(true);
    expect(provider.isDarkMode, true);
  });
}
