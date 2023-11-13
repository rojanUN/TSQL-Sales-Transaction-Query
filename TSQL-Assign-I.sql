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
('Laptop', 1200, 50),
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
(1001, 1, 2, 2400, '2023-11-10'),
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

