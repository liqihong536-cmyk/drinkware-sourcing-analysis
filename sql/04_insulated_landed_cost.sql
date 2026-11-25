-- =====================================================================
-- 04_insulated_landed_cost.sql
-- Question: After duty and freight, which country is the cheapest source
--           for insulated drinkware?
-- Method  : Landed cost per unit = (customs value + freight + duty) / units.
--           Restricted to a single HTS code (9617.00.10, <=1L) so that
--           capacity mix does not distort unit values across countries.
-- =====================================================================

WITH c AS (
  SELECT
    EXTRACT(YEAR FROM month_date) AS yr,
    country,
    SUM(customs_value)   AS v,
    SUM(duties)          AS d,
    SUM(freight_charges) AS f,
    SUM(quantity)        AS q
  FROM trade.cups_monthly
  WHERE hts = '9617001000'
    AND EXTRACT(YEAR FROM month_date) IN (2024, 2026)
    AND country IN ('China', 'Vietnam', 'Thailand', 'Malaysia')
  GROUP BY yr, country
)
SELECT
  yr,
  country,
  ROUND(SAFE_DIVIDE(v, q), 2)         AS fob_per_unit,
  ROUND(SAFE_DIVIDE(f, q), 2)         AS freight_per_unit,
  ROUND(SAFE_DIVIDE(d, q), 2)         AS duty_per_unit,
  ROUND(SAFE_DIVIDE(v + f + d, q), 2) AS landed_per_unit,
  -- How far above the cheapest country in the same year
  ROUND(100 * SAFE_DIVIDE(v + f + d, q)
        / MIN(SAFE_DIVIDE(v + f + d, q)) OVER (PARTITION BY yr) - 100, 1) AS pct_above_cheapest
FROM c
ORDER BY yr, landed_per_unit;
