/*this query builds on query 5 with the cumulative_sum of the total amount with tax earned per country and region; query 5 is used as CTE SalesData here*/
WITH SalesData AS(
  SELECT LAST_DAY(DATE(SalesOrderHeader.OrderDate), MONTH) Month, 
         SalesTerritory.CountryRegionCode CountryRegionCode,
         SalesTerritory.Name Region,
         COUNT(DISTINCT SalesOrderHeader.SalesOrderID) number_orders,
         COUNT(DISTINCT SalesOrderHeader.CustomerID) number_customers,
         COUNT(DISTINCT SalesOrderHeader.SalesPersonID) no_salesPersons,
         ROUND(SUM(SalesOrderHeader.TotalDue), 0) Total_w_tax
FROM `adwentureworks_db.salesorderheader` SalesOrderHeader
  LEFT JOIN `adwentureworks_db.salesterritory` SalesTerritory
USING (TerritoryID)
    GROUP BY ALL
)
SELECT Month,
  CountryRegionCode,
  Region,
  number_orders,
  number_customers, 
  no_SalesPersons,
  Total_w_tax,
  SUM(SalesData.Total_w_tax) OVER (PARTITION BY SalesData.CountryRegionCode, Region ORDER BY SalesData.Month) cumulative_sales_tax
  FROM SalesData
;