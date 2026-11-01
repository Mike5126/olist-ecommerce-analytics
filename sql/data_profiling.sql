create database ecommerce_db

create schema if not exists raw;
create schema if not exists staging;
create schema if not exists mart;

--ecommerce_db	public

--category_translation
--customers
--geolocation
--order_items
--orders
--payments
--products
--reviews
--sellers
-- Check database and tables
select current_database() as database_name, current_schema() as current_schema;

select table_name
from information_schema.tables
where table_schema = 'raw'
order by table_name;

--category_translation	71
--customers	99441
--geolocation	1000163
--order_items	112650
--orders	99441
--payments	103886
--products	32951
--reviews	99224
--sellers	3095
-- 01. Check csv record counts
select 'orders' as table_name, count(*) as total_rows from raw.orders
union all select 'order_items', count(*) from raw.order_items
union all select 'customers', count(*) from raw.customers
union all select 'products', count(*) from raw.products
union all select 'sellers', count(*) from raw.sellers
union all select 'payments', count(*) from raw.payments
union all select 'reviews', count(*) from raw.reviews
union all select 'geolocation', count(*) from raw.geolocation
union all select 'category_translation', count(*) from raw.category_translation
order by table_name;

--delivered	96478
--shipped	1107
--canceled	625
--unavailable	609
--invoiced	314
--processing	301
--created	5
--approved	2
-- 02. Check order status distribution
select order_status, count(*) as total_orders
from raw.orders
group by order_status
order by total_orders desc;

--shipped	1107	1107	100.00
--unavailable	609	609	100.00
--invoiced	314	314	100.00
--created	5	5	100.00
--approved	2	2	100.00
--processing	301	301	100.00
--canceled	625	619	99.04
--delivered	96478	8	0.01
-- 03. Check missing delivery dates by status
select
    order_status,
    count(*) as total_orders,
    count(*) filter (where nullif(trim(order_delivered_customer_date), '') is null) as missing_delivery_dates,
    round(100.0 * count(*) filter (where nullif(trim(order_delivered_customer_date), '') is null) / nullif(count(*), 0), 2) as missing_percentage
from raw.orders
group by order_status
order by missing_percentage desc;


-- 04. Check duplicate customers 
select customer_id, count(*) as occurrences
from raw.customers
group by customer_id
having count(*) > 1
order by occurrences desc;


-- 05. Check duplicate identifier 
select 'orders.order_id' as key_name, order_id as key_value, count(*) as occurrences from raw.orders group by order_id having count(*) > 1
union all select 'products.product_id', product_id, count(*) from raw.products group by product_id having count(*) > 1 
union all select 'sellers.seller_id', seller_id, count(*) from raw.sellers group by seller_id having count(*) > 1 
union all select 'order_items.(order_id,order_item_id)', concat_ws(' | ', order_id, order_item_id), count(*) from raw.order_items
group by order_id, order_item_id
having count(*) > 1
order by key_name, occurrences desc;

--customers.customer_id	0
--customers.customer_unique_id	0
--order_items.order_id	0
--order_items.order_item_id	0
--order_items.product_id	0
--order_items.seller_id	0
--orders.customer_id	0
--orders.order_id	0
--payments.order_id	0
--products.product_id	0
--reviews.order_id	0
--sellers.seller_id	0
-- 06. check null / blank required identifiers
select 'orders.order_id' as field, count(*) as missing_row 
from raw.orders 
where nullif(trim(order_id), '') is null

union all 

select 'orders.customer_id', count(*) 
from raw.orders 
where nullif(trim(customer_id), '') is null

union all 

select 'customers.customer_id', count(*) 
from raw.customers 
where nullif(trim(customer_id), '') is null

union all 

select 'customers.customer_unique_id', count(*) 
from raw.customers 
where nullif(trim(customer_unique_id), '') is null

union all 

select 'order_items.order_id', count(*) 
from raw.order_items 
where nullif(trim(order_id), '') is null

union all 

select 'order_items.order_item_id', count(*) 
from raw.order_items 
where order_item_id is null

union all 

select 'order_items.product_id', count(*) 
from raw.order_items 
where nullif(trim(product_id), '') is null

union all 

select 'order_items.seller_id', count(*) 
from raw.order_items 
where nullif(trim(seller_id), '') is null

union all 

select 'products.product_id', count(*) 
from raw.products 
where nullif(trim(product_id), '') is null

union all 

