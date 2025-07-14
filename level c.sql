--task 1
WITH date_diff AS (
  SELECT *,
         CASE 
           WHEN DATEDIFF(Start_Date, 
                         LAG(End_Date) OVER (ORDER BY Start_Date)) = 0 THEN 0
           ELSE 1
         END AS is_new_project
  FROM Projects
),
project_groups AS (
  SELECT *,
         SUM(is_new_project) OVER (ORDER BY Start_Date) AS group_id
  FROM date_diff
),
project_ranges AS (
  SELECT MIN(Start_Date) AS project_start,
         MAX(End_Date) AS project_end,
         DATEDIFF(MAX(End_Date), MIN(Start_Date)) + 1 AS duration
  FROM project_groups
  GROUP BY group_id
)
SELECT project_start, project_end
FROM project_ranges
ORDER BY duration, project_start;


-- task 2

SELECT S.Name
FROM Students S
JOIN Friends F ON S.ID = F.ID
JOIN Packages P1 ON S.ID = P1.ID        -- student’s salary
JOIN Packages P2 ON F.Friend_ID = P2.ID -- friend’s salary
WHERE P2.Salary > P1.Salary
ORDER BY P2.Salary;


-- task 3
SELECT DISTINCT f1.X, f1.Y
FROM Functions f1
JOIN Functions f2
  ON f1.X = f2.Y AND f1.Y = f2.X
WHERE f1.X <= f1.Y
ORDER BY f1.X;


--task 4
SELECT
  c.contest_id,
  c.hacker_id,
  c.name,
  COALESCE(SUM(s.total_submissions), 0) AS total_submissions,
  COALESCE(SUM(s.total_accepted_submissions), 0) AS total_accepted_submissions,
  COALESCE(SUM(v.total_views), 0) AS total_views,
  COALESCE(SUM(v.total_unique_views), 0) AS total_unique_views
FROM Contests c
JOIN Colleges col ON c.contest_id = col.contest_id
JOIN Challenges ch ON ch.college_id = col.college_id
LEFT JOIN Submission_Stats s ON s.challenge_id = ch.challenge_id
LEFT JOIN View_Stats v ON v.challenge_id = ch.challenge_id
GROUP BY c.contest_id, c.hacker_id, c.name
HAVING
  SUM(COALESCE(s.total_submissions, 0)) != 0 OR
  SUM(COALESCE(s.total_accepted_submissions, 0)) != 0 OR
  SUM(COALESCE(v.total_views, 0)) != 0 OR
  SUM(COALESCE(v.total_unique_views, 0)) != 0
ORDER BY c.contest_id;


--task5
WITH daily_counts AS (
  SELECT 
    submission_date,
    hacker_id,
    COUNT(*) AS submissions
  FROM Submissions
  GROUP BY submission_date, hacker_id
),
max_per_day AS (
  SELECT
    submission_date,
    MAX(submissions) AS max_subs
  FROM daily_counts
  GROUP BY submission_date
),
most_active AS (
  SELECT 
    d.submission_date,
    d.hacker_id,
    d.submissions
  FROM daily_counts d
  JOIN max_per_day m
    ON d.submission_date = m.submission_date AND d.submissions = m.max_subs
),
final_result AS (
  SELECT 
    s.submission_date,
    COUNT(DISTINCT s.hacker_id) AS total_hackers,
    MIN(m.hacker_id) AS top_hacker_id
  FROM Submissions s
  JOIN most_active m ON s.submission_date = m.submission_date
  GROUP BY s.submission_date
)
SELECT 
  f.submission_date,
  f.total_hackers,
  f.top_hacker_id,
  h.name
FROM final_result f
JOIN Hackers h ON f.top_hacker_id = h.hacker_id
ORDER BY f.submission_date;


--task6
SELECT 
  ROUND(
    ABS(MIN(LAT_N) - MAX(LAT_N)) + 
    ABS(MIN(LONG_W) - MAX(LONG_W)),
    4
  ) AS ManhattanDistance
FROM STATION;


--task7
WITH RECURSIVE numbers AS (
  SELECT 2 AS num
  UNION ALL
  SELECT num + 1 FROM numbers WHERE num < 1000
),
primes AS (
  SELECT num FROM numbers n
  WHERE NOT EXISTS (
    SELECT 1 FROM numbers d
    WHERE d.num < n.num AND d.num > 1 AND n.num % d.num = 0
  )
)
SELECT GROUP_CONCAT(num SEPARATOR '&') AS prime_list
FROM primes;


