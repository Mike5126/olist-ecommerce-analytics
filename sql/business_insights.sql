
-- 01. MONTHLY REVENUE AND ORDER VOLUME
select
    date_trunc('month', purchase_date)::date as month,
    count(distinct order_id) as delivered_orders,
    round(sum(delivered_item_sales)::numeric, 2) as delivered_product_sales
from mart.fact_order_items
where order_status = 'delivered'
  and purchase_date is not null
group by 1
order by 1;


-- 02. MONTHLY REVENUE, AOV AND MONTH-OVER-MONTH GROWTH
-- Important: the self-join matches the immediately preceding calendar month.
-- A prior-month threshold of 100 orders suppresses unstable percent changes.
with monthly_metrics as (
    select
        date_trunc('month', purchase_date)::date as month,
        count(distinct order_id) as delivered_orders,
        sum(delivered_item_sales) as revenue
    from mart.fact_order_items
    where order_status = 'delivered'
      and purchase_date is not null
    group by 1
),
monthly_comparison as (
    select
        m.month,
        m.delivered_orders,
        m.revenue,
        p.delivered_orders as previous_orders,
        p.revenue as previous_revenue
    from monthly_metrics m
    left join monthly_metrics p
      on p.month = (m.month - interval '1 month')::date
)
select
    month,
    delivered_orders,
    round(revenue::numeric, 2) as revenue,
    round((revenue / nullif(delivered_orders, 0))::numeric, 2) as aov,
    case when previous_orders >= 100 then
        round(100.0 * (delivered_orders - previous_orders)
              / nullif(previous_orders, 0), 2)
    end as orders_mom_pct,
    case when previous_orders >= 100 then
        round(100.0 * (revenue - previous_revenue)
              / nullif(previous_revenue, 0), 2)
    end as revenue_mom_pct
from monthly_comparison
where month between '2017-01-01' and '2018-08-01'
order by month;


-- 03. TOP 10 PRODUCT CATEGORIES IN NOVEMBER 2017
select
    p.product_category_name,
    count(distinct oi.order_id) as delivered_orders,
    round(sum(oi.delivered_item_sales)::numeric, 2) as revenue
from mart.fact_order_items oi
left join mart.dim_products p
  on oi.product_id = p.product_id
where oi.order_status = 'delivered'
  and oi.purchase_date >= '2017-11-01'
  and oi.purchase_date < '2017-12-01'
group by p.product_category_name
order by revenue desc
limit 10;


-- 04. PRODUCT CATEGORY CONTRIBUTION TO OCT -> NOV 2017 GROWTH
-- Rank by absolute revenue change, not just November revenue.
with category_sales as (
    select
        p.product_category_name,
        date_trunc('month', oi.purchase_date)::date as month,
        sum(oi.delivered_item_sales) as revenue
    from mart.fact_order_items oi
    left join mart.dim_products p
      on oi.product_id = p.product_id
    where oi.order_status = 'delivered'
      and oi.purchase_date >= '2017-10-01'
      and oi.purchase_date < '2017-12-01'
    group by 1, 2
),
category_comparison as (
    select
        product_category_name,
        sum(revenue) filter (where month = '2017-10-01') as oct_revenue,
        sum(revenue) filter (where month = '2017-11-01') as nov_revenue
    from category_sales
    group by 1
)
select
    product_category_name,
    round(coalesce(oct_revenue, 0)::numeric, 2) as oct_revenue,
    round(coalesce(nov_revenue, 0)::numeric, 2) as nov_revenue,
    round((coalesce(nov_revenue, 0) - coalesce(oct_revenue, 0))::numeric, 2)
        as revenue_change,
    round(100.0 * (coalesce(nov_revenue, 0) - coalesce(oct_revenue, 0))
          / nullif(oct_revenue, 0), 2) as growth_pct
from category_comparison
order by revenue_change desc
limit 10;


-- 05. RECONCILE DELIVERED ORDERS VS. VALID DELIVERY DATES
-- Revenue counts all delivered orders; delivery KPIs exclude invalid dates.
select
    date_trunc('month', purchased_at)::date as month,
    count(*) as delivered_orders,
    count(*) filter (
        where delivered_at is not null
          and delivery_days is not null
          and delivery_days >= 0
    ) as valid_delivery_orders,
    count(*) filter (
        where delivered_at is null
           or delivery_days is null
           or delivery_days < 0
    ) as excluded_delivery_orders
