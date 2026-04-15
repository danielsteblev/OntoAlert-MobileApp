from __future__ import annotations

import re
from functools import lru_cache
from pathlib import Path

from django.conf import settings

from apps.lessons.models import Lesson, Topic

try:
    from owlready2 import get_ontology
except ImportError:  # pragma: no cover
    get_ontology = None


STOPWORDS = {
    "и",
    "в",
    "на",
    "по",
    "с",
    "что",
    "как",
    "где",
    "или",
    "ли",
    "при",
    "за",
    "для",
    "это",
    "если",
    "не",
    "у",
}


def normalize_text(query: str) -> list[str]:
    tokens = re.findall(r"[a-zA-Zа-яА-Я0-9]+", query.lower())
    return [token for token in tokens if token not in STOPWORDS and len(token) > 2]


@lru_cache(maxsize=1)
def load_ontology_keywords() -> dict[str, list[str]]:
    ontology_path = Path(settings.ONTOLOGY_PATH)
    if not ontology_path.exists() or get_ontology is None:
        return {}

    ontology = get_ontology(str(ontology_path)).load()
    article_keywords: dict[str, list[str]] = {}
    for individual in ontology.individuals():
        article_code = getattr(individual, "articleCode", [])
        keywords = getattr(individual, "hasKeyword", [])
        if article_code:
            article_keywords[str(article_code[0])] = [str(keyword) for keyword in keywords]
    return article_keywords


def semantic_search(query: str) -> dict:
    normalized_terms = normalize_text(query)
    ontology_keywords = load_ontology_keywords()

    scored_topics = []
    for topic in Topic.objects.all():
        topic_terms = {term.lower() for term in topic.semantic_keywords}
        topic_terms.update(re.findall(r"[a-zA-Zа-яА-Я0-9]+", topic.title.lower()))
        topic_terms.update(re.findall(r"[a-zA-Zа-яА-Я0-9]+", topic.summary.lower()))
        topic_terms.update(keyword.lower() for keyword in ontology_keywords.get(topic.article_code, []))

        overlap = sorted(set(normalized_terms) & topic_terms)
        score = len(overlap)
        if normalized_terms and topic.article_code.replace(".", "") in "".join(normalized_terms):
            score += 2
        if score:
            scored_topics.append((score, overlap, topic))

    scored_topics.sort(key=lambda item: item[0], reverse=True)
    top_topic = scored_topics[0][2] if scored_topics else Topic.objects.order_by("article_code").first()
    matched_terms = scored_topics[0][1] if scored_topics else []

    lessons = list(Lesson.objects.filter(topic=top_topic).select_related("topic")[:3]) if top_topic else []
    matched_article = top_topic.article_code if top_topic else "20.1"
    confidence = float(min(1.0, (scored_topics[0][0] / max(len(normalized_terms), 1)))) if scored_topics else 0.3

    return {
        "query": query,
        "normalized_terms": normalized_terms,
        "matched_article": matched_article,
        "confidence": round(confidence, 2),
        "explanation": (
            f"Запрос сопоставлен с ключевыми словами главы 20: {', '.join(matched_terms)}."
            if matched_terms
            else "Прямое совпадение не найдено, поэтому показана наиболее базовая тема по главе 20."
        ),
        "lessons": lessons,
    }
