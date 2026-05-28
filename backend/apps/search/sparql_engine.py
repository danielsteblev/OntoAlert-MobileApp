from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from django.conf import settings

try:
    from rdflib import Graph
    from rdflib.namespace import OWL, RDF
except ImportError:  # pragma: no cover
    Graph = None
    OWL = RDF = None


ONTOLOGY_PREFIX = "http://fast-learning.local/chapter20.owl#"

MATCH_BY_TERMS_QUERY = """
PREFIX ch: <http://fast-learning.local/chapter20.owl#>

SELECT DISTINCT ?articleCode ?matchedLabel ?matchType WHERE {
  ?article a ch:Article ;
           ch:articleCode ?articleCode ;
           ch:hasKeyword ?articleKw .
  {
    ?articleKw ch:keywordLabel ?matchedLabel .
    FILTER(LCASE(STR(?matchedLabel)) IN (%(terms)s))
    BIND("direct" AS ?matchType)
  }
  UNION
  {
    ?articleKw ch:keywordLabel ?canonicalLabel .
    ?syn ch:synonymOf ?articleKw ;
         ch:keywordLabel ?matchedLabel .
    FILTER(LCASE(STR(?matchedLabel)) IN (%(terms)s))
    BIND("synonym" AS ?matchType)
  }
}
ORDER BY ?articleCode
"""


def _escape_term(term: str) -> str:
    return term.replace("\\", "\\\\").replace('"', '\\"')


def build_terms_filter(terms: list[str]) -> str:
    if not terms:
        return '"__empty__"'
    return ", ".join(f'"{_escape_term(term.lower())}"' for term in terms)


@lru_cache(maxsize=1)
def load_rdf_graph() -> Graph | None:
    if Graph is None:
        return None

    ontology_path = Path(settings.ONTOLOGY_PATH)
    if not ontology_path.exists():
        return None

    graph = Graph()
    graph.parse(str(ontology_path), format="xml")
    return graph


def run_article_match_query(terms: list[str]) -> dict:
    graph = load_rdf_graph()
    if graph is None or not terms:
        return {
            "matches": [],
            "sparql_query": None,
            "sparql_available": False,
        }

    terms_filter = build_terms_filter(terms[:30])
    sparql_query = MATCH_BY_TERMS_QUERY % {"terms": terms_filter}
    rows = graph.query(sparql_query)

    matches = []
    for row in rows:
        matches.append(
            {
                "article_code": str(row.articleCode),
                "keyword": str(row.matchedLabel),
                "match_type": str(row.matchType) if row.matchType else "direct",
            }
        )

    return {
        "matches": matches,
        "sparql_query": sparql_query.strip(),
        "sparql_available": True,
    }


def score_sparql_matches(matches: list[dict]) -> dict[str, dict]:
    scores: dict[str, dict] = {}
    for match in matches:
        article_code = match["article_code"]
        bucket = scores.setdefault(
            article_code,
            {"score": 0.0, "keywords": [], "match_types": []},
        )
        weight = 3.0 if match["match_type"] == "direct" else 2.5
        bucket["score"] += weight
        bucket["keywords"].append(match["keyword"])
        bucket["match_types"].append(match["match_type"])
    return scores
