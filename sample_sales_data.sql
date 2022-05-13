select * from sales_data_sample

--understanding dataset by collecting distinct records
select distinct(ORDERLINENUMBER) from sales_data_sample order by ORDERLINENUMBER

select distinct(YEAR_ID) from sales_data_sample

select distinct(PRODUCTLINE) from sales_data_sample

select distinct(CUSTOMERNAME) from sales_data_sample

select distinct(COUNTRY) from sales_data_sample

select distinct(DEALSIZE) from sales_data_sample

select distinct(STATUS) from sales_data_sample

--group sales by product line
select   PRODUCTLINE, round(sum(SALES),2) as 'Total sales' 
from     sales_data_sample
group by PRODUCTLINE order by 2 desc

--Total customers and Total sale made
select count(distinct(CUSTOMERNAME)) as 'Total Customer', round(sum(SALES),2) as 'Total sales made' 
from   sales_data_sample

--Total customers and Total sale made by year
select YEAR_ID,count(distinct(CUSTOMERNAME)) as 'Total Customer', count(distinct(STATUS)) as 'Sales ',
       round(sum(SALES),2) as 'Total sales made' 
from   sales_data_sample
group by YEAR_ID order by YEAR_ID

--Total sales by customername
select CUSTOMERNAME, round(sum(SALES),2) as 'Total sales made' 
from   sales_data_sample
group by CUSTOMERNAME order by [Total sales made] desc

select DEALSIZE, ROUND(SUM(sales),2) as 'Total sales' 
from   sales_data_sample
group by DEALSIZE


--total monthly record of sales for year 2003
select DATENAME(month, ORDERDATE) as 'Month',COUNT(ORDERNUMBER) as 'Total Orders',
       SUM(QUANTITYORDERED) as 'Total quantity ordered', ROUND(SUM(sales),2) as 'Total monthly sales' 
from   sales_data_sample
where  YEAR_ID = 2003
group by DATENAME(month, ORDERDATE) 
order by 4 desc

--total monthly record of sales for year 2004
select DATENAME(month, ORDERDATE) as 'Month',COUNT(ORDERNUMBER) as 'Total Orders',
       SUM(QUANTITYORDERED) as 'Total quantity ordered', ROUND(SUM(sales),2) as 'Total monthly sales' 
from   sales_data_sample
where  YEAR_ID = 2004
group by DATENAME(month, ORDERDATE) order by 4 desc

--total monthly record of sales for year 2005
select DATENAME(month, ORDERDATE) as 'Month',COUNT(ORDERNUMBER) as 'Total Orders',
       SUM(QUANTITYORDERED) as 'Total quantity ordered',ROUND(SUM(sales),2) as 'Total monthly sales' 
from   sales_data_sample
where  YEAR_ID = 2005
group by DATENAME(month, ORDERDATE)
order by 4 desc

--product sold in the month of novermber for year 2003
select MONTH_ID, PRODUCTLINE,SUM(QUANTITYORDERED) as 'Quantity sold', 
       ROUND(avg(SALES),2) as 'Avg sales' 
from   sales_data_sample
where  YEAR_ID = 2003 and MONTH_ID = 11 
group by MONTH_ID, PRODUCTLINE 
order by 4 desc

--best customer (RFM analysis)

DROP TABLE IF EXISTS #rfm
;with rfm as (
select CUSTOMERNAME,
		MAX(CONVERT(DATE,ORDERDATE)) as 'Last order date',
		DATEDIFF(DD,MAX(CONVERT(date,ORDERDATE)),(select MAX(CONVERT(DATE,orderdate)) from sales_data_sample)) as 'Recency',
		COUNT(ORDERNUMBER) as 'Frequency',
		ROUND(AVG(SALES),2) as 'AVG Monetary Sales'
from   sales_data_sample
group by CUSTOMERNAME
),
 rfm_cal as (
select *,
		NTILE(4) over (order by recency desc) as 'rfm Recency',
		NTILE(4) over (order by frequency) as 'rfm frequency',
		NTILE(4) over (order by [avg monetary sales]) as 'rfm AVG Monetary sales'
from rfm
)
select *,
		[rfm Recency] + [rfm frequency] + [rfm AVG Monetary sales] as 'rfm value',
		CONVERT(nvarchar,[rfm Recency]) + CONVERT(nvarchar, [rfm frequency]) + CONVERT(nvarchar,[rfm AVG Monetary sales]) as 'rfm value string'
INTO #rfm
from rfm_cal

select CUSTOMERNAME,[rfm value string],
		case when [rfm value] > 8 then 'High value customer'
			when [rfm value] > 4 and [rfm value] < 9 then 'valued customer'
			else 'low valued customer' end as 'rfmCategory'

from #rfm 

--products that are sold together

select distinct (ordernumber), 
stuff(
	(select ',' + PRODUCTCODE 
	 from sales_data_sample p
	 where ORDERNUMBER in (
			select ordernumber 
			from ( 
				select ORDERNUMBER, count(ORDERNUMBER) as TotalOrders
				from sales_data_sample
				where STATUS = 'shipped'
				group by ORDERNUMBER) as totalorder
		    where TotalOrders = 2) and p.ORDERNUMBER = s.ORDERNUMBER
	 for xml path ('')),
1,1,'') as productcode
from sales_data_sample s
order by productcode desc

--productlines frequently used together 
with newT 
as (
select distinct (ordernumber), stuff(
   (select distinct(',' + productline) 
	from sales_data_sample p 
	where ordernumber in (
		select ordernumber
		from  (select ORDERNUMBER, COUNT(ORDERNUMBER) as TotalOrders
			   from sales_data_sample
			   group by ORDERNUMBER) as orders
		where TotalOrders > 2) and p.ORDERNUMBER = s.ORDERNUMBER
	for xml path ('')),
1,1,'') as productline, count(distinct PRODUCTLINE) as ProductlineUsed
from sales_data_sample s
group by ordernumber )

select ordernumber,productline,productlineused
from newT
where productlineused > 2
order by productlineused desc

