CREATE PROCEDURE PopulateTimeDimension
    @InputDate DATE
AS
BEGIN
    DECLARE @StartDate DATE = DATEFROMPARTS(YEAR(@InputDate), 1, 1);
    DECLARE @EndDate DATE = DATEFROMPARTS(YEAR(@InputDate), 12, 31);

    INSERT INTO TimeDimension (
        Date, CalendarYear, CalendarMonth, CalendarDay,
        DayName, DayNameShort, DayNumInWeek, DayNumInMonth, DayNumInYear,
        DaySuffix, WeekOfYear, FiscalPeriod, FiscalQuarter,
        FiscalYear, FiscalYearPeriod
    )
    SELECT
        d.Date,
        YEAR(d.Date) AS CalendarYear,
        MONTH(d.Date) AS CalendarMonth,
        DAY(d.Date) AS CalendarDay,
        DATENAME(WEEKDAY, d.Date) AS DayName,
        LEFT(DATENAME(WEEKDAY, d.Date), 3) AS DayNameShort,
        DATEPART(WEEKDAY, d.Date) AS DayNumInWeek,
        DAY(d.Date) AS DayNumInMonth,
        DATEPART(DAYOFYEAR, d.Date) AS DayNumInYear,
        CAST(DAY(d.Date) AS VARCHAR) + 
            CASE 
                WHEN DAY(d.Date) IN (11,12,13) THEN 'th'
                WHEN RIGHT(CAST(DAY(d.Date) AS VARCHAR),1) = '1' THEN 'st'
                WHEN RIGHT(CAST(DAY(d.Date) AS VARCHAR),1) = '2' THEN 'nd'
                WHEN RIGHT(CAST(DAY(d.Date) AS VARCHAR),1) = '3' THEN 'rd'
                ELSE 'th'
            END AS DaySuffix,
        DATEPART(WEEK, d.Date) AS WeekOfYear,
        MONTH(d.Date) AS FiscalPeriod,
        ((MONTH(d.Date)-1)/3 + 1) AS FiscalQuarter,
        YEAR(d.Date) AS FiscalYear,
        CAST(YEAR(d.Date) AS VARCHAR) + RIGHT('0' + CAST(MONTH(d.Date) AS VARCHAR), 2) AS FiscalYearPeriod
    FROM (
        SELECT DATEADD(DAY, number, @StartDate) AS Date
        FROM master.dbo.spt_values
        WHERE type = 'P' AND number <= DATEDIFF(DAY, @StartDate, @EndDate)
    ) d
END;


--execution
EXEC PopulateTimeDimension '2020-07-14';
