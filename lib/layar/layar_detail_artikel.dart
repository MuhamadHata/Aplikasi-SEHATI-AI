import 'package:flutter/material.dart';
import '../../inti/model/model.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final color = Color(article.colorHex);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Elegant Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new,
                      color: Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.white,
                      size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'article_image_${article.id}',
                child: article.imageUrl != null && article.imageUrl!.isNotEmpty
                    ? Image.network(
                        article.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildPlaceholderHeader(color),
                      )
                    : _buildPlaceholderHeader(color),
              ),
            ),
          ),

          // Article Content
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0.0, -30.0, 0.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Info Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          article.subtitle.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 16,
                              color: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.color),
                          const SizedBox(width: 4),
                          Text(
                            article.readTime,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                              fontFamily: 'Poppins',
                            ) ??
                        const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          height: 1.3,
                          fontFamily: 'Poppins',
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Divider(
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: 0.5),
                      thickness: 1.5),
                  const SizedBox(height: 24),

                  // Main Content (Body)
                  Text(
                    article.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.8,
                              letterSpacing: 0.2,
                            ) ??
                        const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          height: 1.8,
                          letterSpacing: 0.2,
                        ),
                    textAlign: TextAlign.start,
                  ),

                  const SizedBox(height: 40),

                  // Footer or author tag
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.2),
                          radius: 24,
                          child: Text(
                            'N',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SEHATI-AI Health Writer',
                              style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ) ??
                                  const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 15,
                                  ),
                            ),
                            Text(
                              'Kesehatan & Kebugaran',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderHeader(Color color) {
    return Container(
      color: color.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          article.emoji,
          style: const TextStyle(fontSize: 100),
        ),
      ),
    );
  }
}
