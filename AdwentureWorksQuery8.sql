--this query builds on query 7 by adding taxes on a country level
WITH SalesData AS (
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
),
CountryTaxRates AS (
  SELECT StateProvince.CountryRegionCode CountryRegionCode2,
       --tax rates can vary in country based on province so the column needed is mean_tax_rate
        ROUND(AVG(MaxTaxRate), 1) AS mean_tax_rate,
       --not all regions have data with taxes; this column represents the percentage of provinces with available tax rates for each country
        ROUND(COUNT(DISTINCT CASE WHEN MaxTaxRate IS NOT NULL THEN StateProvince.StateProvinceID END) / (COUNT(DISTINCT StateProvince.StateProvinceID)), 2) perc_provinces_w_tax
    FROM `adwentureworks_db.stateprovince` StateProvince
    --some states have multiple tax rates so the highest one is chosen
    LEFT JOIN (
                SELECT StateProvinceID, MAX(TaxRate) AS MaxTaxRate
                FROM `adwentureworks_db.salestaxrate` SalesTaxRate
                GROUP BY StateProvinceID
                  ) AS MaxTaxRates ON StateProvince.StateProvinceID = MaxTaxRates.StateProvinceID
    GROUP BY StateProvince.CountryRegionCode
)
SELECT 
  Month,
  CountryRegionCode,
  Region,
  number_orders,
  number_customers, 
  no_SalesPersons,
  Total_w_tax,
  RANK() OVER (PARTITION BY SalesData.CountryRegionCode, Region ORDER BY SalesData.Total_w_tax DESC) country_sales_rank,
  SUM(SalesData.Total_w_tax) OVER (PARTITION BY SalesData.CountryRegionCode, Region ORDER BY SalesData.Month) cumulative_sales_tax,
  mean_tax_rate,
  perc_provinces_w_tax
  FROM SalesData
  LEFT JOIN CountryTaxRates 
  ON SalesData.CountryRegionCode = CountryTaxRates.CountryRegionCode2
  ;
 