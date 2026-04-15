import 'package:flutter/material.dart';

import '../../../core/models/app_models.dart';

class LessonCatalogScreen extends StatelessWidget {
  const LessonCatalogScreen({
    super.key,
    required this.lessons,
    required this.onOpenLesson,
    required this.onToggleBookmark,
  });

  final List<LessonSummary> lessons;
  final Future<void> Function(LessonSummary lesson) onOpenLesson;
  final Future<void> Function(LessonSummary lesson) onToggleBookmark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Все уроки')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.64,
        ),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          final lesson = lessons[index];
          return InkWell(
            onTap: () => onOpenLesson(lesson),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      _CatalogImage(
                        imageUrl: lesson.imageUrl,
                        height: 120,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => onToggleBookmark(lesson),
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: Icon(
                                lesson.isBookmarked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18,
                                color: const Color(0xFFFF5DAA),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${lesson.questionsCount} вопросов',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_alt_outlined,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${lesson.learnersCount}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: Color(0xFF5DD17B),
                      ),
                      Text(
                        lesson.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFF5DD17B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CatalogImage extends StatelessWidget {
  const _CatalogImage({
    required this.imageUrl,
    required this.height,
  });

  final String imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          imageUrl,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(borderRadius),
        ),
      );
    }
    return _placeholder(borderRadius);
  }

  Widget _placeholder(BorderRadius borderRadius) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7E48FF), Color(0xFF2490FF), Color(0xFFFF6A00)],
        ),
      ),
      child: const Icon(
        Icons.photo_library_rounded,
        color: Colors.white,
        size: 34,
      ),
    );
  }
}
