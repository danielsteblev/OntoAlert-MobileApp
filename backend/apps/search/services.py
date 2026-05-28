from __future__ import annotations

import re

from apps.lessons.models import Lesson, Topic
from apps.search.nlp import preprocess_query
from apps.search.sparql_engine import run_article_match_query, score_sparql_matches

TOKEN_PATTERN = re.compile(r"[a-zA-Zа-яА-ЯёЁ0-9]+")

WEIGHT_ONTOLOGY_DIRECT = 3.0
WEIGHT_ONTOLOGY_SYNONYM = 2.5
WEIGHT_DB_KEYWORD = 2.0
WEIGHT_TITLE = 1.5
WEIGHT_SUMMARY = 1.0
WEIGHT_ARTICLE_CODE = 2.0


def _topic_term_sets(topic: Topic, ontology_keywords: dict[str, list[str]]) -> dict[str, set[str]]:
    db_keywords = {term.lower() for term in topic.semantic_keywords}
    title_terms = set(TOKEN_PATTERN.findall(topic.title.lower()))
    summary_terms = set(TOKEN_PATTERN.findall(topic.summary.lower()))
    owl_terms = {keyword.lower() for keyword in ontology_keywords.get(topic.article_code, [])}
    return {
        "db_keywords": db_keywords,
        "title_terms": title_terms,
        "summary_terms": summary_terms,
        "owl_terms": owl_terms,
        "all_terms": db_keywords | title_terms | summary_terms | owl_terms,
    }


def _score_topic(
    topic: Topic,
    search_terms: set[str],
    sparql_scores: dict[str, dict],
    ontology_keywords: dict[str, list[str]],
) -> dict | None:
    term_sets = _topic_term_sets(topic, ontology_keywords)
    overlap = sorted(search_terms & term_sets["all_terms"])

    score = 0.0
    breakdown: list[str] = []

    db_overlap = search_terms & term_sets["db_keywords"]
    title_overlap = search_terms & term_sets["title_terms"]
    summary_overlap = search_terms & term_sets["summary_terms"]
    owl_overlap = search_terms & term_sets["owl_terms"]

    if db_overlap:
        score += len(db_overlap) * WEIGHT_DB_KEYWORD
        breakdown.append(f"ключевые слова темы: {', '.join(sorted(db_overlap))}")
    if title_overlap:
        score += len(title_overlap) * WEIGHT_TITLE
        breakdown.append(f"заголовок: {', '.join(sorted(title_overlap))}")
    if summary_overlap:
        score += len(summary_overlap) * WEIGHT_SUMMARY
        breakdown.append(f"описание: {', '.join(sorted(summary_overlap))}")
    if owl_overlap:
        score += len(owl_overlap) * WEIGHT_ONTOLOGY_DIRECT
        breakdown.append(f"онтология (локально): {', '.join(sorted(owl_overlap))}")

    sparql_bucket = sparql_scores.get(topic.article_code)
    if sparql_bucket:
        score += sparql_bucket["score"]
        breakdown.append(
            "SPARQL по онтологии: "
            + ", ".join(f"{keyword} ({match_type})" for keyword, match_type in zip(
                sparql_bucket["keywords"],
                sparql_bucket["match_types"],
                strict=False,
            ))
        )

    article_digits = topic.article_code.replace(".", "")
    if article_digits and article_digits in "".join(search_terms):
        score += WEIGHT_ARTICLE_CODE
        breakdown.append(f"код статьи {topic.article_code}")

    if score <= 0:
        return None

    return {
        "topic": topic,
        "score": score,
        "overlap": overlap,
        "breakdown": breakdown,
        "sparql_keywords": sparql_bucket["keywords"] if sparql_bucket else [],
    }


def _load_ontology_keywords_from_sparql() -> dict[str, list[str]]:
    """Fallback map for local scoring when SPARQL graph is unavailable."""
    from functools import lru_cache
    from pathlib import Path

    from django.conf import settings

    try:
        from owlready2 import get_ontology
    except ImportError:
        return {}

    ontology_path = Path(settings.ONTOLOGY_PATH)
    if not ontology_path.exists():
        return {}

    @lru_cache(maxsize=1)
    def _cached() -> dict[str, list[str]]:
        ontology = get_ontology(str(ontology_path)).load()
        article_keywords: dict[str, list[str]] = {}
        for individual in ontology.individuals():
            article_code = getattr(individual, "articleCode", [])
            keywords = getattr(individual, "hasKeyword", [])
            if not article_code:
                continue
            labels = []
            for keyword in keywords:
                label = getattr(keyword, "keywordLabel", [])
                if label:
                    labels.append(str(label[0]))
                else:
                    labels.append(keyword.name.replace("Keyword_", "").replace("_", " "))
            article_keywords[str(article_code[0])] = labels
        return article_keywords

    return _cached()


def semantic_search(query: str) -> dict:
    nlp_result = preprocess_query(query)
    search_terms = set(nlp_result["expanded_terms"])
    sparql_result = run_article_match_query(nlp_result["expanded_terms"])
    sparql_scores = score_sparql_matches(sparql_result["matches"])
    ontology_keywords = _load_ontology_keywords_from_sparql()

    scored_topics = []
    for topic in Topic.objects.all():
        scored = _score_topic(topic, search_terms, sparql_scores, ontology_keywords)
        if scored:
            scored_topics.append(scored)

    scored_topics.sort(key=lambda item: item["score"], reverse=True)
    top = scored_topics[0] if scored_topics else None
    top_topic = top["topic"] if top else Topic.objects.order_by("article_code").first()
    matched_terms = top["overlap"] if top else []
    matched_article = top_topic.article_code if top_topic else "20.1"

    max_score = top["score"] if top else 0.0
    confidence = float(min(1.0, max_score / max(len(search_terms) * WEIGHT_ONTOLOGY_DIRECT, 1))) if top else 0.3

    if top:
        explanation = (
            f"Запрос обработан NLP ({nlp_result['nlp_engine']}): леммы "
            f"{', '.join(nlp_result['lemmas']) or '—'}; "
            f"расширение синонимами: {', '.join(nlp_result['synonym_sources']) or 'нет'}. "
            f"Лучшее совпадение — статья {matched_article} "
            f"({'; '.join(top['breakdown'])})."
        )
    else:
        explanation = (
            "Прямое совпадение не найдено. Показана базовая тема главы 20. "
            f"NLP-леммы: {', '.join(nlp_result['lemmas']) or '—'}."
        )

    lessons = list(Lesson.objects.filter(topic=top_topic).select_related("topic")[:3]) if top_topic else []

    return {
        "query": query,
        "normalized_terms": nlp_result["lemmas"],
        "expanded_terms": nlp_result["expanded_terms"],
        "matched_article": matched_article,
        "confidence": round(confidence, 2),
        "explanation": explanation,
        "matched_terms": matched_terms,
        "nlp": {
            "engine": nlp_result["nlp_engine"],
            "raw_tokens": nlp_result["raw_tokens"],
            "lemmas": nlp_result["lemmas"],
            "synonym_sources": nlp_result["synonym_sources"],
            "expanded_terms": nlp_result["expanded_terms"],
        },
        "sparql": {
            "available": sparql_result["sparql_available"],
            "query": sparql_result["sparql_query"],
            "matches": sparql_result["matches"],
        },
        "ranking": [
            {
                "article_code": item["topic"].article_code,
                "title": item["topic"].title,
                "score": round(item["score"], 2),
                "matched_terms": item["overlap"],
            }
            for item in scored_topics[:5]
        ],
        "lessons": lessons,
    }
