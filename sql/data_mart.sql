
-- 00. create mart schema
create schema if not exists mart;


-- 01. drop existing mart tables
drop table if exists mart.fact_order_items;
drop table if exists mart.fact_orders;
drop table if exists mart.dim_customers;
drop table if exists mart.dim_products;
drop table if exists mart.dim_sellers;
drop table if exists mart.dim_date;


-- 02. mart.dim_customers
create table mart.dim_customers as
select
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
from staging.customers;


-- 03. mart.dim_products
create table mart.dim_products as
select
    product_id,
    product_category_name,
    category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
from staging.products;


-- 04. mart.dim_sellers
create table mart.dim_sellers as
select
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
from staging.sellers;


-- 05. mart.dim_date
create table mart.dim_date as
with date_range as (
    select
        min(purchased_at)::date as min_date,
        max(purchased_at)::date as max_date
    from staging.orders
),
dates as (
    select
        generate_series(
            min_date,
            max_date,
            interval '1 day'
        )::date as date_key
    from date_range
)
select
    date_key,
    extract(year from date_key)::integer as year,
    extract(quarter from date_key)::integer as quarter,
    extract(month from date_key)::integer as month,
    extract(day from date_key)::integer as day,
    extract(isodow from date_key)::integer as day_of_week,
    to_char(date_key, 'Month') as month_name,
    to_char(date_key, 'Day') as day_name,
    case
        when extract(isodow from date_key) in (6, 7)
            then true
        else false
    end as is_weekend
from dates;


-- 06. mart.fact_orders
create table mart.fact_orders as
select
    o.order_id,
    o.customer_id,
    o.order_status,

    o.purchased_at,
    o.purchased_at::date as purchase_date,

    o.approved_at,
    o.shipped_at,
    o.delivered_at,
    o.estimated_delivery_at,

    case
	    when o.order_status = 'delivered'
	        and o.delivered_at is not null
	        and o.estimated_delivery_at is not null
	    then
	        case
	            when o.delivered_at::date > o.estimated_delivery_at::date
	            then 1
	            else 0
	        end
	    else null
	end as is_late,

    case
        when o.order_status = 'delivered'
            and o.delivered_at is not null
            and o.purchased_at is not null
        then o.delivered_at::date - o.purchased_at::date
        else null
    end as delivery_days,

    case
        when o.order_status = 'delivered'
        then 1
        else 0
    end as is_delivered,

    case
        when o.order_status = 'canceled'
        then 1
        else 0
    end as is_canceled

from staging.orders o;


-- 07. mart.fact_order_items
create table mart.fact_order_items as
select
    oi.order_id,
    oi.order_item_id,
    o.customer_id,
    oi.product_id,
    oi.seller_id,

    o.purchased_at::date as purchase_date,
    o.order_status,

    oi.shipping_limit_at,

    oi.price,
    oi.freight_value,

    oi.price + oi.freight_value as total_item_value,

    case
        when o.order_status = 'delivered'
        then oi.price
        else 0
    end as delivered_item_sales

from staging.order_items oi
left join staging.orders o
    on oi.order_id = o.order_id;


-- 08. add primary keys
alter table mart.dim_customers
add primary key (customer_id);

alter table mart.dim_products
add primary key (product_id);

alter table mart.dim_sellers
add primary key (seller_id);

alter table mart.dim_date
add primary key (date_key);

alter table mart.fact_orders
add primary key (order_id);

alter table mart.fact_order_items
add primary key (order_id, order_item_id);


-- 09. add foreign keys
alter table mart.fact_orders
add constraint fk_orders_customer
foreign key (customer_id)
references mart.dim_customers(customer_id);

alter table mart.fact_order_items
add constraint fk_items_order
foreign key (order_id)
references mart.fact_orders(order_id);

alter table mart.fact_order_items
add constraint fk_items_customer
foreign key (customer_id)
references mart.dim_customers(customer_id);

alter table mart.fact_order_items
add constraint fk_items_product
foreign key (product_id)
references mart.dim_products(product_id);

