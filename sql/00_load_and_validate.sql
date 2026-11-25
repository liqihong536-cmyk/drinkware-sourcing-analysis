-- =====================================================================
-- 00_load_and_validate.sql
-- Purpose : Document how the raw USITC DataWeb export was loaded into
--           BigQuery and validate that all four measures arrived intact.
-- Source  : USITC DataWeb, Imports for Consumption, HTS-10, monthly,
--           Jan 2018 - Sep 2026, all countries broken out.
--           HTS headings pulled: 9617, 7323.93, 7013.28, 7013.37
-- =====================================================================

-- Load notes (BigQuery console upload into trade.imports_raw):
--   * Schema (STRING for hts so codes are never treated as numbers):
--     data_type:STRING, country:STRING, year:INTEGER, month:INTEGER,
--     hts:STRING, description:STRING, quantity_description:STRING,
--     value:FLOAT, extra:STRING
--   * "extra" absorbs a trailing comma present on every exported line.
--   * Header rows to skip = 1. Number of errors allowed = 3:
--     DataWeb stacks the four measures as sections, and each later
--     section repeats its header row (lines 33803, 67605, 101408).

-- Check 1: each measure should cover the same codes, countries and months.
-- Rows labelled 'Total:' and blank (NULL) rows are DataWeb artifacts.
SELECT
  data_type,
  COUNT(*)                      AS rows_count,
  COUNT(DISTINCT hts)           AS hts_codes,
  COUNT(DISTINCT country)       AS countries,
  MIN(year * 100 + month)       AS first_month,
  MAX(year * 100 + month)       AS last_month,
  ROUND(SUM(value), 0)          AS total_value
FROM trade.imports_raw
GROUP BY data_type;

-- Check 2: list every HTS-10 code with its description, unit and value,
-- to decide which codes actually represent drinkware.
SELECT
  hts,
  ANY_VALUE(description) AS description,
  ANY_VALUE(IF(data_type = 'First Unit of Quantity', quantity_description, NULL)) AS quantity_unit,
  ROUND(SUM(IF(data_type = 'Customs Value', value, 0)) / 1e6, 1) AS customs_value_musd
FROM trade.imports_raw
WHERE data_type IS NOT NULL
  AND data_type != 'Total:'
GROUP BY hts
ORDER BY hts;
