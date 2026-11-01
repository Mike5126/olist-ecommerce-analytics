
# Data Mart Validation Report

## Scope

This report documents the design and validation of the Data Mart layer in the Olist E-Commerce Analytics project.

The Data Mart is built from the cleaned and standardized data in the PostgreSQL `staging` schema. It uses a dimensional data model to support sales analysis, customer analysis, product performance, and delivery performance reporting.

The validation focuses on row count consistency, data integrity, financial reconciliation, and business metric calculations.

## 1. Data Mart inventory

The Data Mart contains two fact tables and four dimension tables.

| Table | Type | Grain | Description |
|---|---|---|---|
| fact_orders | Fact | One row per order | Order status, delivery dates, and delivery performance |
| fact_order_items | Fact | One row per order item | Product sales value and freight charges |
| dim_customers | Dimension | One row per customer_id | Customer identifiers and geographical information |
| dim_products | Dimension | One row per product_id | Product attributes and categories |
| dim_sellers | Dimension | One row per seller_id | Seller identifiers and geographical information |
| dim_date | Dimension | One row per date | Calendar attributes for time-based analysis |

The `mart` schema is designed to separate measurable business events from descriptive attributes.

## 2. Row count validation

Row counts were compared between the `staging` and `mart` schemas to verify that the transformation process did not introduce unexpected row loss or duplication.

| Table | Staging rows | Mart rows | Difference | Status |
|---|---:|---:|---:|---|
| orders / fact_orders | 99,441 | 99,441 | 0 | PASS |
| order_items / fact_order_items | 112,650 | 112,650 | 0 | PASS |
| customers / dim_customers | 99,441 | 99,441 | 0 | PASS |
| products / dim_products | 32,951 | 32,951 | 0 | PASS |
| sellers / dim_sellers | 3,095 | 3,095 | 0 | PASS |

All five tested tables have matching row counts.

The `dim_date` table is generated independently using `generate_series()` and contains one row per calendar date between the earliest and latest order purchase dates.

Its row count was not included in the staging-to-mart comparison.

## 3. Data integrity validation

Primary keys and foreign keys were defined to maintain data integrity between fact and dimension tables.

| Check | Observation | Interpretation |
|---|---|---|
| Duplicate `fact_orders.order_id` | Result not explicitly recorded | Duplicate-check query was included, but the result requires confirmation. |
| Duplicate `(order_id, order_item_id)` | Result not explicitly recorded | Composite-key uniqueness requires confirmation. |
| Missing customer references | 0 | No missing customer references detected in `fact_order_items`. |
| Missing product references | 0 | No missing product references detected in `fact_order_items`. |
| Missing seller references | 0 | No missing seller references detected in `fact_order_items`. |
| Primary key constraints | Defined in SQL | Constraints enforce uniqueness and non-null values if successfully created. |
| Foreign key constraints | Defined in SQL | Constraints enforce relationships if successfully created. |

No missing dimension references were detected in the three tested relationships.

The successful creation of primary and foreign key constraints should be confirmed in PostgreSQL before considering constraint validation complete.

## 4. Financial reconciliation

Product prices and freight charges were compared between the staging and Data Mart layers.

| Metric | Staging value | Mart value | Difference | Status |
|---|---:|---:|---:|---|
| Total product price | 13,591,643.70 | 13,591,643.70 | 0.00 | PASS |
| Total freight charges | 2,251,909.54 | 2,251,909.54 | 0.00 | PASS |

Both financial measures match exactly between the two layers.

These results indicate that the tested monetary values were preserved during Data Mart transformation.

The total product price represents the sum of `price` across all order items, regardless of order status.

It should not be interpreted as recognized revenue or completed sales.

The `delivered_item_sales` metric is calculated separately and includes product prices only for orders with the `delivered` status.

## 5. Order status validation

The order status distribution was checked using `mart.fact_orders`.

| Order status | Total orders |
|---|---:|
| delivered | 96,478 |
| shipped | 1,107 |
| canceled | 625 |
| unavailable | 609 |
| invoiced | 314 |
| processing | 301 |
| created | 5 |
| approved | 2 |

The distribution matches the previously reported results from the raw data profiling stage.

This supports consistency between the source order statuses and the Data Mart.

## 6. Delivery performance validation

Delivery performance metrics were calculated from `mart.fact_orders`.

| Metric | Observed value |
|---|---:|
| Total orders | 99,441 |
| Delivered orders | 96,478 |
| Canceled orders | 625 |
| Late deliveries | 6,534 |
| Average delivery days | 12.50 |

