SELECT *
FROM project2.dbo.sales_data;


--Checking unique values
SELECT DISTINCT status
FROM project2.dbo.sales_data;
SELECT DISTINCT year_id
FROM project2.dbo.sales_data;
SELECT DISTINCT productline
FROM project2.dbo.sales_data;
SELECT DISTINCT country
FROM project2.dbo.sales_data;
SELECT DISTINCT dealsize
FROM project2.dbo.sales_data;
SELECT DISTINCT territory
FROM project2.dbo.sales_data;


--Checking unique month_id's where year_id is 2003
SELECT DISTINCT MONTH_ID
FROM project2.dbo.sales_data
WHERE YEAR_ID = 2003;


--Group sales(sum of)/revenue
SELECT productline, SUM(sales) Revenue
FROM project2.dbo.sales_data
GROUP BY productline
ORDER BY 2 DESC;

SELECT YEAR_ID, SUM(sales) Revenue
FROM project2.dbo.sales_data
GROUP BY YEAR_ID
ORDER BY 2 DESC;

SELECT DEALSIZE, SUM(sales) Revenue
FROM project2.dbo.sales_data
GROUP BY DEALSIZE
ORDER BY 2 DESC;


--Best month for sales in a specific year.
SELECT month_id, SUM(sales) Revenue, COUNT(ordernumber) Frequency
FROM project2.dbo.sales_data
WHERE year_id = 2004 -- Change year here
GROUP BY month_id 
ORDER BY 2 DESC;


--Which products were sold most in November and their sales
SELECT month_id, PRODUCTLINE, SUM(sales) Revenue, COUNT(ordernumber) Frequency
FROM project2.dbo.sales_data
WHERE year_id = 2003 AND month_id = 11
GROUP BY month_id, productline
ORDER BY 3 DESC;


-- Used to check which are the best customers
DROP TABLE IF EXISTS #rfm
;with rfm AS
(
	SELECT 
		customername,
		SUM(sales) MonetaryValue,
		AVG(sales) AvgMonetaryValue,
		COUNT(ordernumber) Frequency,
		MAX(orderdate) LastOrderDate,
		(SELECT MAX(orderdate) FROM project2.dbo.sales_data) MaxOrderDate,
		DATEDIFF(DD, MAX(orderdate), (SELECT MAX(orderdate) FROM project2.dbo.sales_data)) Recency
	FROM project2.dbo.sales_data
	GROUP BY customername
),
rfmCalc AS
(
	SELECT r.*,
		NTILE(4) OVER (ORDER BY Recency DESC) rfmRecency,
		NTILE(4) OVER (ORDER BY Frequency) rfmFrequency,
		NTILE(4) OVER (ORDER BY MonetaryValue) rfmMonetary
	FROM rfm r
)
SELECT 
	c.*, rfmRecency + rfmFrequency + rfmMonetary AS rfmCell,
	CAST(rfmRecency AS varchar) + CAST(rfmFrequency AS varchar) + CAST(rfmMonetary AS varchar) rfmCellString
INTO #rfm
FROM rfmCalc c;

SELECT *
FROM #rfm;

SELECT customername, rfmRecency, rfmFrequency, rfmMonetary,
	CASE
		WHEN rfmCellString in (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost customers'
		WHEN rfmCellString in (113, 114, 143, 244, 334, 343, 344) THEN 'slipping away, cannot lose'
		WHEN rfmCellString in (311, 411, 331) THEN 'new customers'
		WHEN rfmCellString in (222, 223, 233, 322) THEN 'potential churners'
		WHEN rfmCellString in (323, 333, 321, 422, 332,432) THEN 'active'
		WHEN rfmCellString in (433, 434, 443, 444) THEN 'loyal'
	END rfmSegment
FROM #rfm;


SELECT ordernumber, COUNT(*) RN
FROM project2.dbo.sales_data
WHERE status = 'Shipped'
GROUP BY ordernumber
ORDER BY 2 DESC;

SELECT *
FROM project2.dbo.sales_data
WHERE ordernumber = '10411'


SELECT ordernumber
FROM (
	SELECT ordernumber, COUNT(*) rn
	FROM project2.dbo.sales_data
	WHERE status = 'Shipped'
	GROUP BY ordernumber
)m
WHERE rn = 2;


--Check which products are most often sold together
SELECT DISTINCT ordernumber, STUFF(	
	(SELECT ','+ productcode
	FROM project2.dbo.sales_data p
	WHERE ordernumber IN
	(
		SELECT ordernumber
		FROM (
			SELECT ordernumber, COUNT(*) rn
			FROM project2.dbo.sales_data
			WHERE status = 'Shipped'
			GROUP BY ordernumber
		)m
		WHERE rn = 3
	)
	AND p.ordernumber = s.ordernumber
	FOR xml PATH (''))

	,1, 1, '') productcode
FROM project2.dbo.sales_data s
ORDER BY 2 DESC;


--City with the highest number of sales in a specific country
SELECT city, SUM(sales) Revenue
FROM project2.dbo.sales_data
WHERE country = 'USA'
GROUP BY city
ORDER BY 2 DESC;


--Best product in the US
SELECT country, year_id, productline, SUM(sales) Revenue
FROM project2.dbo.sales_data
WHERE country = 'UK'
GROUP BY country, year_id, productline
ORDER BY 4 DESC;