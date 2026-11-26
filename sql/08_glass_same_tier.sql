-- =====================================================================
-- 08_glass_same_tier.sql
-- Question: Within the SAME price tier, which countries land glass
--           tumblers cheapest? (2026 Jan-Sep, $0.30-$3 per unit tier)
-- Method  : HTS 7013.37.20xx codes cover drinking glasses valued over
--           $0.30 but not over $3 each. The 8-digit prefix captures codes
--           that were split during the period (2000 -> 2010 / 2090).
--
-- Bug fix : An earlier version filtered small countries with WHERE before
--           computing SUM(v) OVER (). SQL runs WHERE before window
--           functions, so ~$14M from smaller countries (~10% of the tier)
--           dropped out of the denominator and every share was inflated by
--           ~11%: China 52.4% -> 47.1%, Mexico 33.4% -> 30.0%,
--           Italy 4.8% -> 4.3%, Poland 2.9% -> 2.6%.
--           Caught by cross-checking against the Power BI measure.
--           Fix: compute shares in a CTE first, then filter.
-- =====================================================================

WITH c AS (
  SELECT
    country,
    SUM(customs_value)   AS v,
    SUM(duties)          AS d,
    SUM(freight_charges) AS f,
    SUM(quantity)        AS q
  FROM trade.cups_monthly
  WHERE STARTS_WITH(hts, '70133720')
    AND month_date >= '2026-01-01'
  GROUP BY country
),
shares AS (
  -- Window runs over ALL countries here, before any filtering
  SELECT *, 100 * v / SUM(v) OVER () AS share_pct
  FROM c
)
SELECT
  country,
  ROUND(v / 1e6, 1)                   AS value_musd,
  ROUND(share_pct, 1)                 AS share_pct,
  ROUND(SAFE_DIVIDE(v, q), 2)         AS fob_per_unit,
  ROUND(SAFE_DIVIDE(f, q), 3)         AS freight_per_unit,
  ROUND(SAFE_DIVIDE(d, q), 3)         AS duty_per_unit,
  ROUND(SAFE_DIVIDE(v + f + d, q), 2) AS landed_per_unit
FROM shares
WHERE v > 2e6
ORDER BY value_musd DESC;