The `is_delivered` and `is_canceled` columns are binary indicators derived from `order_status`.

The `is_late` column identifies delivered orders whose actual delivery date is later than the estimated delivery date.

Orders without sufficient delivery information are assigned `NULL` for this indicator.

The `delivery_days` metric measures the calendar-day difference between the purchase date and actual delivery date for eligible delivered orders.

### Delivery performance limitations

The previous data quality assessment identified:

- 8 delivered orders without an actual delivery date.
- 6 canceled orders with an actual delivery date.

These records remain in the dataset.

They should be handled using metric-specific business rules rather than being automatically deleted.

When calculating the late delivery rate, the denominator should include only delivered orders with valid actual and estimated delivery dates.

## 7. Product category analysis

The `fact_order_items` table was joined with `dim_products` to calculate delivered product sales by category.

The following categories recorded the highest delivered product sales in the validation query.

| Product category | Total order items | Delivered product sales |
|---|---:|---:|
| health_beauty | 9,670 | 1,233,131.72 |
| watches_gifts | 5,991 | 1,166,176.98 |
| bed_bath_table | 11,115 | 1,023,434.76 |
| sports_leisure | 8,641 | 954,852.55 |
| computers_accessories | 7,827 | 888,724.61 |
| furniture_decor | 8,334 | 711,927.69 |
| housewares | 6,964 | 615,628.69 |
| cool_stuff | 3,796 | 610,204.10 |
| auto | 4,235 | 578,966.65 |
| toys | 4,117 | 471,286.48 |

The `total_items` column counts all order item rows in each category, regardless of order status.

The `delivered_product_sales` column sums product prices only for orders marked as delivered.

These measures have different business definitions and should not be interpreted as equivalent.

The category `Unknown` remains available for products without a valid category label.

## 8. Monthly sales validation

Monthly sales were calculated by joining `fact_order_items` with `dim_date` using the purchase date.

The query groups transactions by year and month and calculates:

- Total distinct orders with order items.
- Delivered product sales.

The monthly results cover purchase periods from 2016 through 2018.

Selected observations include:

| Year | Month | Orders with items | Delivered product sales |
|---|---:|---:|---:|
| 2017 | 10 | 4,568 | 648,247.65 |
| 2017 | 11 | 7,451 | 987,765.37 |
| 2017 | 12 | 5,624 | 726,033.19 |
| 2018 | 1 | 7,220 | 924,645.00 |
| 2018 | 3 | 7,188 | 953,356.25 |
| 2018 | 5 | 6,853 | 977,544.69 |
| 2018 | 8 | 6,452 | 838,576.64 |

November 2017 recorded the highest delivered product sales among the listed months.

Monthly metrics use the purchase date rather than the actual delivery date.

As a result, delivered product sales are attributed to the month in which the corresponding order was placed.

## 9. Key findings and proposed handling

1. **Row count consistency:** All five tested staging-to-mart table comparisons returned matching row counts. No unexpected row loss or duplication was detected by these count checks.

2. **Financial consistency:** Total product prices and freight charges match exactly between staging and mart, supporting the accuracy of the tested monetary transformations.

3. **Dimension relationships:** No missing customer, product, or seller references were detected in the tested joins.

4. **Order status consistency:** The Data Mart order status distribution matches the previously reported raw data distribution.

5. **Delivery performance:** The model supports delivery time and late delivery analysis. Existing delivery-date inconsistencies require explicit handling in KPI calculations.

6. **Product category performance:** Delivered product sales can be analyzed by category. Missing categories are preserved using the `Unknown` label.

7. **Time-based analysis:** The date dimension supports monthly, quarterly, yearly, and weekday reporting. Its calendar coverage should be reviewed if additional date roles are introduced.

8. **Constraint verification:** Primary key and foreign key definitions are present in the SQL script, but successful execution and duplicate-check results should be confirmed separately.

9. **Metric definitions:** Product prices, freight charges, and delivered product sales represent different financial measures and must remain clearly distinguished in reporting.

## 10. Conclusion

The Data Mart validation results show that the tested transformations preserve row counts and monetary values between the staging and mart layers.

The dimensional model supports order analysis, product performance, customer segmentation, seller analysis, and delivery performance reporting.

The main reconciliation and dimension-reference checks passed.

Duplicate-check outcomes and database constraint execution should be confirmed before declaring all integrity validations complete.

The Data Mart is ready for the next stage of SQL-based business analysis, subject to these remaining verification items and consistent KPI definitions.
