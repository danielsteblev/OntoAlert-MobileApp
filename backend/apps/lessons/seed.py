from __future__ import annotations

import json
from typing import Any

from django.conf import settings
from django.db import transaction

from apps.lessons.models import AnswerOption, Lesson, Question, Topic


def _load_seed_payload() -> dict:
    with open(settings.CONTENT_SEED_PATH, "r", encoding="utf-8") as seed_file:
        return json.load(seed_file)


def _topic_defaults(topic_payload: dict) -> dict:
    return {
        "title": topic_payload["title"],
        "article_code": topic_payload["article_code"],
        "summary": topic_payload["summary"],
        "semantic_keywords": topic_payload["semantic_keywords"],
    }


def _lesson_defaults(topic: Topic, lesson_payload: dict) -> dict:
    return {
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
    }


def _apply_model_updates(instance, values: dict[str, Any]) -> bool:
    changed = False
    for field, value in values.items():
        if getattr(instance, field) != value:
            setattr(instance, field, value)
            changed = True
    if changed:
        instance.save()
    return changed


def _sync_questions(lesson: Lesson, lesson_payload: dict, stats: dict) -> None:
    for question_payload in lesson_payload.get("questions", []):
        question, created = Question.objects.get_or_create(
            lesson=lesson,
            prompt=question_payload["prompt"],
            defaults={"explanation": question_payload.get("explanation", "")},
        )
        if created:
            stats["questions_created"] += 1
        elif question.explanation != question_payload.get("explanation", ""):
            question.explanation = question_payload.get("explanation", "")
            question.save(update_fields=["explanation"])
            stats["questions_updated"] += 1

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
            stats["options_created"] += len(question_payload["options"])


@transaction.atomic
def sync_ontology_topics(*, update_existing: bool = True) -> dict[str, int]:
    payload = _load_seed_payload()
    stats = {
        "topics_created": 0,
        "topics_updated": 0,
        "lessons_created": 0,
        "lessons_updated": 0,
        "questions_created": 0,
        "questions_updated": 0,
        "options_created": 0,
    }

    for topic_payload in payload["topics"]:
        topic, created = Topic.objects.get_or_create(
            slug=topic_payload["slug"],
            defaults=_topic_defaults(topic_payload),
        )
        if created:
            stats["topics_created"] += 1
        elif update_existing and _apply_model_updates(topic, _topic_defaults(topic_payload)):
            stats["topics_updated"] += 1

        for lesson_payload in topic_payload["lessons"]:
            lesson, lesson_created = Lesson.objects.get_or_create(
                slug=lesson_payload["slug"],
                defaults=_lesson_defaults(topic, lesson_payload),
            )
            if lesson_created:
                stats["lessons_created"] += 1
            elif update_existing:
                lesson_values = _lesson_defaults(topic, lesson_payload)
                if lesson.topic_id != topic.id:
                    lesson_values["topic"] = topic
                if _apply_model_updates(lesson, lesson_values):
                    stats["lessons_updated"] += 1
            elif lesson.topic_id != topic.id:
                lesson.topic = topic
                lesson.save(update_fields=["topic"])
                stats["lessons_updated"] += 1

            _sync_questions(lesson, lesson_payload, stats)

    return stats


def _sync_hints(payload: dict) -> None:
    from apps.content.models import HintStory, HintStorySlide

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


@transaction.atomic
def ensure_demo_content() -> None:
    if Topic.objects.exists() and Lesson.objects.exists():
        return

    payload = _load_seed_payload()
    sync_ontology_topics(update_existing=True)
    _sync_hints(payload)
