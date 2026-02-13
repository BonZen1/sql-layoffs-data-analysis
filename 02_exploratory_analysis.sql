/*
Project: Global Layoffs Exploratory Data Analysis
Tool: MySQL
Description: Exploratory analysis of cleaned layoffs dataset 
             to identify trends by company, industry, country, and time.
Author: Bon Joseph
Date: 2026
*/


-- OVERVIEW OF DATA

-- View cleaned dataset
SELECT *
FROM layoffs_staging2;

-- Check maximum layoffs and highest percentage laid off
SELECT 
    MAX(total_laid_off) AS max_total_laid_off,
    MAX(percentage_laid_off) AS max_percentage_laid_off
FROM layoffs_staging2;

-- Companies that laid off 100% of employees
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1;


-- COMPANY LEVEL ANALYSIS

-- Total layoffs by company (descending order)
SELECT 
    company,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;


-- INDUSTRY ANALYSIS

-- Total layoffs by industry
SELECT 
    industry,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY total_laid_off DESC;


-- COUNTRY ANALYSIS

-- Total layoffs by country
SELECT 
    country,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;


-- DATE & TIME ANALYSIS

-- Date range of dataset
SELECT 
    MIN(date) AS earliest_date,
    MAX(date) AS latest_date
FROM layoffs_staging2;

-- Total layoffs by year
SELECT 
    YEAR(date) AS year,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY YEAR(date)
ORDER BY year DESC;

-- Monthly layoffs trend
SELECT 
    DATE_FORMAT(date, '%Y-%m') AS month,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE date IS NOT NULL
GROUP BY month
ORDER BY month ASC;



-- ROLLING (CUMULATIVE) LAYOFF TREND

WITH monthly_totals AS (
    SELECT 
        DATE_FORMAT(date, '%Y-%m') AS month,
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    WHERE date IS NOT NULL
    GROUP BY month
)

SELECT 
    month,
    total_laid_off,
    SUM(total_laid_off) OVER (ORDER BY month) AS rolling_total
FROM monthly_totals
ORDER BY month;


-- COMPANY PERFORMANCE OVER TIME

-- Total layoffs by company per year
SELECT 
    company,
    YEAR(date) AS year,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company, YEAR(date)
ORDER BY total_laid_off DESC;


-- TOP 5 COMPANIES PER YEAR (Using Ranking)

WITH company_year AS (
    SELECT 
        company,
        YEAR(date) AS year,
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging2
    GROUP BY company, YEAR(date)
),

company_year_rank AS (
    SELECT 
        company,
        year,
        total_laid_off,
        DENSE_RANK() OVER (
            PARTITION BY year 
            ORDER BY total_laid_off DESC
        ) AS ranking
    FROM company_year
    WHERE year IS NOT NULL
)

SELECT *
FROM company_year_rank
WHERE ranking <= 5
ORDER BY year, ranking;
