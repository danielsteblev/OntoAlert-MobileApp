from __future__ import annotations

import json

from django.conf import settings
from django.db import transaction

from apps.lessons.models import AnswerOption, Lesson, Question, Topic


def _load_seed_payload() -> dict:
    with open(settings.CONTENT_SEED_PATH, "r", encoding="utf-8") as seed_file:
        return json.load(seed_file)


@transaction.atomic
def ensure_demo_content() -> None:
    if Topic.objects.exists() and Lesson.objects.exists():
        return

    payload = _load_seed_payload()

    from apps.content.models import HintStory, HintStorySlide

    for topic_payload in payload["topics"]:
        topic, _ = Topic.objects.get_or_create(
            slug=topic_payload["slug"],
            defaults={
                "title": topic_payload["title"],
                "article_code": topic_payload["article_code"],
                "summary": topic_payload["summary"],
                "semantic_keywords": topic_payload["semantic_keywords"],
            },
        )

        for lesson_payload in topic_payload["lessons"]:
            lesson, _ = Lesson.objects.get_or_create(
                slug=lesson_payload["slug"],
                defaults={
                    "topic": topic,
                    "title": lesson_payload["title"],
                    "short_description": lesson_payload["short_description"],
                    "theory": lesson_payload["theory"],
                    "article_excerpt": lesson_payload["article_excerpt"],
                    "sort_order": lesson_payload.get("sort_order", 0),
                    "rating": lesson_payload.get("rating", 4.8),
                    "learners_count": lesson_payload.get("learners_count", 0),
                    "difficulty": lesson_payload.get("difficulty", "beginner"),
                    "estimated_minutes": lesson_payload.get("estimated_minutes", 10),
                },
            )

            for question_payload in lesson_payload.get("questions", []):
                question, _ = Question.objects.get_or_create(
                    lesson=lesson,
                    prompt=question_payload["prompt"],
                    defaults={"explanation": question_payload.get("explanation", "")},
                )
                if not question.options.exists():
                    AnswerOption.objects.bulk_create(
                        [
                            AnswerOption(
                                question=question,
                                text=option["text"],
                                is_correct=option["is_correct"],
                            )
                            for option in question_payload["options"]
                        ]
                    )

    for hint_payload in payload.get("hints", []):
        story, _ = HintStory.objects.get_or_create(
            title=hint_payload["title"],
            defaults={
                "subtitle": hint_payload["subtitle"],
                "body": hint_payload["body"],
                "highlight_text": hint_payload["highlight_text"],
                "sort_order": hint_payload.get("sort_order", 0),
            },
        )
        if story.image and not story.slides.exists():
            HintStorySlide.objects.get_or_create(
                story=story,
                sort_order=1,
                defaults={"image": story.image},
            )
