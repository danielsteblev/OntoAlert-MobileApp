import 'package:flutter/material.dart';

import '../../../core/models/app_models.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.onToggleBookmark,
    required this.onSubmitCompletion,
  });

  final LessonDetail lesson;
  final Future<void> Function(bool currentlyBookmarked) onToggleBookmark;
  final Future<LessonDetail> Function({
    required int scorePercent,
    required int rating,
  }) onSubmitCompletion;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  late LessonDetail _lesson = widget.lesson;
  int? _selectedOptionIndex;
  bool _showAnswerState = false;
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  bool _quizStarted = false;
  bool _quizCompleted = false;
  int _selectedRating = 5;
  bool _isSubmittingCompletion = false;
  bool _hasSubmittedCompletion = false;

  LessonQuestion get _currentQuestion =>
      _lesson.questions[_currentQuestionIndex];

  void _startQuiz() {
    setState(() {
      _quizStarted = true;
      _quizCompleted = false;
      _currentQuestionIndex = 0;
      _selectedOptionIndex = null;
      _correctAnswers = 0;
      _showAnswerState = false;
      _selectedRating = 5;
      _hasSubmittedCompletion = false;
    });
  }

  void _selectOption(int index) {
    if (_showAnswerState) {
      return;
    }
    setState(() => _selectedOptionIndex = index);
  }

  void _checkAnswer() {
    if (_selectedOptionIndex == null) {
      return;
    }
    final option = _currentQuestion.options[_selectedOptionIndex!];
    if (option.isCorrect) {
      _correctAnswers += 1;
    }
    setState(() => _showAnswerState = true);
  }

  void _goNext() {
    if (_currentQuestionIndex >= _lesson.questions.length - 1) {
      setState(() => _quizCompleted = true);
      return;
    }
    setState(() {
      _currentQuestionIndex += 1;
      _selectedOptionIndex = null;
      _showAnswerState = false;
    });
  }

  Future<void> _submitCompletion() async {
    final scorePercent = _lesson.questions.isEmpty
        ? 0
        : ((_correctAnswers / _lesson.questions.length) * 100).round();
    setState(() => _isSubmittingCompletion = true);
    try {
      final updatedLesson = await widget.onSubmitCompletion(
        scorePercent: scorePercent,
        rating: _selectedRating,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lesson = updatedLesson;
        _hasSubmittedCompletion = true;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingCompletion = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson.title),
        actions: [
          IconButton(
            onPressed: () =>
                widget.onToggleBookmark(_lesson.isBookmarked),
            icon: Icon(
              _lesson.isBookmarked
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _quizCompleted
            ? _LessonCompletedView(
                lesson: _lesson,
                correctAnswers: _correctAnswers,
                selectedRating: _selectedRating,
                isSubmittingCompletion: _isSubmittingCompletion,
                hasSubmittedCompletion: _hasSubmittedCompletion,
                onSelectRating: (rating) =>
                    setState(() => _selectedRating = rating),
                onSubmitCompletion: _submitCompletion,
                onRestart: _startQuiz,
              )
            : !_quizStarted
                ? _LessonIntroView(
                    lesson: _lesson,
                    onStartQuiz: _startQuiz,
                  )
                : _LessonQuizView(
                    lesson: _lesson,
                    currentQuestionIndex: _currentQuestionIndex,
                    selectedOptionIndex: _selectedOptionIndex,
                    showAnswerState: _showAnswerState,
                    correctAnswers: _correctAnswers,
                    onSelectOption: _selectOption,
                    onCheckAnswer: _checkAnswer,
                    onNextQuestion: _goNext,
                  ),
      ),
    );
  }
}

class _LessonIntroView extends StatelessWidget {
  const _LessonIntroView({
    required this.lesson,
    required this.onStartQuiz,
  });

  final LessonDetail lesson;
  final VoidCallback onStartQuiz;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _LessonHeroCard(lesson: lesson),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Статья ${lesson.topic.articleCode}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blueAccent,
                      ),
                ),
                if (lesson.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    lesson.description,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Краткая теория',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(lesson.theory),
                const SizedBox(height: 14),
                const Text(
                  'Фрагмент статьи',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(lesson.articleExcerpt),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onStartQuiz,
          child: Text('Начать урок (${lesson.questions.length} вопросов)'),
        ),
      ],
    );
  }
}

