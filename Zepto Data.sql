-- =====================================================
--  ZEPTO INVENTORY ANALYSIS  |  PostgreSQL (pgAdmin)
-- =====================================================

-- 1. CREATE TABLE
drop table if exists zepto

create table zepto(
sku_id serial primary key,
category varchar(120),
name varchar(150) not null,
mrp numeric(8,2),
discount_percent numeric(5,2),
available_quantity integer,
discount_selling_price numeric(8,2),
weight_in_grams integer,
out_of_stock boolean,
quantity integer
);


--data exploration

--data overview
select * from zepto

--sample data
select * from zepto
limit 10

--number of rows
select count(*) from zepto

--checking null values 
select * from zepto
where name is null or category is null or mrp is null or discount_percent is null or discount_selling_price is null or weight_in_grams is null or  avalible_quantity is null or out_of_stock is null or quantity is null;

--diifrent product categories
select distinct category
from zepto
order by category

--check stock (out of stock vs in stock)
select out_of_stock ,count(sku_id)
from zepto
group by out_of_stock

--product names present multiple times
select name, count(sku_id) as "Number of products prsent"
from zepto
group by name
having count(sku_id)>1
order by count(sku_id) desc


--cleaning
--product with price zero 
select *
from zepto
where mrp = 0 or discount_selling_price = 0;

delete from zepto
where mrp = 0

--convert mrp units to rupees
update zepto
set mrp=mrp/100.0,
discount_selling_price =discount_selling_price/100.0

select mrp , discount_selling_price from zepto


--creating metrics
create or replace view metrics as
select
sku_id,
category,
name,
mrp,
discount_percent,
discount_selling_price,
available_quantity,
weight_in_grams,
out_of_stock,
--discount amount
round((mrp - discount_selling_price)::numeric, 2) as discount_amount,
--calculated discount percentage
round((mrp - discount_selling_price)*100 :: numeric ,2) as calculated_discount_percent,
--inventory value at mrp
round((mrp*available_quantity) :: numeric ,2) as inventory_value_at_mrp,
--discounted_inventory_value
round((discount_selling_price * available_quantity)::numeric,2) as discounted_inventory_value,
--potential_customer_savings
round(((mrp - discount_selling_price) * available_quantity)::numeric,2) as potential_customer_savings,
--price_per_gram
round((discount_selling_price / NULLIF(weight_in_grams, 0))::numeric,2) as price_per_gram

FROM zepto;

drop view metrics;
select count(*)
from metrics

SELECT *
FROM metrics
LIMIT 10;

--EDA
--
select
min(mrp) as minimum_mrp,
max(mrp) as maximum_mrp,
round(avg(mrp)::numeric , 2) as average_mrp,
min(discount_selling_price) as minimum_discount_selling_price,
max(discount_selling_price) as maximum_discount_selling_price,
round(avg(discount_selling_price)::numeric , 2) as average_discount_selling_price
from zepto

-- 1. which categories have the most products?
select category, count(*) as total_products
from zepto
group by category
order by total_products desc;


-- 2. which products have the highest discounts?
select name, category, discount_percent
from zepto
order by discount_percent desc
limit 10;


-- 3. which products offer the highest discounts in rupees?
select name, mrp, discount_selling_price,
       mrp - discount_selling_price as discount_amount
from zepto
order by discount_amount desc
limit 10;


-- 4. which categories have the highest average discounts?
select category, round(avg(discount_percent)::numeric, 2) as avg_discount
from zepto
group by category
order by avg_discount desc;


-- 5. how are products distributed across discount ranges?
select
    case
        when discount_percent = 0 then 'no discount'
        when discount_percent <= 10 then '1-10%'
        when discount_percent <= 25 then '11-25%'
        when discount_percent <= 50 then '26-50%'
        else 'above 50%'
    end as discount_range,
    count(*) as total_products
from zepto
group by discount_range
order by total_products desc;


-- 6. what percentage of products are out of stock?
select
    round(
        count(*) filter (where out_of_stock = true) * 100.0
        / nullif(count(*), 0), 2
    ) as out_of_stock_percentage
from zepto;


-- 7. which categories have the most out-of-stock products?
select category, count(*) as out_of_stock_products
from zepto
where out_of_stock = true
group by category
order by out_of_stock_products desc;


-- 8. which products have the lowest available stock?
select name, category, available_quantity
from zepto
where available_quantity > 0
order by available_quantity asc
limit 10;


-- 9. which categories have the highest inventory value at mrp?
select category,
       round(sum(mrp * available_quantity)::numeric, 2) as inventory_value
from zepto
group by category
order by inventory_value desc;


-- 10. which categories have the highest discounted inventory value?
select category,
       round(sum(discount_selling_price * available_quantity)::numeric, 2)
       as discounted_inventory_value
from zepto
group by category
order by discounted_inventory_value desc;


-- 11. which products have the lowest price per gram?
select name, category,
       round((discount_selling_price / nullif(weight_in_grams, 0))::numeric, 2)
       as price_per_gram
from zepto
where weight_in_grams > 0
order by price_per_gram asc
limit 10;


-- 12. which categories combine high discounts with high inventory quantities?
select category,
       round(avg(discount_percent)::numeric, 2) as avg_discount,
       sum(available_quantity) as total_stock
from zepto
group by category
order by avg_discount desc, total_stock desc;


