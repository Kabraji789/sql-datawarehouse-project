-----------------------------------
-- crm_cust_info
-------------------------------------
-- below are few qualities check queries with bronze 
select  top 100 *
from bronze.crm_cust_info;
select count(*) as total_rows from bronze.crm_cust_info;
select count(cst_id) as total_non_values from bronze.crm_cust_info;
select count(distinct cst_id) as unique_values from bronze.crm_cust_info;
select * from bronze.crm_cust_info where cst_id is null;

/*  checking how many duplicate value exist in the primary key*/
--check for duplicate in primary keys
select cst_id, count(*) from bronze.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null;


--check for unwanted space  and it goes same for the firstname as well so use trim function
select cst_lastname from bronze.crm_cust_info where cst_lastname != trim(cst_lastname);

-- data standardization and consistency in two columns gendr and marital status and we make it to female for f and male for m
-- and s  for singl and m for married
select distinct(cst_gndr) from bronze.crm_cust_info; -- we have null values as well in this 
select distinct(cst_marital_status) from bronze.crm_cust_info; -- we deal with null as n/a

----------------------------------- quality check queries for crmcust_info----------------------------------
select  top 100 *
from silver.crm_cust_info;
select count(*) as total_rows from silver.crm_cust_info;
select count(cst_id) as total_non_values from silver.crm_cust_info;
select count(distinct cst_id) as unique_values from silver.crm_cust_info;
select * from silver.crm_cust_info where cst_id is null;

/*  checking how many duplicate value exist in the primary key */
--check for duplicate in primary keys ---> there will be no duplicates now in primary key
select cst_id, count(*) from silver.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null;


-- it won't give any difference now
select cst_lastname from silver.crm_cust_info where cst_lastname != trim(cst_lastname);

-- data standardization and consistency in two columns gendr and marital status and we make it to female for f and male for m
-- now these queries will give n/a where data was null in the bronze layer
select distinct(cst_gndr) from silver.crm_cust_info; -- we have null values as well in this 
select distinct(cst_marital_status) from silver.crm_cust_info; -- we deal with null as n/a

-----------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------
-- cust_prd_info
---------------------------------------------------------

select top 50 * from bronze.crm_prd_info;
select prd_id, count(*) from bronze.crm_prd_info
group by prd_id
having count(*) > 1 or prd_id is null;

--check if the prd_cost have negative or null values
select prd_cost from bronze.crm_prd_info where prd_cost < 0 or prd_cost is null;

-- data standardization
--prd_line
select distinct(prd_line) from bronze.crm_prd_info;

------------------------- quality checking for crm_prd_info--------------------------------------------
select * from silver.crm_prd_info;
select prd_cost from silver.crm_prd_info where prd_cost < 0 or prd_cost is null; --if cost is null of negative
select distinct(prd_line) from silver.crm_prd_info; --data standardization
select * from silver.crm_prd_info where prd_start_dt > prd_end_dt; -- checking the order of the date if start date > end date

----------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------
---crm_sales_details
------------------------------------------------

---checking if date <=0
use DataWarehouse;
select  * from bronze.crm_sales_details
where sls_due_dt <=0 or len(sls_due_dt) != 8
or sls_due_dt >20500101 or sls_due_dt<19000101; -- this range shows that our business is running in this range only

-- checking if order date is higher then shipping or due date
select * from bronze.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt;

-- checking if sales != quantity* price and if any quantity or price or seales has negative, zero or null values
select sls_sales,
	   sls_quntity,
	   sls_price
from bronze.crm_sales_details
where sls_sales != sls_quntity*sls_price
or sls_sales <= 0 or sls_quntity <=0 or sls_price <=0
or sls_sales is null or sls_quntity is null or sls_price is null
order by sls_sales,sls_quntity,sls_price;

------------------------------------quality checking for crm_sales_details-----------------------------------------------

--checking if the sales < quantity * price and any value is null or negative
select sls_sales,
	   sls_quantity,
	   sls_price
from silver.crm_sales_details
where sls_sales != sls_quantity*sls_price
or sls_sales <= 0 or sls_quantity <=0 or sls_price <=0
or sls_sales is null or sls_quantity is null or sls_price is null
order by sls_sales,sls_quantity,sls_price;

--check if we still have order dates greater than shipping or due date
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt; 

--------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------
---erp_cust_az12
------------------------------------------

--checking if birthdate is out of range
select * from bronze.erp_cust_AZ12 where bdate < '1924-01-01' or bdate > GETDATE();

---data standardization and consistency
select distinct(gen) from bronze.erp_cust_AZ12;

---------------------------------quality checking for erp_cust_AZ12--------------------------------------------------

----data stndardizationa nd consistency
select distinct(gen) from silver.erp_cust_AZ12;

-----------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------
---erp_loc_101
-----------------------------------------------
select  top 10 * from bronze.erp_loc_A101;
select top 10 * from bronze.crm_cust_info;

--data standardizaton and consistency
select distinct(cntry) from bronze.erp_loc_A101; 

-------------------------------quality checking for erp_loc_A101--------------------------------------------------------------

select top 10 * from silver.erp_loc_A101;
select distinct(cntry) from silver.erp_loc_A101;

------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------
---erp_px_cat_g1v2
-----------------------------------------------
select * from bronze.erp_px_cat_g1v2;
select top 50 * from silver.crm_prd_info;

select maintenance from bronze.erp_px_cat_g1v2 -- checking for spaces
where trim(maintenance) != maintenance;

select distinct(cat) from bronze.erp_px_cat_g1v2; -- data standardization

---------------------------------------------------------------------------------------------------------------------------------------------
