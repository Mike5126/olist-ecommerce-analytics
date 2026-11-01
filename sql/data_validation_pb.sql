
-- 1.1 Total Orders = 99,441; Delivered Orders = 96,478
select
    count(*) as total_orders,
    count(*) filter (where order_status = 'delivered') as delivered_orders
from mart.fact_orders;

-- 1.2 Delivered Product Sales = BRL 13,221,498.11
select
    round(sum(delivered_item_sales)::numeric, 2) as delivered_product_sales
from mart.fact_order_items;

-- 1.3 Average Order Value = BRL 137.04
-- Definition: delivered product sales / count of delivered orders
with delivered_sales as (
    select sum(delivered_item_sales) as sales
    from mart.fact_order_items
),
delivered_orders as (
    select count(*) as orders
    from mart.fact_orders
    where order_status = 'delivered'
)
select
    round((s.sales / nullif(o.orders, 0))::numeric, 2) as average_order_value
from delivered_sales s
cross join delivered_orders o;


-- 2. CUSTOMER ANALYTICS


-- 2.1 Active Customers = 93,358
select
    count(distinct customer_unique_id) as active_customers
from mart.customer_order_activity;

-- 2.2 Repeat Customers = 2,801
-- Definition: >= 2 distinct delivered orders per customer_unique_id
with customer_orders as (
    select
        customer_unique_id,
        count(distinct order_id) as order_count
    from mart.customer_order_activity
    group by customer_unique_id
)
select
    count(*) filter (where order_count >= 2) as repeat_customers
from customer_orders;

-- 2.3 Average Orders per Customer = 1.03
select
    round(
        count(distinct order_id)::numeric
        / nullif(count(distinct customer_unique_id), 0),
        2
    ) as avg_orders_per_customer
from mart.customer_order_activity;

-- 2.4 Repeat Customer Rate = 3.00%
with customer_orders as (
    select
        customer_unique_id,
        count(distinct order_id) as order_count
    from mart.customer_order_activity
    group by customer_unique_id
)
select
    round(
        100.0 * count(*) filter (where order_count >= 2)
        / nullif(count(*), 0),
        2
    ) as repeat_customer_rate_pct
from customer_orders;


-- 3. DELIVERY PERFORMANCE
-- Only delivered orders with non-null delivery dates / days

-- 3.1 On-Time Orders = 89,936; Late Orders = 6,534
-- Valid classified deliveries = 96,470
select
    count(*) filter (where is_late = 0) as on_time_orders,
    count(*) filter (where is_late = 1) as late_orders
from mart.fact_orders
where order_status = 'delivered'