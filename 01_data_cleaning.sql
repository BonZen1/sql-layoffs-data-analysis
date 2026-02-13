/*
Project: Global Layoffs Data Cleaning
Tool: MySQL
Description: Cleaning and standardizing layoffs dataset for analysis.
Author: Bon Joseph
Date: 2026
*/


SELECT *
FROM layoffs_staging2;

-- STEP 1: CREATE STAGING TABLE
-- Purpose: Work on a copy of the raw data

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;



-- STEP 2: REMOVE DUPLICATES
-- Using ROW_NUMBER() to identify duplicates

CREATE TABLE layoffs_staging2 (
  company TEXT,
  location TEXT,
  industry TEXT,
  total_laid_off INT DEFAULT NULL,
  percentage_laid_off TEXT,
  date TEXT,
  stage TEXT,
  country TEXT,
  funds_raised_millions INT DEFAULT NULL,
  row_num INT
);

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off,
percentage_laid_off, date, stage, country, funds_raised_millions
) AS row_num
FROM layoffs_staging;

-- Delete duplicate rows
DELETE
FROM layoffs_staging2
WHERE row_num > 1;



-- STEP 3: STANDARDIZE DATA
-- Fix inconsistent text values and formatting

-- Remove leading/trailing spaces in company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Standardize industry names (Crypto variations)
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Standardize country names
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';


-- STEP 4: CONVERT DATA TYPES
-- Convert date column from text to DATE format

UPDATE layoffs_staging2
SET date = STR_TO_DATE(date, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE;



-- STEP 5: HANDLE NULL AND BLANK VALUES
-- Fill missing industries using matching company records

-- Convert blank industries to NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Populate NULL industries using matching company & location
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
 AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


-- STEP 6: REMOVE IRRELEVANT ROWS
-- Remove rows where both layoff metrics are NULL

DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;



-- STEP 7: REMOVE HELPER COLUMNS
-- Drop row_num column used for duplicate detection

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
