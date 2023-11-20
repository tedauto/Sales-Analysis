-- checking the data
select * from sales.sales_data_sample;

-- I had to format the orderdate to Y/M/D since it was in D/M/Y 
UPDATE sales.sales_data_sample
SET orderdate = DATE_FORMAT(STR_TO_DATE(orderdate, '%m/%d/%Y %H:%i'), '%Y/%m/%d')

-- checking for unique values
-- nice to plot
select distinct year_id from sales.sales_data_sample;
select distinct dealsize from sales.sales_data_sample;
select distinct country from sales.sales_data_sample;
select distinct productline from sales.sales_data_sample;
select distinct territory from sales.sales_data_sample;

-- Analysis
-- Grouping sales by productline
select productline,
sum(sales) as total_sales 
from sales.sales_data_sample
group by productline
order by total_sales desc

-- yearly sales
select year_id,
sum(sales) as yearly_sales
from sales.sales_data_sample
group by year_id
order by yearly_sales desc


select dealsize,
sum(sales) as total_sales
from sales.sales_data_sample
group by dealsize
order by total_sales desc


-- What was the best month of sales in a specific year?how much was earned?
select month_id,
sum(sales) as total_sales,
count(ordernumber) as number_of_orders
from sales.sales_data_sample
where year_id  = 2004 -- change the years to view the rest
group by month_id
order by total_sales desc

-- November seems to be the best perfoming month.Lets check which products sold in Nov.
select month_id,productline,
sum(sales) as total_sales,
count(ordernumber) as number_of_orders
from sales.sales_data_sample
where year_id  = 2004 and month_id = 11 
group by month_id,productline -- classic cars sold the most
order by  total_sales desc

-- Who is the best customer(RFM analysis)?
-- RFM(Recency-Frequency_Monetary) is an indexing technique that uses past purchase behaviour to segment customers.

-- recency(how long ago the customer purchase was), ### (use last order date)
-- frequency(how often they purchase) and ### count of total orders
-- monetary value(how much they spent) ### total spend
create table refremon as
with rfm as 
(
select 
	customername,
	sum(sales) as monetary_value,
	avg(sales) as average_monetary_value,
	count(ordernumber) as frequency,
	max(orderdate) as last_order,
(select max(orderdate) from sales.sales_data_sample) as max_order_date,
datediff((select max(orderdate) from sales.sales_data_sample), max(orderdate)) as Recency
from
	sales.sales_data_sample
group by 
	customername
),
rfm_calc as  
(
select r.*,
	NTILE(4) over (order by Recency desc) as rfm_recency,
    NTILE(4) over (order by frequency) as rfm_frequency,
    NTILE(4) over (order by average_monetary_value) as rfm_monetary
from rfm as r
)
SELECT 
    c.*,
    rfm_recency + rfm_frequency + rfm_monetary as rfm_cell, -- you can either use the int rfm_cell or the string rfm string
    CONCAT(rfm_recency, rfm_frequency, rfm_monetary) as rfm_string
FROM 
    rfm_calc as c;


-- checking the newly created table 
select * 
from refremon
order by rfm_cell desc

-- create customer categories based on the rfm_cell value
select 
	customername,
    rfm_recency,
    rfm_frequency,
    rfm_monetary,
    case 
		WHEN rfm_cell >= 10 THEN 'Loyal'
		WHEN rfm_cell >= 8 AND rfm_cell < 10 THEN 'Active'
		WHEN rfm_cell >= 6 AND rfm_cell < 8 THEN 'New Customers'
		WHEN rfm_cell >= 4 AND rfm_cell < 6 THEN 'Potential Churners'
		WHEN rfm_cell >= 2 AND rfm_cell < 4 THEN 'Slipping Away'
	END AS customer_group
from refremon

-- What produts are most sold together?
select 
	distinct ordernumber, 
	count(ordernumber) as number_of_orders
from sales.sales_data_sample
group by ordernumber
order by number_of_orders desc



select CONCAT(',', productcode) as productcode
from sales.sales_data_sample
where ordernumber in
	 (
		select ordernumber 
		from(
			select ordernumber,count(*) as rn
			from sales.sales_data_sample
			where status = "Shipped"
			group by ordernumber
		) as two_items
		where rn = 2
	)
    
-- subquery to get what products are sold together
select 
	ordernumber , 
	GROUP_CONCAT(productcode) as productcodes
	from sales.sales_data_sample
	where ordernumber in
		 (
			select ordernumber 
			from(
				select ordernumber,count(*) as rn
				from sales.sales_data_sample 
				where status = "Shipped"
				group by ordernumber
			) as number_of_items
			where rn = 2
		)
	group by ordernumber
    order by ordernumber desc





