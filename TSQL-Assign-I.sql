--Create Product Table--
CREATE table Product(
	ProductID INT IDENTITY(1,1) PRIMARY KEY,
	ProductName varchar(100),
	Price int,
	StockQuantity int
);

--Insert Data Into Product--
INSERT INTO Product (ProductName, Price, StockQuantity)
VALUES
('keychain', 50, 30),
('Smartphone', 800, 100),
('Headphones', 100, 75),
('Tablet', 500, 30),
('Keyboard', 50, 120),
('Monitor', 300, 80);


---Create Customer Table---
CREATE table Customer (
	CustomerID INT IDENTITY(1000,1) PRIMARY KEY,
	FirstName varchar(100) NOT NULL,
	LastName varchar(100) NOT NULL,
	Email varchar(100) NOT NULL,
	Phone varchar(20) NOT NULL
);

---Create SalesTransaction Table---
CREATE TABLE SalesTransaction
(
	TransactionID INT IDENTITY(1,1) PRIMARY KEY,
	CustomerID INT,
	ProductID INT,
	Quantity INT,
	TotalAmount Decimal(10,2),
	TransactionDate DATE,
	FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID),
	FOREIGN KEY (ProductID) REFERENCES Product(ProductID)
);


INSERT INTO SalesTransaction (CustomerID, ProductID, Quantity, TotalAmount, TransactionDate)
VALUES
(1001, 8, 2,9000, '2021-11-10'),
(1000, 3, 3, 300, '2023-11-11'),
(1002, 2, 1, 800, '2023-11-12'),
(1003, 1, 1, 1200, '2023-11-13'),
(1004, 2, 4, 3200, '2023-11-14'),
(1001, 4, 2, 1000, '2023-11-15');


---Create Invoice Table--
CREATE TABLE Invoice
(
	InvoiceID INT IDENTITY(1,1) PRIMARY KEY,
	TransactionID INT,
	IssueDate DATE,
	DueDate DATE,
	Status varchar(20),
	FOREIGN KEY (TransactionID) REFERENCES SalesTransaction(TransactionID)
);

INSERT INTO Invoice (TransactionID, IssueDate, DueDate, Status)
VALUES
(1, '2023-11-10', '2023-11-17', 'Paid'),
(2, '2023-11-11', '2023-11-18', 'Pending'),
(3, '2023-11-12', '2023-11-19', 'Pending'),
(4, '2023-11-13', '2023-11-20', 'Due'),
(5, '2023-11-14', '2023-11-21', 'Pending'),
(6, '2023-11-15', '2023-11-22', 'Due');


-----Creating Stored procedures that take in Json Parameter for CRUD Operations---

--Create Stored Procedure---
GO
CREATE PROCEDURE spCreateProduct 
	@ProductJSON nvarchar(max)
AS
BEGIN
	INSERT INTO Product(ProductName, Price, StockQuantity)
	VALUES(
	JSON_VALUE(@ProductJSON, '$.ProductName'),
	JSON_VALUE(@ProductJSON, '$.Price'),
	JSON_VALUE(@ProductJSON, '$.StockQuantity')
	);
END

EXEC spCreateProduct '{
    "ProductName": "New Laptop",
    "Price": 1500,
    "StockQuantity": 20
}';


---Read Stored Procedure---
GO
CREATE PROCEDURE spReadProduct
	@ProductID INT = NULL
AS
BEGIN
	IF @ProductID IS NULL
		SELECT * FROM Product;
	ELSE 
		SELECT * FROM Product
		WHERE ProductID = @ProductID;
END


----Update Stored Procedure----
GO 
CREATE PROCEDURE spUpdateProduct 
	@ProductID INT,
	@ProductJSON NVARCHAR(MAX)
AS
BEGIN
	UPDATE Product
	SET
	ProductName = JSON_VALUE(@ProductJSON, '$.ProductName'),
	Price = JSON_VALUE(@ProductJSON, '$.Price'),
	StockQuantity = JSON_VALUE(@ProductJSON, '$.StockQuantity')
	WHERE @ProductID = ProductID
END

GO
EXEC spUpdateProduct 
	7,
