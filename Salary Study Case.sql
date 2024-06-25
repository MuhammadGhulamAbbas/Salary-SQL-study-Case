-- 1. Identifying countries offering fully remote managerial roles paying more than $90,000 USD
SELECT distINct(company_locatiON) FROM salaries WHERE job_title like '%Manager%' and salary_IN_usd > 90000 and remote_ratio= 100;

/*2.AS a remote work advocate Working for a progressive HR tech startup who place their freshers’ clients IN large tech firms. you're tasked WITH 
Identifying top 5 Country Having  greatest count of large(company size) number of companies.*/

SELECT company_location, COUNT(company_size) AS cnt 
FROM salaries 
WHERE experience_level = 'EN' 
  AND company_size = 'L'
GROUP BY company_location 
ORDER BY cnt DESC 
LIMIT 5;
/*3. Picture yourself AS a data scientist Working for a workforce management platform. Your objective is to calculate the percentage of employees. 
Who enjoy fully remote roles WITH salaries Exceeding $100,000 USD, Shedding light ON the attractiveness of high-paying remote positions IN today's job market.*/
WITH count_cte AS (
    SELECT COUNT(*) AS count_remote 
    FROM salaries 
    WHERE salary_in_usd > 100000 
      AND remote_ratio = 100
),
total_cte AS (
    SELECT COUNT(*) AS total_count 
    FROM salaries 
    WHERE salary_in_usd > 100000
)
SELECT 
    ROUND((count_cte.count_remote::decimal / total_cte.total_count) * 100, 2) AS percentage
FROM count_cte, total_cte;

/*4.	Imagine you're a data analyst Working for a global recruitment agency. Your Task is to identify the Locations where entry-level average salaries exceed the 
average salary for that job title in market for entry level, helping your agency guide candidates towards lucrative countries.*/
SELECT 
    company_location, 
    t.job_title, 
    average_per_country, 
    average 
FROM 
    (SELECT company_location, job_title, AVG(salary_in_usd) AS average_per_country 
     FROM salaries 
     WHERE experience_level = 'EN' 
     GROUP BY company_location, job_title) AS t 
INNER JOIN 
    (SELECT job_title, AVG(salary_in_usd) AS average 
     FROM salaries 
     WHERE experience_level = 'EN' 
     GROUP BY job_title) AS p 
ON t.job_title = p.job_title 
WHERE average_per_country > average;

/*5. You've been hired by a big HR Consultancy to look at how much people get paid IN different Countries. Your job is to Find out for each job title which
Country pays the maximum average salary. This helps you to place your candidates IN those countries.*/

WITH ranked_salaries AS (
    SELECT 
        company_location,
        job_title,
        AVG(salary_in_usd) AS average_salary,
        ROW_NUMBER() OVER (PARTITION BY job_title ORDER BY AVG(salary_in_usd) DESC) AS rank
    FROM 
        salaries
    GROUP BY 
        company_location, job_title
)
SELECT 
    company_location,
    job_title,
    average_salary
FROM 
    ranked_salaries
WHERE 
    rank = 1;
/*6.  AS a data-driven Business consultant, you've been hired by a multinational corporation to analyze salary trends across different company Locations.
 Your goal is to Pinpoint Locations WHERE the average salary Has consistently Increased over the Past few years (Countries WHERE data is available for 3 years Only(this and pst two years) 
 providing Insights into Locations experiencing Sustained salary growth.*/

WITH locations_with_three_years_data AS (
    SELECT 
        company_location
    FROM (
        SELECT 
            company_location, 
            AVG(salary_IN_usd) AS avg_salary,
            COUNT(DISTINCT work_year) AS num_years
        FROM 
            salaries
        WHERE 
            work_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 2  -- Data for the last three years only
        GROUP BY 
            company_location
        HAVING 
            COUNT(DISTINCT work_year) = 3  -- Locations with data for three years
    ) AS m
), all_salaries AS (
    SELECT 
        s.company_location,
        s.work_year,
        AVG(s.salary_IN_usd) AS average
    FROM 
        salaries s
    JOIN 
        locations_with_three_years_data t ON s.company_location = t.company_location
    WHERE 
        s.work_year BETWEEN EXTRACT(YEAR FROM CURRENT_DATE) - 2 AND EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY 
        s.company_location, s.work_year
)
SELECT 
    company_location,
    MAX(CASE WHEN work_year = EXTRACT(YEAR FROM CURRENT_DATE) - 2 THEN average END) AS AVG_salary_2022,
    MAX(CASE WHEN work_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1 THEN average END) AS AVG_salary_2023,
    MAX(CASE WHEN work_year = EXTRACT(YEAR FROM CURRENT_DATE) THEN average END) AS AVG_salary_2024
FROM 
    all_salaries
GROUP BY 
    company_location
HAVING 
    MAX(CASE WHEN work_year = EXTRACT(YEAR FROM CURRENT_DATE) THEN average END) >
    MAX(CASE WHEN work_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1 THEN average END)
    AND MAX(CASE WHEN work_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1 THEN average END) >
    MAX(CASE WHEN work_year = EXTRACT(YEAR FROM CURRENT_DATE) - 2 THEN average END);
/* 7.	Picture yourself AS a workforce strategist employed by a global HR tech startup. Your missiON is to determINe the percentage of  fully remote work for each 
 experience level IN 2021 and compare it WITH the correspONdINg figures for 2024, highlightINg any significant INcreASes or decreASes IN remote work adoptiON
 over the years.*/
 WITH t1 AS (
    SELECT 
        s1.experience_level, 
        COUNT(CASE WHEN s1.remote_ratio = 100 THEN 1 END) AS total_remote,
        COUNT(*) AS total_2021
    FROM 
        salaries s1
    WHERE 
        s1.work_year = 2021
    GROUP BY 
        s1.experience_level
),
t2 AS (
    SELECT 
        s2.experience_level, 
        COUNT(CASE WHEN s2.remote_ratio = 100 THEN 1 END) AS total_remote,
        COUNT(*) AS total_2024
    FROM 
        salaries s2
    WHERE 
        s2.work_year = 2024
    GROUP BY 
        s2.experience_level
)

SELECT 
    t1.experience_level,
    t1.total_remote AS total_remote_2021,
    t1.total_2021,
    ROUND((t1.total_remote::numeric / t1.total_2021) * 100, 2) AS "2021 remote %",
    t2.total_remote AS total_remote_2024,
    t2.total_2024,
    ROUND((t2.total_remote::numeric / t2.total_2024) * 100, 2) AS "2024 remote %"
FROM 
    t1
INNER JOIN 
    t2 ON t1.experience_level = t2.experience_level;
