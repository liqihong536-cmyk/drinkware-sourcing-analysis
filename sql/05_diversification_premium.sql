-- =====================================================================
-- 05_diversification_premium.sql
-- Question: How much more did U.S. importers pay by sourcing insulated
--           drinkware outside China? (Jan-Sep 2026, <=1L)
-- Method  : (landed cost per unit - China landed cost per unit) x units,
--           for each country with more than $10M in customs value.
-- Result  : ~$65.5M over 9 months (Thailand $34.4M, Vietnam $26.4M,
--           Malaysia $4.7M). The Power BI measure includes all countries
--           and returns $66.3M.
-- =====================================================================

WITH c AS (
  SELECT
    country,
    SUM(customs_value)   AS v,
    SUM(duties)          AS d,
    SUM(freight_charges) AS f,
    SUM(quantity)        AS q
  FROM trade.cups_monthly
  WHERE hts = '9617001000'
    AND month_date >= '2026-01-01'
  GROUP BY country
),
landed AS (
  SELECT country, v, q, SAFE_DIVIDE(v + f + d, q) AS landed_per_unit
  FROM c
  WHERE q > 0
)
SELECT
  l.country,
  ROUND(l.q / 1e6, 2)                                                AS units_million,
  ROUND(l.landed_per_unit, 2)                                        AS landed_per_unit,
  ROUND(l.landed_per_unit - cn.landed_per_unit, 2)                   AS premium_per_unit,
  ROUND((l.landed_per_unit - cn.landed_per_unit) * l.q / 1e6, 1)     AS premium_total_musd
FROM landed l
CROSS JOIN (SELECT landed_per_unit FROM landed WHERE country = 'China') cn
WHERE l.v > 10e6
ORDER BY premium_total_musd DESC;
