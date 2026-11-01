
-- 00. create staging schema
create schema if not exists staging;


-- 01. staging.orders
drop table if exists staging.orders;

create table staging.orders as
select
    order_id,
    customer_id,
    order_status,
    nullif(trim(order_purchase_timestamp), '')::timestamp as purchased_at,
    nullif(trim(order_approved_at), '')::timestamp as approved_at,
    nullif(trim(order_delivered_carrier_date), '')::timestamp as shipped_at,
    nullif(trim(order_delivered_customer_date), '')::timestamp as delivered_at,
    nullif(trim(order_estimated_delivery_date), '')::timestamp as estimated_delivery_at
from raw.orders;


-- 02. staging.order_items
drop table if exists staging.order_items;

create table staging.order_items as
select
    order_id,
    order_item_id::integer as order_item_id,
    product_id,
    seller_id,
    nullif(trim(shipping_limit_date), '')::timestamp as shipping_limit_at,
    price::numeric(12, 2) as price,
    freight_value::numeric(12, 2) as freight_value
from raw.order_items;


-- 03. staging.customers
drop table if exists staging.customers;

create table staging.customers as
select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    nullif(trim(customer_city), '') as customer_city,
    nullif(trim(customer_state), '') as customer_state
from raw.customers;


-- 04. staging.products
drop table if exists staging.products;

create table staging.products as
select
    p.product_id,
    nullif(trim(p.product_category_name), '') as product_category_name,
    coalesce(
        nullif(trim(t.product_category_name_english), ''),
        nullif(trim(p.product_category_name), ''),
        'Unknown'
    ) as category_name,
    p.product_name_lenght::integer as product_name_length,
    p.product_description_lenght::integer as product_description_length,
    p.product_photos_qty::integer as product_photos_qty,
    p.product_weight_g::numeric(12, 2) as product_weight_g,
    p.product_length_cm::numeric(12, 2) as product_length_cm,
    p.product_height_cm::numeric(12, 2) as product_height_cm,
    p.product_width_cm::numeric(12, 2) as product_width_cm
from raw.products p
left join raw.category_translation t
    on p.product_category_name = t.product_category_name;


-- 05. staging.sellers
drop table if exists staging.sellers;

create table staging.sellers as
select
    seller_id,
    seller_zip_code_prefix,
    nullif(trim(seller_city), '') as seller_city,
    nullif(trim(seller_state), '') as seller_state
from raw.sellers;


-- 06. staging.payments
drop table if exists staging.payments;

create table staging.payments as
select
    order_id,
    payment_sequential::integer as payment_sequential,
    nullif(trim(payment_type), '') as payment_type,
    payment_installments::integer as payment_installments,
    payment_value::numeric(12, 2) as payment_value
from raw.payments;


-- 07. staging.reviews
drop table if exists staging.reviews;

create table staging.reviews as
select
    review_id,
    order_id,
    review_score::integer as review_score,
    nullif(trim(review_comment_title), '') as review_comment_title,
    nullif(trim(review_comment_message), '') as review_comment_message,
    nullif(trim(review_creation_date), '')::timestamp as review_created_at,
    nullif(trim(review_answer_timestamp), '')::timestamp as review_answered_at
from raw.reviews;


-- 08. staging.geolocation
drop table if exists staging.geolocation;

create table staging.geolocation as
select
    geolocation_zip_code_prefix,
    geolocation_lat::numeric(12, 8) as latitude,
    geolocation_lng::numeric(12, 8) as longitude,
    nullif(trim(geolocation_city), '') as city,
    nullif(trim(geolocation_state), '') as state
from raw.geolocation;

--customers	99441	99441	0	pass
--geolocation	1000163	1000163	0	pass
--order_items	112650	112650	0	pass
--orders	99441	99441	0	pass
--payments	103886	103886	0	pass
--products	32951	32951	0	pass
--reviews	99224	99224	0	pass
--sellers	3095	3095	0	pass
-- 09. validation: row count comparison
with row_counts as (
    select
        'orders' as table_name,
        (select count(*) from raw.orders) as raw_count,
        (select count(*) from staging.orders) as staging_count

    union all

    select
        'order_items',
        (select count(*) from raw.order_items),
        (select count(*) from staging.order_items)

    union all

    select
        'customers',
        (select count(*) from raw.customers),
        (select count(*) from staging.customers)

    union all

    select
        'products',
        (select count(*) from raw.products),
        (select count(*) from staging.products)

    union all

    select
        'sellers',
        (select count(*) from raw.sellers),
        (select count(*) from staging.sellers)

    union all

    select
        'payments',
        (select count(*) from raw.payments),
        (select count(*) from staging.payments)

    union all

    select
        'reviews',
        (select count(*) from raw.reviews),
        (select count(*) from staging.reviews)

    union all

    select
        'geolocation',
        (select count(*) from raw.geolocation),
        (select count(*) from staging.geolocation)
)
select
    table_name,
    raw_count,
    staging_count,
    staging_count - raw_count as difference,
    case
        when raw_count = staging_count then 'pass'
        else 'fail'
    end as status
