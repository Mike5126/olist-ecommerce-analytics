
--2016-09-01	1	134.97		
--2016-10-01	265	40325.11	134.97	29777.09
--2016-12-01	1	10.90	40325.11	
--2017-01-01	750	111798.36	10.90	1025573.03
--2017-02-01	1653	234223.40	111798.36	109.51
--2017-03-01	2546	359198.85	234223.40	53.36
--2017-04-01	2303	340669.68	359198.85	-5.16
--2017-05-01	3546	489338.25	340669.68	43.64
--2017-06-01	3135	421923.37	489338.25	-13.78
--2017-07-01	3872	481604.52	421923.37	14.15
--2017-08-01	4193	554699.70	481604.52	15.18
--2017-09-01	4150	607399.67	554699.70	9.50
--2017-10-01	4478	648247.65	607399.67	6.73
--2017-11-01	7289	987765.37	648247.65	52.37
--2017-12-01	5513	726033.19	987765.37	-26.50
--2018-01-01	7069	924645.00	726033.19	27.36
--2018-02-01	6555	826437.13	924645.00	-10.62
--2018-03-01	7003	953356.25	826437.13	15.36
--2018-04-01	6798	973534.09	953356.25	2.12
--2018-05-01	6749	977544.69	973534.09	0.41
--2018-06-01	6099	856077.86	977544.69	-12.43
--2018-07-01	6159	867953.46	856077.86	1.39
--2018-08-01	6351	838576.64	867953.46	-3.38

with monthly_sales as (
	select
		date_trunc('month', fo.purchased_at)::date as month,
		count(distinct fo.order_id) as total_orders,
		sum(foi.price) as revenue
	from mart.fact_order_items foi 
	join mart.fact_orders fo 
		on foi.order_id = fo.order_id 
	where fo.order_status = 'delivered'
		and fo.purchased_at is not null 
	group by 1
),
monthly_growth as (
	select
		month,
		total_orders,
		revenue,
		lag(revenue) over(order by month) as previous_month_revenue,
		lag(month) over(order by month) as previous_month
	from monthly_sales
)

select
	month,
	total_orders,
	revenue,
	previous_month_revenue,
	case 
		when previous_month = (month - interval '1 month')::date
		then round(100.0*(revenue - previous_month_revenue) / nullif(previous_month_revenue, 0), 2)
		else null 
	end as month_growth_pct
	
from monthly_growth
order by month;