from mart.fact_orders
where order_status = 'delivered'
  and purchased_at >= '2017-10-01'
  and purchased_at < '2018-01-01'
group by 1
order by 1;


-- 06. CUSTOMER PURCHASE FREQUENCY DISTRIBUTION
with customer_orders as (
    select
        customer_unique_id,
        count(distinct order_id) as order_count
    from mart.customer_order_activity
    group by customer_unique_id
)
select
    order_count,
    count(*) as customers,
    round(100.0 * count(*) / sum(count(*)) over (), 2) as customer_pct
from customer_orders
group by order_count
order by order_count;


-- 07. TIME BETWEEN CONSECUTIVE DELIVERED PURCHASES
-- Uses DATE-level purchase granularity, so same-day purchases are 0 days apart.
-- Mean is interval-weighted, not customer-weighted.
with purchase_history as (
    select distinct
        customer_unique_id,
        order_id,
        purchase_date
    from mart.customer_order_activity
    where purchase_date is not null
),
ordered_purchases as (
    select
        customer_unique_id,
        order_id,
        purchase_date,
        lag(purchase_date) over (
            partition by customer_unique_id
            order by purchase_date, order_id
        ) as previous_purchase_date
    from purchase_history
)
select
    count(*) as repeat_purchase_intervals,
    round(avg(purchase_date - previous_purchase_date)::numeric, 2)
        as avg_days_between_orders,
    round(
        percentile_cont(0.5) within group (
            order by purchase_date - previous_purchase_date
        )::numeric, 2
    ) as median_days_between_orders
from ordered_purchases
where previous_purchase_date is not null;


-- 08. MONTHLY COHORT RETENTION (LONG FORMAT)
-- M0 is 100%; subsequent months count customers with delivered purchases
-- in THAT month, not cumulative retention.
-- A month without returning customers is absent from long-form output.
with purchases as (
    select distinct
        customer_unique_id,
        date_trunc('month', purchase_date)::date as purchase_month
    from mart.customer_order_activity
    where purchase_date is not null
),
customer_cohorts as (
    select customer_unique_id, min(purchase_month) as cohort_month
    from purchases
    group by customer_unique_id
),
cohort_activity as (
    select distinct
        p.customer_unique_id,
        c.cohort_month,
        ((extract(year from p.purchase_month)
           - extract(year from c.cohort_month)) * 12
          + extract(month from p.purchase_month)
          - extract(month from c.cohort_month))::int as month_number
    from purchases p
    join customer_cohorts c
      on p.customer_unique_id = c.customer_unique_id
),
cohort_sizes as (
    select cohort_month, count(*) as cohort_size
    from customer_cohorts
    group by cohort_month
)
select
    a.cohort_month,
    s.cohort_size,
    a.month_number,
    count(distinct a.customer_unique_id) as retained_customers,
    round(100.0 * count(distinct a.customer_unique_id)
          / nullif(s.cohort_size, 0), 2) as retention_rate_pct
from cohort_activity a
join cohort_sizes s
  on a.cohort_month = s.cohort_month
where a.cohort_month between '2017-01-01' and '2018-02-01'
  and a.month_number between 0 and 6
group by a.cohort_month, s.cohort_size, a.month_number
order by a.cohort_month, a.month_number;


-- 09. COHORT RETENTION M0-M6 (PIVOT FORMAT FOR HEATMAP)
-- Only cohorts through February 2018 are included to allow all 6 months
-- to be observed by August 2018. Missing activity within the window = 0%.
with purchases as (
    select distinct
        customer_unique_id,
        date_trunc('month', purchase_date)::date as purchase_month
    from mart.customer_order_activity
    where purchase_date is not null
),
cohorts as (
    select customer_unique_id, min(purchase_month) as cohort_month
    from purchases
    group by customer_unique_id
),
activity as (
    select
        c.customer_unique_id,
        c.cohort_month,
        ((extract(year from p.purchase_month)
           - extract(year from c.cohort_month)) * 12
          + extract(month from p.purchase_month)
          - extract(month from c.cohort_month))::int as month_number
    from cohorts c
    join purchases p
      on c.customer_unique_id = p.customer_unique_id
),
retention as (
    select
        cohort_month,
        month_number,
        count(distinct customer_unique_id) as customers
    from activity
    where month_number between 0 and 6
    group by cohort_month, month_number
),
cohort_sizes as (
    select cohort_month, count(*) as cohort_size
    from cohorts
    group by cohort_month
)
select
    s.cohort_month,
    s.cohort_size,
    round(100.0 * coalesce(max(r.customers) filter (where r.month_number = 0), 0)
          / nullif(s.cohort_size, 0), 2) as m0,
    round(100.0 * coalesce(max(r.customers) filter (where r.month_number = 1), 0)
          / nullif(s.cohort_size, 0), 2) as m1,
    round(100.0 * coalesce(max(r.customers) filter (where r.month_number = 2), 0)
          / nullif(s.cohort_size, 0), 2) as m2,
    round(100.0 * coalesce(max(r.customers) filter (where r.month_number = 3), 0)
          / nullif(s.cohort_size, 0), 2) as m3,
    round(100.0 * coalesce(max(r.customers) filter (where r.month_number = 4), 0)
          / nullif(s.cohort_size, 0), 2) as m4,
    round(100.0 * coalesce(max(r.customers) filter (where r.month_number = 5), 0)
          / nullif(s.cohort_size, 0), 2) as m5,
    round(100.0 * coalesce(max(r.customers) filter (where r.month_number = 6), 0)
          / nullif(s.cohort_size, 0), 2) as m6
