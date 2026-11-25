# Power BI Model: Measures and Calculated Columns

Semantic model built on `cups_dashboard` (exported from `sql/09_build_dashboard_table.sql`).

**Design rule:** every ratio is a measure computed as *sum ÷ sum*, so results stay correctly weighted at any level of slicing (year, country, region, product, price tier). Ratios are never pre-computed in the data and then averaged.

**Column renames for display:** `product_group` → Product Group, `price_tier` → Price Tier, `country` → Country, `region` → region_raw (hidden). Power BI column names are case-insensitive, so the original `region` column had to be renamed before the cleaned column could be called `Region`.

## Calculated columns

```dax
Year = YEAR(cups_dashboard[month_date])
```

```dax
Region =
SWITCH(
    TRUE(),
    cups_dashboard[Country] IN {"Bulgaria", "Belgium", "Netherlands", "United Kingdom", "Spain",
        "Lithuania", "Latvia", "Estonia", "Greece", "Croatia", "Sweden", "Denmark", "Finland",
        "Norway", "Ireland", "Luxembourg", "Switzerland", "Serbia", "Ukraine", "San Marino"}, "Europe",
    cups_dashboard[Country] IN {"Colombia", "Brazil", "Argentina", "Chile", "Peru", "Bolivia",
        "Ecuador", "Uruguay", "Costa Rica", "Dominican Republic", "El Salvador", "Guatemala"}, "Latin America",
    cups_dashboard[region_raw]
)
```

`SWITCH(TRUE(), ...)` evaluates conditions top to bottom and returns the first match, which reads more cleanly than nested `IF` statements.

## Base measures

```dax
Total Customs Value = SUM(cups_dashboard[customs_value])
Total Duties        = SUM(cups_dashboard[duties])
Total Freight       = SUM(cups_dashboard[freight_charges])
Total Units         = SUM(cups_dashboard[quantity])
```

## Ratios and unit costs

```dax
Effective Tariff %   = DIVIDE([Total Duties], [Total Customs Value])
Freight %            = DIVIDE([Total Freight], [Total Customs Value])
FOB per Unit         = DIVIDE([Total Customs Value], [Total Units])
Freight per Unit     = DIVIDE([Total Freight], [Total Units])
Duty per Unit        = DIVIDE([Total Duties], [Total Units])
Landed Cost per Unit = DIVIDE([Total Customs Value] + [Total Duties] + [Total Freight], [Total Units])
```

`DIVIDE` returns blank instead of an error when the denominator is zero.

## Share and comparison to China

```dax
Import Share % =
DIVIDE(
    [Total Customs Value],
    CALCULATE(
        [Total Customs Value],
        REMOVEFILTERS(cups_dashboard[Country], cups_dashboard[region_raw], cups_dashboard[Region])
    )
)
```

The denominator removes country and region filters but keeps year, product and price-tier filters, so the share is always "of the current product, tier and year". All region columns must be listed: an earlier version only cleared the original region column, so a chart using the cleaned `Region` as its legend divided each region by itself and showed 100% everywhere.

```dax
China Landed Cost = CALCULATE([Landed Cost per Unit], cups_dashboard[Country] = "China")

Premium vs China % = DIVIDE([Landed Cost per Unit] - [China Landed Cost], [China Landed Cost])
```

## Diversification premium

```dax
Diversification Premium $ =
SUMX(
    FILTER(VALUES(cups_dashboard[Country]), cups_dashboard[Country] <> "China"),
    ([Landed Cost per Unit] - [China Landed Cost]) * [Total Units]
)
```

`SUMX` iterates over each non-China country: inside the iteration, `[Landed Cost per Unit]` is evaluated for that country (context transition), while `[China Landed Cost]` overrides the country filter back to China. With Insulated stainless, Up to 1L and 2026 selected, the result is **$66.3M**. The SQL version (`05_diversification_premium.sql`) returns $65.5M because it only includes countries above $10M in customs value.
