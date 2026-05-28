# Семантический поиск (NLP + OWL + SPARQL)

## Поток обработки запроса

1. **NLP preprocessing** (`backend/apps/search/nlp.py`)
   - токенизация запроса;
   - удаление стоп-слов;
   - лемматизация через `pymorphy3` (fallback: regex);
   - расширение терминов по словарю синонимов `ontology/data/legal_synonyms.json`.

2. **SPARQL-запрос к OWL** (`backend/apps/search/sparql_engine.py`)
   - RDF-граф загружается из `ontology/data/chapter20.owl` (`rdflib`);
   - запрос ищет статьи (`ch:Article`) по ключевым словам (`ch:keywordLabel`);
   - учитываются синонимы через `ch:synonymOf`.

3. **Ранжирование тем** (`backend/apps/search/services.py`)
   - совпадения из SPARQL (вес выше);
   - ключевые слова темы в PostgreSQL;
   - заголовок и summary темы;
   - код статьи в тексте запроса.

4. **Ответ API** `POST /api/search/semantic`
   - `matched_article`, `confidence`, `explanation`;
   - блоки `nlp`, `sparql`, `ranking` для демонстрации на защите.

## Онтология

- Seed: `ontology/data/chapter20_seed.json`
- Синонимы: `ontology/data/legal_synonyms.json`
- Сборка: `python ontology/scripts/build_chapter20_ontology.py`
- Результат: `ontology/data/chapter20.owl`

Классы: `Article`, `Offense`, `Keyword`, `LessonTopic`.

Свойства:
- `articleCode`, `summary`, `keywordLabel`
- `hasKeyword`, `synonymOf`, `mapsToLesson`, `describedByArticle`

## Пример SPARQL

```sparql
PREFIX ch: <http://fast-learning.local/chapter20.owl#>

SELECT DISTINCT ?articleCode ?matchedLabel ?matchType WHERE {
  ?article a ch:Article ;
           ch:articleCode ?articleCode ;
           ch:hasKeyword ?articleKw .
  {
    ?articleKw ch:keywordLabel ?matchedLabel .
    FILTER(LCASE(STR(?matchedLabel)) IN ("хулиганство", "мелкое"))
    BIND("direct" AS ?matchType)
  }
  UNION
  {
    ?articleKw ch:keywordLabel ?canonicalLabel .
    ?syn ch:synonymOf ?articleKw ;
         ch:keywordLabel ?matchedLabel .
    FILTER(LCASE(STR(?matchedLabel)) IN ("пьяный"))
    BIND("synonym" AS ?matchType)
  }
}
```

## Как объяснить на защите

- **NLP** приводит разные формы слов к нормальной форме и расширяет юридические синонимы.
- **Онтология** хранит связи «статья → ключевые слова → синонимы».
- **SPARQL** формально извлекает кандидатов из графа знаний.
- **Backend** объединяет формальный вывод SPARQL и прикладные данные (уроки, темы) в итоговый ответ для мобильного клиента.

## Обновление данных на сервере

```bash
python ontology/scripts/build_chapter20_ontology.py
python ontology/scripts/validate_ontology.py
docker compose up -d --build
```

Если в БД уже есть старый seed без новых статей (20.3, 20.6), выполните:

```bash
python manage.py sync_ontology_topics
```

Команда добавляет и обновляет темы/уроки из `chapter20_seed.json` без сброса базы. Только вставка новых записей: `--create-only`.
