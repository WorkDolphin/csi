WITH DeptStats AS (
    SELECT 
        e.DepartmentID,
        AVG(e.Salary) AS AvgSalary,
        COUNT(*) AS NumEmployees
    FROM Employees e
    GROUP BY e.DepartmentID
),
OverallAvg AS (
    SELECT AVG(Salary) AS OverallAverage FROM Employees
)
SELECT 
    d.Name AS DepartmentName,
    ds.AvgSalary AS AverageSalary,
    ds.NumEmployees AS NumberOfEmployees
FROM DeptStats ds
JOIN Departments d ON ds.DepartmentID = d.DepartmentID
JOIN OverallAvg oa ON ds.AvgSalary > oa.OverallAverage;
