--96470	6534	89936	6.77	12.50

select 
	count(*) as eligible_delivered_orders,
	count(*) filter (where delivered_at::date > estimated_delivery_at::date) as late_orders,
	count(*) filter (where delivered_at::date <= estimated_delivery_at::date),
	round(100.0*count(*) filter (where delivered_at::date > estimated_delivery_at::date) / nullif(count(*), 0), 2) as late_delivery_rate_pct,
	round(avg(delivery_days), 2) as avg_delivery_days
from mart.fact_orders fo 
where order_status = 'delivered'
	and delivered_at is not null
	and estimated_delivery_at is not null
	and purchased_at is not null;


--AC	80	3	3.75	21.00
--AL	397	85	21.41	24.50
--AM	145	4	2.76	26.36
--AP	67	2	2.99	27.18
--BA	3256	396	12.16	19.28
--CE	1279	176	13.76	21.20
--DF	2080	118	5.67	12.90
--ES	1995	214	10.73	15.72
--GO	1957	128	6.54	15.54
--MA	717	125	17.43	21.51
--MG	11354	519	4.57	11.94
--MS	701	68	9.70	15.54
--MT	886	53	5.98	18.00
--PA	946	106	11.21	23.73
--PB	517	54	10.44	20.39
--PE	1593	153	9.60	18.40
--PI	476	66	13.87	19.39
--PR	4923	199	4.04	11.94
--RJ	12350	1495	12.11	15.24
--RN	474	44	9.28	19.22
--RO	243	7	2.88	19.28
--RR	41	5	12.20	29.34
--RS	5344	325	6.08	15.25
--SC	3546	291	8.21	14.90
--SE	335	51	15.22	21.46
--SP	40494	1820	4.49	8.70
--TO	274	27	9.85	17.60

-- delivery performance by customer state
select
	c.customer_state,
	count(*) as eligible_delivered_orders,
	count(*) filter (where o.is_late = 1) as late_orders,
	round(100.0 * count(*) filter (where o.is_late = 1) / nullif(count(*), 0), 2) as late_delivery_rate_pct,
	round(avg(o.delivery_days), 2) as avg_delivery_days
from mart.fact_orders o
join mart.dim_customers c
	on o.customer_id = c.customer_id
where o.order_status = 'delivered'
	and o.delivered_at is not null
	and o.estimated_delivery_at is not null
	and o.purchased_at is not null
group by c.customer_state

--8	6

-- delivery anomalies to monitor
select
	count(*) filter (where order_status = 'delivered' and delivered_at is null) as delivered_without_delivery_date,
	count(*) filter (where order_status = 'canceled' and delivered_at is not null) as canceled_with_delivery_date
from mart.fact_orders;