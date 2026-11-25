-- =====================================================================
-- 01_build_cups_monthly.sql
-- Purpose : Build the core analysis table: one row per month x country x
--           HTS-10 code, with the four DataWeb measures pivoted into columns.
--
-- Scope decisions:
--   * Insulated stainless: 9617.00.10 (<=1L) and 9617.00.30 (1-2L).
--     The 1-2L code is kept because popular 40 oz tumblers (~1.18L) fall here.
--     Excluded: 9617.00.40 (>2L jugs) and 9617.00.60 (parts).
--   * Glass: all codes under 7013.28 (stemware) and 7013.37 (other
--     drinking glasses).
--   * All of 7323.93 is excluded. It is dominated by cookware and kitchenware,
--     and the only code that could hold non-insulated steel cups
--     (7323.93.0080, "household articles, NESOI") is ~$9.4B of mixed goods
--     with no way to isolate cups.
--   * Note: CBP reclassified insulated steel beverage containers from
--     7323.93.0080 (2% MFN) to 9617.00.10 (7.2% MFN), so trend analysis on
--     7323.93 alone would show a misleading decline.
-- =====================================================================

CREATE OR REPLACE TABLE trade.cups_monthly AS
SELECT
  DATE(year, month, 1) AS month_date,
  country,
  hts,
  CASE
    WHEN hts IN ('9617001000', '9617003000') THEN 'Insulated stainless'
    WHEN STARTS_WITH(hts, '701328') THEN 'Glass stemware'
    WHEN STARTS_WITH(hts, '701337') THEN 'Glass tumblers'
  END AS product_group,
  -- Pivot: one column per measure (conditional aggregation)
  SUM(IF(data_type = 'Customs Value', value, 0))                   AS customs_value,
  SUM(IF(data_type = 'Calculated Duties', value, 0))               AS duties,
  SUM(IF(data_type = 'Charges, Insurance, and Freight', value, 0)) AS freight_charges,
  SUM(IF(data_type = 'First Unit of Quantity', value, 0))          AS quantity
FROM trade.imports_raw
WHERE data_type IS NOT NULL
  AND data_type != 'Total:'
  AND (hts IN ('9617001000', '9617003000')
       OR STARTS_WITH(hts, '701328')
       OR STARTS_WITH(hts, '701337'))
GROUP BY month_date, country, hts, product_group;
