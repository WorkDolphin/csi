--SCD TYPE 0
CREATE PROCEDURE sp_SCD_Type0
AS
BEGIN
    -- Ignore changes: only insert new records
    INSERT INTO DimCustomer (CustomerID, Name, Email, Address)
    SELECT s.CustomerID, s.Name, s.Email, s.Address
    FROM StagingCustomer s
    LEFT JOIN DimCustomer d ON s.CustomerID = d.CustomerID
    WHERE d.CustomerID IS NULL
END


--SCD TYPE 1
CREATE PROCEDURE sp_SCD_Type1
AS
BEGIN
    -- Update existing records (overwrite)
    UPDATE d
    SET d.Name = s.Name,
        d.Email = s.Email,
        d.Address = s.Address
    FROM DimCustomer d
    JOIN StagingCustomer s ON d.CustomerID = s.CustomerID

    -- Insert new records
    INSERT INTO DimCustomer (CustomerID, Name, Email, Address)
    SELECT s.CustomerID, s.Name, s.Email, s.Address
    FROM StagingCustomer s
    LEFT JOIN DimCustomer d ON s.CustomerID = d.CustomerID
    WHERE d.CustomerID IS NULL
END


--SCD TYPE 2
CREATE PROCEDURE sp_SCD_Type2
AS
BEGIN
    DECLARE @CurrentDate DATE = GETDATE()

    -- Expire old records
    UPDATE d
    SET d.EndDate = @CurrentDate, d.IsCurrent = 0
    FROM DimCustomer d
    JOIN StagingCustomer s ON d.CustomerID = s.CustomerID
    WHERE d.IsCurrent = 1
      AND (d.Name <> s.Name OR d.Email <> s.Email OR d.Address <> s.Address)

    -- Insert new version
    INSERT INTO DimCustomer (CustomerID, Name, Email, Address, StartDate, EndDate, IsCurrent)
    SELECT s.CustomerID, s.Name, s.Email, s.Address, @CurrentDate, NULL, 1
    FROM StagingCustomer s
    LEFT JOIN DimCustomer d ON s.CustomerID = d.CustomerID AND d.IsCurrent = 1
    WHERE d.CustomerID IS NULL
       OR (d.Name <> s.Name OR d.Email <> s.Email OR d.Address <> s.Address)
END


--SCD TYPE 3
CREATE PROCEDURE sp_SCD_Type3
AS
BEGIN
    -- Update current value and store previous value
    UPDATE d
    SET d.PreviousAddress = d.Address,
        d.Address = s.Address
    FROM DimCustomer d
    JOIN StagingCustomer s ON d.CustomerID = s.CustomerID
    WHERE d.Address <> s.Address

    -- Insert new records
    INSERT INTO DimCustomer (CustomerID, Name, Email, Address, PreviousAddress)
    SELECT s.CustomerID, s.Name, s.Email, s.Address, NULL
    FROM StagingCustomer s
    LEFT JOIN DimCustomer d ON s.CustomerID = d.CustomerID
    WHERE d.CustomerID IS NULL
END


--SDE TYPE 4
CREATE PROCEDURE sp_SCD_Type4
AS
BEGIN
    -- Archive old data
    INSERT INTO DimCustomerHistory (CustomerID, Name, Email, Address, ArchiveDate)
    SELECT d.CustomerID, d.Name, d.Email, d.Address, GETDATE()
    FROM DimCustomer d
    JOIN StagingCustomer s ON d.CustomerID = s.CustomerID
    WHERE d.Name <> s.Name OR d.Email <> s.Email OR d.Address <> s.Address

    -- Update main table
    UPDATE d
    SET d.Name = s.Name,
        d.Email = s.Email,
        d.Address = s.Address
    FROM DimCustomer d
    JOIN StagingCustomer s ON d.CustomerID = s.CustomerID

    -- Insert new customers
    INSERT INTO DimCustomer (CustomerID, Name, Email, Address)
    SELECT s.CustomerID, s.Name, s.Email, s.Address
    FROM StagingCustomer s
    LEFT JOIN DimCustomer d ON s.CustomerID = d.CustomerID
    WHERE d.CustomerID IS NULL
END


--SDE TYPE 6
CREATE PROCEDURE sp_SCD_Type6
AS
BEGIN
    DECLARE @CurrentDate DATE = GETDATE()

    -- Expire old record
    UPDATE d
    SET d.EndDate = @CurrentDate,
        d.IsCurrent = 0
    FROM DimCustomer d
    JOIN StagingCustomer s ON d.CustomerID = s.CustomerID
    WHERE d.IsCurrent = 1
      AND (d.Name <> s.Name OR d.Email <> s.Email OR d.Address <> s.Address)

    -- Insert new version with current + previous values
    INSERT INTO DimCustomer (CustomerID, Name, Email, Address, PreviousAddress, StartDate, EndDate, IsCurrent)
    SELECT s.CustomerID, s.Name, s.Email, s.Address, d.Address, @CurrentDate, NULL, 1
    FROM StagingCustomer s
    JOIN DimCustomer d ON s.CustomerID = d.CustomerID AND d.IsCurrent = 1
    WHERE d.Name <> s.Name OR d.Email <> s.Email OR d.Address <> s.Address

    -- Insert new customers
    INSERT INTO DimCustomer (CustomerID, Name, Email, Address, PreviousAddress, StartDate, EndDate, IsCurrent)
    SELECT s.CustomerID, s.Name, s.Email, s.Address, NULL, @CurrentDate, NULL, 1
    FROM StagingCustomer s
    LEFT JOIN DimCustomer d ON s.CustomerID = d.CustomerID
    WHERE d.CustomerID IS NULL
END