class _LessonQuizView extends StatelessWidget {
  const _LessonQuizView({
    required this.lesson,
    required this.currentQuestionIndex,
    required this.selectedOptionIndex,
    required this.showAnswerState,
    required this.correctAnswers,
    required this.onSelectOption,
    required this.onCheckAnswer,
    required this.onNextQuestion,
  });

  final LessonDetail lesson;
  final int currentQuestionIndex;
  final int? selectedOptionIndex;
  final bool showAnswerState;
  final int correctAnswers;
  final ValueChanged<int> onSelectOption;
  final VoidCallback onCheckAnswer;
  final VoidCallback onNextQuestion;

  @override
  Widget build(BuildContext context) {
    final question = lesson.questions[currentQuestionIndex];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (currentQuestionIndex + 1) / lesson.questions.length,
                  minHeight: 10,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('${currentQuestionIndex + 1}/${lesson.questions.length}'),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  question.prompt,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final isSelected = selectedOptionIndex == index;
          final isCorrect = option.isCorrect;
          final bool highlightCorrect = showAnswerState && isCorrect;
          final bool highlightWrong =
              showAnswerState && isSelected && !isCorrect;

          Color borderColor = Colors.white12;
          if (highlightCorrect) {
            borderColor = const Color(0xFF48D875);
          } else if (highlightWrong) {
            borderColor = const Color(0xFFFF6B6B);
          } else if (isSelected) {
            borderColor = const Color(0xFF2E83FF);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => onSelectOption(index),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      highlightCorrect
                          ? Icons.check_circle_rounded
                          : highlightWrong
                              ? Icons.cancel_rounded
                              : isSelected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                      color: borderColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(option.text)),
                  ],
                ),
              ),
            ),
          );
        }),
        if (showAnswerState && question.explanation.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                question.explanation,
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        ElevatedButton(
          onPressed: showAnswerState
              ? onNextQuestion
              : selectedOptionIndex == null
                  ? null
                  : onCheckAnswer,
          child: Text(
            showAnswerState
                ? (currentQuestionIndex == lesson.questions.length - 1
                    ? 'Завершить урок'
                    : 'Следующий вопрос')
                : 'Проверить ответ',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Верных ответов: $correctAnswers',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class _LessonCompletedView extends StatelessWidget {
  const _LessonCompletedView({
    required this.lesson,
    required this.correctAnswers,
    required this.selectedRating,
    required this.isSubmittingCompletion,
    required this.hasSubmittedCompletion,
    required this.onSelectRating,
    required this.onSubmitCompletion,
    required this.onRestart,
  });

  final LessonDetail lesson;
  final int correctAnswers;
  final int selectedRating;
  final bool isSubmittingCompletion;
  final bool hasSubmittedCompletion;
  final ValueChanged<int> onSelectRating;
  final Future<void> Function() onSubmitCompletion;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final percent = lesson.questions.isEmpty
        ? 0
        : (correctAnswers / lesson.questions.length * 100).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded,
                size: 84, color: Color(0xFF48D875)),
            const SizedBox(height: 18),
            Text(
              'Урок завершён',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Вы ответили верно на $correctAnswers из ${lesson.questions.length} вопросов',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E83FF),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Оцени урок',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starNumber = index + 1;
                return IconButton(
                  onPressed: () => onSelectRating(starNumber),
                  icon: Icon(
                    starNumber <= selectedRating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xFF5DD17B),
                    size: 34,
                  ),
                );
              }),
            ),
            if (hasSubmittedCompletion) ...[
              const SizedBox(height: 4),
              Text(
                'Спасибо! Рейтинг и количество прошедших обновлены.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isSubmittingCompletion ? null : onSubmitCompletion,
              child: Text(
                isSubmittingCompletion
                    ? 'Сохраняем оценку...'
                    : 'Сохранить результат',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRestart,
              child: const Text('Пройти ещё раз'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonHeroCard extends StatelessWidget {
  const _LessonHeroCard({required this.lesson});

  final LessonDetail lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E8BFF), Color(0xFF6B43FF)],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            '${lesson.questions.length} вопросов • ${lesson.estimatedMinutes} минут',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
