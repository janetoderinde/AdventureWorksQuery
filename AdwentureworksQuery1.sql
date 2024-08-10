/*This query is to create a detailed overview of all individual customers stored in an individual table and/or defined by CustomerType = 'I'
  The top 200 rows are selected ordered by total amount (with tax)*/
--Create CTE LatestCustomerAddress to ensure the latest address id per customer is returned
WITH LatestCustomerAddress AS (
    SELECT 
        CustomerID,
        MAX(AddressID) AS LatestAddressID
    FROM 
        `adwentureworks_db.customeraddress`
    GROUP BY 
        CustomerID
),
--Create CTE CustomerSales to get aggregated sales and order details per customer ID
CustomerSales AS (
    SELECT 
        CustomerID,
        COUNT(SalesOrderID) AS NumberOfOrders,
        ROUND(SUM(TotalDue),2) AS TotalAmount,
        MAX(OrderDate) AS LastOrderDate
    FROM 
        `adwentureworks_db.salesorderheader`
    GROUP BY 
        CustomerID
),
--Create last CTE CustomerDetails to have the detailed overview; 1st and 2nd CTEs are joined to this CTE
    CustomerDetails AS (
    SELECT 
        Individual.CustomerID,
        Contact.FirstName,
        Contact.LastName, 
        CONCAT(Contact.Firstname, ' ', Contact.LastName) FullName, 
--CONCAT function in CASE WHEN to add addressing titles for null and non-null title column
        CASE WHEN Contact.Title IS NOT NULL 
                THEN CONCAT(Contact.Title, ' ', Contact. Firstname)
                    ELSE CONCAT('Dear', ' ', Contact.Firstname)
                END AS AddressingTitle,
        Contact.EmailAddress,
        Contact.Phone,
        Customer.AccountNumber,
        Customer.CustomerType, 
        Address.AddressLine1 CustomerAddress,
        Address.City,
        StateProvince.Name AS State,
        CountryRegion.Name AS Country,
        NumberOfOrders,
        TotalAmount,
        LastOrderDate
    FROM 
    --FROM Individual Table to ensure the Customer Type = 'I' criteria is fulfilled
        `adwentureworks_db.individual` Individual 
    INNER JOIN 
        `adwentureworks_db.contact` Contact  ON Individual.ContactID = Contact.ContactID
    INNER JOIN 
        `adwentureworks_db.customer` Customer ON Individual.CustomerID = Customer.CustomerID
    INNER JOIN 
    --JOIN first CTE to get latest customer address
        LatestCustomerAddress ON Individual.CustomerID = LatestCustomerAddress.CustomerID   
    INNER JOIN 
        `adwentureworks_db.address` Address ON LatestCustomerAddress.LatestAddressID = Address.AddressID
    INNER JOIN 
        `adwentureworks_db.stateprovince` StateProvince ON Address.StateProvinceID = StateProvince.StateProvinceID
    INNER JOIN 
        `adwentureworks_db.countryregion` CountryRegion ON StateProvince.CountryRegionCode = CountryRegion.CountryRegionCode
    INNER JOIN 
    --JOIN second CTE (CustomerSales) to get aggregated sales and order details
        CustomerSales ON Individual.CustomerID = CustomerSales.CustomerID
)
SELECT CustomerID, 
       FirstName, 
       LastName, 
       FullName, 
       AddressingTitle, 
       EmailAddress, 
       Phone, 
       AccountNumber, 
       CustomerType, 
       CustomerAddress, 
       City, 
       State, 
       Country, 
       NumberOfOrders, 
       TotalAmount, 
       LastOrderDate
FROM CustomerDetails
ORDER BY TotalAmount DESC --DESC function ensures the top customers are returned
LIMIT 200
;


