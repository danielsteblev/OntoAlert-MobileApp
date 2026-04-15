from __future__ import annotations

from collections import Counter

from apps.lessons.models import Bookmark, Lesson
from apps.recommendations.models import RecommendationLog
from apps.search.models import SearchQuery


def build_recommendations_for_user(user):
    recent_queries = SearchQuery.objects.filter(user=user).order_by("-created_at")[:10]
    bookmarked_ids = set(Bookmark.objects.filter(user=user).values_list("lesson_id", flat=True))
    all_lessons = list(Lesson.objects.select_related("topic").all())

    topic_counter = Counter()
    for query in recent_queries:
        article = query.matched_article
        if article:
            for lesson in all_lessons:
                if lesson.topic.article_code != article:
                    continue
                topic_counter[lesson.id] += 3
        for lesson in all_lessons:
            if set(query.normalized_terms) & set(lesson.topic.semantic_keywords):
                topic_counter[lesson.id] += 2

    for lesson_id in bookmarked_ids:
        topic_counter[lesson_id] += 1

    scored_lessons = []
    for lesson_id, score in topic_counter.items():
        lesson = next(lesson for lesson in all_lessons if lesson.id == lesson_id)
        reason = f"Совпадение с вашими последними запросами по статье {lesson.topic.article_code}"
        scored_lessons.append({"lesson": lesson, "score": score, "reason": reason})

    if not scored_lessons:
        for lesson in all_lessons[:3]:
            scored_lessons.append(
                {"lesson": lesson, "score": 1, "reason": "Базовая рекомендованная тема для старта по главе 20"}
            )

    scored_lessons.sort(key=lambda item: item["score"], reverse=True)
    selected = scored_lessons[:5]

    RecommendationLog.objects.filter(user=user).delete()
    RecommendationLog.objects.bulk_create(
        [
            RecommendationLog(user=user, lesson=item["lesson"], reason=item["reason"], score=item["score"])
            for item in selected
        ]
    )
    return selected