from row_counts
order by table_name;


-- 10. validation: duplicate orders
select
    order_id,
    count(*) as total
from staging.orders
group by order_id
having count(*) > 1;


-- 11. validation: duplicate products
select
    product_id,
    count(*) as total
from staging.products
group by product_id
having count(*) > 1;


-- 12. validation: duplicate order items
select
    order_id,
    order_item_id,
    count(*) as total
from staging.order_items
group by order_id, order_item_id
having count(*) > 1;

--bed_bath_table	3029
--sports_leisure	2867
--furniture_decor	2657
--health_beauty	2444
--housewares	2335
--auto	1900
--computers_accessories	1639
--toys	1411
--watches_gifts	1329
--telephony	1134
--baby	919
--perfumery	868
--stationery	849
--fashion_bags_accessories	849
--cool_stuff	789
--garden_tools	753
--pet_shop	719
--Unknown	610
--electronics	517
--construction_tools_construction	400
--home_appliances	370
--luggage_accessories	349
--consoles_games	317
--office_furniture	309
--musical_instruments	289
--small_appliances	231
--home_construction	225
--books_general_interest	216
--fashion_shoes	173
--furniture_living_room	156
--air_conditioning	124
--books_technical	123
--fixed_telephony	116
--home_confort	111
-- 13. validation: product categories
select
    category_name,
    count(*) as total_products
from staging.products
group by category_name
order by total_products desc;

--32951	610	0
-- 14. validation: missing product categories
select
    count(*) as total_products,
    count(*) filter (
        where category_name = 'Unknown'
    ) as unknown_products,
    count(*) filter (
        where category_name is null
    ) as null_categories
from staging.products;

--customers	customer_id	text
--customers	customer_unique_id	text
--customers	customer_zip_code_prefix	bigint
--customers	customer_city	text
--customers	customer_state	text
--geolocation	geolocation_zip_code_prefix	bigint
--geolocation	latitude	numeric
--geolocation	longitude	numeric
--geolocation	city	text
--geolocation	state	text
--order_items	order_id	text
--order_items	order_item_id	integer
--order_items	product_id	text
--order_items	seller_id	text
--order_items	shipping_limit_at	timestamp without time zone
--order_items	price	numeric
--order_items	freight_value	numeric
--orders	order_id	text
--orders	customer_id	text
--orders	order_status	text
--orders	purchased_at	timestamp without time zone
--orders	approved_at	timestamp without time zone
--orders	shipped_at	timestamp without time zone
--orders	delivered_at	timestamp without time zone
--orders	estimated_delivery_at	timestamp without time zone
--payments	order_id	text
--payments	payment_sequential	integer
--payments	payment_type	text
--payments	payment_installments	integer
--payments	payment_value	numeric
--products	product_id	text
--products	product_category_name	text
--products	category_name	text
--products	product_name_length	integer
--products	product_description_length	integer
--products	product_photos_qty	integer
--products	product_weight_g	numeric
--products	product_length_cm	numeric
--products	product_height_cm	numeric
--products	product_width_cm	numeric
--reviews	review_id	text
--reviews	order_id	text
--reviews	review_score	integer
--reviews	review_comment_title	text
--reviews	review_comment_message	text
--reviews	review_created_at	timestamp without time zone
--reviews	review_answered_at	timestamp without time zone
--sellers	seller_id	text
--sellers	seller_zip_code_prefix	bigint
--sellers	seller_city	text
--sellers	seller_state	text
-- 15. validation: column data types
select
    table_name,
    column_name,
    data_type
from information_schema.columns
where table_schema = 'staging'
order by table_name, ordinal_position;

--8
-- 16. validation: missing delivery timestamps
select
    count(*) as delivered_orders_missing_date
from staging.orders
where order_status = 'delivered'
    and delivered_at is null;

--0
-- 17. validation: invalid delivery chronology
select
    count(*) as delivered_before_purchase
from staging.orders
where delivered_at < purchased_at;

--6
-- 18. validation: canceled but delivered orders
select
    count(*) as canceled_but_delivered
from staging.orders
where order_status = 'canceled'
    and delivered_at is not null;

--0	0	383	0
-- 19. validation: zero or negative item values
select
    count(*) filter (where price = 0) as zero_price,
    count(*) filter (where price < 0) as negative_price,
    count(*) filter (where freight_value = 0) as zero_freight,
    count(*) filter (where freight_value < 0) as negative_freight
from staging.order_items;

--9	0
-- 20. validation: payment values
select
    count(*) filter (where payment_value = 0) as zero_payments,
    count(*) filter (where payment_value < 0) as negative_payments
from staging.payments;

--99224	0
-- 21. validation: review scores
select
    count(*) as total_reviews,
    count(*) filter (
        where review_score not between 1 and 5
    ) as invalid_review_scores
from staging.reviews;