'{
    "ProductName": "mero Laptop",
    "Price": 1500,
    "StockQuantity": 20
}';


----Delete Stored Procedure----
GO
CREATE PROCEDURE spDeleteProduct
	@ProductID INT
AS
BEGIN
	DELETE from Product
	WHERE ProductID = @ProductID
END


EXEC spDeleteProduct 7


-----------Creating Invoice---------

---Alter table salestransaction to link transaction to invoice---
ALTER TABLE SalesTransaction 
ADD InvoiceID INT NULL,
FOREIGN KEY (InvoiceID) REFERENCES Invoice(InvoiceID);



----Queries----
--List of customers whose name starts with the letter "A" or ends with the letter "S" but should have the letter "K"--
SELECT * FROM Customer
WHERE Customer.FirstName LIKE 'a%k%' OR Customer.FirstName LIKE '%k%s';

--
SELECT * 
FROM SalesTransaction;

SELECT * 
FROM Customer;


----Name of customer who has spent highest amount in a specific date range----
SELECT TOP 1 cus.FirstName, cus.LastName
FROM Customer cus
JOIN SalesTransaction st ON cus.CustomerID = st.CustomerID
WHERE st.TransactionDate BETWEEN '2023-10-30' AND '2023-11-13'
ORDER BY st.TotalAmount DESC;


SELECT * FROM Product;
SELECT * FROM SalesTransaction;


----List Products that have not been bought in the current year---
SELECT *
FROM Product pro
LEFT JOIN SalesTransaction st  ----OR INNER JOIN
ON pro.ProductID = st.ProductID
WHERE st.TransactionDate IS NULL OR YEAR(st.TransactionDate) <> YEAR(GETDATE()) ; 

---To delete the products that have not been bought in the current year---
DELETE
FROM Product 
WHERE NOT EXISTS (
	SELECT 1
	FROM SalesTransaction st
	WHERE Product.ProductID = st.ProductID
	AND
	(st.TransactionDate IS NOT NULL AND YEAR(st.TransactionDate) = YEAR(GETDATE()))
);


----adding delete cascade to deal with the refernce error "FK__SalesTran__Produ__5070F446"------
ALTER TABLE SalesTransaction
DROP CONSTRAINT FK__SalesTran__Produ__5070F446;


---ADD CASCADE DELETE which deletes any referencing rows in child table when the referenced row in the parent table gets deleted-----
ALTER TABLE SalesTransaction
ADD CONSTRAINT FK__SalesTran__Produ__5070F446
FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON DELETE CASCADE;

SELECT *
FROM Product;

SELECT *
FROM SalesTransaction;


---------------------------
---------------------------
ALTER TABLE Product
ADD Remaining INT;

-----------The product should have a remaining column which shows the remaining quantity of the product. This should be updated on the basis of sales transactions. 
-----------List out the products whose remaining quantity is less than 2.---------
GO
CREATE PROCEDURE spUpdateRemaining
AS
BEGIN
	UPDATE Product
	SET Remaining = Product.StockQuantity - COALESCE(sst.TotalQuantity, 0)
	FROM Product 
	LEFT JOIN (
		SELECT ProductID, SUM(Quantity) TotalQuantity 
		FROM SalesTransaction
		GROUP BY ProductID
	) sst ON Product.ProductID = sst.ProductID;
END

EXEC spUpdateRemaining;

SELECT * 
FROM Product 
WHERE Remaining < 2;


-----GET PRODUCT OF THE YEAR----
SELECT *
FROM Product;

SELECT *
FROM SalesTransaction;

SELECT *
FROM Customer;

WITH ProductCustomerCount_CTE AS (
	SELECT p.ProductID,p.ProductName, COUNT(DISTINCT st.CustomerID) as CustomerCount
	FROM Product p
	LEFT JOIN SalesTransaction st 
	ON p.ProductID = st.ProductID
	WHERE YEAR(st.TransactionDate) = YEAR(GETDATE())
	GROUP BY p.ProductID, p.ProductName
)

SELECT * 
FROM ProductCustomerCount_CTE
ORDER BY CustomerCount DESC;