from cohort_sizes s
left join retention r
  on s.cohort_month = r.cohort_month
where s.cohort_month between '2017-01-01' and '2018-02-01'
group by s.cohort_month, s.cohort_size
order by s.cohort_month;


-- 10. DELIVERY PERFORMANCE BY CUSTOMER STATE
-- Avoid ranking very small states: require >= 100 valid deliveries.
with state_delivery as (
    select
        c.customer_state,
        count(*) as delivered_orders,
        count(*) filter (
            where o.delivered_at is not null
              and o.delivery_days is not null
              and o.delivery_days >= 0
        ) as valid_delivery_orders,
        count(*) filter (
            where o.is_late = 1
              and o.delivered_at is not null
              and o.delivery_days is not null
              and o.delivery_days >= 0
        ) as late_orders,
        avg(o.delivery_days) filter (
            where o.delivered_at is not null
              and o.delivery_days is not null
              and o.delivery_days >= 0
        ) as avg_delivery_days
    from mart.fact_orders o
    join mart.dim_customers c
      on o.customer_id = c.customer_id
    where o.order_status = 'delivered'
    group by c.customer_state
)
select
    customer_state,
    delivered_orders,
    valid_delivery_orders,
    late_orders,
    round(avg_delivery_days::numeric, 2) as avg_delivery_days,
    round(100.0 * late_orders / nullif(valid_delivery_orders, 0), 2)
        as late_delivery_rate_pct
from state_delivery
where valid_delivery_orders >= 100
order by late_delivery_rate_pct desc;


-- 11. TOP 10 SELLERS BY DELIVERED PRODUCT REVENUE
select
    oi.seller_id,
    s.seller_state,
    count(distinct oi.order_id) as delivered_orders,
    round(sum(oi.delivered_item_sales)::numeric, 2) as delivered_sales
from mart.fact_order_items oi
join mart.dim_sellers s
  on oi.seller_id = s.seller_id
where oi.order_status = 'delivered'
group by oi.seller_id, s.seller_state
order by delivered_sales desc
limit 10;


-- 12. SELLER REVENUE CONCENTRATION: TOP 10% SHARE
-- Includes all sellers, even those without delivered orders.
-- 10% of 3,095 sellers rounds up to 310 sellers.
with seller_sales as (
    select
        s.seller_id,
        coalesce(sum(oi.delivered_item_sales), 0) as revenue
    from mart.dim_sellers s
    left join mart.fact_order_items oi
      on s.seller_id = oi.seller_id
     and oi.order_status = 'delivered'
    group by s.seller_id
),
ranked_sellers as (
    select
        seller_id,
        revenue,
        row_number() over (order by revenue desc, seller_id) as seller_rank,
        count(*) over () as total_sellers
    from seller_sales
)
select
    count(*) as total_sellers,
    count(*) filter (
        where seller_rank <= ceil(total_sellers * 0.10)
    ) as top_10_pct_sellers,
    round(sum(revenue)::numeric, 2) as total_revenue,
    round(sum(revenue) filter (
        where seller_rank <= ceil(total_sellers * 0.10)
    )::numeric, 2) as top_10_pct_revenue,
    round((100.0 * sum(revenue) filter (
        where seller_rank <= ceil(total_sellers * 0.10)
    ) / nullif(sum(revenue), 0))::numeric, 2) as top_10_pct_revenue_share
from ranked_sellers;
