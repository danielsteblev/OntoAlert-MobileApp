from __future__ import annotations

from pathlib import Path

from owlready2 import get_ontology

from build_chapter20_ontology import OUTPUT_PATH, build_ontology


def validate() -> None:
    ontology_path = Path(OUTPUT_PATH)
    if not ontology_path.exists():
        ontology_path = build_ontology()

    ontology = get_ontology(str(ontology_path)).load()
    articles = list(ontology.Article.instances())
    if not articles:
        raise RuntimeError("Ontology contains no Article instances.")

    for article in articles:
        if not getattr(article, "articleCode", []):
            raise RuntimeError(f"Article {article.name} has no articleCode.")

    print(f"Validated ontology with {len(articles)} articles.")


if __name__ == "__main__":
    validate()
