/*This Query builds on Query 1 to get the data for the top 200 customers with the highest total amount (with tax) who have not ordered for the last 365 days*/

WITH LatestCustomerAddress AS (
    SELECT 
        CustomerID,
        MAX(AddressID) AS LatestAddressID
    FROM 
        `adwentureworks_db.customeraddress`
    GROUP BY 
        CustomerID
),
CustomerSales AS (
    SELECT 
        CustomerID,
        COUNT(SalesOrderID) AS NumberOfOrders,
        ROUND(SUM(TotalDue), 2) AS TotalAmount,
        MAX(OrderDate) AS LastOrderDate
    FROM 
        `adwentureworks_db.salesorderheader`
    GROUP BY 
        CustomerID
),
    CustomerDetails AS (
    SELECT 
        Individual.CustomerID,
        Contact.FirstName,
        Contact.LastName,
        CONCAT(Contact.Firstname, ' ', Contact.LastName) FullName, 
        CASE 
           WHEN Contact.Title IS NOT NULL THEN CONCAT(Contact.Title, ' ', Contact.Firstname)
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
        `adwentureworks_db.individual` Individual 
    INNER JOIN 
        `adwentureworks_db.contact` Contact  ON Individual.ContactID = Contact.ContactID
    INNER JOIN 
        `adwentureworks_db.customer` Customer ON Individual.CustomerID = Customer.CustomerID
    INNER JOIN 
        LatestCustomerAddress ON Individual.CustomerID = LatestCustomerAddress.CustomerID   
    INNER JOIN 
        `adwentureworks_db.address` Address ON LatestCustomerAddress.LatestAddressID = Address.AddressID
    INNER JOIN 
        `adwentureworks_db.stateprovince` StateProvince ON Address.StateProvinceID = StateProvince.StateProvinceID
    INNER JOIN 
        `adwentureworks_db.countryregion` CountryRegion ON StateProvince.CountryRegionCode = CountryRegion.CountryRegionCode
    INNER JOIN 
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
FROM 
    CustomerDetails
--add a WHERE clause to ensure only customers who have not ordered for the last 365 days is returned
    WHERE LastOrderDate <= DATE_SUB((SELECT MAX(OrderDate) FROM `adwentureworks_db.salesorderheader`), INTERVAL 365 DAY)
ORDER BY TotalAmount DESC
LIMIT 200;
