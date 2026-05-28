from pathlib import Path

from django.conf import settings
from django.test import SimpleTestCase, TestCase

from apps.lessons.seed import ensure_demo_content
from apps.search.nlp import preprocess_query
from apps.search.services import semantic_search
from apps.search.sparql_engine import run_article_match_query


class NlpPreprocessorTests(SimpleTestCase):
    def test_lemmatizes_hooliganism_query(self):
        result = preprocess_query("мелкое хулиганство в парке")
        self.assertIn("хулиганство", result["lemmas"])
        self.assertGreater(len(result["expanded_terms"]), len(result["lemmas"]))

    def test_expands_intoxication_synonyms(self):
        result = preprocess_query("пьяный в парке")
        self.assertTrue({"пьяный", "опьянение"} & set(result["expanded_terms"]))


class SparqlEngineTests(SimpleTestCase):
    def test_sparql_finds_article_for_keyword(self):
        ontology_path = Path(settings.ONTOLOGY_PATH)
        if not ontology_path.exists():
            self.skipTest("Ontology file is not built yet.")

        result = run_article_match_query(["хулиганство"])
        self.assertTrue(result["sparql_available"])
        self.assertTrue(result["matches"])
        self.assertTrue(any(match["article_code"] == "20.1" for match in result["matches"]))


class SemanticSearchServiceTests(TestCase):
    def test_semantic_search_returns_sparql_and_nlp_blocks(self):
        ensure_demo_content()
        result = semantic_search("мелкое хулиганство в парке")

        self.assertEqual(result["matched_article"], "20.1")
        self.assertIn("nlp", result)
        self.assertIn("sparql", result)
        self.assertIn("ranking", result)
        self.assertTrue(result["sparql"]["available"])
        self.assertIsNotNone(result["sparql"]["query"])

    def test_synonym_query_maps_to_alcohol_article(self):
        ensure_demo_content()
        result = semantic_search("пьяный человек в общественном месте")
        self.assertIn(result["matched_article"], {"20.20", "20.21"})
