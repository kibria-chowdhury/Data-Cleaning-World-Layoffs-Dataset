
# Data Cleaning: World Layoffs Dataset

This project involves cleaning a messy dataset of company layoffs using PostgreSQL. It includes table creation, duplicate removal, string normalization, missing value handling, and column standardization — all performed in a structured and repeatable way.

---

## Tool: PostgreSQL

## Schema Setup

Setting the working schema:

```sql
SET search_path TO practice;
```

---

## Table Creation

Create the main table to hold the raw data:

```sql
DROP TABLE IF EXISTS world_layoffs;

CREATE TABLE IF NOT EXISTS world_layoffs (
    company VARCHAR,	
    location VARCHAR,
    industry VARCHAR,
    total_laid_off INT,
    percentage_laid_off FLOAT,
    date DATE,
    stage VARCHAR,
    country VARCHAR,
    funds_raised_millions FLOAT
);
```

---

## Importing Data

Importing raw data into `world_layoffs` using PostgreSQL's import tool (e.g., pgAdmin). Validate using:

```sql
SELECT * FROM world_layoffs;
```

---

## Creating a Staging Table

To avoid modifying raw data directly, a staging table is used:

```sql
CREATE TABLE w_layoffs_staging
(LIKE world_layoffs INCLUDING ALL);

INSERT INTO w_layoffs_staging
SELECT *
FROM world_layoffs;
```

---

## Duplicate Removal

### Step 1: Identifying duplicates

```sql
WITH duplicate_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off,
                            percentage_laid_off, date, stage, funds_raised_millions
           ) AS rn
    FROM w_layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE rn > 1;
```

### Step 2: Deleting duplicates using `ctid`

```sql
WITH duplicate_cte AS (
    SELECT ctid,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off,
                            percentage_laid_off, date, stage, funds_raised_millions
           ) AS rn
    FROM w_layoffs_staging
)
DELETE FROM w_layoffs_staging
WHERE ctid IN (
    SELECT ctid
    FROM duplicate_cte
    WHERE rn > 1
);
```

> keeping only the first row in each duplicate group and removing the rest.

---

## Data Standardization

### Trimming whitespace from `company` names:

```sql
UPDATE w_layoffs_staging
SET company = TRIM(company);
```

### Replacing empty `industry` strings with `NULL`:

```sql
UPDATE w_layoffs_staging
SET industry = NULL
WHERE industry = '';
```

### Standardizing industry names:

```sql
UPDATE w_layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```

### Fixing country values:

```sql
UPDATE w_layoffs_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
```

---

## Filling in Missing Values from Matching Rows

For rows where `industry` is null, fill it using other rows of the same company:

```sql
UPDATE w_layoffs_staging t1
SET industry = t2.industry
FROM w_layoffs_staging t2
WHERE t1.company = t2.company
  AND (t1.industry IS NULL OR t1.industry = '')
  AND (t2.industry IS NOT NULL AND t2.industry <> '');
```

---

## Remove Rows with Missing Critical Info

Remove rows where both `total_laid_off` and `percentage_laid_off` are missing:

```sql
DELETE
FROM w_layoffs_staging
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
```

---

## Final Cleaned Dataset

The cleaned version is now stored in `w_layoffs_staging` and can be queried with:

```sql
SELECT * 
FROM w_layoffs_staging;
```

---

## Notes

- The original `world_layoffs` table remains untouched.
- All cleaning steps are non-destructive to the raw data.
- Uses PostgreSQL-specific features like `ctid`, `ROW_NUMBER()`, `SELF JOIN` and `TRIM()`.

---

## Author

Data cleaning process written by: Golam Kibria Chowdhury 
Tools used: PostgreSQL, pgAdmin  
Date: August 2025

---
