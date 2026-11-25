-- =====================================================================
-- 03_insulated_by_country.sql
-- Question: Did sourcing of insulated drinkware shift away from China,
--           and how did tariffs and unit values differ by country?
-- Output  : Top 5 source countries per year.
-- Note    : QUALIFY filters AFTER the window function runs, so share_pct
--           uses all countries in the denominator.
-- =====================================================================

WITH yearly AS (
  SELECT
    EXTRACT(YEAR FROM month_date) AS yr,
    country,
    SUM(customs_value) AS v,
    SUM(duties)        AS d,
    SUM(quantity)      AS q
  FROM trade.cups_monthly
  WHERE product_group = 'Insulated stainless'
  GROUP BY yr, country
)
SELECT
  yr,
  country,
  ROUND(v / 1e6, 1)                                  AS value_musd,
  ROUND(100 * v / SUM(v) OVER (PARTITION BY yr), 1)  AS share_pct,
  ROUND(100 * SAFE_DIVIDE(d, v), 1)                  AS eff_tariff_pct,
  ROUND(SAFE_DIVIDE(v, q), 2)                        AS unit_value_usd
FROM yearly
WHERE TRUE  -- BigQuery requires WHERE, GROUP BY or HAVING alongside QUALIFY
QUALIFY RANK() OVER (PARTITION BY yr ORDER BY v DESC) <= 5
ORDER BY yr, value_musd DESC;