select 'sellers.seller_id', count(*) 
from raw.sellers 
where nullif(trim(seller_id), '') is null

union all 

select 'payments.order_id', count(*) 
from raw.payments 
where nullif(trim(order_id), '') is null

union all 

select 'reviews.order_id', count(*) 
from raw.reviews 
where nullif(trim(order_id), '') is null

order by field;

--order_items -> orders	0
--order_items -> products	0
--order_items -> sellers	0
--orders -> customers	0
--payments -> orders	0
--reviews -> orders	0
-- 07. referential integrity: orphan child records
select 'orders -> customers' as relationship, count(*) as orphan_rows
from raw.orders o left join raw.customers c on o.customer_id = c.customer_id
where c.customer_id is null

union all 

select 'order_items -> orders', count(*)
from raw.order_items oi left join raw.orders o on oi.order_id = o.order_id
where o.order_id is null

union all 

select 'order_items -> products', count(*)
from raw.order_items oi left join raw.products p on oi.product_id = p.product_id
where p.product_id is null

union all 

select 'order_items -> sellers', count(*)
from raw.order_items oi left join raw.sellers s on oi.seller_id = s.seller_id
where s.seller_id is null

union all 

select 'payments -> orders', count(*)
from raw.payments pay left join raw.orders o on pay.order_id = o.order_id
where o.order_id is null

union all 

select 'reviews -> orders', count(*)
from raw.reviews r left join raw.orders o on r.order_id = o.order_id
where o.order_id is null

order by relationship;


--order_items.freight_value	0
--order_items.price	0
--orders.order_estimated_delivery_date	0
--orders.order_purchase_timestamp	0
--payments.payment_value	0
--products.product_category_name	610
--reviews.review_score	0
-- 08. missing values in important business columns
select 'orders.order_purchase_timestamp' as field, count(*) as missing_rows
from raw.orders 
where order_purchase_timestamp is null

union all 

select 'orders.order_estimated_delivery_date', count(*)
from raw.orders 
where order_estimated_delivery_date is null

union all 

select 'order_items.price', count(*)
from raw.order_items 
where price is null

union all 

select 'order_items.freight_value', count(*)
from raw.order_items 
where freight_value is null

union all 

select 'payments.payment_value', count(*)
from raw.payments 
where payment_value is null

union all 

select 'reviews.review_score', count(*)
from raw.reviews 
where review_score is null

union all 

select 'products.product_category_name', count(*)
from raw.products 
where nullif(trim(product_category_name), '') is null

order by field;

--order_items.freight_value	112650	0	0	383
--order_items.price	112650	0	0	0
--payments.payment_value	103886	0	0	9
-- 09. Check invalid numeric values
with numbers as (
    select 'order_items.price' as field, price as value
    from raw.order_items

    union all select 'order_items.freight_value', freight_value
    from raw.order_items

    union all select 'payments.payment_value', payment_value
    from raw.payments
)

select
    field,
    count(*) as total_rows,
    count(*) filter (where value is null) as missing_values,
    count(*) filter (where value < 0) as negative_values,
    count(*) filter (where value = 0) as zero_values
from numbers
group by field
order by field;


--99224	0
-- 10. Check invalid review scores (expected range: 1 to 5)
select
    count(*) as total_reviews,
    count(*) filter(where review_score is not null and review_score not between 1 and 5) as invalid_review_scores
from raw.reviews;

--0d3268bad9b086af767785e3f0fc0133	4f1d63d35fb7c8999853b2699f5c7649	delivered	2018-07-01 21:14:02	2018-07-03 09:28:00		2018-07-24 00:00:00
--20edc82cf5400ce95e1afacc25798b31	28c37425f1127d887d7337f284080a0f	delivered	2018-06-27 16:09:12	2018-07-03 19:26:00		2018-07-19 00:00:00
--2d1e2d5bf4dc7227b3bfebb81328c15f	ec05a6d8558c6455f0cbbd8a420ad34f	delivered	2017-11-28 17:44:07	2017-11-30 18:12:23		2017-12-18 00:00:00
--2d858f451373b04fb5c984a1cc2defaf	e08caf668d499a6d643dafd7c5cc498a	delivered	2017-05-25 23:22:43			2017-06-23 00:00:00
--2ebdfc4f15f23b91474edf87475f108e	29f0540231702fda0cfdee0a310f11aa	delivered	2018-07-01 17:05:11	2018-07-03 13:57:00		2018-07-30 00:00:00
--ab7c89dc1bf4a1ead9d6ec1ec8968a84	dd1b84a7286eb4524d52af4256c0ba24	delivered	2018-06-08 12:09:39	2018-06-12 14:10:00		2018-06-26 00:00:00
--e69f75a717d64fc5ecdfae42b2e8e086	cfda40ca8dd0a5d486a9635b611b398a	delivered	2018-07-01 22:05:55	2018-07-03 13:57:00		2018-07-30 00:00:00
--f5dd62b788049ad9fc0526e3ad11a097	5e89028e024b381dc84a13a3570decb4	delivered	2018-06-20 06:58:43	2018-06-25 08:05:00		2018-07-16 00:00:00
-- 11. Investigate delivered orders without actual delivery date
select
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
from raw.orders
where order_status = 'delivered' and nullif(trim(order_delivered_customer_date), '') is null
order by order_id;

