# Data Quality Report 

## Scope

This report documents SQL-based profiling of the nine tables in the PostgreSQL `raw` schema for the Olist E-Commerce Analytics project. It describes observed data quality, not data cleaning or pipeline implementation. Empty result sets from exception-list queries are treated as no detected exceptions.

## 1. Dataset inventory

| Table | Rows |
|---|---:|
| category_translation | 71 |
| customers | 99,441 |
| geolocation | 1,000,163 |
| order_items | 112,650 |
| orders | 99,441 |
| payments | 103,886 |
| products | 32,951 |
| reviews | 99,224 |
| sellers | 3,095 |

## 2. Order status distribution

| Status | Orders |
|---|---:|
| delivered | 96,478 |
| shipped | 1,107 |
| canceled | 625 |
| unavailable | 609 |
| invoiced | 314 |
| processing | 301 |
| created | 5 |
| approved | 2 |

## 3. Data quality check results

| Check | Observation | Interpretation |
|---|---|---|
| Duplicate `customer_id` | No rows returned | No duplicates detected for the tested identifier. |
| Duplicate identifiers/composite keys | No rows returned | No duplicates detected for the tested keys. |
| Missing required identifiers | 0 across 12 tested fields | All tested identifier fields are populated. |
| Referential integrity | 0 orphan rows across 6 tested relationships | No broken relationships detected in the tested joins. |
| Missing important business fields | 610 missing `products.product_category_name`; 0 for the other six tested fields | Missing category labels affect product classification. |
| Negative numeric values | 0 in price, freight, and payment | No negative values detected in these fields. |
| Zero numeric values | 383 zero `freight_value`; 9 zero `payment_value`; 0 zero `price` | Zero values need business-context review; they are not automatically invalid. |
| Review score range | 0 scores outside 1–5 among 99,224 reviews | No out-of-range non-null review scores detected. |
| Delivered orders without actual delivery date | 8 orders | Delivery performance metrics cannot use these orders without a valid delivery date. |
| Canceled orders with an actual delivery date | 6 orders | Status/date inconsistency warrants investigation. |
| Timestamp text format | 0 invalid purchase and 0 invalid delivered timestamp formats among 99,441 orders | No formatting exceptions found by the executed pattern check; this is not proof of calendar-date validity. |
| Delivery before purchase | 0 orders | No chronology violations detected by the executed query. |
| Category translation coverage | 2 untranslated categories, affecting 13 products | Category translation requires fallback handling. |

### Missing actual delivery date by status

| Order status | Total orders | Missing delivery dates | Missing % |
|---|---:|---:|---:|
| shipped | 1,107 | 1,107 | 100.00% |
| unavailable | 609 | 609 | 100.00% |
| invoiced | 314 | 314 | 100.00% |
| created | 5 | 5 | 100.00% |
| approved | 2 | 2 | 100.00% |
| processing | 301 | 301 | 100.00% |
| canceled | 625 | 619 | 99.04% |
| delivered | 96,478 | 8 | 0.01% |

Missing delivery dates for orders that are not delivered may be expected; they should not all be classified as data errors.

### Untranslated product categories

| `product_category_name` | Affected products |
|---|---:|
| `portateis_cozinha_e_preparadores_de_alimentos` | 10 |
| `pc_gamer` | 3 |

## 4. Key findings and proposed handling

1. **Missing product categories:** 610 of 32,951 product records have no category value (approximately 1.85%). Preserve the records and use an explicit `unknown` or `uncategorized` label in the staging layer rather than silently dropping them.
2. **Delivery-date inconsistencies:** Investigate the 8 delivered orders with no actual delivery timestamp and the 6 canceled orders with an actual delivery timestamp. Keep the raw values unchanged and define metric-specific exclusion or flagging rules.
3. **Zero freight and payment amounts:** Review 383 zero-freight rows and 9 zero-payment rows before deciding whether any are anomalies. Zero can be legitimate under some business circumstances.
4. **Untranslated categories:** Map the two unmatched categories if a verified translation is available, or preserve their original names and flag them for downstream reporting.
5. **Identifiers and joins:** The tested required IDs, uniqueness constraints, and foreign-key-like relationships show no detected exceptions.
6. **Dates:** The reported format and chronology checks returned zero exceptions. Confirm data types and perform robust parsing in staging before relying on these fields for time-based KPIs.
