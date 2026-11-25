-- =====================================================================
-- 06_vietnam_freight_check.sql
-- Question: Vietnam showed ~$0 freight per unit in 2024. Is the freight
--           data missing, or reported but very low?
-- Finding : Every month with imports has a freight record (no missing
--           months), but reported charges are tiny: <0.1% of customs value
--           in 2024, 1.4% in 2025, 2.4% in 2026, vs ~4.5% for China.
--           Likely a reporting practice. Because this understates Vietnam's
--           landed cost, premium estimates in this project are conservative.
-- =====================================================================

SELECT
  EXTRACT(YEAR FROM month_date)                              AS yr,
  ROUND(SUM(customs_value) / 1e6, 1)                         AS value_musd,
  ROUND(SUM(freight_charges) / 1e6, 2)                       AS freight_musd,
  COUNTIF(customs_value > 0)                                 AS months_with_imports,
  COUNTIF(freight_charges = 0 AND customs_value > 0)         AS months_missing_freight
FROM trade.cups_monthly
WHERE country = 'Vietnam'
  AND hts = '9617001000'
GROUP BY yr
ORDER BY yr;
