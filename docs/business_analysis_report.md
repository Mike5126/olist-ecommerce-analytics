# Business Analysis Report

## Scope

This report summarizes results of six SQL business analyses on the Olist E-Commerce Analytics `mart` schema: monthly sales, product categories, repeat customers, delivery performance, RFM segmentation, and sellers. Reported figures come from the actual query outputs recorded in the supplied SQL files. Long row-level results are condensed into selected measures and tables.

**Metric definition:** Delivered product sales = sum of `price` for order items belonging to orders with status `delivered`, excluding freight. Sales are attributed to the purchase month. Values are in the dataset monetary units (BRL), and should not be equated with accounting-recognized revenue.

## 1. Executive summary

| Indicator | Observation |
|---|---:|
| Peak monthly delivered product sales | 987,765.37 (November 2017) |
| Repeat customers | 2,997 of 96,096 (3.12%, calculated from counts) |
| Eligible delivered orders | 96,470 |
| Late orders | 6,534 (6.77%) |
| Average delivery time | 12.50 calendar days |
| RFM-classified customers | 93,358 |
| Largest seller state by product sales | SP: 64.36% |

## 2. Monthly sales performance

The query reports 23 months between September 2016 and August 2018, with no November 2016 result. Early observations have very small sales bases.

| Month | Delivered orders | Product sales | MoM growth |
|---|---:|---:|---:|
| 2016-09 | 1 | 134.97 | N/A |
| 2016-10 | 265 | 40,325.11 | 29777.09% |
| 2016-12 | 1 | 10.90 | N/A |
| 2017-01 | 750 | 111,798.36 | 1025573.03% |
| 2017-02 | 1,653 | 234,223.40 | 109.51% |
| 2017-03 | 2,546 | 359,198.85 | 53.36% |
| 2017-04 | 2,303 | 340,669.68 | -5.16% |
| 2017-05 | 3,546 | 489,338.25 | 43.64% |
| 2017-06 | 3,135 | 421,923.37 | -13.78% |
| 2017-07 | 3,872 | 481,604.52 | 14.15% |
| 2017-08 | 4,193 | 554,699.70 | 15.18% |
| 2017-09 | 4,150 | 607,399.67 | 9.50% |
| 2017-10 | 4,478 | 648,247.65 | 6.73% |
| 2017-11 | 7,289 | 987,765.37 | 52.37% |
| 2017-12 | 5,513 | 726,033.19 | -26.50% |
| 2018-01 | 7,069 | 924,645.00 | 27.36% |
| 2018-02 | 6,555 | 826,437.13 | -10.62% |
| 2018-03 | 7,003 | 953,356.25 | 15.36% |
| 2018-04 | 6,798 | 973,534.09 | 2.12% |
| 2018-05 | 6,749 | 977,544.69 | 0.41% |
| 2018-06 | 6,099 | 856,077.86 | -12.43% |
| 2018-07 | 6,159 | 867,953.46 | 1.39% |
| 2018-08 | 6,351 | 838,576.64 | -3.38% |

### Key findings

1. November 2017 had the highest observed monthly delivered product sales (**987,765.37**), a **52.37%** increase from October; December then declined **26.50%**.
2. May 2018 reached **977,544.69**, slightly above April 2018 (**973,534.09**); August 2018 was **838,576.64**.
3. Very large early percentage changes reflect small bases. MoM is intentionally undefined in the query if the previous observed row is not the preceding calendar month.

## 3. Product category performance

### Top 10 categories by delivered product sales

| Category | Items | Orders | Product sales | Sales share |
|---|---:|---:|---:|---:|
| `health_beauty` | 9,465 | 8,647 | 1,233,131.72 | 9.33% |
| `watches_gifts` | 5,859 | 5,495 | 1,166,176.98 | 8.82% |
| `bed_bath_table` | 10,953 | 9,272 | 1,023,434.76 | 7.74% |
| `sports_leisure` | 8,431 | 7,530 | 954,852.55 | 7.22% |
| `computers_accessories` | 7,644 | 6,530 | 888,724.61 | 6.72% |
| `furniture_decor` | 8,160 | 6,307 | 711,927.69 | 5.38% |
| `housewares` | 6,795 | 5,743 | 615,628.69 | 4.66% |
| `cool_stuff` | 3,718 | 3,559 | 610,204.10 | 4.62% |
| `auto` | 4,140 | 3,810 | 578,966.65 | 4.38% |
| `toys` | 4,030 | 3,804 | 471,286.48 | 3.56% |

