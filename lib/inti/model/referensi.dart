class ReferenceItem {
  final String code;
  final String title;
  final String publisher;
  final String? published; // ISO date string or null
  final String url;
  final String quote; // short excerpt or summary
  final List<String> tags;

  const ReferenceItem({
    required this.code,
    required this.title,
    required this.publisher,
    required this.published,
    required this.url,
    required this.quote,
    required this.tags,
  });

  factory ReferenceItem.fromJson(Map<String, dynamic> json) {
    return ReferenceItem(
      code: (json['code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      publisher: (json['publisher'] ?? '').toString(),
      published: json['published']?.toString(),
      url: (json['url'] ?? '').toString(),
      quote: (json['quote'] ?? '').toString(),
      tags: ((json['tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
