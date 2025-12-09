-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CREATE File_Format for stage files
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FILE FORMAT my_pipe_format
    TYPE = 'CSV'
    FIELD_DELIMITER = '|'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    ESCAPE = '\\'
    SKIP_HEADER = 1;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CREATE Stage
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE [ OR REPLACE ] STAGE scrapped_jobs
    [ FILE_FORMAT = my_pipe_format ]
    [ COMMENT = 'A named internal stage for loading jobs data.' ];

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CREATE JOBS_LOAD Table
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE JOBS_LOAD (
	ID VARCHAR(1000) NOT NULL,
	SITE VARCHAR(255),
	JOB_URL VARCHAR(1000),
	JOB_URL_DIRECT VARCHAR(1000),
	TITLE VARCHAR(500),
	COMPANY VARCHAR(255),
	LOCATION VARCHAR(255),
	DATE_POSTED VARCHAR(255),
	JOB_TYPE VARCHAR(255),
	SALARY_SOURCE VARCHAR(255),
	INTERVAL VARCHAR(255),
	MIN_AMOUNT VARCHAR(255),
	MAX_AMOUNT VARCHAR(255),
	CURRENCY VARCHAR(255),
	IS_REMOTE VARCHAR(255),
	JOB_LEVEL VARCHAR(255),
	JOB_FUNCTION VARCHAR(500),
	LISTING_TYPE VARCHAR(255),
	EMAILS VARCHAR(500),
	DESCRIPTION VARCHAR(1000000),
	COMPANY_INDUSTRY VARCHAR(255),
	COMPANY_URL VARCHAR(1000),
	COMPANY_LOGO VARCHAR(1000),
	COMPANY_URL_DIRECT VARCHAR(1000),
	COMPANY_ADDRESSES VARCHAR(1000),
	COMPANY_NUM_EMPLOYEES VARCHAR(255),
	COMPANY_REVENUE VARCHAR(255),
	COMPANY_DESCRIPTION VARCHAR(5000),
	SKILLS VARCHAR(2000),
	EXPERIENCE_RANGE VARCHAR(255),
	COMPANY_RATING VARCHAR(255),
	COMPANY_REVIEWS_COUNT VARCHAR(255),
	VACANCY_COUNT VARCHAR(255),
	WORK_FROM_HOME_TYPE VARCHAR(255),
	LOAD_TIMESTAMP TIMESTAMP_NTZ(9),
	BATCH_ID VARCHAR(16777216),
	primary key (ID)
);

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CREATE JOBS_STAGE table
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE JOBS_STAGE (
	STAGE_ID NUMBER(38,0) autoincrement start 1 increment 1 noorder,
	SITE VARCHAR(16777216),
	JOB_URL VARCHAR(16777216),
	JOB_URL_DIRECT VARCHAR(16777216),
	TITLE VARCHAR(16777216),
	COMPANY VARCHAR(16777216),
	LOCATION VARCHAR(16777216),
	DATE_POSTED DATE,
	JOB_TYPE VARCHAR(16777216),
	SALARY_SOURCE VARCHAR(16777216),
	INTERVAL VARCHAR(16777216),
	MIN_AMOUNT NUMBER(38,0),
	MAX_AMOUNT NUMBER(38,0),
	CURRENCY VARCHAR(16777216),
	IS_REMOTE VARCHAR(16777216),
	JOB_LEVEL VARCHAR(16777216),
	JOB_FUNCTION VARCHAR(16777216),
	LISTING_TYPE VARCHAR(16777216),
	EMAILS VARCHAR(16777216),
	DESCRIPTION VARCHAR(16777216),
	COMPANY_INDUSTRY VARCHAR(16777216),
	COMPANY_URL VARCHAR(16777216),
	COMPANY_LOGO VARCHAR(16777216),
	COMPANY_URL_DIRECT VARCHAR(16777216),
	COMPANY_ADDRESSES VARCHAR(16777216),
	COMPANY_NUM_EMPLOYEES NUMBER(38,0),
	COMPANY_REVENUE VARCHAR(16777216),
	COMPANY_DESCRIPTION VARCHAR(16777216),
	SKILLS VARCHAR(16777216),
	EXPERIENCE_RANGE VARCHAR(16777216),
	COMPANY_RATING NUMBER(3,2),
	COMPANY_REVIEWS_COUNT NUMBER(38,0),
	VACANCY_COUNT NUMBER(38,0),
	WORK_FROM_HOME_TYPE VARCHAR(16777216),
	LOAD_TIMESTAMP TIMESTAMP_NTZ(9),
	STAGE_TIMESTAMP TIMESTAMP_NTZ(9),
	BATCH_ID VARCHAR(16777216)
);

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create JOBS Target table
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE JOBS (
    JOB_ID INTEGER AUTOINCREMENT PRIMARY KEY,
    SITE STRING,
    JOB_URL STRING UNIQUE,
    JOB_URL_DIRECT STRING,
    TITLE STRING,
    COMPANY STRING,
    LOCATION STRING,
    DATE_POSTED DATE,
    JOB_TYPE STRING,
    SALARY_SOURCE STRING,
    INTERVAL STRING,
    MIN_AMOUNT NUMBER,
    MAX_AMOUNT NUMBER,
    CURRENCY STRING,
    IS_REMOTE STRING,
    JOB_LEVEL STRING,
    JOB_FUNCTION STRING,
    LISTING_TYPE STRING,
    EMAILS STRING,
    DESCRIPTION STRING,
    COMPANY_INDUSTRY STRING,
    COMPANY_URL STRING,
    COMPANY_LOGO STRING,
    COMPANY_URL_DIRECT STRING,
    COMPANY_ADDRESSES STRING,
    COMPANY_NUM_EMPLOYEES NUMBER,
    COMPANY_REVENUE STRING,
    COMPANY_DESCRIPTION STRING,
    SKILLS STRING,
    EXPERIENCE_RANGE STRING,
    COMPANY_RATING NUMBER(3,2),
    COMPANY_REVIEWS_COUNT NUMBER,
    VACANCY_COUNT NUMBER,
    WORK_FROM_HOME_TYPE STRING,
    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    BATCH_ID STRING
);

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create BATCH_LOG table to track all batch operations
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE BATCH_LOG (
    BATCH_LOG_ID INTEGER AUTOINCREMENT PRIMARY KEY,
    BATCH_ID STRING UNIQUE NOT NULL,
    FILE_NAME STRING,
    FILE_PATH STRING,
    LOAD_START_TIME TIMESTAMP,
    LOAD_END_TIME TIMESTAMP,
    DURATION_SECONDS NUMBER(10,2),
    ROWS_IN_FILE INTEGER,
    ROWS_LOADED_TO_LOAD_TABLE INTEGER,
    ROWS_STAGED_TO_STAGE_TABLE INTEGER,
    ROWS_INSERTED_TO_JOBS_TABLE INTEGER,
    ROWS_UPDATED_IN_JOBS_TABLE INTEGER,
    STATUS STRING,  -- SUCCESS, FAILED, IN_PROGRESS
    ERROR_MESSAGE STRING,
    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create ETL stored procedure to move data from file_stage to target with batch logging
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_etl_jobs_pipeline(file_path STRING)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    batch_id STRING;
    load_ts TIMESTAMP;
    end_ts TIMESTAMP;
    file_name STRING;
    rows_in_file INTEGER DEFAULT 0;
    rows_loaded INTEGER DEFAULT 0;
    rows_staged INTEGER DEFAULT 0;
    rows_inserted INTEGER DEFAULT 0;
    rows_updated INTEGER DEFAULT 0;
    error_msg STRING DEFAULT NULL;
    batch_status STRING DEFAULT 'IN_PROGRESS';
BEGIN
    -- Generate batch ID and extract filename
    batch_id := UUID_STRING();
    load_ts := CURRENT_TIMESTAMP();
    file_name := SPLIT_PART(:file_path, '/', -1);

    -- Insert initial batch log entry
    INSERT INTO BATCH_LOG (
        BATCH_ID, FILE_NAME, FILE_PATH, LOAD_START_TIME, STATUS
    ) VALUES (
        :batch_id, :file_name, :file_path, :load_ts, 'IN_PROGRESS'
    );

    BEGIN
        -- Step 1: Create temporary table for initial load
        CREATE TEMPORARY TABLE IF NOT EXISTS temp_jobs_load LIKE jobs_load;
        EXECUTE IMMEDIATE 'TRUNCATE TABLE temp_jobs_load';

        -- Step 2: Copy from stage to temp table
        EXECUTE IMMEDIATE '
            COPY INTO temp_jobs_load (
                ID, SITE, JOB_URL, JOB_URL_DIRECT, TITLE, COMPANY, LOCATION, DATE_POSTED,
                JOB_TYPE, SALARY_SOURCE, INTERVAL, MIN_AMOUNT, MAX_AMOUNT, CURRENCY,
                IS_REMOTE, JOB_LEVEL, JOB_FUNCTION, LISTING_TYPE, EMAILS, DESCRIPTION,
                COMPANY_INDUSTRY, COMPANY_URL, COMPANY_LOGO, COMPANY_URL_DIRECT,
                COMPANY_ADDRESSES, COMPANY_NUM_EMPLOYEES, COMPANY_REVENUE,
                COMPANY_DESCRIPTION, SKILLS, EXPERIENCE_RANGE, COMPANY_RATING,
                COMPANY_REVIEWS_COUNT, VACANCY_COUNT, WORK_FROM_HOME_TYPE
            )
            FROM (
                SELECT
                    $1::string, $2::string, $3::string, $4::string, $5::string,
                    $6::string, $7::string, $8::string, $9::string, $10::string,
                    $11::string, $12::string, $13::string, $14::string, $15::string,
                    $16::string, $17::string, $18::string, $19::string, $20::string,
                    $21::string, $22::string, $23::string, $24::string, $25::string,
                    $26::string, $27::string, $28::string, $29::string, $30::string,
                    $31::string, $32::string, $33::string, $34::string
                FROM ' || :file_path || '
            )
            FILE_FORMAT = (FORMAT_NAME = my_pipe_format)';

        -- Get row count from temp table
        SELECT COUNT(*) INTO :rows_in_file FROM temp_jobs_load;

        -- Step 3: Insert into jobs_load with batch_id
        INSERT INTO jobs_load (
            ID, SITE, JOB_URL, JOB_URL_DIRECT, TITLE, COMPANY, LOCATION, DATE_POSTED,
            JOB_TYPE, SALARY_SOURCE, INTERVAL, MIN_AMOUNT, MAX_AMOUNT, CURRENCY,
            IS_REMOTE, JOB_LEVEL, JOB_FUNCTION, LISTING_TYPE, EMAILS, DESCRIPTION,
            COMPANY_INDUSTRY, COMPANY_URL, COMPANY_LOGO, COMPANY_URL_DIRECT,
            COMPANY_ADDRESSES, COMPANY_NUM_EMPLOYEES, COMPANY_REVENUE,
            COMPANY_DESCRIPTION, SKILLS, EXPERIENCE_RANGE, COMPANY_RATING,
            COMPANY_REVIEWS_COUNT, VACANCY_COUNT, WORK_FROM_HOME_TYPE,
            load_timestamp, BATCH_ID
        )
        SELECT
            t.ID, t.SITE, t.JOB_URL, t.JOB_URL_DIRECT, t.TITLE, t.COMPANY, t.LOCATION,
            t.DATE_POSTED, t.JOB_TYPE, t.SALARY_SOURCE, t.INTERVAL, t.MIN_AMOUNT,
            t.MAX_AMOUNT, t.CURRENCY, t.IS_REMOTE, t.JOB_LEVEL, t.JOB_FUNCTION,
            t.LISTING_TYPE, t.EMAILS, t.DESCRIPTION, t.COMPANY_INDUSTRY, t.COMPANY_URL,
            t.COMPANY_LOGO, t.COMPANY_URL_DIRECT, t.COMPANY_ADDRESSES,
            t.COMPANY_NUM_EMPLOYEES, t.COMPANY_REVENUE, t.COMPANY_DESCRIPTION, t.SKILLS,
            t.EXPERIENCE_RANGE, t.COMPANY_RATING, t.COMPANY_REVIEWS_COUNT,
            t.VACANCY_COUNT, t.WORK_FROM_HOME_TYPE,
            :load_ts,
            :batch_id
        FROM temp_jobs_load t;

        rows_loaded := SQLROWCOUNT;

        -- Step 4: Insert into jobs_stage (transform and deduplicate)
        INSERT INTO jobs_stage (
            SITE, JOB_URL, JOB_URL_DIRECT, TITLE, COMPANY, LOCATION, DATE_POSTED,
            JOB_TYPE, SALARY_SOURCE, INTERVAL, MIN_AMOUNT, MAX_AMOUNT, CURRENCY,
            IS_REMOTE, JOB_LEVEL, JOB_FUNCTION, LISTING_TYPE, EMAILS, DESCRIPTION,
            COMPANY_INDUSTRY, COMPANY_URL, COMPANY_LOGO, COMPANY_URL_DIRECT,
            COMPANY_ADDRESSES, COMPANY_NUM_EMPLOYEES, COMPANY_REVENUE,
            COMPANY_DESCRIPTION, SKILLS, EXPERIENCE_RANGE, COMPANY_RATING,
            COMPANY_REVIEWS_COUNT, VACANCY_COUNT, WORK_FROM_HOME_TYPE,
            LOAD_TIMESTAMP, STAGE_TIMESTAMP, BATCH_ID
        )
        SELECT
            NULLIF(TRIM(l.SITE), ''),
            NULLIF(TRIM(l.JOB_URL), ''),
            NULLIF(TRIM(l.JOB_URL_DIRECT), ''),
            NULLIF(REPLACE(TRIM(l.TITLE), ' ', '_'), ''),
            NULLIF(TRIM(l.COMPANY), ''),
            NULLIF(TRIM(l.LOCATION), ''),
            TRY_TO_DATE(l.DATE_POSTED, 'YYYY-MM-DD'),
            NULLIF(TRIM(l.JOB_TYPE), ''),
            NULLIF(TRIM(l.SALARY_SOURCE), ''),
            NULLIF(TRIM(l.INTERVAL), ''),
            TRY_TO_NUMBER(l.MIN_AMOUNT),
            TRY_TO_NUMBER(l.MAX_AMOUNT),
            NULLIF(TRIM(l.CURRENCY), ''),
            NULLIF(l.IS_REMOTE, ''),
            NULLIF(TRIM(l.JOB_LEVEL), ''),
            NULLIF(TRIM(l.JOB_FUNCTION), ''),
            NULLIF(TRIM(l.LISTING_TYPE), ''),
            NULLIF(TRIM(l.EMAILS), ''),
            NULLIF(REPLACE(TRIM(l.DESCRIPTION), '*', ''), ''),
            NULLIF(TRIM(l.COMPANY_INDUSTRY), ''),
            NULLIF(TRIM(l.COMPANY_URL), ''),
            NULLIF(l.COMPANY_LOGO, ''),
            NULLIF(TRIM(l.COMPANY_URL_DIRECT), ''),
            NULLIF(TRIM(l.COMPANY_ADDRESSES), ''),
            TRY_TO_NUMBER(REPLACE(REPLACE(SPLIT_PART(l.COMPANY_NUM_EMPLOYEES, ' to ', 1), ',', ''), '+', '')),
            NULLIF(TRIM(l.COMPANY_REVENUE), ''),
            NULLIF(TRIM(l.COMPANY_DESCRIPTION), ''),
            NULLIF(l.SKILLS, ''),
            NULLIF(l.EXPERIENCE_RANGE, ''),
            TRY_TO_NUMBER(l.COMPANY_RATING),
            TRY_TO_NUMBER(l.COMPANY_REVIEWS_COUNT),
            TRY_TO_NUMBER(l.VACANCY_COUNT),
            NULLIF(l.WORK_FROM_HOME_TYPE, ''),
            l.LOAD_TIMESTAMP,
            CURRENT_TIMESTAMP(),
            l.BATCH_ID
        FROM jobs_load l
        LEFT JOIN jobs_stage s ON l.JOB_URL = s.JOB_URL
        WHERE s.JOB_URL IS NULL
        AND l.BATCH_ID = :batch_id;

        rows_staged := SQLROWCOUNT;

        -- Step 5: Insert new jobs into JOBS table
        INSERT INTO JOBS (
            SITE, JOB_URL, JOB_URL_DIRECT, TITLE, COMPANY, LOCATION, DATE_POSTED,
            JOB_TYPE, SALARY_SOURCE, INTERVAL, MIN_AMOUNT, MAX_AMOUNT, CURRENCY,
            IS_REMOTE, JOB_LEVEL, JOB_FUNCTION, LISTING_TYPE, EMAILS, DESCRIPTION,
            COMPANY_INDUSTRY, COMPANY_URL, COMPANY_LOGO, COMPANY_URL_DIRECT,
            COMPANY_ADDRESSES, COMPANY_NUM_EMPLOYEES, COMPANY_REVENUE,
            COMPANY_DESCRIPTION, SKILLS, EXPERIENCE_RANGE, COMPANY_RATING,
            COMPANY_REVIEWS_COUNT, VACANCY_COUNT, WORK_FROM_HOME_TYPE,
            CREATED_AT, UPDATED_AT, BATCH_ID
        )
        SELECT
            s.SITE, s.JOB_URL, s.JOB_URL_DIRECT, s.TITLE, s.COMPANY, s.LOCATION,
            s.DATE_POSTED, s.JOB_TYPE, s.SALARY_SOURCE, s.INTERVAL, s.MIN_AMOUNT,
            s.MAX_AMOUNT, s.CURRENCY, s.IS_REMOTE, s.JOB_LEVEL, s.JOB_FUNCTION,
            s.LISTING_TYPE, s.EMAILS, s.DESCRIPTION, s.COMPANY_INDUSTRY, s.COMPANY_URL,
            s.COMPANY_LOGO, s.COMPANY_URL_DIRECT, s.COMPANY_ADDRESSES,
            s.COMPANY_NUM_EMPLOYEES, s.COMPANY_REVENUE, s.COMPANY_DESCRIPTION, s.SKILLS,
            s.EXPERIENCE_RANGE, s.COMPANY_RATING, s.COMPANY_REVIEWS_COUNT,
            s.VACANCY_COUNT, s.WORK_FROM_HOME_TYPE,
            s.STAGE_TIMESTAMP, s.STAGE_TIMESTAMP, s.BATCH_ID
        FROM jobs_stage s
        LEFT JOIN JOBS j ON s.JOB_URL = j.JOB_URL
        WHERE j.JOB_URL IS NULL
        AND s.BATCH_ID = :batch_id;

        rows_inserted := SQLROWCOUNT;

        -- Step 6: Update existing jobs if any changes
        MERGE INTO JOBS j
        USING (
            SELECT * FROM jobs_stage WHERE BATCH_ID = :batch_id
        ) s
        ON j.JOB_URL = s.JOB_URL
        WHEN MATCHED THEN UPDATE SET
            j.TITLE = s.TITLE,
            j.COMPANY = s.COMPANY,
            j.LOCATION = s.LOCATION,
            j.DATE_POSTED = s.DATE_POSTED,
            j.JOB_TYPE = s.JOB_TYPE,
            j.SALARY_SOURCE = s.SALARY_SOURCE,
            j.INTERVAL = s.INTERVAL,
            j.MIN_AMOUNT = s.MIN_AMOUNT,
            j.MAX_AMOUNT = s.MAX_AMOUNT,
            j.CURRENCY = s.CURRENCY,
            j.IS_REMOTE = s.IS_REMOTE,
            j.JOB_LEVEL = s.JOB_LEVEL,
            j.JOB_FUNCTION = s.JOB_FUNCTION,
            j.DESCRIPTION = s.DESCRIPTION,
            j.COMPANY_RATING = s.COMPANY_RATING,
            j.VACANCY_COUNT = s.VACANCY_COUNT,
            j.UPDATED_AT = CURRENT_TIMESTAMP(),
            j.BATCH_ID = s.BATCH_ID;

        rows_updated := SQLROWCOUNT - rows_inserted;

        -- Clean up temp table
        DROP TABLE IF EXISTS temp_jobs_load;

        -- Set success status
        batch_status := 'SUCCESS';
        end_ts := CURRENT_TIMESTAMP();

    EXCEPTION
        WHEN OTHER THEN
            error_msg := SQLERRM;
            batch_status := 'FAILED';
            end_ts := CURRENT_TIMESTAMP();
            DROP TABLE IF EXISTS temp_jobs_load;
    END;

    -- Update batch log with final results
    UPDATE BATCH_LOG
    SET
        LOAD_END_TIME = :end_ts,
        DURATION_SECONDS = DATEDIFF(SECOND, LOAD_START_TIME, :end_ts),
        ROWS_IN_FILE = :rows_in_file,
        ROWS_LOADED_TO_LOAD_TABLE = :rows_loaded,
        ROWS_STAGED_TO_STAGE_TABLE = :rows_staged,
        ROWS_INSERTED_TO_JOBS_TABLE = :rows_inserted,
        ROWS_UPDATED_IN_JOBS_TABLE = :rows_updated,
        STATUS = :batch_status,
        ERROR_MESSAGE = :error_msg
    WHERE BATCH_ID = :batch_id;

    -- Return summary
    IF (batch_status = 'SUCCESS') THEN
        RETURN 'SUCCESS - Batch ID: ' || :batch_id ||
               ' | File: ' || :file_name ||
               ' | Rows in File: ' || :rows_in_file ||
               ' | Loaded: ' || :rows_loaded ||
               ' | Staged: ' || :rows_staged ||
               ' | Inserted: ' || :rows_inserted ||
               ' | Updated: ' || :rows_updated ||
               ' | Duration: ' || DATEDIFF(SECOND, :load_ts, :end_ts) || 's';
    ELSE
        RETURN 'FAILED - Batch ID: ' || :batch_id || ' | Error: ' || :error_msg;
    END IF;

END;
$$;




-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Execute the procedure
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CALL sp_etl_jobs_pipeline('@scrapped_jobs/jobs_2025-12-09_11-24-48.csv');
-- Query batch log to see all processing history
SELECT
    BATCH_LOG_ID,
    BATCH_ID,
    FILE_NAME,
    LOAD_START_TIME,
    DURATION_SECONDS,
    ROWS_IN_FILE,
    ROWS_LOADED_TO_LOAD_TABLE,
    ROWS_STAGED_TO_STAGE_TABLE,
    ROWS_INSERTED_TO_JOBS_TABLE,
    ROWS_UPDATED_IN_JOBS_TABLE,
    STATUS
FROM BATCH_LOG
ORDER BY LOAD_START_TIME DESC;