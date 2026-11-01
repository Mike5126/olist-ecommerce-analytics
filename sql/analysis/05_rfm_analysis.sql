-- rfm analysis: recency, frequency, monetary

with analysis_date as (
	select
		max(purchased_at)::date + 1 as snapshot_date
	from mart.fact_orders
	where order_status = 'delivered'
		and purchased_at is not null
),
customer_rfm as (
	select
		c.customer_unique_id,
		(select snapshot_date from analysis_date) - max(o.purchased_at)::date as recency_days,
		count(distinct o.order_id) as frequency,
		round(sum(i.price), 2) as monetary
	from mart.fact_orders o
	join mart.dim_customers c
		on o.customer_id = c.customer_id
	join mart.fact_order_items i
		on o.order_id = i.order_id
	where o.order_status = 'delivered'
		and o.purchased_at is not null 
		and c.customer_unique_id is not null
	group by c.customer_unique_id
),
rfm_scores as (
	select	
		customer_unique_id,
		recency_days,
		frequency,
		monetary,
		ntile(5) over (
			order by recency_days desc, customer_unique_id
		) as r_score,
		ntile(5) over (
			order by frequency asc, customer_unique_id
		) as f_score,
		ntile(5) over (
			order by monetary asc, customer_unique_id
		) as m_score
	from customer_rfm
),
rfm_segments as(
	select
		customer_unique_id,
		recency_days,
		frequency,
		monetary,
		r_score,
		f_score,
		m_score,
		concat(r_score, f_score, m_score) as rfm_score,
		case
			when r_score >= 4 and f_score >= 4 then 'champions'
			when r_score >= 3 and f_score >= 3 then 'loyal customers'
			when r_score >= 4 and f_score <= 2 then 'recent customers'
			when r_score <= 2 and f_score >= 4 then 'at risk'
			when r_score <= 2 and f_score <= 2 then 'hibernating'
			else 'potential loyalists'
		end as customer_segment
		
	from rfm_scores
	order by monetary desc
)

--hibernating	15050
--potential loyalists	14807
--at risk	14826
--loyal customers	18792
--recent customers	14955
--champions	14928

select 
	customer_segment,
	count(*) total_customers
from rfm_segments
group by customer_segment
