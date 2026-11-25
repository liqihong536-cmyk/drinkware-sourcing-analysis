-- =====================================================================
-- 10_tier_check.sql
-- Purpose : Validate the price-tier parsing. Expect 31 codes in total
--           (2 insulated, 13 stemware, 16 tumblers) and no 'Other'.
-- =====================================================================

SELECT
  product_group,
  price_tier,
  COUNT(DISTINCT hts)                 AS hts_codes,
  ROUND(SUM(customs_value) / 1e6, 1)  AS value_musd
FROM trade.cups_dashboard
GROUP BY product_group, price_tier
ORDER BY product_group, price_tier;
