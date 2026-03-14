# Data Warehouse Project (SQL + Power BI)

## Overview

This project demonstrates the design and implementation of a **modern
data warehouse pipeline** using SQL and Power BI.\
The goal of the project is to simulate a real-world **data engineering
workflow**, starting from raw data ingestion to cleaned analytical
datasets and interactive dashboards.

The project follows the **Bronze → Silver → Gold architecture**, a
common pattern used in modern data warehouses.

------------------------------------------------------------------------

## Architecture

**Bronze Layer** - Raw data ingested from source systems - Minimal
transformations - Used for data auditing and traceability

**Silver Layer** - Data cleaning and standardization - Handling NULL
values, invalid records, and inconsistencies - Data type corrections and
business rule validation

**Gold Layer** - Business-ready datasets - Aggregations and analytical
tables - Used directly for reporting and dashboards

------------------------------------------------------------------------

## Technologies Used

-   **PostgreSQL**
-   **pgAdmin 4**
-   **SQL**
-   **Power BI**
-   **ETL Data Cleaning Techniques**
-   **Git & GitHub**

------------------------------------------------------------------------

## Key Data Cleaning Steps

The ETL pipeline includes several validation and transformation steps:

-   Handling **NULL values**
-   Fixing **negative values**
-   Validating **sales calculations**
-   Cleaning **customer IDs**
-   Standardizing **gender values**
-   Detecting **invalid birth dates**
-   Removing unrealistic values (age \> 100 years)
-   Ensuring data consistency across tables

Example transformation:

``` sql
CASE
    WHEN sls_sales IS NULL
         OR sls_sales <= 0
         OR sls_sales != sls_quantity * ABS(sls_price)
    THEN sls_quantity * ABS(sls_price)
    ELSE sls_sales
END AS sls_sales
```

------------------------------------------------------------------------

## Project Structure

    data-warehouse-project
    │
    ├── bronze/
    │   ├── raw_tables.sql
    │
    ├── silver/
    │   ├── data_cleaning.sql
    │
    ├── gold/
    │   ├── analytical_views.sql
    │
    ├── powerbi/
    │   ├── dashboard.pbix
    │
    └── README.md

------------------------------------------------------------------------

## Example Data Quality Checks

Examples of validation queries used in the project:

**Detect invalid birth dates**

``` sql
SELECT DISTINCT bdate
FROM bronze.erp_cust_az12
WHERE AGE(CURRENT_DATE, bdate) > INTERVAL '100 years'
   OR bdate > CURRENT_DATE;
```

**Detect incorrect sales values**

``` sql
SELECT *
FROM bronze.crm_sales_info
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0;
```


## Project Goals

-   Practice **data warehouse design**
-   Implement **SQL-based ETL transformations**
-   Perform **data quality validation**
-   Build **analytical dashboards**
-   Demonstrate **data engineering skills for portfolio projects**

------------------------------------------------------------------------

## Author

**Vishva Suraj**\
Aspiring Data Analyst / Data Engineer

------------------------------------------------------------------------

## Future Improvements
-   Add **Machine Learning predictions**
-   Implement **automated ETL pipelines**
-   Expand the **Gold layer analytical models**
-   Add more **advanced BI dashboards**
