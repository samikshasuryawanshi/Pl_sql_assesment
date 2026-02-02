USE DATABASE HCL_TRAINING;
USE SCHEMA MYFIRSTSCHEMA;
USE WAREHOUSE MY_HCL_TRAINNING;

CREATE OR REPLACE TABLE employee (
    employee_id    NUMBER(38,0),
    first_name     VARCHAR,
    last_name      VARCHAR,
    email          VARCHAR,
    salary         NUMBER(38,2),
    department_id  NUMBER(38,0),
    hire_date      DATE
);


CREATE OR REPLACE STAGE employee_stage;

LIST @employee_stage;

CREATE OR REPLACE FILE FORMAT employee_csv_fmt
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
NULL_IF = ('', 'NULL');


COPY INTO employee
FROM (
    SELECT
        $1::NUMBER(38,0)                    AS employee_id,
        $2::STRING                         AS first_name,
        $3::STRING                         AS last_name,
        $4::STRING                         AS email,
        $5::NUMBER(38,2)                   AS salary,
        $6::NUMBER(38,0)                   AS department_id,
        TO_DATE($7::STRING, 'MM/DD/YYYY')  AS hire_date
    FROM @employee_stage
)
FILE_FORMAT = (FORMAT_NAME = employee_csv_fmt)
ON_ERROR = CONTINUE;



UPDATE employee
SET
    first_name = INITCAP(first_name),
    last_name  = INITCAP(last_name),
    email      = LOWER(email);



SELECT * FROM employee;



SELECT COUNT(*) FROM employee;

CREATE OR REPLACE STAGE my_unload_stage;


-- Creation of  File Format for Unload
CREATE OR REPLACE FILE FORMAT ff_unload_csv
TYPE = CSV
FIELD_DELIMITER = ','
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
NULL_IF = ('NULL', 'null')
EMPTY_FIELD_AS_NULL = TRUE
COMPRESSION = NONE


-- STEP 3 — Unload Data Using COPY INTO
COPY INTO @my_unload_stage/employees_export
FROM employee
FILE_FORMAT = ff_unload_csv
OVERWRITE = TRUE;


-- testing of unloaded data
-- Step 1 — Check If Files Were Created
LIST @my_unload_stage;


-- Step 2 — Preview File Content Inside Snowflake
SELECT $1, $2, $3, $4, $5
FROM @my_unload_stage/employees_export_0_0_0.csv
(FILE_FORMAT => ff_unload_csv)
LIMIT 10;


-- Step 3 — Compare Row Count
-- Check original table:
SELECT COUNT(*) FROM employee;


-- Then count rows in file:
SELECT COUNT(*)
FROM @my_unload_stage/employees_export_0_0_0.csv
(FILE_FORMAT => ff_unload_csv);



-- View data directly from unloaded stage
SELECT $1, $2, $3, $4, $5, 
FROM @my_unload_stage/employees_export_0_0_0.csv
LIMIT 10;

CREATE OR REPLACE STAGE parquet_stage;



COPY INTO @parquet_stage/employee_parquet/
FROM employee
FILE_FORMAT = (TYPE = PARQUET)
OVERWRITE = TRUE;

LIST @parquet_stage;

CREATE OR REPLACE FILE FORMAT parquet_fmt
TYPE = PARQUET;

SELECT *
FROM @parquet_stage/employee_parquet/
(FILE_FORMAT => parquet_fmt);


CREATE OR REPLACE TABLE employee_export_log (
    last_exported_ts TIMESTAMP
);


INSERT INTO employee_export_log
VALUES ('1900-01-01');

COPY INTO @employee_stage/incremental_exports/employee/
FROM (
    SELECT *
    FROM employee
    WHERE hire_date >= (
        SELECT COALESCE(
            MAX(last_exported_ts),
            '1900-01-01'::DATE
        )
        FROM employee_export_log
    )
)
FILE_FORMAT = (FORMAT_NAME = parquet_fmt)
OVERWRITE = FALSE;



LIST @employee_stage/incremental_exports/employee;


SELECT *
FROM @employee_stage/incremental_exports/employee
(FILE_FORMAT => parquet_fmt);


SELECT * FROM employee_export_log;


COPY INTO @employee_stage/dedup_exports/employee_latest/
FROM (
    SELECT *
    FROM employee
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY employee_id
        ORDER BY hire_date DESC
    ) = 1
)
FILE_FORMAT = (FORMAT_NAME = parquet_fmt)
SINGLE = TRUE
OVERWRITE = TRUE;



LIST @employee_stage/dedup_exports/employee_latest;


