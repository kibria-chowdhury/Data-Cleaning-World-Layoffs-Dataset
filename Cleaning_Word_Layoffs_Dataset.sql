-- Data Cleaning using Postgresql

-- indicating the schema
SET search_path TO practice;
-- table creation
DROP TABLE IF EXISTS world_layoffs;

CREATE TABLE IF NOT EXISTS world_layoffs(
company VARCHAR,	
location VARCHAR,
industry VARCHAR,
total_laid_off INT,
percentage_laid_off	FLOAT,
date DATE,
stage VARCHAR,
country	VARCHAR,
funds_raised_millions FLOAT
);
-- checking if the creation is okay
SELECT * FROM world_layoffs;

-- inserting data using import
-- checking if the importing is okay
SELECT * FROM world_layoffs;

-- creating stage to avoid manipulating the raw data

CREATE TABLE w_layoffs_staging
(LIKE world_layoffs INCLUDING ALL);

SELECT * 
FROM w_layoffs_staging;

INSERT INTO w_layoffs_staging
SELECT *
FROM world_layoffs;

-- finding duplicates
WITH duplicate_cte AS(
	SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, funds_raised_millions
		) AS rn
	FROM w_layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE rn > 1;

-- removing Duplicates

WITH duplicate_cte AS(
	SELECT ctid,
		ROW_NUMBER() OVER(
			PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, funds_raised_millions
			) AS rn
	FROM w_layoffs_staging
)
DELETE FROM w_layoffs_staging
WHERE ctid IN(
	SELECT ctid
	FROM duplicate_cte
	WHERE rn >1
);

/*
keeping only the first (rn = 1) and deleting the rest (rn>1)
ctid(hidden system column in PostgreSQL) used to ensuring only the exact duplicate rows are deleted
*/

-- Standardizing data

-- removing spaces at beginning of company names as well as from the ending
SELECT company, 
	TRIM(company)
FROM w_layoffs_staging;

UPDATE w_layoffs_staging
SET company = TRIM(company);

-- checking industry string
SELECT DISTINCT industry
FROM w_layoffs_staging
ORDER BY 1;

SELECT *
FROM w_layoffs_staging
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- making the '' or empty values to NULL as they are easy to work with

UPDATE w_layoffs_staging
SET industry = NULL
WHERE industry = '';

SELECT *
FROM w_layoffs_staging
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- found this Crypto also as Crypto Currency, which is the same thing.
SELECT *
FROM w_layoffs_staging
WHERE industry LIKE 'Crypto%';

UPDATE w_layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- checking industry if there are any issues there.
SELECT DISTINCT location
FROM w_layoffs_staging;

-- -- checking countries if there are any issues there. There is a '.' after the United States

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM w_layoffs_staging
WHERE country LIKE 'United States%';

UPDATE w_layoffs_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- checking data type of Date if it contains DATE as data type of TEXT
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'w_layoffs_staging'
  AND column_name = 'date';

-- found that company like airbnb is missing it's industry data in another row, we will see how many are there
SELECT *
FROM w_layoffs_staging
WHERE company LIKE 'Airbnb%';

SELECT t1.industry,
	t2.industry
FROM w_layoffs_staging t1
JOIN w_layoffs_staging t2
	ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND (t2.industry IS NOT NULL OR t2.industry <> '');

UPDATE w_layoffs_staging t1
SET industry = t2.industry
FROM w_layoffs_staging t2
WHERE t1.company = t2.company
AND (t1.industry IS NULL OR t1.industry = '')
AND (t2.industry IS NOT NULL OR t2.industry <> '');

-- working properly now
SELECT *
FROM w_layoffs_staging
WHERE company LIKE 'Airbnb%';

-- finding nulls in total_laid_off and pecentage_laid_off columns

SELECT *
FROM w_layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- there is nothing to compare as there are nulls in both rows, so I will be deleting these rows though deleting rows is not ideal

DELETE
FROM w_layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Most possible finalized version of our Raw Messy World_Layoffs Dataset

SELECT * 
FROM w_layoffs_staging;