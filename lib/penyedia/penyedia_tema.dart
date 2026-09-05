import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode;

  bool get isDarkMode => _isDarkMode;

  // initialDark is pre-loaded from SharedPreferences in main() before runApp()
  // to eliminate the flash of wrong theme on startup.
  ThemeProvider({bool initialDark = false}) : _isDarkMode = initialDark;

  Future<void> toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);

    // Update system UI overlay to match theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    notifyListeners();
  }
}
