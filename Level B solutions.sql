--stored procedure 

--Q1
CREATE PROCEDURE InsertOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity SMALLINT,
    @Discount FLOAT = 0.0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AvailableStock INT;
    DECLARE @ReorderLevel INT;
    DECLARE @DefaultUnitPrice MONEY;

    -- Get current stock and reorder level
    SELECT @AvailableStock = UnitsInStock, 
           @ReorderLevel = ReorderLevel,
           @DefaultUnitPrice = UnitPrice
    FROM Production.Product
    WHERE ProductID = @ProductID;

    -- Check if product exists
    IF @AvailableStock IS NULL
    BEGIN
        PRINT 'Invalid ProductID.';
        RETURN;
    END

    -- If UnitPrice is not provided, use default
    IF @UnitPrice IS NULL
    BEGIN
        SET @UnitPrice = @DefaultUnitPrice;
    END

    -- Ensure sufficient stock is available
    IF @AvailableStock < @Quantity
    BEGIN
        PRINT 'Not enough stock available. Operation aborted.';
        RETURN;
    END

    -- Insert into Order Details (assumed as Sales.SalesOrderDetail)
    INSERT INTO Sales.SalesOrderDetail (
        SalesOrderID, ProductID, OrderQty, UnitPrice, UnitPriceDiscount
    )
    VALUES (
        @OrderID, @ProductID, @Quantity, @UnitPrice, @Discount
    );

    -- Check if insert was successful
    IF @@ROWCOUNT = 0
    BEGIN
        PRINT 'Failed to place the order. Please try again.';
        RETURN;
    END

    -- Update product inventory
    UPDATE Production.Product
    SET UnitsInStock = UnitsInStock - @Quantity
    WHERE ProductID = @ProductID;

    -- Check if new stock is below reorder level
    SELECT @AvailableStock = UnitsInStock
    FROM Production.Product
    WHERE ProductID = @ProductID;

    IF @AvailableStock < @ReorderLevel
    BEGIN
        PRINT 'Warning: Product stock below reorder level.';
    END

    PRINT 'Order placed successfully.';
END;
GO


--Q2
CREATE PROCEDURE UpdateOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity SMALLINT = NULL,
    @Discount FLOAT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldQuantity INT;
    DECLARE @OldUnitPrice MONEY;
    DECLARE @OldDiscount FLOAT;
    DECLARE @NewQuantity INT;

    -- Fetch current order detail values
    SELECT @OldQuantity = OrderQty,
           @OldUnitPrice = UnitPrice,
           @OldDiscount = UnitPriceDiscount
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

    IF @OldQuantity IS NULL
    BEGIN
        PRINT 'Order detail not found.';
        RETURN;
    END

    -- Determine new values using ISNULL (keep old if NULL passed)
    SET @NewQuantity = ISNULL(@Quantity, @OldQuantity);

    -- Update order detail
    UPDATE Sales.SalesOrderDetail
    SET OrderQty = @NewQuantity,
        UnitPrice = ISNULL(@UnitPrice, @OldUnitPrice),
        UnitPriceDiscount = ISNULL(@Discount, @OldDiscount)
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

    -- Adjust inventory
    DECLARE @StockChange INT;
    SET @StockChange = @OldQuantity - @NewQuantity;

    UPDATE Production.Product
    SET UnitsInStock = UnitsInStock + @StockChange
    WHERE ProductID = @ProductID;

    PRINT 'Order details updated successfully.';
END;
GO


--Q3
CREATE PROCEDURE GetOrderDetails
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if any record exists for the given OrderID
    IF EXISTS (
        SELECT 1 
        FROM Sales.SalesOrderDetail 
        WHERE SalesOrderID = @OrderID
    )
    BEGIN
        -- Return matching order details
        SELECT *
        FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID;
    END
    ELSE
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR(10)) + ' does not exist';
        RETURN 1;
    END
END;
GO

EXEC GetOrderDetails @OrderID = 43659;


--Q4

