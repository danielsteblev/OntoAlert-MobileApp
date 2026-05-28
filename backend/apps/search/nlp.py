from __future__ import annotations

import json
import re
from functools import lru_cache
from pathlib import Path

from django.conf import settings


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
    "от",
    "до",
    "из",
    "к",
    "о",
    "об",
}

TOKEN_PATTERN = re.compile(r"[a-zA-Zа-яА-ЯёЁ0-9]+")


@lru_cache(maxsize=1)
def _morph_analyzer():
    try:
        import pymorphy3

        return pymorphy3.MorphAnalyzer()
    except ImportError:
        try:
            import pymorphy2

            return pymorphy2.MorphAnalyzer()
        except ImportError:
            return None


@lru_cache(maxsize=1)
def _synonym_map() -> dict[str, set[str]]:
    synonyms_path = settings.ROOT_DIR / "ontology" / "data" / "legal_synonyms.json"
    if not synonyms_path.exists():
        return {}

    with open(synonyms_path, "r", encoding="utf-8") as file:
        payload = json.load(file)

    mapping: dict[str, set[str]] = {}
    for group in payload.get("groups", []):
        normalized_group = {term.strip().lower() for term in group if term.strip()}
        for term in normalized_group:
            mapping[term] = normalized_group
    return mapping


def tokenize(query: str) -> list[str]:
    return [token.lower() for token in TOKEN_PATTERN.findall(query.lower())]


def lemmatize(token: str) -> str:
    morph = _morph_analyzer()
    if morph is None:
        return token

    parsed = morph.parse(token)
    if not parsed:
        return token
    return parsed[0].normal_form


def expand_with_synonyms(terms: set[str]) -> tuple[set[str], list[str]]:
    synonym_map = _synonym_map()
    expanded = set(terms)
    applied_groups: list[str] = []

    for term in list(terms):
        group = synonym_map.get(term)
        if not group:
            continue
        before = len(expanded)
        expanded.update(group)
        if len(expanded) > before:
            applied_groups.append(term)

    return expanded, applied_groups


def preprocess_query(query: str) -> dict:
    raw_tokens = [token for token in tokenize(query) if token not in STOPWORDS and len(token) > 2]
    lemmas = []
    for token in raw_tokens:
        lemma = lemmatize(token)
        if lemma not in STOPWORDS and len(lemma) > 2:
            lemmas.append(lemma)

    unique_lemmas = sorted(set(lemmas))
    expanded_terms, synonym_sources = expand_with_synonyms(set(unique_lemmas))

    return {
        "raw_tokens": raw_tokens,
        "lemmas": unique_lemmas,
        "expanded_terms": sorted(expanded_terms),
        "synonym_sources": synonym_sources,
        "nlp_engine": "pymorphy" if _morph_analyzer() is not None else "regex",
    }
