/*This query builds on Query2 to add a new column 'CustomerStatus' which marks active and inactive customers based on whether they have ordered
anything during the past 365 days*/

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
       LastOrderDate, 
--extra column (CustomerStatus) using CASE WHEN function to mark active and inactive customers
       CASE WHEN LastOrderDate < DATE_SUB((SELECT MAX(OrderDate) FROM `adwentureworks_db.salesorderheader`), INTERVAL 365 DAY) 
            THEN 'Inactive'
             ELSE 'Active'
              END AS CustomerStatus
FROM 
    CustomerDetails
ORDER BY CustomerID DESC
LIMIT 500;
