-- =====================================================================
-- 09_build_dashboard_table.sql
-- Purpose : Dashboard-ready table for Power BI. Adds a region grouping
--           and a price tier parsed from the HTS description.
--
-- Price tier: CASE order matters. "$3 BUT NOT OVER $5" contains the text
--   "OVER $5", so the narrower patterns must be tested first.
-- Region: mapping finalized after reviewing the 'Other' bucket. In the
--   Power BI model the same mapping is applied as a calculated column
--   (see powerbi/dax_measures.md). Remaining 'Other' is <1% of value.
-- =====================================================================

CREATE OR REPLACE TABLE trade.cups_dashboard AS
WITH descriptions AS (
  SELECT hts, ANY_VALUE(description) AS description
  FROM trade.imports_raw
  WHERE hts IS NOT NULL
  GROUP BY hts
)
SELECT
  c.month_date,
  c.country,
  CASE
    WHEN c.country = 'China' THEN 'China'
    WHEN c.country IN ('Vietnam', 'Thailand', 'Malaysia', 'Cambodia', 'Indonesia', 'Philippines')
      THEN 'Southeast Asia'
    WHEN c.country IN ('Mexico', 'Canada') THEN 'USMCA'
    WHEN c.country IN ('Germany', 'Italy', 'France', 'Poland', 'Slovakia', 'Czechia (Czech Republic)',
                       'Spain', 'Portugal', 'Austria', 'Slovenia', 'Romania', 'Hungary', 'Turkey',
                       'Bulgaria', 'Belgium', 'Netherlands', 'United Kingdom', 'Lithuania', 'Latvia',
                       'Estonia', 'Greece', 'Croatia', 'Sweden', 'Denmark', 'Finland', 'Norway',
                       'Ireland', 'Luxembourg', 'Switzerland', 'Serbia', 'Ukraine', 'San Marino')
      THEN 'Europe'
    WHEN c.country IN ('Colombia', 'Brazil', 'Argentina', 'Chile', 'Peru', 'Bolivia', 'Ecuador',
                       'Uruguay', 'Costa Rica', 'Dominican Republic', 'El Salvador', 'Guatemala')
      THEN 'Latin America'
    ELSE 'Other'
  END AS region,
  c.product_group,
  c.hts,
  CASE
    WHEN c.hts = '9617001000' THEN 'Up to 1L'
    WHEN c.hts = '9617003000' THEN '1L to 2L'
    WHEN d.description LIKE '%SPECIALLY TEMPERED%'        THEN 'Tempered'
    WHEN d.description LIKE '%30 CENTS BUT NOT OVER $3%'  THEN '$0.30 to $3'
    WHEN d.description LIKE '%NOT OVER 30 CENTS%'         THEN 'Up to $0.30'
    WHEN d.description LIKE '%$3 BUT NOT OVER $5%'        THEN '$3 to $5'
    WHEN d.description LIKE '%OVER $5%'                   THEN 'Over $5'
    ELSE 'Other'
  END AS price_tier,
  c.customs_value,
  c.duties,
  c.freight_charges,
  c.quantity
FROM trade.cups_monthly c
LEFT JOIN descriptions d
  ON d.hts = c.hts;
