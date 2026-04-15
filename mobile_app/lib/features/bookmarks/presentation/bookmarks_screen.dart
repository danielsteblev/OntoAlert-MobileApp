import 'package:flutter/material.dart';

import '../../../core/models/app_models.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({
    super.key,
    required this.bookmarks,
    required this.onOpenLesson,
  });

  final List<LessonSummary> bookmarks;
  final Future<void> Function(LessonSummary lesson) onOpenLesson;

  @override
  Widget build(BuildContext context) {
    if (bookmarks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Пока нет сохранённых уроков. Добавьте тему в избранное из каталога или поиска.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: bookmarks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final lesson = bookmarks[index];
        return Card(
          child: ListTile(
            title: Text(lesson.title),
            subtitle: Text('Статья ${lesson.topic.articleCode} • ${lesson.estimatedMinutes} мин'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            onTap: () => onOpenLesson(lesson),
          ),
        );
      },
    );
  }
}