### Key findings

1. `health_beauty` ranks first (**1,233,131.72; 9.33%**), followed by `watches_gifts` (**1,166,176.98; 8.82%**).
2. The ten categories account for about **62.43%** of delivered product sales (sum of rounded percentage shares).
3. `bed_bath_table` has the greatest number of items within this top-ten list (10,953) despite ranking third in sales value.

## 4. Repeat customer analysis

| Metric | Count |
|---|---:|
| Unique customers | 96,096 |
| One-time customers | 93,099 |
| Repeat customers | 2,997 |
| Repeat rate, recomputed from counts | 3.12% |

### Frequency distribution

| Distinct orders | Customers |
|---:|---:|
| 1 | 93,099 |
| 2 | 2,745 |
| 3 | 203 |
| 4 | 30 |
| 5 | 8 |
| 6 | 6 |
| 7 | 3 |
| 9 | 1 |
| 17 | 1 |

### Key findings and validation note

1. The majority of customers made one order. The repeat rate derived from the counts is **2,997 / 96,096 = 3.12%**.
2. The provided repeat-customer SQL does **not** filter order status, whereas sales and RFM use delivered orders. Keep these populations distinct in interpretation.
3. The percentage formula in the uploaded query uses integer `100`, which can cause integer-division truncation in PostgreSQL. Use `100.0` before division and rerun the percentage query; the **3.12%** above is recomputed from the observed counts.

## 5. Delivery performance

| Metric | Observation |
|---|---:|
| Eligible delivered orders | 96,470 |
| Late orders | 6,534 |
| On-time or early orders | 89,936 |
| Late delivery rate | 6.77% |
| Average delivery time | 12.50 days |
| Delivered orders without delivery date | 8 |
| Canceled orders with delivery date | 6 |

### Selected customer states

| State | Eligible orders | Late orders | Late rate | Avg delivery days |
|---|---:|---:|---:|---:|
| SP | 40,494 | 1,820 | 4.49% | 8.70 |
| RJ | 12,350 | 1,495 | 12.11% | 15.24 |
| MG | 11,354 | 519 | 4.57% | 11.94 |
| AL | 397 | 85 | 21.41% | 24.50 |
| MA | 717 | 125 | 17.43% | 21.51 |
| CE | 1,279 | 176 | 13.76% | 21.20 |
| RR | 41 | 5 | 12.20% | 29.34 |

### Key findings

1. The late rate across eligible delivered orders is **6.77%**.
2. SP has the largest eligible-order volume (40,494) and a late rate of **4.49%**; RJ has a **12.11%** rate across 12,350 orders.
3. AL has a **21.41%** late rate across 397 orders. RR has **29.34** average delivery days but only 41 eligible orders; smaller samples merit caution.
4. Eight delivered orders lack actual delivery dates, while six canceled orders have actual delivery dates. Retain these anomalies for investigation and metric-specific handling.

## 6. RFM customer segmentation

RFM uses delivered orders only. The snapshot date is one day after the latest qualifying purchase. Monetary excludes freight; segment rules use R and F scores, while M is calculated but is not included in segment assignment.

| Segment | Customers | Share |
|---|---:|---:|
| loyal customers | 18,792 | 20.13% |
| hibernating | 15,050 | 16.12% |
| recent customers | 14,955 | 16.02% |
| champions | 14,928 | 15.99% |
| at risk | 14,826 | 15.88% |
| potential loyalists | 14,807 | 15.86% |
| **Total** | **93,358** | **100.00%** |

### Key findings and limitations

1. `loyal customers` is the largest rule-assigned segment (18,792 customers). These labels reflect the code-defined scoring rules rather than externally validated customer behavior.
2. The provided SQL output has segment customer counts but **no monetary totals by segment**; monetary-contribution claims require a separate aggregation.
3. `ntile(5)` can give different F scores to customers tied on Frequency. Since many Olist customers purchase only once, tie-consistent business thresholds should be assessed before making marketing recommendations.
4. The RFM population differs from the repeat-customer population because it is delivered-only.

## 7. Seller performance

### Top 10 sellers by delivered product sales

