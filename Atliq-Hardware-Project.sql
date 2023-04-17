SELECT * FROM gdb023.dim_customer;

#QUERY1-Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT DISTINCT(market)
FROM gdb023.dim_customer
WHERE region = 'APAC' AND customer = 'Atliq Exclusive';

#other method for Power-Bi dashboard
SELECT customer, dim_customer.customer_code,platform,region,fiscal_year,sold_quantity,MARKET,sub_zone
FROM dim_customer JOIN fact_sales_monthly ON fact_sales_monthly.customer_code=dim_customer.customer_code
WHERE CUSTOMER='ATLIQ EXCLUSIVE' AND REGION='APAC';

#QUERY2-What is the percentage of unique product increase in 2021 vs. 2020? 
#The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg
WITH CTE1 AS 
	(SELECT count(DISTINCT product_code) AS UNIQUE_PRODUCT_2020
	FROM  fact_sales_monthly
	WHERE fiscal_year='2020'),
CTE2 AS 
	(SELECT COUNT( DISTINCT product_code) AS UNIQUE_PRODUCT_2021
	FROM  fact_sales_monthly
	WHERE fiscal_year='2021')
SELECT 
	UNIQUE_PRODUCT_2020,
    UNIQUE_PRODUCT_2021,
	ROUND((UNIQUE_PRODUCT_2021 - UNIQUE_PRODUCT_2020)*100/UNIQUE_PRODUCT_2020,2) AS percentage_chg
FROM CTE1
CROSS JOIN CTE2;


#QUERY3-Provide a report with all the unique product counts for each segment 
#and sort them in descending order of product counts. 
#The final output contains 2 fields,
# 1. segment 
# 2. product_count
SELECT segment, COUNT(*) AS product_count
FROM dim_product
GROUP BY segment 
ORDER BY PRODUCT_COUNT;


#QUERY4-Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
#The final output contains these fields, 
#1.segment
#2.product_count_2020 
#3.product_count_2021 
#4.difference
WITH CTE1 AS
	(SELECT dim_product.segment , COUNT(distinct fact_sales_monthly.product_code) AS PRODUCT_COUNT_2020
	FROM DIM_PRODUCT
	JOIN  FACT_SALES_MONTHLY ON DIM_PRODUCT.PRODUCT_CODE=FACT_SALES_MONTHLY.PRODUCT_CODE
	WHERE FISCAL_YEAR=2020
	GROUP BY dim_product.segment),
CTE2 AS 
	(SELECT dim_product.segment , COUNT(distinct fact_sales_monthly.product_code) AS PRODUCT_COUNT_2021
	FROM DIM_PRODUCT
	JOIN  FACT_SALES_MONTHLY ON DIM_PRODUCT.PRODUCT_CODE=FACT_SALES_MONTHLY.PRODUCT_CODE
	WHERE FISCAL_YEAR=2021
	GROUP BY dim_product.segment)
SELECT CTE1.SEGMENT,PRODUCT_COUNT_2020,PRODUCT_COUNT_2021,
(PRODUCT_COUNT_2021- PRODUCT_COUNT_2020) AS DIFFERENCE
FROM CTE1
JOIN CTE2
ON CTE1.segment = CTE2.segment
ORDER BY DIFFERENCE DESC;


#QUERY5-Get the products that have the highest and lowest manufacturing costs. 
#The final output should contain these fields, 
#1.product_code 
#2.product 
#3.manufacturing_cost
SELECT dim_product.product_code,PRODUCT,MANUFACTURING_COST FROM fact_manufacturing_cost
JOIN dim_product
ON dim_product.product_code=fact_manufacturing_cost.product_code
WHERE fact_manufacturing_cost.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM gdb023.fact_manufacturing_cost)
OR
fact_manufacturing_cost.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM gdb023.fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;


#QUERY 6-Generate a report which contains the top 5 customers who 
#received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
#The final output contains these fields, 
#1.customer_code 
#2.customer average_discount_percentage
SELECT DIM_CUSTOMER.CUSTOMER_CODE,DIM_CUSTOMER.CUSTOMER, ROUND(AVG(fact_pre_invoice_deductions.pre_invoice_discount_pct),2) AS AVERAGE_PCT
FROM fact_pre_invoice_deductions
JOIN dim_customer
ON dim_customer.customer_code=fact_pre_invoice_deductions.customer_code
WHERE fiscal_year=2021
group by customer_code,customer
ORDER BY AVERAGE_PCT desc
LIMIT 5;


#Query7-Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
#This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
#The final report contains these columns: 
#1.Month 
#2.Year 
#3.Gross sales Amount
SELECT CONCAT(MONTHNAME(date), ' (', YEAR(date), ')') AS 'Month', YEAR(DATE_ADD(date, INTERVAL 4 MONTH)) AS year,SUM(fact_gross_price.gross_price*fact_sales_monthly.sold_quantity) AS GROSS_SALES_AMOUNT
FROM fact_gross_price JOIN fact_sales_monthly ON fact_gross_price.product_code=fact_sales_monthly.product_code
JOIN dim_customer 
ON dim_customer.CUSTOMER_CODE=FACT_SALES_MONTHLY.CUSTOMER_CODE
WHERE dim_customer.customer = 'Atliq Exclusive'
group by month,year;

#QUERY8-In which quarter of 2020, got the maximum total_sold_quantity? 
#The final output contains these fields sorted by 
#1the total_sold_quantity, 
#2.Quarter total_sold_quantity
SELECT 
CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then 1  
    WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then 2
    WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then 3
    WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then 4
    END AS Quarters,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters
ORDER BY total_sold_quantity DESC;

#QUERY9-Which channel helped to bring more gross sales in the fiscal year 2021 and
#the percentage of contribution? 
#The final output contains these fields, 
#1.channel 
#2.gross_sales_mln 
#3.percentage
with CTE1 as (
SELECT channel AS Channel,round(sum(fact_gross_price.gross_price*fact_sales_monthly.sold_quantity)/1000000,2) AS Gross_Sales_mln
from fact_gross_price join fact_sales_monthly on fact_gross_price.product_code=fact_sales_monthly.product_code
join dim_customer on dim_customer.customer_code=fact_sales_monthly.customer_code
where fact_sales_monthly.fiscal_year='2021'
group by Channel)

select*,ROUND(Gross_Sales_mln*100/sum(Gross_Sales_mln) OVER(), 2)
      AS Percentage
      FROM CTE1;
      
#Query10-Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
#The final output contains these fields, division product_code
WITH CTE1 AS (
    SELECT fact_gross_price.product_code, division, SUM(fact_gross_price.gross_price*fact_sales_monthly.sold_quantity) AS total_sold_quantity
    FROM fact_gross_price 
    JOIN fact_sales_monthly ON fact_gross_price.product_code=fact_sales_monthly.product_code
    JOIN dim_product ON dim_product.product_code=fact_sales_monthly.product_code
    WHERE fact_gross_price.fiscal_year=2021
    GROUP BY division, fact_gross_price.product_code
),
CTE2 AS (
    SELECT *, RANK() OVER (ORDER BY total_sold_quantity DESC) AS Ranking
    FROM CTE1
)
SELECT *
FROM CTE2
where Ranking < 4;
