// ==========================================
// BAGIAN: LAYANAN (SERVICES)
// Berisi logika bisnis, pemanggilan API, dan fungsi inti aplikasi.
// ==========================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'layanan_minicpm_ondevice.dart';

/// Hybrid AI service for SEHATI-AI.
///
/// Flow:
/// 1. Try the active provider first.
/// 2. Rotate to the next key when that provider hits quota/rate limit.
/// 3. Fall back to the other provider when all keys of the current provider
///    are exhausted or the provider is temporarily unavailable.
///
/// Keys are injected with `--dart-define` so they are not committed to source.
/// For stronger security, route AI requests through your own backend proxy.
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  static const String _assetConfigPath = 'assets/config/ai_config.json';
  static const String _groqKeysEnv = String.fromEnvironment('NUBI_GROQ_KEYS');
  static const String _geminiKeysEnv =
      String.fromEnvironment('NUBI_GEMINI_KEYS');
  static const String _preferredProviderEnv =
      String.fromEnvironment('NUBI_AI_PRIMARY', defaultValue: 'groq');

  List<_AiProvider> _providers = const [];
  int _currentProviderIndex = 0;
  Future<void>? _initialization;
  bool _isInitialized = false;

  Future<void> initialize() {
    if (_isInitialized) return Future.value();
    final existing = _initialization;
    if (existing != null) return existing;
    final future = _loadConfiguration();
    _initialization = future;
    return future;
  }

  /// Send a text-only prompt with automatic key rotation and provider failover.
  Future<String?> generateText(
    String prompt, {
    String? model,
    String? systemPrompt,
  }) async {
    // 1. Try On-Device MiniCPM-V first (No limit, 100% local)
    if (MiniCpmVOnDeviceService.instance.isEnabled) {
      final onDeviceRes = await MiniCpmVOnDeviceService.instance.generateText(
        prompt,
        systemPrompt: systemPrompt,
      );
      if (onDeviceRes != null && onDeviceRes.trim().isNotEmpty) {
        debugPrint('[HybridAI] Served by On-Device MiniCPM-V (No limit/Offline)');
        return cleanAiText(onDeviceRes);
      }
    }

    await initialize();
    return _executeWithFailover((provider) {
      if (provider.type == _AiProviderType.groq) {
        return _generateGroqText(
          provider,
          prompt,
          model: model,
          systemPrompt: systemPrompt,
        );
      }
      return _generateGeminiText(
        provider,
        prompt,
        model: model,
        systemPrompt: systemPrompt,
      );
    });
  }

  /// Send a multi-turn chat conversation with automatic provider failover.
  Future<String?> generateChat(
    List<Map<String, String>> messages, {
    String? model,
    String? systemPrompt,
    double temperature = 0.5,
  }) async {
    // 1. Try On-Device MiniCPM-V first (No limit, 100% local)
    if (MiniCpmVOnDeviceService.instance.isEnabled) {
      final onDeviceRes = await MiniCpmVOnDeviceService.instance.generateChat(
        messages,
        systemPrompt: systemPrompt,
      );
      if (onDeviceRes != null && onDeviceRes.trim().isNotEmpty) {
        debugPrint('[HybridAI] Served by On-Device MiniCPM-V Chat (No limit/Offline)');
        return cleanAiText(onDeviceRes);
      }
    }

    await initialize();
    return _executeWithFailover((provider) {
      if (provider.type == _AiProviderType.groq) {
        return _generateGroqChat(
          provider,
          messages,
          model: model,
          systemPrompt: systemPrompt,
          temperature: temperature,
        );
      }
      return _generateGeminiChat(
        provider,
        messages,
        model: model,
        systemPrompt: systemPrompt,
        temperature: temperature,
      );
    });
  }

  /// Send a multimodal request (text + image) with automatic provider failover.
  Future<String?> generateWithImage(
    String prompt,
    Uint8List imageBytes, {
    String? model,
    String? systemPrompt,
    String mimeType = 'image/jpeg',
  }) async {
    // 1. Try On-Device MiniCPM-V Vision first (No limit, 100% local)
    if (MiniCpmVOnDeviceService.instance.isEnabled) {
      final onDeviceRes = await MiniCpmVOnDeviceService.instance.generateVision(
        imageBytes: imageBytes,
        prompt: prompt,
        systemPrompt: systemPrompt,
      );
      if (onDeviceRes != null && onDeviceRes.trim().isNotEmpty) {
        debugPrint('[HybridAI] Served by On-Device MiniCPM-V Vision (No limit/Offline)');
        return onDeviceRes.trim();
      }
    }

    await initialize();
    return _executeWithFailover((provider) {
      if (provider.type == _AiProviderType.groq) {
        return _generateGroqWithImage(
          provider,
          prompt,
          imageBytes,
          model: model,
          systemPrompt: systemPrompt,
          mimeType: mimeType,
        );
      }
      return _generateGeminiWithImage(
        provider,
        prompt,
        imageBytes,
        model: model,
        systemPrompt: systemPrompt,
        mimeType: mimeType,
      );
    });
  }

  Future<String?> _executeWithFailover(
    Future<String?> Function(_AiProvider provider) request,
  ) async {
    if (_providers.isEmpty) {
      throw Exception(
        'AI provider belum dikonfigurasi. Isi NUBI_GROQ_KEYS dan/atau '
        'NUBI_GEMINI_KEYS via --dart-define.',
      );
    }

    final errors = <String>[];

    for (int providerAttempt = 0;
        providerAttempt < _providers.length;
        providerAttempt++) {
      final providerIndex =
          (_currentProviderIndex + providerAttempt) % _providers.length;
      final provider = _providers[providerIndex];

      for (int keyAttempt = 0;
          keyAttempt < provider.apiKeys.length;
          keyAttempt++) {
        try {
          final response = await request(provider);
          _currentProviderIndex = providerIndex;
          return response;
        } catch (e) {
          final errorText = e.toString();
          errors.add('${provider.label}[key ${provider.currentKeyIndex + 1}]: '
              '$errorText');

          final exhausted = _isUsageLimitError(errorText);
          final shouldTryNextKey = exhausted && provider.rotateKey();
          final shouldTryNextProvider = exhausted || _shouldFallbackProvider(errorText);

          debugPrint('[HybridAI] ${provider.label} failed: $errorText');

          if (shouldTryNextKey) {
            continue;
          }

          if (shouldTryNextProvider) {
            break;
          }

          rethrow;
        }
      }
    }

    throw Exception(
      '[HybridAI] Semua provider AI gagal. Detail: ${errors.join(' | ')}',
    );
  }

  Future<String?> _generateGroqText(
    _AiProvider provider,
    String prompt, {
    String? model,
    String? systemPrompt,
    double temperature = 0.7,
  }) async {
    final messages = <Map<String, dynamic>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    return _postGroq(
      provider,
      messages: messages,
      model: model ?? provider.textModel,
      temperature: temperature,
      timeout: const Duration(seconds: 30),
    );
  }

  Future<String?> _generateGroqChat(
    _AiProvider provider,
    List<Map<String, String>> messages, {
    String? model,
    String? systemPrompt,
    double temperature = 0.5,
  }) async {
    final requestMessages = <Map<String, dynamic>>[];

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      requestMessages.add({'role': 'system', 'content': systemPrompt});
    }

    for (final message in messages) {
      final role = message['role']?.trim();
      final content = message['content']?.trim();
      if (role == null || role.isEmpty || content == null || content.isEmpty) {
        continue;
      }
      requestMessages.add({'role': role, 'content': content});
    }

    if (requestMessages.isEmpty) {
      throw ArgumentError('Messages cannot be empty.');
    }

    return _postGroq(
      provider,
      messages: requestMessages,
      model: model ?? provider.textModel,
      temperature: temperature,
      timeout: const Duration(seconds: 45),
    );
  }

  Future<String?> _generateGroqWithImage(
    _AiProvider provider,
    String prompt,
    Uint8List imageBytes, {
    String? model,
    String? systemPrompt,
    String mimeType = 'image/jpeg',
    double temperature = 0.7,
  }) async {
    final base64Image = base64Encode(imageBytes);
    final messages = <Map<String, dynamic>>[];

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    messages.add({
      'role': 'user',
      'content': [
        {'type': 'text', 'text': prompt},
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:$mimeType;base64,$base64Image',
          },
        },
      ],
    });

    return _postGroq(
      provider,
      messages: messages,
      model: model ?? provider.visionModel,
      temperature: temperature,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<String?> _postGroq(
    _AiProvider provider, {
    required List<Map<String, dynamic>> messages,
    required String model,
    required double temperature,
    required Duration timeout,
  }) async {
    http.Response response = await http
        .post(
          Uri.parse(provider.baseUrl),
          headers: {
            'Authorization': 'Bearer ${provider.currentKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': temperature,
          }),
        )
        .timeout(timeout);

    if (response.statusCode == 404 && model == 'qwen/qwen3.8-27b') {
      debugPrint('[HybridAI] Model $model returned 404, fallback to qwen/qwen3.6-27b');
      response = await http
          .post(
            Uri.parse(provider.baseUrl),
            headers: {
              'Authorization': 'Bearer ${provider.currentKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'qwen/qwen3.6-27b',
              'messages': messages,
              'temperature': temperature,
            }),
          )
          .timeout(timeout);
    }

    return _parseGroqResponse(response);
  }

  Future<String?> _generateGeminiText(
    _AiProvider provider,
    String prompt, {
    String? model,
    String? systemPrompt,
    double temperature = 0.7,
  }) async {
    final contents = [
      {
        'role': 'user',
        'parts': [
          {'text': prompt},
        ],
      },
    ];

    return _postGemini(
      provider,
      contents: contents,
      model: model ?? provider.textModel,
      systemPrompt: systemPrompt,
      temperature: temperature,
      timeout: const Duration(seconds: 30),
    );
  }

  Future<String?> _generateGeminiChat(
    _AiProvider provider,
    List<Map<String, String>> messages, {
    String? model,
    String? systemPrompt,
    double temperature = 0.5,
  }) async {
    final contents = <Map<String, dynamic>>[];

    for (final message in messages) {
      final role = message['role']?.trim().toLowerCase();
      final content = message['content']?.trim();
      if (content == null || content.isEmpty) {
        continue;
      }

      contents.add({
        'role': role == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': content},
        ],
      });
    }

    if (contents.isEmpty) {
      throw ArgumentError('Messages cannot be empty.');
    }

    return _postGemini(
      provider,
      contents: contents,
      model: model ?? provider.textModel,
      systemPrompt: systemPrompt,
      temperature: temperature,
      timeout: const Duration(seconds: 45),
    );
  }

  Future<String?> _generateGeminiWithImage(
    _AiProvider provider,
    String prompt,
    Uint8List imageBytes, {
    String? model,
    String? systemPrompt,
    String mimeType = 'image/jpeg',
    double temperature = 0.7,
  }) async {
    final contents = [
      {
        'role': 'user',
        'parts': [
          {'text': prompt},
          {
            'inline_data': {
              'mime_type': mimeType,
              'data': base64Encode(imageBytes),
            },
          },
        ],
      },
    ];

    return _postGemini(
      provider,
      contents: contents,
      model: model ?? provider.visionModel,
      systemPrompt: systemPrompt,
      temperature: temperature,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<String?> _postGemini(
    _AiProvider provider, {
    required List<Map<String, dynamic>> contents,
    required String model,
    required double temperature,
    required Duration timeout,
    String? systemPrompt,
  }) async {
    final payload = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
      },
    };

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      payload['system_instruction'] = {
        'parts': [
          {'text': systemPrompt},
        ],
      };
    }

    final response = await http
        .post(
          Uri.parse('${provider.baseUrl}/$model:generateContent'),
          headers: {
            'x-goog-api-key': provider.currentKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(timeout);

    return _parseGeminiResponse(response);
  }

  /// Membersihkan teks AI dari formatting bintang ganda (**), garis pembatas,
  /// serta tanda hubung/bullet di awal baris (- ) agar tidak terkesan kaku (AI slop),
  /// melainkan tampil alami, naratif, dan profesional.
  static String cleanAiText(String text) {
    if (text.isEmpty) return text;
    var cleaned = text
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll('`', '');

    final lines = cleaned.split('\n');
    final processed = <String>[];
    for (final line in lines) {
      var trimmed = line.trim();
      // Lewati garis pemisah horizontal markdown
      if (RegExp(r'^[\-\_]{2,}$').hasMatch(trimmed)) {
        continue;
      }
      // Hapus bullet marker di awal baris
      if (RegExp(r'^[\-\*\u2022]\s+').hasMatch(trimmed)) {
        trimmed = trimmed.replaceFirst(RegExp(r'^[\-\*\u2022]\s+'), '');
      }
      processed.add(trimmed);
    }
    return processed.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  String? _parseGroqResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final raw = data['choices']?[0]?['message']?['content'] as String?;
      return raw != null ? cleanAiText(raw) : null;
    }

    throw Exception('Groq API error ${response.statusCode}: ${response.body}');
  }

  String? _parseGeminiResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Gemini API returned no candidates.');
      }

      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw Exception('Gemini API returned empty content.');
      }

      final text = parts
          .map((part) => part is Map<String, dynamic> ? part['text'] : null)
          .whereType<String>()
          .join('\n')
          .trim();

      if (text.isEmpty) {
        throw Exception('Gemini API returned no text output.');
      }

      return cleanAiText(text);
    }

    throw Exception('Gemini API error ${response.statusCode}: ${response.body}');
  }

  bool _isUsageLimitError(String error) {
    final normalized = error.toLowerCase();
    return normalized.contains('429') ||
        normalized.contains('quota') ||
        normalized.contains('rate limit') ||
        normalized.contains('rate_limit') ||
        normalized.contains('resource_exhausted') ||
        normalized.contains('too many requests') ||
        normalized.contains('usage limit');
  }

  bool _shouldFallbackProvider(String error) {
    final normalized = error.toLowerCase();
    return normalized.contains('401') ||
        normalized.contains('403') ||
        normalized.contains('500') ||
        normalized.contains('502') ||
        normalized.contains('503') ||
        normalized.contains('504') ||
        normalized.contains('timed out') ||
        normalized.contains('timeout') ||
        normalized.contains('socketexception') ||
        normalized.contains('connection closed') ||
        normalized.contains('connection reset') ||
        normalized.contains('temporarily unavailable') ||
        normalized.contains('unavailable') ||
        normalized.contains('invalid api key') ||
        normalized.contains('api key not valid');
  }

  Future<void> _loadConfiguration() async {
    final assetConfig = await _readAssetConfig();
    final preferredRaw = _firstNonEmpty(
      _preferredProviderEnv,
      assetConfig?['NUBI_AI_PRIMARY']?.toString(),
      assetConfig?['primary']?.toString(),
    );

    final groqKeys = _parseKeys(
      _groqKeysEnv,
      fallback: assetConfig?['NUBI_GROQ_KEYS'] ?? assetConfig?['groqKeys'],
    );
    final geminiKeys = _parseKeys(
      _geminiKeysEnv,
      fallback:
          assetConfig?['NUBI_GEMINI_KEYS'] ?? assetConfig?['geminiKeys'],
    );

    _providers = _buildProviders(
      groqKeys: groqKeys,
      geminiKeys: geminiKeys,
      preferredProviderRaw: preferredRaw,
    );
    _currentProviderIndex = _initialProviderIndex(
      providers: _providers,
      preferredProviderRaw: preferredRaw,
    );
    _isInitialized = true;
    debugPrint(
      '[HybridAI] Loaded ${_providers.length} provider(s) from configuration.',
    );
  }

  Future<Map<String, dynamic>?> _readAssetConfig() async {
    try {
      final raw = await rootBundle.loadString(_assetConfigPath);
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Optional local asset config; ignore when not present.
    }
    return null;
  }

  List<_AiProvider> _buildProviders({
    required List<String> groqKeys,
    required List<String> geminiKeys,
    required String preferredProviderRaw,
  }) {
    final providers = <_AiProvider>[];

    if (groqKeys.isNotEmpty) {
      providers.add(
        _AiProvider(
          type: _AiProviderType.groq,
          label: 'Groq',
          apiKeys: groqKeys,
          textModel: 'qwen/qwen3.8-27b',
          visionModel: 'qwen/qwen3.8-27b',
          baseUrl: 'https://api.groq.com/openai/v1/chat/completions',
        ),
      );
    }

    if (geminiKeys.isNotEmpty) {
      providers.add(
        _AiProvider(
          type: _AiProviderType.gemini,
          label: 'Gemini',
          apiKeys: geminiKeys,
          textModel: 'gemini-2.0-flash',
          visionModel: 'gemini-2.0-flash',
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta/models',
        ),
      );
    }

    providers.sort((a, b) {
      final preferred = _parseProviderType(preferredProviderRaw);
      if (preferred == null) return 0;
      if (a.type == preferred && b.type != preferred) return -1;
      if (b.type == preferred && a.type != preferred) return 1;
      return 0;
    });

    return List.unmodifiable(providers);
  }

  List<String> _parseKeys(String raw, {Object? fallback}) {
    if (raw.trim().isNotEmpty) {
      return _splitKeys(raw);
    }

    if (fallback is String) {
      return _splitKeys(fallback);
    }

    if (fallback is List) {
      return fallback
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    return const [];
  }

  List<String> _splitKeys(String raw) {
    return raw
        .split(RegExp(r'[\n,;]+'))
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toList(growable: false);
  }

  String _firstNonEmpty(String primary, String? secondary, String? tertiary) {
    if (primary.trim().isNotEmpty) return primary.trim();
    if ((secondary ?? '').trim().isNotEmpty) return secondary!.trim();
    if ((tertiary ?? '').trim().isNotEmpty) return tertiary!.trim();
    return 'groq';
  }

  _AiProviderType? _parseProviderType(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'groq':
        return _AiProviderType.groq;
      case 'gemini':
        return _AiProviderType.gemini;
      default:
        return null;
    }
  }

  int _initialProviderIndex({
    required List<_AiProvider> providers,
    required String preferredProviderRaw,
  }) {
    if (providers.isEmpty) return 0;
    final preferred = _parseProviderType(preferredProviderRaw);
    if (preferred == null) return 0;
    final index = providers.indexWhere((provider) => provider.type == preferred);
    return index >= 0 ? index : 0;
  }
}

enum _AiProviderType {
  groq,
  gemini,
}

class _AiProvider {
  _AiProvider({
    required this.type,
    required this.label,
    required this.apiKeys,
    required this.textModel,
    required this.visionModel,
    required this.baseUrl,
  });

  final _AiProviderType type;
  final String label;
  final List<String> apiKeys;
  final String textModel;
  final String visionModel;
  final String baseUrl;

  int currentKeyIndex = 0;

  String get currentKey => apiKeys[currentKeyIndex];

  bool rotateKey() {
    if (apiKeys.length <= 1) {
      return false;
    }
    if (currentKeyIndex < apiKeys.length - 1) {
      currentKeyIndex++;
      debugPrint('[$label] Rotating to key index $currentKeyIndex');
      return true;
    }
    currentKeyIndex = 0;
    return false;
  }
}