alter table mart.fact_order_items
add constraint fk_items_seller
foreign key (seller_id)
references mart.dim_sellers(seller_id);

alter table mart.fact_orders
add constraint fk_orders_date
foreign key (purchase_date)
references mart.dim_date(date_key);

alter table mart.fact_order_items
add constraint fk_items_date
foreign key (purchase_date)
references mart.dim_date(date_key);


-- 10. create indexes
create index idx_fact_orders_customer
on mart.fact_orders(customer_id);

create index idx_fact_orders_date
on mart.fact_orders(purchase_date);

create index idx_fact_items_customer
on mart.fact_order_items(customer_id);

create index idx_fact_items_product
on mart.fact_order_items(product_id);

create index idx_fact_items_seller
on mart.fact_order_items(seller_id);

create index idx_fact_items_date
on mart.fact_order_items(purchase_date);

--orders	99441	99441
--order_items	112650	112650
--customers	99441	99441
--products	32951	32951
--sellers	3095	3095
-- 11. validation: row count comparison
select
    'orders' as table_name,
    (select count(*) from staging.orders) as staging_count,
    (select count(*) from mart.fact_orders) as mart_count

union all

select
    'order_items',
    (select count(*) from staging.order_items),
    (select count(*) from mart.fact_order_items)

union all

select
    'customers',
    (select count(*) from staging.customers),
    (select count(*) from mart.dim_customers)

union all

select
    'products',
    (select count(*) from staging.products),
    (select count(*) from mart.dim_products)

union all

select
    'sellers',
    (select count(*) from staging.sellers),
    (select count(*) from mart.dim_sellers);


-- 12. validation: duplicate orders
select
    order_id,
    count(*) as total
from mart.fact_orders
group by order_id
having count(*) > 1;


-- 13. validation: duplicate order items
select
    order_id,
    order_item_id,
    count(*) as total
from mart.fact_order_items
group by order_id, order_item_id
having count(*) > 1;

--13591643.70	13591643.70
-- 14. validation: sales amount comparison
select
    (select sum(price)
     from staging.order_items) as staging_sales,

    (select sum(price)
     from mart.fact_order_items) as mart_sales;

--2251909.54	2251909.54
-- 15. validation: freight amount comparison
select
    (select sum(freight_value) 
     from staging.order_items) as staging_freight,

    (select sum(freight_value)
     from mart.fact_order_items) as mart_freight;

--delivered	96478
--shipped	1107
--canceled	625
--unavailable	609
--invoiced	314
--processing	301
--created	5
--approved	2
-- 16. validation: order status
select
    order_status,
    count(*) as total_orders
from mart.fact_orders
group by order_status
order by total_orders desc;

--99441	96478	625	6534	12.50
-- 17. validation: delivery performance
select
    count(*) as total_orders,
    sum(is_delivered) as delivered_orders,
    sum(is_canceled) as canceled_orders,
    sum(is_late) as late_deliveries,
    round(avg(delivery_days), 2) as avg_delivery_days
from mart.fact_orders;