--1950d777989f6a877539f53795b4c3c3	1bccb206de9f0f25adc6871a1bcf77b2	canceled	2018-02-19 19:48:52	2018-03-21 22:03:51
--2c45c33d2f9cb8ff8b1c86cc28c11c30	de4caa97afa80c8eeac2ff4c8da5b72e	canceled	2016-10-09 15:39:56	2016-11-09 14:53:50
--65d1e226dfaeb8cdc42f665422522d14	70fc57eeae292675927697fe03ad3ff5	canceled	2016-10-03 21:01:41	2016-11-08 10:58:34
--770d331c84e5b214bd9dc70a10b829d0	6c57e6119369185e575b36712766b0ef	canceled	2016-10-07 14:52:30	2016-10-14 15:07:11
--8beb59392e21af5eb9547ae1a9938d06	bf609b5741f71697f65ce3852c5d2623	canceled	2016-10-08 20:17:50	2016-10-19 18:47:43
--dabf2b0e35b423f94618bf965fcb7514	5cdec0bb8cbdf53ffc8fdc212cd247c6	canceled	2016-10-09 00:56:52	2016-10-16 14:36:59
-- 12. Investigate canceled orders with a delivery date
select
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date
from raw.orders
where order_status = 'canceled' and nullif(trim(order_delivered_customer_date), '') is not null
order by order_id;

--99441	0	0
-- 13. Check order date consistency: timestamp format validation
select column_name, data_type
from information_schema.columns
where table_schema = 'raw'
  and table_name = 'orders'
  and column_name in ('order_purchase_timestamp', 'order_delivered_customer_date');


select
    count(*) as total_orders,
    count(*) filter (
        where nullif(btrim(order_purchase_timestamp), '') is not null
          and trim(order_purchase_timestamp) !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') as invalid_purchase_timestamp_format,

    count(*) filter (
        where nullif(btrim(order_delivered_customer_date), '') is not null
          and trim(order_delivered_customer_date) !~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') as invalid_delivered_timestamp_format
from raw.orders;

--0
-- 14. Check date chronology: delivered before purchase
with parsed as (
    select
        order_id,
        order_status,

        case
            when trim(order_purchase_timestamp) ~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'
             and to_char(
                    to_timestamp(
                        order_purchase_timestamp, 'yyyy-mm-dd hh24:mi:ss'), 'yyyy-mm-dd hh24:mi:ss') = trim(order_purchase_timestamp)
            then to_timestamp(
                order_purchase_timestamp, 'yyyy-mm-dd hh24:mi:ss') end as purchased_at,

        case
            when trim(order_delivered_customer_date) ~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'
             and to_char(
                    to_timestamp(
                        order_delivered_customer_date, 'yyyy-mm-dd hh24:mi:ss'), 'yyyy-mm-dd hh24:mi:ss') = trim(order_delivered_customer_date)
            then to_timestamp(
                order_delivered_customer_date, 'yyyy-mm-dd hh24:mi:ss') end as delivered_at
    from raw.orders
)

select
    count(*) as delivered_before_purchase
from parsed
where purchased_at is not null
  and delivered_at is not null
  and delivered_at < purchased_at;

--portateis_cozinha_e_preparadores_de_alimentos	10
--pc_gamer	3
-- 15. Check category translation coverage
select p.product_category_name, count(*) as total_products
from raw.products p
left join raw.category_translation t
    on p.product_category_name = t.product_category_name
where nullif(trim(p.product_category_name), '') is not null and t.product_category_name is null
group by p.product_category_name
order by total_products desc;


