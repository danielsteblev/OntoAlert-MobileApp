class UserProfile {
  const UserProfile({
    required this.username,
    required this.email,
    required this.fullName,
    required this.bio,
    required this.university,
  });

  final String username;
  final String email;
  final String fullName;
  final String bio;
  final String university;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return UserProfile(
      username: user['username']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      university: json['university']?.toString() ?? '',
    );
  }
}

class LessonTopic {
  const LessonTopic({
    required this.title,
    required this.articleCode,
    required this.summary,
  });

  final String title;
  final String articleCode;
  final String summary;

  factory LessonTopic.fromJson(Map<String, dynamic> json) {
    return LessonTopic(
      title: json['title']?.toString() ?? '',
      articleCode: json['article_code']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
    );
  }
}

class LessonSummary {
  const LessonSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.isBookmarked,
    required this.topic,
    required this.imageUrl,
    required this.rating,
    required this.learnersCount,
    required this.questionsCount,
  });

  final int id;
  final String title;
  final String description;
  final String difficulty;
  final int estimatedMinutes;
  final bool isBookmarked;
  final LessonTopic topic;
  final String imageUrl;
  final double rating;
  final int learnersCount;
  final int questionsCount;

  factory LessonSummary.fromJson(Map<String, dynamic> json) {
    return LessonSummary(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      description: json['short_description']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 0,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      topic: LessonTopic.fromJson(json['topic'] as Map<String, dynamic>? ?? {}),
      imageUrl: json['image_url']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      learnersCount: (json['learners_count'] as num?)?.toInt() ?? 0,
      questionsCount: (json['questions_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class QuestionOption {
  const QuestionOption({required this.text, required this.isCorrect});

  final String text;
  final bool isCorrect;

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      text: json['text']?.toString() ?? '',
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }
}

class LessonQuestion {
  const LessonQuestion({
    required this.prompt,
    required this.explanation,
    required this.options,
  });

  final String prompt;
  final String explanation;
  final List<QuestionOption> options;

  factory LessonQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    return LessonQuestion(
      prompt: json['prompt']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      options: rawOptions
          .map((option) =>
              QuestionOption.fromJson(option as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LessonDetail extends LessonSummary {
  const LessonDetail({
    required super.id,
    required super.title,
    required super.description,
    required super.difficulty,
    required super.estimatedMinutes,
    required super.isBookmarked,
    required super.topic,
    required super.imageUrl,
    required super.rating,
    required super.learnersCount,
    required super.questionsCount,
    required this.theory,
    required this.articleExcerpt,
    required this.questions,
  });

  final String theory;
  final String articleExcerpt;
  final List<LessonQuestion> questions;

  factory LessonDetail.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? const [];
    return LessonDetail(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      description: json['short_description']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 0,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      topic: LessonTopic.fromJson(json['topic'] as Map<String, dynamic>? ?? {}),
      imageUrl: json['image_url']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      learnersCount: (json['learners_count'] as num?)?.toInt() ?? 0,
      questionsCount: (json['questions_count'] as num?)?.toInt() ?? 0,
      theory: json['theory']?.toString() ?? '',
      articleExcerpt: json['article_excerpt']?.toString() ?? '',
      questions: rawQuestions
          .map((question) =>
              LessonQuestion.fromJson(question as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StorySlide {
  const StorySlide({
    required this.id,
    required this.imageUrl,
    required this.sortOrder,
  });

  final int id;
  final String imageUrl;
  final int sortOrder;

  factory StorySlide.fromJson(Map<String, dynamic> json) {
    return StorySlide(
      id: json['id'] as int? ?? 0,
      imageUrl: json['image_url']?.toString() ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class HintStory {
  const HintStory({
    required this.id,
    required this.title,
    required this.coverImageUrl,
    required this.slides,
    required this.sortOrder,
  });

  final int id;
  final String title;
  final String coverImageUrl;
  final List<StorySlide> slides;
  final int sortOrder;

  factory HintStory.fromJson(Map<String, dynamic> json) {
    final rawSlides = json['slides'] as List<dynamic>? ?? const [];
    return HintStory(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      coverImageUrl: json['cover_image_url']?.toString() ?? '',
      slides: rawSlides
          .map((slide) => StorySlide.fromJson(slide as Map<String, dynamic>))
          .toList(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class SearchHistoryItem {
  const SearchHistoryItem({
    required this.queryText,
    required this.matchedArticle,
  });

  final String queryText;
  final String matchedArticle;

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      queryText: json['query_text']?.toString() ?? '',
      matchedArticle: json['matched_article']?.toString() ?? '',
    );
  }
}

class SearchResult {
  const SearchResult({
    required this.query,
    required this.matchedArticle,
    required this.explanation,
    required this.confidence,
    required this.lessons,
  });

  final String query;
  final String matchedArticle;
  final String explanation;
  final double confidence;
  final List<LessonSummary> lessons;

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['lessons'] as List<dynamic>? ?? const [];
    return SearchResult(
      query: json['query']?.toString() ?? '',
      matchedArticle: json['matched_article']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      lessons: rawLessons
          .map((lesson) =>
              LessonSummary.fromJson(lesson as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecommendationItem {
  const RecommendationItem({
    required this.lesson,
    required this.reason,
    required this.score,
  });

  final LessonSummary lesson;
  final String reason;
  final double score;

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      lesson:
          LessonSummary.fromJson(json['lesson'] as Map<String, dynamic>? ?? {}),
      reason: json['reason']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}