CREATE PROCEDURE DeleteOrderDetails
    @OrderID INT,
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the OrderID and ProductID combination exists
    IF NOT EXISTS (
        SELECT 1
        FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @OrderID AND ProductID = @ProductID
    )
    BEGIN
        PRINT 'Invalid OrderID or ProductID. No matching record found.';
        RETURN -1;
    END

    -- Delete the record
    DELETE FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID AND ProductID = @ProductID;

    PRINT 'Order detail deleted successfully.';
END;
GO

EXEC DeleteOrderDetails @OrderID = 43659, @ProductID = 776;


--Function

--Q1
CREATE FUNCTION FormatDate_MMDDYYYY
(
    @inputDate DATETIME
)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN CONVERT(VARCHAR(10), @inputDate, 101);  -- 101 = MM/DD/YYYY
END;
GO

--Q2
CREATE FUNCTION FormatDate_YYYYMMDD
(
    @inputDate DATETIME
)
RETURNS VARCHAR(8)
AS
BEGIN
    RETURN CONVERT(VARCHAR(8), @inputDate, 112);  -- 112 = YYYYMMDD
END;
GO


SELECT dbo.FormatDate_MMDDYYYY('2006-11-21 23:34:05.920') AS MMDDYYYY_Format;
SELECT dbo.FormatDate_YYYYMMDD('2006-11-21 23:34:05.920') AS YYYYMMDD_Format;


--Views

--Q1
CREATE VIEW vwCustomerOrders AS
SELECT 
    c.CompanyName,
    soh.SalesOrderID AS OrderID,
    soh.OrderDate,
    p.ProductID,
    p.Name AS ProductName,
    sod.OrderQty AS Quantity,
    sod.UnitPrice,
    sod.OrderQty * sod.UnitPrice AS TotalPrice
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID;
GO


--Q2
CREATE VIEW vwCustomerOrders_Yesterday AS
SELECT 
    c.CompanyName,
    soh.SalesOrderID AS OrderID,
    soh.OrderDate,
    p.ProductID,
    p.Name AS ProductName,
    sod.OrderQty AS Quantity,
    sod.UnitPrice,
    sod.OrderQty * sod.UnitPrice AS TotalPrice
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
JOIN Sales.Customer c ON soh.CustomerID = c.CustomerID
WHERE CAST(soh.OrderDate AS DATE) = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE);
GO


--Q3
CREATE VIEW MyProducts AS
SELECT 
    p.ProductID,
    p.ProductName,
    p.QuantityPerUnit,
    p.UnitPrice,
    s.CompanyName,
    c.CategoryName
FROM Products p
JOIN Suppliers s ON p.SupplierID = s.SupplierID
JOIN Categories c ON p.CategoryID = c.CategoryID
WHERE p.Discontinued = 0;
GO


--Triggers

--Q1
CREATE TRIGGER trg_DeleteOrder_InsteadOf
ON Orders
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- First delete from Order Details for the deleted order(s)
    DELETE FROM [Order Details]
    WHERE OrderID IN (SELECT OrderID FROM DELETED);

    -- Then delete from Orders
    DELETE FROM Orders
    WHERE OrderID IN (SELECT OrderID FROM DELETED);
END;
GO

--Q2
CREATE TRIGGER trg_CheckStock_BeforeInsert
ON [Order Details]
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductID INT, @OrderQty INT, @CurrentStock INT;

    -- Assuming only one row inserted at a time
    SELECT 
        @ProductID = ProductID, 
        @OrderQty = Quantity
    FROM INSERTED;

    -- Get current stock
    SELECT @CurrentStock = UnitsInStock
    FROM Products
    WHERE ProductID = @ProductID;

    -- Check if sufficient stock exists
    IF @CurrentStock IS NOT NULL AND @CurrentStock >= @OrderQty
    BEGIN
        -- Insert the order
        INSERT INTO [Order Details](OrderID, ProductID, UnitPrice, Quantity, Discount)
        SELECT OrderID, ProductID, UnitPrice, Quantity, Discount
        FROM INSERTED;

        -- Update stock
        UPDATE Products
        SET UnitsInStock = UnitsInStock - @OrderQty
        WHERE ProductID = @ProductID;

        PRINT 'Order placed and stock updated successfully.';
    END
    ELSE
    BEGIN
        -- Reject the insert
        RAISERROR ('Order could not be placed due to insufficient stock.', 16, 1);
    END
END;
GO