--task8
SELECT
    MAX(CASE WHEN Occupation = 'Doctor' THEN Name END) AS Doctor,
    MAX(CASE WHEN Occupation = 'Professor' THEN Name END) AS Professor,
    MAX(CASE WHEN Occupation = 'Singer' THEN Name END) AS Singer,
    MAX(CASE WHEN Occupation = 'Actor' THEN Name END) AS Actor
FROM (
    SELECT Name, Occupation,
           ROW_NUMBER() OVER (PARTITION BY Occupation ORDER BY Name) AS rn
    FROM OCCUPATIONS
) AS sub
GROUP BY rn;


--task9
SELECT
    N,
    CASE 
        WHEN P IS NULL THEN 'Root'
        WHEN N NOT IN (SELECT DISTINCT P FROM BST WHERE P IS NOT NULL) THEN 'Leaf'
        ELSE 'Inner'
    END AS NodeType
FROM BST
ORDER BY N;


--task 10
SELECT 
    c.company_code,
    c.founder,
    COUNT(DISTINCT lm.lead_manager_code) AS lead_manager_count,
    COUNT(DISTINCT sm.senior_manager_code) AS senior_manager_count,
    COUNT(DISTINCT m.manager_code) AS manager_count,
    COUNT(DISTINCT e.employee_code) AS employee_count
FROM Company c
LEFT JOIN Lead_Manager lm ON c.company_code = lm.company_code
LEFT JOIN Senior_Manager sm ON c.company_code = sm.company_code
LEFT JOIN Manager m ON c.company_code = m.company_code
LEFT JOIN Employee e ON c.company_code = e.company_code
GROUP BY c.company_code, c.founder
ORDER BY c.company_code;


--task11

SELECT s.Name
FROM Students s
JOIN Friends f ON s.ID = f.ID
JOIN Packages sp ON s.ID = sp.ID
JOIN Packages fp ON f.Friend_ID = fp.ID
WHERE fp.Salary > sp.Salary
ORDER BY fp.Salary;


--task 12
SELECT 
    JobFamily,
    SUM(CASE WHEN Location = 'India' THEN Cost ELSE 0 END) * 100.0 / SUM(Cost) AS India_Percentage,
    SUM(CASE WHEN Location = 'International' THEN Cost ELSE 0 END) * 100.0 / SUM(Cost) AS International_Percentage
FROM EmployeeCost
GROUP BY JobFamily;


--task 13

BUFinance(BU, Month, Cost, Revenue)

SELECT 
    BU,
    Month,
    CAST(Cost AS FLOAT) / NULLIF(Revenue, 0) AS CostToRevenueRatio
FROM BUFinance;


--task 14

SELECT 
    SubBand,
    COUNT(*) AS Headcount,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS HeadcountPercentage
FROM Employees
GROUP BY SubBand;


--task 15
WITH RankedEmployees AS (
    SELECT *, RANK() OVER (PARTITION BY 1 ORDER BY Salary DESC) AS rnk
    FROM Employees
)
SELECT *
FROM RankedEmployees
WHERE rnk <= 5;


--task 16
UPDATE TableName
SET Col1 = Col1 + Col2,
    Col2 = Col1 - Col2,
    Col1 = Col1 - Col2;

UPDATE TableName
SET Col1 = Col1 ^ Col2,
    Col2 = Col1 ^ Col2,
    Col1 = Col1 ^ Col2;


--task 17
-- Create login at SQL Server level
CREATE LOGIN UserLoginName WITH PASSWORD = 'StrongPassword!123';

-- Create user at database level
USE YourDatabaseName;
CREATE USER UserName FOR LOGIN UserLoginName;

-- Grant db_owner role
ALTER ROLE db_owner ADD MEMBER UserName;


--task 18
SELECT 
    BU,
    Month,
    SUM(Cost * Weight) / NULLIF(SUM(Weight), 0) AS WeightedAverageCost
FROM EmployeeCost
GROUP BY BU, Month;


--task 19
SELECT 
    CEILING(
        AVG(Salary * 1.0) 
        - 
        AVG(CAST(REPLACE(CAST(Salary AS VARCHAR), '0', '') AS FLOAT))
    ) AS ErrorDifference
FROM EMPLOYEES;


--task 20
INSERT INTO TargetTable
SELECT * 
FROM SourceTable
EXCEPT
SELECT * 
FROM TargetTable;