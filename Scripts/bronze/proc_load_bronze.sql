/*
Stored Procedure : Load Bronze Layer (source -> bronze)
=====================================================
Script Purpose :	this stored procedures load the data into Bronze layer from source CSV files.
                       - truncate the bronze tables if exists
					             - bulk insert form csv

*/


EXEC bronze.load_bronze;

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @bronze_start_time DATETIME,@bronze_end_time DATETIME;
	SET @bronze_start_time = GETDATE();
	BEGIN TRY
		PRINT '-------INSERETING DATA INTO DDL-------';
		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_cust_info;
		BULK INSERT bronze.crm_cust_info
		FROM 'G:\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> loding duration' + CAST(DATEDIFF(second,@start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------';
		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_cust_info;
		BULK INSERT bronze.crm_prd_info
		FROM 'G:\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> loding duration' + CAST(DATEDIFF(second,@start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_sales_details;
		BULK INSERT bronze.crm_sales_details
		FROM 'G:\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> loding duration' + CAST(DATEDIFF(second,@start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_cust_AZ12;
		BULK INSERT bronze.erp_cust_AZ12
		FROM 'G:\sql-data-warehouse-project\datasets\source_erp\cust_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> loding duration' + CAST(DATEDIFF(second,@start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_loc_A101;
		BULK INSERT bronze.erp_loc_A101
		FROM 'G:\sql-data-warehouse-project\datasets\source_erp\loc_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> loding duration' + CAST(DATEDIFF(second,@start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'G:\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> loding duration' + CAST(DATEDIFF(second,@start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '---------------------------';
	END TRY
	BEGIN CATCH
	PRINT '================================================';
	PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
	PRINT '================================================';
	END CATCH
	SET @bronze_end_time = GETDATE();
	PRINT '>> bronze layer time' + CAST(DATEDIFF(second, @bronze_start_time, @bronze_end_time ) AS NVARCHAR) + ' seconds';
END
