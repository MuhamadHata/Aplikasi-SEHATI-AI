import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sehati_ai/inti/layanan/layanan_gemini.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // Enable real HTTP requests in test
  SharedPreferences.setMockInitialValues({});

  test('AI Pipeline: generateText', () async {
    final res = await GeminiService.instance.generateText('Sebutkan 3 tips hidup sehat secara singkat.');
    print('generateText response:\n$res');
    expect(res, isNotNull);
    expect(res!.isNotEmpty, true);
  }, timeout: const Timeout(Duration(seconds: 40)));

  test('AI Pipeline: generateChat', () async {
    final res = await GeminiService.instance.generateChat([
      {'role': 'user', 'content': 'Halo, saya sering merasa lelah setelah berolahraga.'},
      {'role': 'assistant', 'content': 'Apakah Anda cukup minum air dan beristirahat?'},
      {'role': 'user', 'content': 'Kurang minum air sepertinya.'},
    ]);
    print('generateChat response:\n$res');
    expect(res, isNotNull);
    expect(res!.isNotEmpty, true);
  }, timeout: const Timeout(Duration(seconds: 40)));

  test('AI Pipeline: generateWithImage', () async {
    final bytes = File('assets/images/app_icon.png').readAsBytesSync();
    final res = await GeminiService.instance.generateWithImage(
      'Apa yang terlihat pada gambar ini?',
      bytes,
    );
    print('generateWithImage response:\n$res');
    expect(res, isNotNull);
    expect(res!.isNotEmpty, true);
  }, timeout: const Timeout(Duration(seconds: 40)));
}
