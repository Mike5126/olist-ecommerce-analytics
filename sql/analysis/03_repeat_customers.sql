--96096	93099	2997

with customer_orders as (
	select
		c.customer_unique_id,
		count(distinct o.order_id) as total_orders
	from mart.fact_orders o 
	join mart.dim_customers c
		on o.customer_id = c.customer_id
		and c.customer_unique_id is not null
	group by c.customer_unique_id
)

select
	count(*) as total_customers,
	count(*) filter (where total_orders = 1) as one_time_customers,
	count(*) filter (where total_orders > 1) as repeat_customers,
	round(100*count(*) filter (where total_orders > 1) / nullif(count(*), 0), 2) as repeat_customer_rate_pct
from customer_orders;

--1	93099
--2	2745
--3	203
--4	30
--5	8
--6	6
--7	3
--9	1
--17	1

select
    total_orders,
    count(*) as total_customers
from customer_orders
group by total_orders
order by total_orders;