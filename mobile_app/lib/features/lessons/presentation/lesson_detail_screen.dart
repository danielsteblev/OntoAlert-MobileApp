import 'package:flutter/material.dart';

import '../../../core/models/app_models.dart';

class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.onToggleBookmark,
  });

  final LessonDetail lesson;
  final Future<void> Function(bool currentlyBookmarked) onToggleBookmark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        actions: [
          IconButton(
            onPressed: () => onToggleBookmark(lesson.isBookmarked),
            icon: Icon(lesson.isBookmarked ? Icons.favorite : Icons.favorite_border),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Статья ${lesson.topic.articleCode}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blueAccent),
          ),
          const SizedBox(height: 8),
          Text(lesson.description, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Краткая теория', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(lesson.theory),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Фрагмент статьи', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(lesson.articleExcerpt),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Мини-тест', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...lesson.questions.map(
            (question) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(question.prompt, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ...question.options.map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              option.isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: option.isCorrect ? Colors.green : Colors.white54,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(option.text)),
                          ],
                        ),
                      ),
                    ),
                    if (question.explanation.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(question.explanation, style: const TextStyle(color: Colors.white70)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
