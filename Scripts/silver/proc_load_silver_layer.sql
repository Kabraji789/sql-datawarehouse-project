/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/
EXECUTE silver.load_silver;

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
		DECLARE @silver_start_time DATETIME,@silver_end_time DATETIME;
		SET @silver_start_time = GETDATE();
		BEGIN TRY
			PRINT '>> Truncating table : silver.crm_cust_info'
			TRUNCATE TABLE silver.crm_cust_info;

			PRINT '>> Inserting Data Into : silver.crm_cust_info'
			INSERT INTO silver.crm_cust_info(
				cst_id,
				cst_key,
				cst_firstname,
				cst_lastname,
				cst_marital_status,
				cst_gndr,
				cst_create_date)

			select 
				cst_id,
				cst_key,
				trim(cst_firstname) as cst_firstname,
				trim(cst_lastname) as cst_lastname,
				case
					when UPPER(trim(cst_marital_status)) = 'S' then 'Single' -- using trim if any spaces or using upper if we get the value in lowercase
					when UPPER(trim(cst_marital_status)) = 'M' then 'Married'
					else 'n/a'
				end as cst_marital_status,

				case
					when UPPER(trim(cst_gndr)) = 'F' then 'Female' -- using trim if any spaces or using upper if we get the value in lowercase
					when UPPER(trim(cst_gndr)) = 'M' then 'Male'
					else 'n/a'
				end as cst_gndr,
				cst_create_date
			from (
			select *,
			ROW_NUMBER() over(partition by cst_id order by cst_create_date ) as flag_last
			from bronze.crm_cust_info
			where cst_id is not null
			)x
			where flag_last =1; -- flag_last = 1 bcs we only considering the rows from the duplicate primary key which are latest created



			--------------------------------------------------------------------------------------------------------

			PRINT '>> Truncating table : silver.crm_prd_info'
			TRUNCATE TABLE silver.crm_prd_info;

			PRINT '>> Inserting Data Into : silver.crm_prd_info'
			INSERT INTO silver.crm_prd_info(
					prd_id,
					cat_id,
					prd_key,
					prd_nm,
					prd_cost,
					prd_line,
					prd_start_dt,
					prd_end_dt
			)
			select
				prd_id,
				replace((SUBSTRING(prd_key,1,5)),'-','_') as cat_id, -- replacing - to underscore in the cat_id s in the erp table id contains _
				substring(prd_key,7,len(prd_key)) as prd_key, -- to connect this table with sales table we just used this substring method
				prd_nm,
				ISNULL(prd_cost,0) as prd_cost,
				case
					when upper(trim(prd_line)) = 'M' then 'Mountain'
					when upper(trim(prd_line)) = 'R' then 'Road'
					when upper(trim(prd_line)) = 'S' then 'Other Sales'
					when upper(trim(prd_line)) = 'T' then 'Touring'
					else 'n/a' end as prd_line,
				cast (prd_start_dt as DATE) as prd_start_dt,--getting rid of the time as its 00 everywhere
				cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt) -1 as DATE) as prd_end_dt -- creating the end date using the start date with lead
			from bronze.crm_prd_info;


			------------------------------------------------------------------------------------------------------------

			PRINT '>> Truncating table : silver.crm_sales_details'
			TRUNCATE TABLE silver.crm_sales_details;

			PRINT '>> Inserting Data Into : silver.crm_sales_details'

			INSERT INTO silver.crm_sales_details(
				sls_ord_num ,
				sls_prd_key ,
				sls_cust_id ,
				sls_order_dt ,
				sls_ship_dt ,
				sls_due_dt ,
				sls_sales ,
				sls_quantity ,
				sls_price)
			SELECT
				sls_ord_num,
				sls_prd_key,
				sls_cust_id,
				case when sls_order_dt = 0 or len(sls_order_dt) != 8 then NULL
					 else cast(cast(sls_order_dt AS varchar) AS DATE)
					 end sls_order_dt,
				case when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then NULL
					 else cast(cast(sls_ship_dt AS varchar) AS DATE)
					 end sls_order_dt,
				case when sls_due_dt = 0 or len(sls_due_dt) != 8 then NULL  ---int to varchar to date	
					 else cast(cast(sls_due_dt AS varchar) AS DATE)
					 end sls_due_dt,
				case when sls_sales is null or sls_sales <=0 or sls_sales != (sls_quntity * ABS(sls_price)) then sls_quntity * abs(sls_price)
					 else sls_sales
				end as sls_sales,
				sls_quntity,
				case when sls_price is null or sls_price <= 0 then sls_sales / nullif(sls_quntity,0) -- any number should not be diveded by zero so making sure if 0 then do it as null
					 else sls_price
				end as sls_price
			FROM bronze.crm_sales_details;



			-----------------------------------------------------------------------------------------------------------------------------
			PRINT '>> Truncating table : silver.erp_cust_AZ12'
			TRUNCATE TABLE silver.erp_cust_AZ12;

			PRINT '>> Inserting Data Into : silver.erp_cust_AZ12'


			INSERT INTO silver.erp_cust_AZ12(
				cid,
				bdate,
				gen)
			select
			case when cid like 'NAS%' then substring(cid,4,len(cid))  -- remove nas values if present 
				 else cid
			end as cid,
			case when bdate > getdate() then NULL  -- setting future values to null
 				 else bdate
			end as bdate,
			case when upper(trim(gen)) in ('F','FEMALE') then 'Female'
				 when upper(trim(gen)) in ('M', 'MALE') then 'Male'
				 else 'n/a'
			end as gen
			from bronze.erp_cust_AZ12;


			---------------------------------------------------------------------------------------------------------------------------
			PRINT '>> Truncating table : silver.erp_loc_A101'
			TRUNCATE TABLE silver.erp_loc_A101;

			PRINT '>> Inserting Data Into : silver.erp_loc_A101'

			INSERT INTO silver.erp_loc_A101(
				cid,
				cntry)
			select
				case when cid like '%-%' then replace(cid,'-','') ---connecting this table with cust_info so replacing - with ''
				else cid
				end as cid,
				case when upper(trim(cntry)) = 'DE' then 'Germany'
					 when upper(trim(cntry)) in ('US','USA','UNITED STATES') then 'United States'  -- donig data standardization
					 when trim(cntry) = '' or cntry is null then 'n/a'
					 else trim(cntry)
				end as cntry

			from bronze.erp_loc_A101;


			-----------------------------------------------------------------------------------------------------------------------
			PRINT '>> Truncating table : silver.erp_px_cat_g1v2'
			TRUNCATE TABLE silver.erp_px_cat_g1v2;

			PRINT '>> Inserting Data Into : silver.erp_px_cat_g1v2'

			INSERT INTO silver.erp_px_cat_g1v2(
			id,cat,subcat,maintenance)
			select
				id,
				cat,
				subcat,
				maintenance
			from bronze.erp_px_cat_g1v2;
		END TRY
		BEGIN CATCH
			PRINT '================================================';
			PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
			PRINT '================================================';
		END CATCH
	SET @silver_end_time = GETDATE();
	PRINT '>> silver layer time' + CAST(DATEDIFF(second, @silver_start_time, @silver_end_time ) AS NVARCHAR) + 'seconds';
END
