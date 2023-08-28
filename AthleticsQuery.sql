
/*Calculating and adding Sales, COGS and Gross Profit Margin to the existing table */
alter table SupplyChainData
add Sales as (
case when [Delivery Status] = 'Shipping canceled' then 0
else ((1- [Order Discount Rate])* ([Product Price ($)]* [Order Quantity]))
end); 

alter table SupplyChainData
add COGS as (
case when [Delivery Status] = 'Shipping canceled' then 0
else (((1- [Order Discount Rate])* ([Product Price ($)]* [Order Quantity])) - [Order Profit Per Order ($)])
end);

alter table SupplyChainData
add GrossProfitMargin as (
case when [Delivery Status] = 'Shipping canceled' then 0 
else (((1- [Order Discount Rate])* ([Product Price ($)]* [Order Quantity])) - (((1- [Order Discount Rate])* ([Product Price ($)]* [Order Quantity])) - [Order Profit Per Order ($)]))/((1- [Order Discount Rate])* ([Product Price ($)]* [Order Quantity])) 
end);

/*Calculating time taken for shipment */
alter table SupplyChainData
add ShippingTime as (
case when [Delivery Status] = 'Shipping canceled' then 0 
else DATEDIFF(day, Order_date, Shipping_date)
end);


/*Calculating shipment status */
alter table SupplyChainData
add ShippingStatus as (
case when [Delivery Status] = 'Shipping canceled' then 'Cancelled Shipment'
when DATEDIFF(day, Order_date, Shipping_date) > [Days for shipment (scheduled)] then 'Late Shipment'
else 'On-time Shipment'
end);





/*Questions*/

/*What are the monthly sales and order quantity for Athletics?*/
select DATEPART(month, order_date) as Month, SUM([Order Quantity]) as [Product Quantity], SUM(Sales) as [Monthly Sales]
from SupplyChainData
where Order_date is not null and [Delivery Status] != 'Shipping canceled'
group by DATEPART(month, order_date)
order by month



/*Which continent has the most sales? How does profit compare to the sales?*/
--SOLUTION 1:
select (case when [Order Region] like '%Europe%' then 'Europe'
when [Order Region] like '%Asia%' then 'Asia'
when [Order Region] = 'Central America' or [Order Region] = 'Canada' or [Order Region] = 'Caribbean' then 'North America'
when [Order Region] = 'South America' then 'South America'
when [Order Region] like '%Africa%' then 'Africa'
when [Order Region] = 'Oceania' then 'Oceania'
end) as [Continents], SUM(Sales) as [Sales by Region], SUM([Order Profit Per Order ($)]) as [Gross Profit],  (SUM([Order Profit Per Order ($)])/SUM(Sales))*100 as [Profit:Sales Ratio (%)]
from SupplyChainData
where [Order Region] is not null and [Delivery Status] != 'Shipping canceled'
group by
(case when [Order Region] like '%Europe%'  then 'Europe'
when [Order Region] like '%Asia%'  then 'Asia'
when [Order Region] = 'Central America' or [Order Region] = 'Canada' or [Order Region] = 'Caribbean' then 'North America'
when [Order Region] = 'South America' then 'South America'
when [Order Region] like '%Africa%' then 'Africa'
when [Order Region] = 'Oceania' then 'Oceania'
end)
order by [Sales by Region] desc;

--SOLUTION 2
with countries as (
select (case when [Order Region] like '%Europe%' then 'Europe'
when [Order Region] like '%Asia%' then 'Asia'
when [Order Region] = 'Central America' or [Order Region] = 'Canada' or [Order Region] = 'Caribbean' then 'North America'
when [Order Region] = 'South America' then 'South America'
when [Order Region] like '%Africa%' then 'Africa'
when [Order Region] = 'Oceania' then 'Oceania'
end) as [Continents], Sales, [Order Profit Per Order ($)]
from SupplyChainData
where [Order Region] is not null and [Delivery Status] != 'Shipping canceled'
)
select Continents, SUM(Sales) as [Sales by Region], SUM([Order Profit Per Order ($)]) as [Gross Profit],  (SUM([Order Profit Per Order ($)])/SUM(Sales))*100 as [Profit:Sales Ratio (%)]
from countries
group by Continents;




/*Which product category has the most sales? And which products within these categories are top-selling? */
with temp as (
select [Product Name], [Product Category], sum([Order Quantity]) as Quantity
from SupplyChainData
where [Delivery Status] != 'Shipping canceled'
group by [Product Category], [Product Name]
),
temp2 as (
select [Product Category], sum([Order Quantity]) as CategorySum
from SupplyChainData
where [Delivery Status] != 'Shipping canceled'
group by [Product Category]
)

select DENSE_RANK() over (partition by t1.[Product Category] order by Quantity desc) as ProductRank,t1.[Product Category], CategorySum , [Product Name], Quantity
from temp t1
join temp2 t2 on t1.[Product Category] = t2.[Product Category]
order by CategorySum desc



/*Who are Athletics top customers (specified by customer segment)?*/
select top(20) [Order Id], [Customer Segment], SUM(sales) as [Customer Sales]
from SupplyChainData
group by [Order Id], [Customer Segment]
order by [Customer Sales] desc


/*Sales by customer segment: Corporate vs. Consumer */
select [Customer Segment], SUM(Sales)as [Sales by Segment], SUM(Sales)*100/(select SUM(sales) from SupplyChainData) as [Percentage Total]
from SupplyChainData
where [Customer Segment] is not null
group by [Customer Segment]
order by [Sales by Segment] desc


/*Athletics' shipping efficiency: Shipping status by %*/
select ShippingStatus, COUNT(ShippingStatus)*100/(select COUNT(ShippingStatus) from SupplyChainData) as [Percentage Total]
from SupplyChainData
group by ShippingStatus
order by [Percentage Total] desc

