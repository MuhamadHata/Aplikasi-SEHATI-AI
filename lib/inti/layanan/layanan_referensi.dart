import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../model/referensi.dart';

class ReferenceService {
  ReferenceService._();
  static final ReferenceService instance = ReferenceService._();

  bool _loaded = false;
  final List<ReferenceItem> _items = [];

  Future<void> _load() async {
    if (_loaded) return;
    final raw = await rootBundle
        .loadString('ai_workspace/dataset/references_health.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = (decoded['items'] as List?) ?? const [];
    _items
      ..clear()
      ..addAll(list
          .whereType<Map<String, dynamic>>()
          .map((e) => ReferenceItem.fromJson(e)));
    _loaded = true;
  }

  Future<List<ReferenceItem>> getAll() async {
    await _load();
    return List<ReferenceItem>.unmodifiable(_items);
  }

  Future<List<ReferenceItem>> getByTags(List<String> tags) async {
    await _load();
    final wanted = tags.map((t) => t.toLowerCase()).toSet();
    if (wanted.isEmpty) return List<ReferenceItem>.unmodifiable(_items);
    final filtered = _items.where((it) {
      final t = it.tags.map((e) => e.toLowerCase()).toSet();
      return t.intersection(wanted).isNotEmpty;
    }).toList();
    return List<ReferenceItem>.unmodifiable(filtered);
  }

  Future<List<ReferenceItem>> getByCodes(List<String> codes) async {
    await _load();
    final wanted =
        codes.map((c) => c.trim()).where((c) => c.isNotEmpty).toSet();
    if (wanted.isEmpty) return const [];
    final filtered = _items.where((it) => wanted.contains(it.code)).toList();
    return List<ReferenceItem>.unmodifiable(filtered);
  }
}
