/*this query builds on Query3 to extracxt data on all 'active' customers from North America; only customers that have either ordered no less than 2500 in total amount (with tax) or ordered 5 + times are represented*/

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
        SalesTerritory.Group Territory,
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
        `adwentureworks_db.salesterritory` SalesTerritory ON StateProvince.TerritoryID = SalesTerritory.TerritoryID
    INNER JOIN 
    CustomerSales ON Individual.CustomerID = CustomerSales.CustomerID
),
--new CTE 'CustomerStatusCTE' is created 
    CustomerStatusCTE AS(
                    SELECT *, 
                            CASE WHEN LastOrderDate < DATE_SUB((SELECT MAX(OrderDate) FROM `adwentureworks_db.salesorderheader`), INTERVAL 365 DAY) THEN 'Inactive'
                     ELSE 'Active'
                        END AS CustomerStatus
                            FROM CustomerDetails)
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
       CustomerAddress, 
--Split CustomerAddress into two columns: Address_no and Address_st
       LEFT(CustomerAddress, STRPOS(CustomerAddress, ' ') - 1) Address_no, 
       RIGHT(CustomerAddress, LENGTH(CustomerAddress) - STRPOS(CustomerAddress, ' ')) Address_st
FROM CustomerStatusCTE
    WHERE CustomerStatus = 'Active' --only active customers
    AND Territory = 'North America' --from North America
    AND (TotalAmount >= 2500 OR NumberOfOrders >= 5)  --OR in AND function 
ORDER BY Country, State, LastOrderDate
LIMIT 500;
