-- =====================================================================
-- 02_category_overview.sql
-- Question: How did import value, effective tariff rate, freight share and
--           unit value change by product group and year?
-- Note    : Ratios are computed as SUM / SUM (weighted), never as averages
--           of ratios. 2026 covers Jan-Sep only.
-- =====================================================================

SELECT
  product_group,
  EXTRACT(YEAR FROM month_date)                              AS yr,
  ROUND(SUM(customs_value) / 1e6, 1)                         AS value_musd,
  ROUND(100 * SUM(duties) / SUM(customs_value), 1)           AS eff_tariff_pct,
  ROUND(100 * SUM(freight_charges) / SUM(customs_value), 1)  AS freight_pct,
  ROUND(SUM(customs_value) / SUM(quantity), 2)               AS unit_value_usd
FROM trade.cups_monthly
GROUP BY product_group, yr
ORDER BY product_group, yr;
