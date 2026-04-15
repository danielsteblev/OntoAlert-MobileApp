import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/app_models.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.story,
  });

  final HintStory story;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  static const _slideDuration = Duration(seconds: 4);

  late final PageController _pageController = PageController();
  Timer? _timer;
  int _currentIndex = 0;
  bool _isPaused = false;

  List<StorySlide> get _slides => widget.story.slides.isNotEmpty
      ? widget.story.slides
      : [
          StorySlide(
            id: widget.story.id,
            imageUrl: widget.story.coverImageUrl,
            sortOrder: 0,
          ),
        ];

  @override
  void initState() {
    super.initState();
    _scheduleNextSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _scheduleNextSlide() {
    _timer?.cancel();
    if (_isPaused || _slides.isEmpty) {
      return;
    }
    _timer = Timer(_slideDuration, _goNext);
  }

  void _goNext() {
    if (_currentIndex >= _slides.length - 1) {
      Navigator.of(context).maybePop();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  void _goPrevious() {
    if (_currentIndex == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  void _pauseStory() {
    setState(() => _isPaused = true);
    _timer?.cancel();
  }

  void _resumeStory() {
    setState(() => _isPaused = false);
    _scheduleNextSlide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onLongPressStart: (_) => _pauseStory(),
              onLongPressEnd: (_) => _resumeStory(),
              onVerticalDragEnd: (_) => Navigator.of(context).maybePop(),
              onTapUp: (details) {
                final width = MediaQuery.sizeOf(context).width;
                if (details.localPosition.dx < width * 0.35) {
                  _goPrevious();
                } else {
                  _goNext();
                }
              },
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  _scheduleNextSlide();
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _StorySlideView(
                    imageUrl: slide.imageUrl,
                    fallbackLabel: widget.story.title,
                  );
                },
              ),
            ),
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Row(
                children: List.generate(
                  _slides.length,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(
                          right: index == _slides.length - 1 ? 0 : 4),
                      decoration: BoxDecoration(
                        color: index <= _currentIndex
                            ? Colors.white
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorySlideView extends StatelessWidget {
  const _StorySlideView({
    required this.imageUrl,
    required this.fallbackLabel,
  });

  final String imageUrl;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F6BFF), Color(0xFF723CFF), Color(0xFFFF7B23)],
        ),
      ),
      child: Center(
        child: fallbackLabel.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  fallbackLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            : const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 86,
              ),
      ),
    );
  }
}
