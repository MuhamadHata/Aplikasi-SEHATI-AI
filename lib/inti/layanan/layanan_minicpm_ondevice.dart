// ==========================================
// BAGIAN: LAYANAN ON-DEVICE AI (SERVICES)
// Layanan MiniCPM-V Vision-Language Model untuk inferensi lokal/on-device
// tanpa kuota, tanpa batasan limit, dan dapat berjalan secara offline.
// ==========================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class MiniCpmVOnDeviceService {
  MiniCpmVOnDeviceService._();
  static final MiniCpmVOnDeviceService instance = MiniCpmVOnDeviceService._();

  static const String _prefEnabledKey = 'use_minicpm_ondevice';
  static const String _prefLocalEndpointKey = 'minicpm_local_endpoint';

  // Default port jika menjalankan background llama.cpp / local server di Android
  static const String defaultLocalEndpoint = 'http://127.0.0.1:8080';

  // URL model MiniCPM-V 2.6 (Quantized GGUF Q4_K_M) dari HuggingFace (OpenBMB)
  static const String modelDownloadUrl =
      'https://huggingface.co/openbmb/MiniCPM-V-2_6-gguf/resolve/main/ggml-model-Q4_K_M.gguf';
  static const String mmprojDownloadUrl =
      'https://huggingface.co/openbmb/MiniCPM-V-2_6-gguf/resolve/main/mmproj-model-f16.gguf';

  bool _isEnabled = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = 'Siap digunakan';
  String _localEndpoint = defaultLocalEndpoint;
  bool _isInitialized = false;

  bool get isEnabled => _isEnabled;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String get statusMessage => _statusMessage;
  String get localEndpoint => _localEndpoint;

  final ValueNotifier<double> downloadProgressNotifier =
      ValueNotifier<double>(0.0);
  final ValueNotifier<String> statusNotifier =
      ValueNotifier<String>('Inisialisasi...');

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_prefEnabledKey) ?? true;
      _localEndpoint =
          prefs.getString(_prefLocalEndpointKey) ?? defaultLocalEndpoint;

      final exists = await checkModelFilesExist();
      if (exists) {
        _statusMessage = 'Model MiniCPM-V On-Device aktif & siap';
      } else {
        _statusMessage = 'Model MiniCPM-V belum diunduh (Cloud Fallback aktif)';
      }
      statusNotifier.value = _statusMessage;
      _isInitialized = true;
    } catch (e) {
      debugPrint('[MiniCPM-V] Init error: $e');
    }
  }

  /// Mengecek apakah file bobot model MiniCPM-V sudah tersimpan di direktori lokal HP
  Future<bool> checkModelFilesExist() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final modelFile = File('${dir.path}/models/minicpm-v-2_6-q4.gguf');
      final mmprojFile = File('${dir.path}/models/mmproj-minicpm-v-2_6.gguf');
      return await modelFile.exists() && await mmprojFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Mendapatkan path direktori penyimpanan model
  Future<String> getModelDirectoryPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${dir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }

  /// Mengaktifkan atau menonaktifkan mode on-device
  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabledKey, value);
    _statusMessage = value
        ? 'MiniCPM-V On-Device diaktifkan'
        : 'MiniCPM-V On-Device dinonaktifkan';
    statusNotifier.value = _statusMessage;
  }

  /// Mengubah endpoint lokal (misal: localhost atau host port)
  Future<void> setLocalEndpoint(String endpoint) async {
    _localEndpoint = endpoint.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLocalEndpointKey, _localEndpoint);
  }

  /// Melakukan inferensi visual langsung di perangkat (On-Device)
  /// Mengirim gambar & prompt ke engine MiniCPM-V
  Future<String?> generateVision({
    required Uint8List imageBytes,
    required String prompt,
    String? systemPrompt,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    if (!_isEnabled) return null;

    await initialize();

    try {
      final base64Image = base64Encode(imageBytes);
      final formattedUrl = 'data:image/jpeg;base64,$base64Image';

      final messages = <Map<String, dynamic>>[];
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt.trim(),
        });
      }

      messages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {'url': formattedUrl}
          },
        ],
      });

      // Panggil endpoint local MiniCPM-V runtime (OpenAI-compatible VLM format)
      final uri = Uri.parse('$_localEndpoint/v1/chat/completions');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'minicpm-v',
              'messages': messages,
              'temperature': 0.3,
              'max_tokens': 1024,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices.first['message']?['content']?.toString();
          if (content != null && content.isNotEmpty) {
            debugPrint('[MiniCPM-V On-Device] Inference success (Local)');
            return content.trim();
          }
        }
      }
    } catch (e) {
      debugPrint('[MiniCPM-V On-Device] Local engine vision check: $e');
      return null;
    }

    return null;
  }

  /// Melakukan inferensi teks On-Device tanpa batas kuota
  Future<String?> generateText(
    String prompt, {
    String? systemPrompt,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!_isEnabled) return null;
    await initialize();

    try {
      final messages = <Map<String, dynamic>>[];
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
        messages.add({'role': 'system', 'content': systemPrompt.trim()});
      }
      messages.add({'role': 'user', 'content': prompt});

      final uri = Uri.parse('$_localEndpoint/v1/chat/completions');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'minicpm-v',
              'messages': messages,
              'temperature': 0.7,
              'max_tokens': 1024,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices.first['message']?['content']?.toString();
          if (content != null && content.isNotEmpty) {
            debugPrint('[MiniCPM-V On-Device] Text inference success (Local)');
            return content.trim();
          }
        }
      }
    } catch (e) {
      debugPrint('[MiniCPM-V On-Device] Local text engine check: $e');
      return null;
    }
    return null;
  }

  /// Melakukan percakapan multi-turn Chatbot On-Device tanpa batas kuota
  Future<String?> generateChat(
    List<Map<String, String>> messages, {
    String? systemPrompt,
    Duration timeout = const Duration(seconds: 40),
  }) async {
    if (!_isEnabled) return null;
    await initialize();

    try {
      final requestMessages = <Map<String, dynamic>>[];
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
        requestMessages.add({'role': 'system', 'content': systemPrompt.trim()});
      }
      for (final m in messages) {
        final r = m['role']?.trim();
        final c = m['content']?.trim();
        if (r != null && r.isNotEmpty && c != null && c.isNotEmpty) {
          requestMessages.add({'role': r, 'content': c});
        }
      }

      if (requestMessages.isEmpty) return null;

      final uri = Uri.parse('$_localEndpoint/v1/chat/completions');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'minicpm-v',
              'messages': requestMessages,
              'temperature': 0.5,
              'max_tokens': 1024,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices.first['message']?['content']?.toString();
          if (content != null && content.isNotEmpty) {
            debugPrint('[MiniCPM-V On-Device] Chat inference success (Local)');
            return content.trim();
          }
        }
      }
    } catch (e) {
      debugPrint('[MiniCPM-V On-Device] Local chat engine check: $e');
      return null;
    }
    return null;
  }

  /// Download model MiniCPM-V ke penyimpanan lokal perangkat
  Future<bool> downloadModel({
    Function(double progress, String status)? onProgress,
  }) async {
    if (_isDownloading) return false;
    _isDownloading = true;
    _downloadProgress = 0.0;
    _statusMessage = 'Memulai pengunduhan model MiniCPM-V...';
    statusNotifier.value = _statusMessage;
    downloadProgressNotifier.value = 0.0;

    try {
      final modelDir = await getModelDirectoryPath();
      final modelPath = '$modelDir/minicpm-v-2_6-q4.gguf';
      final mmprojPath = '$modelDir/mmproj-minicpm-v-2_6.gguf';

      // 1. Download mmproj
      _statusMessage = 'Mengunduh komponen Visual Projector (1/2)...';
      statusNotifier.value = _statusMessage;
      onProgress?.call(0.1, _statusMessage);

      final mmprojFile = File(mmprojPath);
      if (!await mmprojFile.exists()) {
        final client = http.Client();
        final req = http.Request('GET', Uri.parse(mmprojDownloadUrl));
        final res = await client.send(req);
        final sink = mmprojFile.openWrite();
        await res.stream.pipe(sink);
        await sink.close();
      }

      // 2. Download language backbone
      _statusMessage = 'Mengunduh model bobot MiniCPM-V 2.6 (2/2)...';
      statusNotifier.value = _statusMessage;
      onProgress?.call(0.3, _statusMessage);

      final modelFile = File(modelPath);
      if (!await modelFile.exists()) {
        final client = http.Client();
        final req = http.Request('GET', Uri.parse(modelDownloadUrl));
        final res = await client.send(req);
        final totalLength = res.contentLength ?? 1800000000;
        int received = 0;

        final sink = modelFile.openWrite();
        await for (final chunk in res.stream) {
          sink.add(chunk);
          received += chunk.length;
          final p = 0.3 + (received / totalLength) * 0.7;
          _downloadProgress = p.clamp(0.0, 1.0);
          downloadProgressNotifier.value = _downloadProgress;
          onProgress?.call(_downloadProgress,
              'Mengunduh: ${(_downloadProgress * 100).toStringAsFixed(1)}%');
        }
        await sink.close();
      }

      _downloadProgress = 1.0;
      downloadProgressNotifier.value = 1.0;
      _statusMessage = 'Model MiniCPM-V siap digunakan 100% On-Device!';
      statusNotifier.value = _statusMessage;
      onProgress?.call(1.0, _statusMessage);
      _isDownloading = false;
      return true;
    } catch (e) {
      _statusMessage = 'Gagal mengunduh model: $e';
      statusNotifier.value = _statusMessage;
      _isDownloading = false;
      debugPrint('[MiniCPM-V] Download error: $e');
      return false;
    }
  }

  /// Menghapus file model lokal untuk menghemat memori
  Future<void> deleteModelFiles() async {
    try {
      final modelDir = await getModelDirectoryPath();
      final dir = Directory(modelDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      _statusMessage = 'Model lokal dihapus';
      statusNotifier.value = _statusMessage;
    } catch (e) {
      debugPrint('[MiniCPM-V] Delete error: $e');
    }
  }
}