| Seller ID | City | State | Orders | Items | Product sales |
|---|---|---|---:|---:|---:|
| `4869f7a5dfa277a7dca6462dcf3b52b2` | guariba | SP | 1,124 | 1,148 | 226,987.93 |
| `53243585a1d6dc2643021fd1853d8905` | lauro de freitas | BA | 348 | 400 | 217,940.44 |
| `4a3ca9315b744ce9f8e9374361493884` | ibitinga | SP | 1,772 | 1,949 | 196,882.12 |
| `fa1c13f2614d7b5c4749cbc52fecda94` | sumare | SP | 578 | 579 | 190,917.14 |
| `7c67e1448b00f6e969d365cea6b010ab` | itaquaquecetuba | SP | 973 | 1,355 | 186,570.05 |
| `7e93a43ef30c4f03f38b393420bc753a` | barueri | SP | 319 | 322 | 165,981.49 |
| `da8622b14eb17ae2831f4ac5b9dab84a` | piracicaba | SP | 1,311 | 1,548 | 159,816.87 |
| `7a67c85e85bb2ce8582c35f2203ad736` | sao paulo | SP | 1,145 | 1,155 | 139,658.69 |
| `1025f0e2d44d7041d6cf58b6550e0bfa` | sao paulo | SP | 910 | 1,420 | 138,208.56 |
| `955fee9216a65b617aa5c0531780ce60` | sao paulo | SP | 1,261 | 1,472 | 131,836.71 |

### Leading seller states

| State | Active sellers | Product sales | Share |
|---|---:|---:|---:|
| SP | 1,769 | 8,509,511.46 | 64.36% |
| PR | 335 | 1,232,096.99 | 9.32% |
| MG | 236 | 977,866.31 | 7.40% |
| RJ | 163 | 820,611.59 | 6.21% |
| SC | 184 | 613,591.65 | 4.64% |
| RS | 125 | 373,412.08 | 2.82% |
| BA | 18 | 277,925.51 | 2.10% |

### Selected monthly seller activity

| Month | Active sellers | Orders | Product sales |
|---|---:|---:|---:|
| 2017-01 | 219 | 750 | 111,798.36 |
| 2017-11 | 937 | 7,289 | 987,765.37 |
| 2018-01 | 956 | 7,069 | 924,645.00 |
| 2018-04 | 1,105 | 6,798 | 973,534.09 |
| 2018-05 | 1,105 | 6,749 | 977,544.69 |
| 2018-08 | 1,261 | 6,351 | 838,576.64 |

### Key findings

1. The highest-selling seller in the supplied Top 10 list is in **Guariba, SP**, with **226,987.93** delivered product sales.
2. The seller state **SP** contributes **8,509,511.46**, representing **64.36%** of seller-state product sales in the query output.
3. Active sellers increase from **219 in January 2017** to **1,261 in August 2018** in the monthly results. This is an observed association, not evidence of a specific cause.
4. Monthly Top 5 seller rankings are retained in the SQL for drill-down instead of being copied into this report. Seller state is different from the customer destination state.

## 8. Key findings and proposed handling

1. **Sales trends:** Examine the November 2017 peak and subsequent decrease using additional business context before inferring the drivers.
2. **Category concentration:** Monitor leading categories using both sales value and number of items to distinguish price effects from volume.
3. **Repeat purchase:** Recalculate repeat rates using a documented eligible-order population and correct percentage arithmetic in SQL.
4. **Delivery:** Investigate geographic differences and preserve anomaly records; report late-delivery rates only for eligible orders.
5. **RFM:** Prefer tie-consistent Frequency scoring and aggregate Monetary by segment before suggesting segment-specific spend strategies.
6. **Sellers:** Monitor the geographic concentration in SP and use the monthly activity series to examine seller participation.

## 9. Analysis limitations

Different queries operate at different grains and use different eligible populations. Monthly sales are attributed to purchase month, while delivery metrics require valid actual and estimated dates. Early months have sparse data. RFM is rank-based and does not yet include a spending-by-segment output. Seller-state and customer-state analyses describe different geographical perspectives. Observed associations are not causal findings.

## 10. Conclusion

The six SQL analyses provide a compact and reproducible view of sales, product performance, customer repeats, delivery operations, RFM segments, and sellers. The business findings can inform Power BI dashboard design after the noted consistency and validation issues are addressed.
