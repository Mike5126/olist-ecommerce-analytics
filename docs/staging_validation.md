# Staging Validation Report

## Scope

This report documents SQL-based validation of the eight tables created in the PostgreSQL `staging` schema for the Olist E-Commerce Analytics project. It covers row-count reconciliation, data type conversion, category normalization, and selected data-quality checks performed after running `sql/01_staging.sql`. The original data remains in the `raw` schema. Results are based on the supplied Step 7 SQL outputs; checks without recorded output are identified as unconfirmed.

## 1. Staging table inventory

| Table | Raw rows | Staging rows | Difference | Status |
|---|---:|---:|---:|---|
| customers | 99,441 | 99,441 | 0 | PASS |
| geolocation | 1,000,163 | 1,000,163 | 0 | PASS |
| order_items | 112,650 | 112,650 | 0 | PASS |
| orders | 99,441 | 99,441 | 0 | PASS |
| payments | 103,886 | 103,886 | 0 | PASS |
| products | 32,951 | 32,951 | 0 | PASS |
| reviews | 99,224 | 99,224 | 0 | PASS |
| sellers | 3,095 | 3,095 | 0 | PASS |

All eight staging tables match their raw-source row counts. Equal row counts confirm record-count preservation, but do not independently establish value-level accuracy or uniqueness.

## 2. Staging transformations

| Table | Transformation |
|---|---|
| orders | Cast purchase, approval, shipment, actual delivery, and estimated delivery fields to timestamps; rename date columns for analysis. |
| order_items | Convert item sequence to integer, shipping limit to timestamp, and monetary values to `numeric(12, 2)`. |
| customers | Retain identifiers and ZIP code; trim location fields and convert blank strings to null. |
| products | Translate category names where available; fall back to the original name and then `Unknown`; standardize measurement column names and numeric types. |
| sellers | Retain identifiers and ZIP code; normalize city and state fields. |
| payments | Convert payment sequence and installments to integer; cast payment value to `numeric(12, 2)`; normalize payment type. |
| reviews | Convert review scores to integer, review dates to timestamps, and blank comments to null. |
| geolocation | Cast coordinates to `numeric(12, 8)` and normalize city and state fields. |

The `raw.category_translation` table is used to enrich `staging.products`; no separate `staging.category_translation` table is created.

## 3. Validation check results

| Check | Observation | Interpretation |
|---|---|---|
| Row-count reconciliation | All 8 tables match their raw sources | No row-count difference detected. |
| Duplicate `orders.order_id` | No output recorded in the supplied Step 7 notes | Not yet confirmed from Step 7 evidence. |
| Duplicate `products.product_id` | No output recorded in the supplied Step 7 notes | Not yet confirmed from Step 7 evidence. |
| Duplicate `(order_id, order_item_id)` | No output recorded in the supplied Step 7 notes | Not yet confirmed from Step 7 evidence. |
| Data type conversion | Timestamp, integer, and numeric types shown in the staging column metadata | Expected data types observed for the converted columns. |
| Missing product category fallback | 610 `Unknown`; 0 null `category_name` among 32,951 products | The category fallback handles missing source categories without dropping products. |
| Delivered orders without actual delivery date | 8 orders | Preserve the missing dates and account for them in delivery metrics. |
| Canceled orders with actual delivery date | 6 orders | Status/date inconsistency needs business review. |
| Delivery before purchase | 0 orders | No chronology exceptions detected by the executed query. |
| Zero monetary values | 383 zero freight values; 9 zero payments; 0 zero prices | Zero values require business context and are not automatically invalid. |
| Negative monetary values | 0 negative prices, freight values, or payments | No negative values detected in the tested fields. |
| Review score range | 0 values outside 1–5 among 99,224 reviews | No out-of-range scores detected by the executed query. |

### Product category normalization

| Metric | Result |
|---|---:|
| Total staged products | 32,951 |
| `category_name = 'Unknown'` | 610 |
| Null `category_name` | 0 |

The category normalization logic prioritizes the English translation, then the original Portuguese category, then `Unknown`. The prior profiling step identified two untranslated categories covering 13 products; their original names are retained when a translation is unavailable.

### Verified staging data types

| Column | Data type |
|---|---|
| `orders.purchased_at`, `orders.delivered_at`, `orders.shipped_at` | `timestamp without time zone` |
| `order_items.shipping_limit_at` | `timestamp without time zone` |
| `order_items.order_item_id` | `integer` |
| `order_items.price`, `order_items.freight_value` | `numeric` |
| `products.product_name_length`, `reviews.review_score` | `integer` |
| `products.product_weight_g`, `payments.payment_value` | `numeric` |
| `reviews.review_created_at` | `timestamp without time zone` |
| `geolocation.latitude`, `geolocation.longitude` | `numeric` |

The ZIP code prefixes appear as `bigint` in the supplied schema output. When used as location identifiers, leading-zero preservation should be considered.

## 4. Key findings and proposed handling

1. **Row-count preservation:** All eight staging tables reconcile with the raw tables. Confirm duplicate-key checks separately because their Step 7 result sets were not recorded in the supplied notes.
2. **Category handling:** All 32,951 products are retained; 610 products receive `Unknown`, and missing English translations fall back to the original category name.
3. **Delivery-date inconsistencies:** Keep the 8 delivered orders without actual delivery timestamps and the 6 canceled orders with delivery timestamps. Define inclusion and exclusion rules for delivery KPIs.
4. **Zero monetary values:** Preserve 383 zero-freight records and 9 zero-payment records pending business interpretation. No negative values were found in the tested monetary fields.
5. **Date and review validation:** No delivery-before-purchase exceptions or out-of-range review scores were detected in the executed checks.
6. **Downstream modeling:** Define fact-table grain before combining orders, order items, payments, and reviews. Aggregate geolocation by ZIP code before joining it to analytical dimensions to avoid row multiplication.
7. **Schema constraints:** Tables created with `create table as select` do not automatically inherit primary keys, foreign keys, or indexes. Add the required constraints or indexes after validating the intended table grain.
