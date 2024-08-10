/*This is a query of monthly sales numbers in each country & region for ALL types of customers; included in the query are number of orders, customers and sales persons in each month with a total amount with tax earned*/

SELECT LAST_DAY(DATE(SalesOrderHeader.OrderDate), MONTH) Month, 
         SalesTerritory.CountryRegionCode CountryRegionCode,
         SalesTerritory.Name Region,
         COUNT(DISTINCT SalesOrderHeader.SalesOrderID) number_orders,
         COUNT(DISTINCT SalesOrderHeader.CustomerID) number_customers,
         COUNT(DISTINCT SalesOrderHeader.SalesPersonID) no_salesPersons,
         ROUND(SUM(SalesOrderHeader.TotalDue)) Total_w_tax
FROM `adwentureworks_db.salesorderheader` SalesOrderHeader
  LEFT JOIN `adwentureworks_db.salesterritory` SalesTerritory
USING (TerritoryID) --common key
    GROUP BY ALL;
