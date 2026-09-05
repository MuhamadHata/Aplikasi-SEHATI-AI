// ==========================================
// BAGIAN: LAYANAN (SERVICES)
// Berisi logika bisnis, pemanggilan API, dan fungsi inti aplikasi.
// ==========================================

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import '../model/model.dart';

class KemkesService {
  static const String _baseUrl = 'https://kemkes.go.id';

  Future<List<Article>> fetchArticles() async {
    try {
      final response =
          await http.get(Uri.parse('$_baseUrl/id/category/artikel-kesehatan'));

      if (response.statusCode == 200) {
        final document = parse(response.body);
        final List<Article> articles = [];

        // Kemkes uses card-like elements, usually <a> tags wrapping the article info
        // We will look for <a> tags that look like they belong to articles.
        // E.g. .card-post, .article-item, etc.
        // A generic approach: find links with images inside them
        final elements = document.querySelectorAll('a');

        int idCounter = 100;
        final Set<String> seenUrls = {};

        for (var el in elements) {
          final href = el.attributes['href'];
          if (href == null || !href.contains('/id/')) continue;

          final imgEl = el.querySelector('img');
          if (imgEl == null) continue;

          final imgSrc = imgEl.attributes['src'];
          if (imgSrc == null || imgSrc.isEmpty) continue;

          // Fallbacks for finding title
          String title = imgEl.attributes['alt'] ?? '';
          if (title.isEmpty || title.length < 10) {
            title = el.text.trim().replaceAll(RegExp(r'\s+'), ' ');
          }
          if (title.isEmpty) continue;

          // Let's not include things that aren't articles
          if (href.contains('/category/') || href.contains('/media/')) continue;

          final fullUrl = href.startsWith('http') ? href : '$_baseUrl$href';

          if (seenUrls.contains(fullUrl)) continue;
          seenUrls.add(fullUrl);

          String fullImgSrc = imgSrc;
          if (!fullImgSrc.startsWith('http')) {
            fullImgSrc = fullImgSrc.startsWith('/')
                ? '$_baseUrl$fullImgSrc'
                : '$_baseUrl/$fullImgSrc';
          }

          // Try to find date
          String date = 'Baru-baru ini';
          final txt = el.text;
          final dateRegex = RegExp(r'(\d{1,2}\s+[a-zA-Z]+\s+\d{4})');
          final match = dateRegex.firstMatch(txt);
          if (match != null) {
            date = match.group(1) ?? date;
          }

          articles.add(Article(
            id: idCounter++,
            title: title.length > 60 ? '${title.substring(0, 57)}...' : title,
            subtitle: date,
            emoji: '📰',
            readTime: '3 min',
            colorHex: 0xFF2196F3,
            content: title,
            imageUrl: fullImgSrc,
            url: fullUrl,
          ));

          if (articles.length >= 5) break; // Limit to 5 for home screen
        }

        return articles.isNotEmpty ? articles : _fallbackArticles();
      }
    } catch (e) {
      print('Kemkes Fetch Error: $e');
    }
    return _fallbackArticles();
  }

  List<Article> _fallbackArticles() {
    return [
      const Article(
        id: 1,
        title: 'Mengenal Gizi Seimbang',
        subtitle: 'Kemkes',
        emoji: '🥗',
        readTime: '3 menit',
        colorHex: 0xFF43E97B,
        content: 'Gizi seimbang tidak berarti diet ketat...',
        url: 'https://kemkes.go.id/',
      ),
    ];
  }
}
