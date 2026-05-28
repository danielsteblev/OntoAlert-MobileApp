from __future__ import annotations

import json
from pathlib import Path

from owlready2 import DataProperty, FunctionalProperty, ObjectProperty, Thing, get_ontology


SCRIPT_DIR = Path(__file__).resolve().parent
DATA_DIR = SCRIPT_DIR.parent / "data"
SEED_PATH = DATA_DIR / "chapter20_seed.json"
SYNONYMS_PATH = DATA_DIR / "legal_synonyms.json"
OUTPUT_PATH = DATA_DIR / "chapter20.owl"
ONTOLOGY_IRI = "http://fast-learning.local/chapter20.owl"


def load_seed() -> dict:
    with open(SEED_PATH, "r", encoding="utf-8") as file:
        return json.load(file)


def load_synonym_groups() -> list[list[str]]:
    if not SYNONYMS_PATH.exists():
        return []
    with open(SYNONYMS_PATH, "r", encoding="utf-8") as file:
        payload = json.load(file)
    return payload.get("groups", [])


def keyword_id(value: str) -> str:
    return f"Keyword_{value.replace(' ', '_').replace('.', '_')}"


def ensure_keyword(onto, cache: dict, value: str):
    normalized = value.strip().lower()
    if normalized in cache:
        return cache[normalized]

    keyword = onto.Keyword(keyword_id(normalized))
    keyword.keywordLabel = normalized
    cache[normalized] = keyword
    return keyword


def link_synonyms(onto, cache: dict, groups: list[list[str]]) -> None:
    for group in groups:
        canonical = ensure_keyword(onto, cache, group[0])
        for synonym_value in group[1:]:
            synonym = ensure_keyword(onto, cache, synonym_value)
            synonym.synonymOf = [canonical]


def build_ontology() -> Path:
    payload = load_seed()
    synonym_groups = load_synonym_groups()
    onto = get_ontology(ONTOLOGY_IRI)
    keyword_cache: dict[str, object] = {}

    with onto:
        class Article(Thing):
            pass

        class Offense(Thing):
            pass

        class Keyword(Thing):
            pass

        class LessonTopic(Thing):
            pass

        class describedByArticle(ObjectProperty):
            domain = [Offense]
            range = [Article]

        class hasKeyword(ObjectProperty):
            domain = [Article]
            range = [Keyword]

        class mapsToLesson(ObjectProperty):
            domain = [Article]
            range = [LessonTopic]

        class synonymOf(ObjectProperty):
            domain = [Keyword]
            range = [Keyword]

        class articleCode(DataProperty, FunctionalProperty):
            domain = [Article]
            range = [str]

        class summary(DataProperty, FunctionalProperty):
            domain = [Article]
            range = [str]

        class keywordLabel(DataProperty, FunctionalProperty):
            domain = [Keyword]
            range = [str]

    link_synonyms(onto, keyword_cache, synonym_groups)

    for topic_payload in payload["topics"]:
        article_id = f"Article_{topic_payload['article_code'].replace('.', '_')}"
        lesson_id = f"Lesson_{topic_payload['slug'].replace('-', '_')}"
        offense_id = f"Offense_{topic_payload['slug'].replace('-', '_')}"

        article = onto.Article(article_id)
        article.articleCode = topic_payload["article_code"]
        article.summary = topic_payload["summary"]

        lesson_topic = onto.LessonTopic(lesson_id)
        offense = onto.Offense(offense_id)
        offense.describedByArticle = [article]
        article.mapsToLesson = [lesson_topic]

        for keyword_value in topic_payload["semantic_keywords"]:
            keyword = ensure_keyword(onto, keyword_cache, keyword_value)
            if keyword not in article.hasKeyword:
                article.hasKeyword.append(keyword)

    onto.save(file=str(OUTPUT_PATH), format="rdfxml")
    return OUTPUT_PATH


if __name__ == "__main__":
    output = build_ontology()
    print(f"Ontology saved to {output}")
