import 'package:flutter/material.dart';

import '../../../core/models/app_models.dart';

class SearchChatEntry {
  const SearchChatEntry({
    required this.query,
    required this.result,
  });

  final String query;
  final SearchResult result;
}

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
  static const _quickPrompts = <String>[
    'Украли телефон',
    'Разбили окно',
    'Ударили человека',
    'Шумят ночью',
  ];

  final _queryController = TextEditingController();
  final List<SearchChatEntry> _entries = <SearchChatEntry>[];
  bool _isLoading = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _submit([String? presetQuery]) async {
    final query = (presetQuery ?? _queryController.text).trim();
    if (query.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await widget.onSearch(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _entries.insert(
          0,
          SearchChatEntry(
            query: query,
            result: result,
          ),
        );
        _queryController.clear();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      child: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height - 32,
              ),
              margin: EdgeInsets.fromLTRB(
                10,
                22,
                10,
                bottomInset > 0 ? 8 : 22,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            'Семантический\nпоиск',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 30),
                        ),
                      ],
                    ),
                    Expanded(
                      child: _entries.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 8),
                              Image.asset(
                                'assets/images/search_mascot.png',
                                height: 250,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Здесь пока ничего нет,\nможет начнём?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                height: 52,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _quickPrompts.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (context, index) {
                                    final prompt = _quickPrompts[index];
                                    return InkWell(
                                      onTap: () => _submit(prompt),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E8BFF),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          prompt,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            itemCount: _entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final entry = _entries[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E8BFF),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Text(entry.query),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF282828),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Статья ${entry.result.matchedArticle}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(entry.result.explanation),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Уверенность: ${(entry.result.confidence * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        if (entry.result.lessons.isNotEmpty) ...[
                                          const SizedBox(height: 14),
                                          const Text(
                                            'Подходящие уроки',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          ...entry.result.lessons.map(
                                            (lesson) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: InkWell(
                                                onTap: () async {
                                                  Navigator.of(context).pop();
                                                  await widget.onOpenLesson(
                                                    lesson,
                                                  );
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF343434,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      16,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              lesson.title,
                                                              style:
                                                                  const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              '${lesson.topic.articleCode} • ${lesson.questionsCount} вопросов',
                                                              style:
                                                                  const TextStyle(
                                                                color: Colors
                                                                    .white70,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons
                                                            .arrow_forward_ios_rounded,
                                                        size: 16,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF343434),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: TextField(
                              controller: _queryController,
                              decoration: const InputDecoration(
                                hintText: 'Введите ваш вопрос...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                              ),
                              onSubmitted: (_) => _submit(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: _isLoading ? null : _submit,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 64,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E8BFF),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              _isLoading
                                  ? Icons.hourglass_top_rounded
                                  : Icons.send_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
