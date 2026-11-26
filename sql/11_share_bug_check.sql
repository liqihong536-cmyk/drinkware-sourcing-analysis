-- =====================================================================
-- 11_share_bug_check.sql
-- Purpose : Reproduce the share bug found in the glass same-tier analysis
--           and show buggy vs. corrected shares side by side.
--
-- The bug : Filtering with WHERE v > 2e6 BEFORE computing SUM(v) OVER ()
--           removes small countries from the denominator, because SQL
--           evaluates WHERE before window functions.
--           Logical order: FROM -> WHERE -> GROUP BY -> HAVING ->
--           window functions -> QUALIFY -> ORDER BY
--
-- Result (2026 Jan-Sep, glass tumblers, $0.30-$3 tier):
--   country   value_musd  buggy_share_pct  correct_share_pct
--   China        64.3          52.4              47.1
--   Mexico       41.0          33.4              30.0
--   Italy         5.8           4.8               4.3
--   Germany       5.6           4.6               4.1
--   Poland        3.5           2.9               2.6
--   Colombia      2.5           2.1               1.9
--   The six countries total $122.7M vs. $136.5M for the full tier, so
--   every share was inflated by a factor of ~1.11.
-- =====================================================================

WITH c AS (
  SELECT country, SUM(customs_value) AS v
  FROM trade.cups_monthly
  WHERE STARTS_WITH(hts, '70133720')
    AND month_date >= '2026-01-01'
  GROUP BY country
)
SELECT
  country,
  ROUND(v / 1e6, 1) AS value_musd,
  -- Reproduces the bug: denominator only includes countries above $2M
  ROUND(100 * v / SUM(IF(v > 2e6, v, 0)) OVER (), 1) AS buggy_share_pct,
  -- Correct: denominator includes every country
  ROUND(100 * v / SUM(v) OVER (), 1) AS correct_share_pct
FROM c
WHERE TRUE
QUALIFY v > 2e6  -- QUALIFY runs after window functions, so it filters safely
ORDER BY v DESC;
