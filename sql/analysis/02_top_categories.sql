--health_beauty	9465	8647	1233131.72	130.28	9.33
--watches_gifts	5859	5495	1166176.98	199.04	8.82
--bed_bath_table	10953	9272	1023434.76	93.44	7.74
--sports_leisure	8431	7530	954852.55	113.25	7.22
--computers_accessories	7644	6530	888724.61	116.26	6.72
--furniture_decor	8160	6307	711927.69	87.25	5.38
--housewares	6795	5743	615628.69	90.60	4.66
--cool_stuff	3718	3559	610204.10	164.12	4.62
--auto	4140	3810	578966.65	139.85	4.38
--toys	4030	3804	471286.48	116.94	3.56

select
	coalesce(p.category_name, 'Unknown') as category_name,
	count(*) as total_items,
	count(distinct i.order_id) as total_orders,
	round(sum(i.price), 2) as revenue,
	round(avg(i.price), 2) as avg_item_price,
	round(100.0*sum(i.price) / nullif(sum(sum(i.price)) over(), 0), 2) as revenue_share_pct
from mart.fact_order_items i join
mart.dim_products p
	on i.product_id = p.product_id
where i.order_status = 'delivered'
group by coalesce(p.category_name, 'Unknown')
order by revenue desc
limit 10;