--health_beauty	9670	1233131.72
--watches_gifts	5991	1166176.98
--bed_bath_table	11115	1023434.76
--sports_leisure	8641	954852.55
--computers_accessories	7827	888724.61
--furniture_decor	8334	711927.69
--housewares	6964	615628.69
--cool_stuff	3796	610204.10
--auto	4235	578966.65
--toys	4117	471286.48
--garden_tools	4347	470495.28
--baby	3065	400421.84
--perfumery	3419	390144.65
--telephony	4545	309860.23
--office_furniture	1691	268154.31
--stationery	2517	223788.69
--computers	203	218684.14
--pet_shop	1947	211695.64
--musical_instruments	680	184315.74
--small_appliances	679	182754.12
--Unknown	1603	170726.63
--electronics	2767	155043.93
--fashion_bags_accessories	2031	149329.39
--consoles_games	1137	148003.37
--construction_tools_construction	929	142108.49
--luggage_accessories	1092	138701.63
--home_appliances_2	238	107953.95
--home_construction	604	81407.57
--home_appliances	771	78832.48
--agro_industry_and_commerce	212	70566.10
--furniture_living_room	503	67350.70
--home_confort	434	58008.45
--fixed_telephony	264	55315.21
--air_conditioning	297	53323.56
--audio	364	50570.60
--small_appliances_home_oven_and_coffee	76	46589.56
--kitchen_dining_laundry_garden_furniture	281	45531.98
--books_general_interest	553	45302.15
--construction_tools_lights	304	39957.00
--construction_tools_safety	194	38773.22
--industry_commerce_and_business	268	38498.81
--food	510	28731.15
--market_place	311	27795.77
--costruction_tools_garden	238	25096.28
--art	209	23657.30
--fashion_shoes	262	23001.46
--drinks	379	21529.84
--signaling_and_security	199	21315.05
--furniture_bedroom	109	19051.80
--books_technical	267	18702.23
--costruction_tools_tools	103	15903.95
--food_drink	278	14942.88
--fashion_male_clothing	132	10452.33
--fashion_underwear_beach	131	9305.95
--christmas_supplies	153	8737.84
--tablets_printing_image	83	7528.41
--cine_photo	72	6674.47
--music	38	6034.35
--dvds_blu_ray	64	4542.59
--party_supplies	43	4465.19
--books_imported	60	4418.86
--furniture_mattress_and_upholstery	38	4323.38
--portateis_cozinha_e_preparadores_de_alimentos	15	3933.63
--fashio_female_clothing	48	2634.94
--fashion_sport	30	2094.52
--la_cuisine	14	2054.99
--arts_and_craftmanship	24	1814.01
--diapers_and_hygiene	39	1500.79
--pc_gamer	9	1306.95
--flowers	33	1110.04
--home_comfort_2	30	760.27
--cds_dvds_musicals	14	730.00
--fashion_childrens_clothes	8	519.95
--security_and_services	2	283.29
-- 18. validation: category sales
select
    p.category_name,
    count(*) as total_items,
    sum(f.delivered_item_sales) as delivered_product_sales
from mart.fact_order_items f
left join mart.dim_products p
    on f.product_id = p.product_id
group by p.category_name
order by delivered_product_sales desc;

--2016	9	3	134.97
--2016	10	308	40325.11
--2016	12	1	10.90
--2017	1	789	111798.36
--2017	2	1733	234223.40
--2017	3	2641	359198.85
--2017	4	2391	340669.68
--2017	5	3660	489338.25
--2017	6	3217	421923.37
--2017	7	3969	481604.52
--2017	8	4293	554699.70
--2017	9	4243	607399.67
--2017	10	4568	648247.65
--2017	11	7451	987765.37
--2017	12	5624	726033.19
--2018	1	7220	924645.00
--2018	2	6694	826437.13
--2018	3	7188	953356.25
--2018	4	6934	973534.09
--2018	5	6853	977544.69
--2018	6	6160	856077.86
--2018	7	6273	867953.46
--2018	8	6452	838576.64
--2018	9	1	0
-- 19. validation: monthly sales
select
    d.year,
    d.month,
    count(distinct f.order_id) as total_orders_with_items,
    sum(f.delivered_item_sales) as delivered_product_sales
from mart.fact_order_items f
join mart.dim_date d
    on f.purchase_date = d.date_key
group by d.year, d.month
order by d.year, d.month;

--0	0	0
-- 20. validation: missing dimension references
select
    count(*) filter (where c.customer_id is null) as missing_customers,

    count(*) filter (where p.product_id is null) as missing_products,

    count(*) filter (where s.seller_id is null) as missing_sellers

from mart.fact_order_items f

left join mart.dim_customers c on f.customer_id = c.customer_id

left join mart.dim_products p on f.product_id = p.product_id

left join mart.dim_sellers s on f.seller_id = s.seller_id;
