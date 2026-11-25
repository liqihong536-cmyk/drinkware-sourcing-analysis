-- =====================================================================
-- 07_glass_by_country.sql
-- Question: How do glass drinkware sources, tariffs and freight compare
--           by country, before and after the tariff changes?
-- Years   : 2018 (baseline), 2024 (before the 2025 increase), 2026 (latest).
-- Note    : The year filter does not distort shares because the window is
--           partitioned by product group and year.
-- =====================================================================

WITH yearly AS (
  SELECT
    product_group,
    EXTRACT(YEAR FROM month_date) AS yr,
    country,
    SUM(customs_value)   AS v,
    SUM(duties)          AS d,
    SUM(freight_charges) AS f,
    SUM(quantity)        AS q
  FROM trade.cups_monthly
  WHERE product_group IN ('Glass tumblers', 'Glass stemware')
  GROUP BY product_group, yr, country
)
SELECT
  product_group,
  yr,
  country,
  ROUND(v / 1e6, 1)                                                AS value_musd,
  ROUND(100 * v / SUM(v) OVER (PARTITION BY product_group, yr), 1) AS share_pct,
  ROUND(100 * SAFE_DIVIDE(d, v), 1)                                AS eff_tariff_pct,
  ROUND(100 * SAFE_DIVIDE(f, v), 1)                                AS freight_pct,
  ROUND(SAFE_DIVIDE(v, q), 2)                                      AS unit_value_usd
FROM yearly
WHERE yr IN (2018, 2024, 2026)
QUALIFY RANK() OVER (PARTITION BY product_group, yr ORDER BY v DESC) <= 6
ORDER BY product_group, yr, value_musd DESC;
