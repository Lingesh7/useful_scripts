--Tables: Products 
----------------
--product name and price from prdts tbl wch has price abv Rs.1000. 

--1
select name, price from products where price > 1000; 
-- Table: Inventory
-- category_id cols identical

--2 
select a.* from 
(select p.*, i.* 
from products p 
right join inventory i 
where p.category_id = i.category_id )a where a.category_id is not null;

--3 
--product_details,prd_id 
--Nokia_105 1 1
--Nokia_105 2 2
--Nokia 209 3 1

select a.* from (
select prd_dtls, prd_id, row_number() over partitioned by product_dtls as r_num
from products) a
where a.r_num = 1;

--4
-- prd_names starts with vowel and ends with er.
select product_name
from products
where substring(product_name,0,1) in ('a','e','i','o','u') 
	  and 
	  substring(product_name,-2,-1) = 'er';

--5
--seq id num to get odd number alter records from the products tbl
--postgres
select * from products where eval(seq_id//2 != 0); 





