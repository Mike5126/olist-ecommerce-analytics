# Data Validation Report

**Project:** Olist E-Commerce Analytics  
**Database:** PostgreSQL (`ecommerce_db`)  
**Data layer:** `mart`  
**Reporting tool:** Power BI Desktop  
**Validation scope:** Dashboard KPI totals under the unfiltered / **All** selection  
**Currency:** BRL (Brazilian real)

---

## 1. Objective

This report validates the principal KPI totals displayed in the four-page Olist E-Commerce Power BI report against independently executed SQL queries in PostgreSQL. The goal is to confirm consistent metric definitions across the data mart and the BI layer, document exclusions, and record the remaining validation work.

## 2. Data Sources and Scope

The following PostgreSQL tables and view were used for KPI reconciliation:

| Data source | Purpose |
|---|---|
| `mart.fact_orders` | Order counts, delivery status, on-time/late indicators, delivery durations |
| `mart.fact_order_items` | Delivered product sales and seller participation |
| `mart.dim_sellers` | Total seller population |
| `mart.customer_order_activity` | Customer activity for delivered orders and repeat-purchase measures |

The Power BI report comprises **Executive Overview**, **Customer Analytics**, **Delivery Performance**, and **Seller Performance**.

**Scope distinction:** The checks below reconcile **overall totals**, with slicers reset to **All**. Detailed chart values, filter combinations, map geography, and time-dependent behavior were not independently reconciled in this report. A `PASS` therefore applies only to the KPI and scope shown in the relevant row.

## 3. Validation Methodology

1. Execute SQL validation queries in PostgreSQL against the `mart` layer.
2. Compare the SQL outputs to their corresponding Power BI DAX measures or displayed KPI Cards.
3. Account for display formatting (e.g., `13.22M` and `4.27K`) and rounded percentages.
4. Record metric definitions, data exclusions, and unresolved validation requirements.

**Result convention:** `PASS` indicates agreement at the precision visible on the dashboard; `PASS (display rounded)` indicates that the underlying SQL result agrees with the dashboard's abbreviated or rounded presentation. This is not a direct comparison of unrounded internal DAX values.

## 4. Executive Overview Validation

**Metric scope:** All orders for order-count measures; only `delivered` orders for product-sales measures. Product sales exclude freight charges and are assigned to purchase dates in the sales analysis.

| KPI | PostgreSQL result | Power BI display | Validation |
|---|---:|---:|---|
| Total Orders | 99,441 | 99,441 | PASS |
| Delivered Orders | 96,478 | 96,478 | PASS |
| Delivered Product Sales | BRL 13,221,498.11 | BRL 13.22M | PASS (display rounded) |
| Average Order Value (AOV) | BRL 137.04 | BRL 137.04 | PASS |

**Key definitions:**

- **Total Orders:** `count(*)` from `mart.fact_orders`.
- **Delivered Orders:** Order count where `order_status = 'delivered'`.
- **Delivered Product Sales:** `sum(delivered_item_sales)` from `mart.fact_order_items`, excluding freight.
- **AOV:** Delivered Product Sales divided by Delivered Orders. This is an overall delivered-order measure; product- or seller-level filtering requires a compatible order-count denominator.

## 5. Customer Analytics Validation

**Metric scope:** `mart.customer_order_activity`, containing delivered orders and uniquely identified customers. A repeat customer has **at least two distinct delivered orders** in the selected analysis scope.

| KPI | PostgreSQL result | Power BI display | Validation |
|---|---:|---:|---|
| Active Customers | 93,358 | 93,358 | PASS |
| Repeat Customers | 2,801 | 2,801 | PASS |
| Average Orders per Customer | 1.03 | 1.03 | PASS |
| Repeat Customer Rate | 3.00% | 3.00% | PASS |

**Key definitions:**

- **Active Customers:** `count(distinct customer_unique_id)` from `mart.customer_order_activity`.
- **Repeat Customers:** Number of `customer_unique_id` values associated with at least two distinct `order_id` values.
- **Average Orders per Customer:** Distinct delivered orders divided by distinct active customers.
- **Repeat Customer Rate:** Repeat Customers divided by Active Customers, multiplied by 100.

**Not yet reconciled:** The displayed **Avg. Days Between Orders** KPI, and the New vs. Returning Customers chart's per-month classifications and totals, require separate independent SQL checks. *Repeat Customers* (two or more orders within scope) and *Returning Customers* (customers purchasing in a later month than their first delivered-order month) are different metrics and must not be interchanged.

## 6. Delivery Performance Validation

**Eligible delivery records:** Orders with `order_status = 'delivered'`, a non-null actual delivery timestamp, and a non-null delivery-duration value. Delivery-duration averages and medians additionally require `delivery_days >= 0`.

| KPI | PostgreSQL result | Power BI display | Validation |
|---|---:|---:|---|
| On-Time Orders | 89,936 | Used in rate measures | SQL count confirmed |
| Late Orders | 6,534 | 6,534 | PASS |
| On-Time Delivery Rate | 93.23% | 93.2% | PASS (display rounded) |
| Late Delivery Rate | 6.77% | 6.8% | PASS (display rounded) |
| Average Delivery Days | 12.50 days | 12.5 days | PASS |
| Median Delivery Days | 10.00 days | 10.0 days | PASS |

