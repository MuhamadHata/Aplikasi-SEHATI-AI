// ==========================================
// BAGIAN: LAYANAN (SERVICES)
// Berisi logika bisnis, pemanggilan API, dan fungsi inti aplikasi.
// ==========================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/model.dart';

class NewsApiService {
  static const String _baseUrl = 'https://newsapi.org/v2';
  static const String _apiKey =
      '18c346c042b54deab2076b67f06751e2'; // USER PROVIDED

  /// Fetch top health headlines from Indonesia
  static Future<List<Article>> fetchTopHealthNews() async {
    try {
      final url = Uri.parse(
          '$_baseUrl/top-headlines?country=id&category=health&apiKey=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> articlesJson = data['articles'] ?? [];

        final List<Article> articles = [];
        int idCounter = 1;

        for (var json in articlesJson) {
          // Skip articles that don't have a title or URL
          if (json['title'] == null || json['url'] == null) continue;

          final String title = json['title'] ?? 'Berita Kesehatan';
          final String sourceName = json['source']?['name'] ?? 'NewsAPI';
          final String? imageUrl = json['urlToImage'];
          final String content = json['description'] ?? title;
          final String url = json['url'];

          // Remove common " - SourceName" suffix if present in NewsAPI titles
          final String cleanTitle = title.split(' - ').first;

          articles.add(Article(
            id: idCounter++,
            title: cleanTitle.length > 60
                ? '${cleanTitle.substring(0, 57)}...'
                : cleanTitle,
            subtitle: sourceName,
            emoji: '📰',
            readTime:
                '3 min', // Estimated or hardcoded since API doesn't provide
            colorHex: 0xFF2196F3,
            content: content,
            imageUrl: imageUrl,
            url: url,
          ));

          if (articles.length >= 5) break;
        }

        return articles.isNotEmpty ? articles : _fallbackArticles();
      } else {
        print('NewsAPI Error Status: ${response.statusCode}');
        return _fallbackArticles();
      }
    } catch (e) {
      print('NewsAPI Fetch Error: $e');
      return _fallbackArticles();
    }
  }

  static List<Article> _fallbackArticles() {
    return [
      const Article(
        id: 1,
        title: 'Mengenal Gizi Seimbang',
        subtitle: 'SEHATI-AI Health',
        emoji: '🥗',
        readTime: '3 menit',
        colorHex: 0xFF43E97B,
        content: 'Gizi seimbang penting bagi kesehatan...',
        url: 'https://www.halodoc.com/artikel',
      ),
    ];
  }
}
