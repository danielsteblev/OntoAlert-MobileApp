import 'package:flutter/material.dart';

import '../../../core/models/app_models.dart';

class SearchHistoryScreen extends StatelessWidget {
  const SearchHistoryScreen({super.key, required this.history});

  final List<SearchHistoryItem> history;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История запросов')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = history[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(item.queryText),
              subtitle: Text('Статья ${item.matchedArticle}'),
            ),
          );
        },
      ),
    );
  }
}
