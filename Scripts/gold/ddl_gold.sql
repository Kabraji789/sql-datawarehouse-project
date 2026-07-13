
/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================

/*
data integration is necessary and we have to check if data we are joining from two tables are consistent or not.
this is giving null as well because the id from cust_info is not available in the erp_loc table.
if we get issue that which data is the source of truth then it should be discussed with business and in our case its CRM	
*/

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER( order by cst_id) as customer_key, -- this is the surrogate key 
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	cl.cntry AS country,
	ci.cst_marital_status AS marital_status,
	
	case when ci.cst_gndr != 'n/a' then ci.cst_gndr  -- CRM is the mster for gender
		  else COALESCE(ca.gen,'n/a')
	 end as gender,
	 ca.bdate AS birthdate,
	 ci.cst_create_date AS create_date 
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_AZ12 ca
ON		  ca.cid = ci.cst_key
LEFT JOIN silver.erp_loc_A101 cl
ON		  cl.cid = ci.cst_key;

GO

/* for the product dimensions we don't want historical data so we need only current data so if end date = null thn we will onsder that only */

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
select
	ROW_NUMBER() over(order by pd.prd_start_dt,pd.prd_key) as product_key, 
	pd.prd_id AS product_id,
	pd.prd_key AS product_number,
	pd.prd_nm AS product_name,
	pd.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS sub_category,
	pc.maintenance,
	pd.prd_cost AS product_cost,
	pd.prd_line AS product_line,
	pd.prd_start_dt	AS start_date
from silver.crm_prd_info pd
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON		  pd.cat_id = pc.id
where prd_end_dt is null; -- filter out historical data

GO



-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

/* 
we will use the surrogate ids from the dimension tables to replace these prd_key an cust_id to join the the fact table and dimension table
*/
CREATE VIEW gold.fact_sales AS
select
	sd.sls_ord_num AS order_number,
	--sd.sls_prd_key , removed this as we will using the surrogate keys
	--sd.sls_cust_id ,
	pr.product_key,
	cr.customer_key,
	sd.sls_order_dt AS order_date ,
	sd.sls_ship_dt AS order_ship_date ,
	sd.sls_due_dt AS order_due_date ,
	sd.sls_sales As sales_amount ,
    sd.sls_quantity AS quantity ,
	sd.sls_price AS price
from silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON        sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cr
ON		  sd.sls_cust_id = cr.customer_id;

GO
