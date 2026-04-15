from __future__ import annotations

import json
from pathlib import Path

from owlready2 import DataProperty, FunctionalProperty, ObjectProperty, Thing, get_ontology


SCRIPT_DIR = Path(__file__).resolve().parent
DATA_DIR = SCRIPT_DIR.parent / "data"
SEED_PATH = DATA_DIR / "chapter20_seed.json"
OUTPUT_PATH = DATA_DIR / "chapter20.owl"


def load_seed() -> dict:
    with open(SEED_PATH, "r", encoding="utf-8") as file:
        return json.load(file)


def build_ontology() -> Path:
    payload = load_seed()
    onto = get_ontology("http://fast-learning.local/chapter20.owl")

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

        class articleCode(DataProperty, FunctionalProperty):
            domain = [Article]
            range = [str]

        class summary(DataProperty, FunctionalProperty):
            domain = [Article]
            range = [str]

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
            keyword_id = f"Keyword_{keyword_value.replace(' ', '_')}"
            keyword = onto.Keyword(keyword_id)
            article.hasKeyword.append(keyword)

    onto.save(file=str(OUTPUT_PATH), format="rdfxml")
    return OUTPUT_PATH


if __name__ == "__main__":
    output = build_ontology()
    print(f"Ontology saved to {output}")
