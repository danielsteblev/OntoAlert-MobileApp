import 'package:flutter/material.dart';

import '../../../app/app_session.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/app_models.dart';
import '../../bookmarks/presentation/bookmarks_screen.dart';
import '../../lessons/presentation/lesson_detail_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../search_history/presentation/search_history_screen.dart';
import 'story_viewer_screen.dart';

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
  final Set<int> _viewedStoryIds = <int>{};

  Future<List<LessonSummary>> _loadLessons() => widget.apiClient.fetchLessons();
  Future<List<HintStory>> _loadHints() => widget.apiClient.fetchHints();
  Future<List<LessonSummary>> _loadBookmarks() =>
      widget.apiClient.fetchBookmarks();

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
            await widget.apiClient
                .toggleBookmark(lesson.id, bookmarked: currentlyBookmarked);
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

  Future<void> _openStory(HintStory story) async {
    setState(() => _viewedStoryIds.add(story.id));
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(story: story),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.session.profile;
    final tabs = <Widget>[
      _HomeDashboard(
        lessonsFuture: _loadLessons(),
        hintsFuture: _loadHints(),
        onOpenLesson: _openLesson,
        onOpenSearch: _openSearch,
        onOpenSearchHistory: _openSearchHistory,
        onOpenStory: _openStory,
        viewedStoryIds: _viewedStoryIds,
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
          NavigationDestination(
              icon: Icon(Icons.home_rounded), label: 'Главная'),
          NavigationDestination(
              icon: Icon(Icons.favorite_rounded), label: 'Избранное'),
          NavigationDestination(
              icon: Icon(Icons.person_rounded), label: 'Профиль'),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({
    required this.lessonsFuture,
    required this.hintsFuture,
    required this.onOpenLesson,
    required this.onOpenSearch,
    required this.onOpenSearchHistory,
    required this.onOpenStory,
    required this.viewedStoryIds,
  });

  final Future<List<LessonSummary>> lessonsFuture;
  final Future<List<HintStory>> hintsFuture;
  final Future<void> Function(LessonSummary lesson) onOpenLesson;
  final Future<void> Function() onOpenSearch;
  final Future<void> Function() onOpenSearchHistory;
  final Future<void> Function(HintStory story) onOpenStory;
  final Set<int> viewedStoryIds;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        FutureBuilder<List<HintStory>>(
          future: hintsFuture,
          builder: (context, snapshot) {
            final hints = snapshot.data ?? const <HintStory>[];
            return SizedBox(
              height: 126,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: hints.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final story = hints[index];
                  final isViewed = viewedStoryIds.contains(story.id);
                  return _StoryCard(
                    story: story,
                    isViewed: isViewed,
                    onTap: () => onOpenStory(story),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SearchBlock(
            onOpenSearch: onOpenSearch,
            onOpenSearchHistory: onOpenSearchHistory,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SectionContainer(
            title: 'Уроки для вас',
            actionText: 'Все уроки',
            onActionTap: onOpenSearchHistory,
            child: FutureBuilder<List<LessonSummary>>(
              future: lessonsFuture,
              builder: (context, snapshot) {
                final lessons = snapshot.data ?? const <LessonSummary>[];
                if (lessons.isEmpty) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return SizedBox(
                  height: 232,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: lessons.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => _LessonCard(
                      lesson: lessons[index],
                      onTap: () => onOpenLesson(lessons[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _DocumentsSection(),
        ),
      ],
    );
  }
}

class _SearchBlock extends StatelessWidget {
  const _SearchBlock({
    required this.onOpenSearch,
    required this.onOpenSearchHistory,
  });

  final Future<void> Function() onOpenSearch;
  final Future<void> Function() onOpenSearchHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Что хотите сегодня узнать?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              onOpenSearch();
            },
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF343434),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded,
                      color: Color(0xFFF8F7F5), size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Украли телефон, разбили окно...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFF8F7F5),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                onOpenSearchHistory();
              },
              child: const Text('История запросов'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({
    required this.title,
    required this.actionText,
    required this.onActionTap,
    required this.child,
  });

  final String title;
  final String actionText;
  final Future<void> Function() onActionTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  onActionTap();
                },
                child: const Row(
                  children: [
                    Text(
                      'Все уроки',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E83FF),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: Color(0xFF2E83FF)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.isViewed,
    required this.onTap,
  });

  final HintStory story;
  final bool isViewed;
  final VoidCallback onTap;

  String get _previewImageUrl {
    if (story.coverImageUrl.isNotEmpty) {
      return story.coverImageUrl;
    }
    if (story.slides.isNotEmpty) {
      return story.slides.first.imageUrl;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 91,
        height: 108,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isViewed ? const Color(0xFF343434) : const Color(0xFF1E8BFF),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _CoverImage(
            imageUrl: _previewImageUrl,
            title: '',
            width: 91,
            height: 108,
            borderRadius: 16,
          ),
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.onTap,
  });

  final LessonSummary lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _CoverImage(
                  imageUrl: lesson.imageUrl,
                  title: lesson.title,
                  width: 150,
                  height: 104,
                  borderRadius: 22,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(
                      lesson.isBookmarked
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: const Color(0xFFFF5DAA),
                      size: 18,
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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              lesson.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 14, color: Colors.white70, height: 1.05),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people_alt_outlined,
                    size: 16, color: Colors.white70),
                const SizedBox(width: 4),
                Text('${lesson.learnersCount}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(width: 12),
                const Icon(Icons.star_rounded,
                    size: 18, color: Color(0xFF5DD17B)),
                const SizedBox(width: 2),
                Text(
                  lesson.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Color(0xFF5DD17B), fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${lesson.questionsCount} вопросов',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection();

  static const _documents = <String>[
    'Конституция',
    'Трудовой кодекс',
    'Гражданский кодекс',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Полезные документы',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Смотреть все',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E83FF),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFF2E83FF)),
            ],
          ),
          const SizedBox(height: 16),
          ..._documents.map(
            (document) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        document,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.description_outlined,
                          color: Color(0xFF282828), size: 18),
                    ),
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

class _CoverImage extends StatelessWidget {
  const _CoverImage({
    required this.imageUrl,
    required this.title,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final String imageUrl;
  final String title;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7E48FF), Color(0xFF2490FF), Color(0xFFFF6A00)],
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Align(
        alignment: title.isEmpty ? Alignment.center : Alignment.bottomLeft,
        child: title.isEmpty
            ? const Icon(
                Icons.photo_library_rounded,
                color: Colors.white,
                size: 30,
              )
            : Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