**Reconciliation:**

| Check | Count |
|---|---:|
| Delivered orders | 96,478 |
| On-time + late orders with valid delivery dates | 96,470 |
| Delivered orders omitted from delivery-timing KPIs | 8 |

The eight excluded orders are consistent with the previously identified `delivered` orders lacking an actual delivery date. On-time and late rates use the 96,470 evaluable deliveries as the denominator. They must not be calculated over all 99,441 orders or over all 96,478 delivered orders without an explicit missing-date policy.

**Monthly trend caveat:** SQL confirmed that September 2016 has only **one** delivered order, with a delivery duration of **55 days**. That month's average (55.00 days) is valid mathematically but not representative. A chart-level minimum sample-size rule (e.g., at least 30 delivered orders) should be disclosed if applied.

**Date-coverage caveat:** September 2018 had **16 total orders and zero delivered orders**; October 2018 had **4 total orders and zero delivered orders**. A monthly delivered-sales or delivery-duration trend ending in August 2018 should state the chosen time range, while the original records remain in the database.

## 7. Seller Performance Validation

**Metric scope:** Seller population from `mart.dim_sellers`; sales and active seller participation from delivered-order items in `mart.fact_order_items`.

| KPI | PostgreSQL result | Power BI display | Validation |
|---|---:|---:|---|
| Total Sellers | 3,095 | 3,095 | PASS |
| Active Sellers | 2,970 | 2,970 | PASS |
| Delivered Product Sales | BRL 13,221,498.11 | BRL 13.22M | PASS (display rounded) |
| Average Sales per Seller | BRL 4,271.89 | BRL 4.27K | PASS (display rounded) |
| Active Seller Rate | 95.96% | 96.0% | PASS (display rounded) |

**Key definitions:**

- **Total Sellers:** `count(distinct seller_id)` from `mart.dim_sellers`.
- **Active Sellers:** Distinct sellers with at least one order item from a `delivered` order.
- **Average Sales per Seller:** Delivered Product Sales divided by **all** 3,095 sellers, including sellers with no delivered-order sales.
- **Active Seller Rate:** Active Sellers divided by Total Sellers.

**Interpretation note:** Average Sales per Seller is **not** the same as Average Sales per *Active* Seller; the latter would use 2,970 as its denominator.

## 8. Data Quality Findings and Reporting Decisions

| Finding | Evidence | Treatment / implication |
|---|---|---|
| Eight delivered orders lack a delivery timestamp | 96,478 delivered vs. 96,470 eligible for timing metrics | Exclude from on-time/late and duration calculations; disclose denominator |
| Very limited final-month coverage | September 2018: 16 orders, 0 delivered; October 2018: 4 orders, 0 delivered | Do not interpret zero delivered-product sales as proof of a business collapse; disclose visualization range |
| Sparse first month for delivery-time analysis | September 2016: one eligible order, 55 delivery days | Disclose sample size; consider minimum monthly count for trends |
| KPI presentation uses rounded values | Sales in millions, seller averages in thousands, rates to one decimal | Compare at the stated display precision; retain precise SQL results in documentation |
| Customer repeat and monthly returning concepts differ | 2,801 repeat customers by order count; monthly returning customers by historical month | Keep definitions distinct in chart labels, DAX, and commentary |

## 9. Validation Limitations and Follow-up Tests

The following tasks remain outside the evidence supplied for this report:

1. **Slicer validation:** Compare SQL and DAX under combinations of Year, Customer State, Seller State, and Order Status; verify intended visual interactions.
2. **Visual detail validation:** Reconcile monthly trends, category rankings, top sellers, seller order-volume bins, geographic totals, and the delivery-day distribution against independent SQL.
3. **Customer retention measures:** Validate the Average Days Between Orders metric, first-purchase/returning-customer classification, and any time-filter policy.
4. **Map and model controls:** Confirm Shape Map keys match state names, and verify dimension-to-fact filter paths do not cause missing or double-counted results.
5. **Precision check:** Where required, inspect Power BI values at full numeric precision rather than relying only on abbreviated Card displays.

## 10. Conclusion

The PostgreSQL query outputs supplied for the four Power BI pages agree with the dashboard's displayed **overall KPI totals** at their shown precision. Executive Overview, Customer Analytics, Delivery Performance, and Seller Performance have therefore passed **summary-level KPI reconciliation**.

This is **not yet a full end-to-end certification** of every slicer interaction, chart value, and derived customer metric. Those items are explicitly listed as follow-up tests. The main documented data-quality exception is the set of eight delivered orders without a delivery timestamp, which is correctly excluded from delivery-timing calculations.

**Recommended next deliverable:** `docs/business_insights_report.md`, using validated KPI definitions and separately verified time-series, customer, delivery, and seller analyses.
