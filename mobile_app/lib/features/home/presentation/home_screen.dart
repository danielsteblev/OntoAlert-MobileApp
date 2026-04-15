import 'package:flutter/material.dart';

import '../../../app/app_session.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/app_models.dart';
import '../../bookmarks/presentation/bookmarks_screen.dart';
import '../../lessons/presentation/lesson_detail_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../search_history/presentation/search_history_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.session,
    required this.apiClient,
  });

  final AppSession session;
  final ApiClient apiClient;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  Future<List<LessonSummary>> _loadLessons() => widget.apiClient.fetchLessons();
  Future<List<HintStory>> _loadHints() => widget.apiClient.fetchHints();
  Future<List<RecommendationItem>> _loadRecommendations() => widget.apiClient.fetchRecommendations();
  Future<List<LessonSummary>> _loadBookmarks() => widget.apiClient.fetchBookmarks();

  Future<void> _openLesson(LessonSummary lesson) async {
    final detail = await widget.apiClient.fetchLessonDetail(lesson.id);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonDetailScreen(
          lesson: detail,
          onToggleBookmark: (currentlyBookmarked) async {
            await widget.apiClient.toggleBookmark(lesson.id, bookmarked: currentlyBookmarked);
            if (mounted) {
              Navigator.of(context).pop();
              setState(() {});
            }
          },
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openSearch() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          onSearch: widget.apiClient.semanticSearch,
          onOpenLesson: _openLesson,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openSearchHistory() async {
    final history = await widget.apiClient.fetchSearchHistory();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SearchHistoryScreen(history: history)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.session.profile;
    final tabs = <Widget>[
      _HomeDashboard(
        profile: profile,
        lessonsFuture: _loadLessons(),
        hintsFuture: _loadHints(),
        recommendationsFuture: _loadRecommendations(),
        onOpenLesson: _openLesson,
        onOpenSearch: _openSearch,
        onOpenSearchHistory: _openSearchHistory,
      ),
      FutureBuilder<List<LessonSummary>>(
        future: _loadBookmarks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return BookmarksScreen(
            bookmarks: snapshot.data!,
            onOpenLesson: _openLesson,
          );
        },
      ),
      if (profile != null)
        ProfileScreen(
          profile: profile,
          onSave: ({
            required fullName,
            required email,
            required university,
            required bio,
          }) async {
            await widget.session.updateProfile(
              fullName: fullName,
              email: email,
              university: university,
              bio: bio,
            );
            setState(() {});
          },
          onLogout: widget.session.logout,
        )
      else
        const Center(child: CircularProgressIndicator()),
    ];

    return Scaffold(
      body: SafeArea(child: tabs[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Главная'),
          NavigationDestination(icon: Icon(Icons.favorite_rounded), label: 'Избранное'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Профиль'),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({
    required this.profile,
    required this.lessonsFuture,
    required this.hintsFuture,
    required this.recommendationsFuture,
    required this.onOpenLesson,
    required this.onOpenSearch,
    required this.onOpenSearchHistory,
  });

  final UserProfile? profile;
  final Future<List<LessonSummary>> lessonsFuture;
  final Future<List<HintStory>> hintsFuture;
  final Future<List<RecommendationItem>> recommendationsFuture;
  final Future<void> Function(LessonSummary lesson) onOpenLesson;
  final Future<void> Function() onOpenSearch;
  final Future<void> Function() onOpenSearchHistory;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Здравствуйте, ${profile?.fullName.isNotEmpty == true ? profile!.fullName : profile?.username ?? "студент"}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Что хотите сегодня узнать?'),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onOpenSearch,
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 12),
                  Expanded(child: Text('Украли телефон, шум во дворе, мелкое хулиганство...')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onOpenSearchHistory,
            child: const Text('Открыть историю запросов'),
          ),
          const SizedBox(height: 20),
          const Text('Актуальные подсказки', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          FutureBuilder<List<HintStory>>(
            future: hintsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final hint = snapshot.data![index];
                    return Container(
                      width: 260,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7A3CFF), Color(0xFF1C7DFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hint.highlightText, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(hint.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(hint.subtitle),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Рекомендуемые уроки', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          FutureBuilder<List<RecommendationItem>>(
            future: recommendationsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: snapshot.data!
                    .map(
                      (item) => Card(
                        child: ListTile(
                          title: Text(item.lesson.title),
                          subtitle: Text(item.reason),
                          trailing: Text(item.lesson.topic.articleCode),
                          onTap: () => onOpenLesson(item.lesson),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Уроки для вас', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          FutureBuilder<List<LessonSummary>>(
            future: lessonsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                children: snapshot.data!
                    .map(
                      (lesson) => Card(
                        child: ListTile(
                          title: Text(lesson.title),
                          subtitle: Text('${lesson.topic.articleCode} • ${lesson.description}'),
                          trailing: Text('${lesson.estimatedMinutes} мин'),
                          onTap: () => onOpenLesson(lesson),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
