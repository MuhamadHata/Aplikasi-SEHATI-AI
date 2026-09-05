import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExerciseGifWidget extends StatelessWidget {
  final String exerciseName;
  final String emoji;
  final String? mediaUrl;

  const ExerciseGifWidget({
    super.key,
    required this.exerciseName,
    required this.emoji,
    this.mediaUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaUrl == null || mediaUrl!.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _buildEmojiFallback(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: mediaUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 200,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => Container(
          width: double.infinity,
          height: 200,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: _buildEmojiFallback(),
        ),
      ),
    );
  }

  Widget _buildEmojiFallback() {
    return Center(
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 83),
      ),
    );
  }
}
