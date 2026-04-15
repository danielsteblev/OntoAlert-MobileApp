import 'package:flutter/material.dart';

import '../../../core/models/app_models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.onSearch,
    required this.onOpenLesson,
  });

  final Future<SearchResult> Function(String query) onSearch;
  final Future<void> Function(LessonSummary lesson) onOpenLesson;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryController = TextEditingController();
  SearchResult? _result;
  bool _isLoading = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final result = await widget.onSearch(_queryController.text.trim());
      if (mounted) {
        setState(() => _result = result);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Семантический поиск')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _queryController,
            decoration: const InputDecoration(
              hintText: 'Например: шум во дворе ночью или мелкое хулиганство',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: Text(_isLoading ? 'Ищем...' : 'Найти'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Статья ${_result!.matchedArticle}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_result!.explanation),
                    const SizedBox(height: 8),
                    Text('Уверенность: ${(_result!.confidence * 100).toStringAsFixed(0)}%'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Подходящие уроки', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._result!.lessons.map(
              (lesson) => Card(
                child: ListTile(
                  title: Text(lesson.title),
                  subtitle: Text('${lesson.topic.articleCode} • ${lesson.description}'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  onTap: () => widget.onOpenLesson(lesson),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
