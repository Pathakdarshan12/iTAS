-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create Skills Master Table (Reference data)
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE SKILLS_MASTER (
    SKILL_ID INTEGER AUTOINCREMENT PRIMARY KEY,
    SKILL_NAME STRING UNIQUE,
    SKILL_CATEGORY STRING,  -- Technical, Soft Skills, Tools, Languages, Frameworks, etc.
    ALIASES STRING,  -- Alternative names (e.g., "JS" for "JavaScript")
    CREATED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

INSERT INTO SKILLS_MASTER (SKILL_NAME, SKILL_CATEGORY, ALIASES) VALUES
-- Programming Languages
('Python', 'Programming Language', 'python,py'),
('Java', 'Programming Language', 'java'),
('JavaScript', 'Programming Language', 'javascript,js,ecmascript'),
('TypeScript', 'Programming Language', 'typescript,ts'),
('C++', 'Programming Language', 'c++,cpp'),
('C#', 'Programming Language', 'c#,csharp'),
('Go', 'Programming Language', 'golang,go'),
('Ruby', 'Programming Language', 'ruby'),
('PHP', 'Programming Language', 'php'),
('Swift', 'Programming Language', 'swift'),
('Kotlin', 'Programming Language', 'kotlin'),
('Rust', 'Programming Language', 'rust'),
('SQL', 'Programming Language', 'sql,structured query language'),
('R', 'Programming Language', 'r language'),

-- Frameworks & Libraries
('React', 'Framework', 'react,reactjs,react.js'),
('Angular', 'Framework', 'angular,angularjs'),
('Vue.js', 'Framework', 'vue,vuejs,vue.js'),
('Node.js', 'Framework', 'node,nodejs,node.js'),
('Django', 'Framework', 'django'),
('Flask', 'Framework', 'flask'),
('Spring Boot', 'Framework', 'spring,springboot'),
('.NET', 'Framework', 'dotnet,.net,asp.net'),
('Express.js', 'Framework', 'express,expressjs'),
('FastAPI', 'Framework', 'fastapi'),
('TensorFlow', 'Framework', 'tensorflow,tf'),
('PyTorch', 'Framework', 'pytorch'),
('Pandas', 'Library', 'pandas'),
('NumPy', 'Library', 'numpy'),

-- Databases
('MySQL', 'Database', 'mysql'),
('PostgreSQL', 'Database', 'postgresql,postgres,psql'),
('MongoDB', 'Database', 'mongodb,mongo'),
('Redis', 'Database', 'redis'),
('Oracle', 'Database', 'oracle db,oracle database'),
('Microsoft SQL Server', 'Database', 'sql server,mssql,ms sql'),
('Cassandra', 'Database', 'cassandra'),
('DynamoDB', 'Database', 'dynamodb'),
('Elasticsearch', 'Database', 'elasticsearch,elastic'),
('Snowflake', 'Database', 'snowflake'),

-- Cloud Platforms
('AWS', 'Cloud Platform', 'aws,amazon web services'),
('Azure', 'Cloud Platform', 'azure,microsoft azure'),
('Google Cloud', 'Cloud Platform', 'gcp,google cloud platform'),
('Docker', 'DevOps Tool', 'docker,containers'),
('Kubernetes', 'DevOps Tool', 'kubernetes,k8s'),
('Jenkins', 'DevOps Tool', 'jenkins'),
('Terraform', 'DevOps Tool', 'terraform'),

-- Data & Analytics
('Tableau', 'Analytics Tool', 'tableau'),
('Power BI', 'Analytics Tool', 'powerbi,power bi'),
('Apache Spark', 'Big Data', 'spark,pyspark'),
('Hadoop', 'Big Data', 'hadoop'),
('Airflow', 'Data Engineering', 'airflow,apache airflow'),
('Kafka', 'Data Engineering', 'kafka,apache kafka'),
('ETL', 'Data Engineering', 'etl,extract transform load'),

-- Soft Skills
('Communication', 'Soft Skill', 'communication,verbal,written'),
('Leadership', 'Soft Skill', 'leadership,team lead'),
('Problem Solving', 'Soft Skill', 'problem solving,analytical'),
('Teamwork', 'Soft Skill', 'teamwork,collaboration,team player'),
('Agile', 'Methodology', 'agile,scrum,kanban'),
('Project Management', 'Soft Skill', 'project management,pmp');

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create Extracted Skills Table
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE JOB_EXTRACTED_SKILLS (
    EXTRACTION_ID INTEGER AUTOINCREMENT PRIMARY KEY,
    JOB_ID INTEGER,
    SKILL_ID INTEGER,
    SKILL_NAME STRING,
    MENTION_COUNT INTEGER,  -- How many times skill appears
    CONFIDENCE_SCORE NUMBER(3,2),  -- 0-1 score
    EXTRACTED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (JOB_ID) REFERENCES JOBS(JOB_ID),
    FOREIGN KEY (SKILL_ID) REFERENCES SKILLS_MASTER(SKILL_ID),
    UNIQUE (JOB_ID, SKILL_ID)
);

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create Extracted Requirements Table
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE JOB_EXTRACTED_REQUIREMENTS (
    REQUIREMENT_ID INTEGER AUTOINCREMENT PRIMARY KEY,
    JOB_ID INTEGER,
    REQUIREMENT_TYPE STRING,  -- Education, Experience, Certification, Language
    REQUIREMENT_VALUE STRING,
    EXTRACTED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (JOB_ID) REFERENCES JOBS(JOB_ID)
);

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create Extracted Benefits Table
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TABLE JOB_EXTRACTED_BENEFITS (
    BENEFIT_ID INTEGER AUTOINCREMENT PRIMARY KEY,
    JOB_ID INTEGER,
    BENEFIT_TYPE STRING,  -- Health Insurance, 401k, Remote, Flexible Hours, etc.
    BENEFIT_DESCRIPTION STRING,
    EXTRACTED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (JOB_ID) REFERENCES JOBS(JOB_ID)
);

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create Analytics Views
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_job_skills_summary AS
SELECT
    j.JOB_ID,
    j.TITLE,
    j.COMPANY,
    j.LOCATION,
    j.MIN_AMOUNT,
    j.MAX_AMOUNT,
    COUNT(DISTINCT jes.SKILL_ID) as total_skills,
    LISTAGG(DISTINCT jes.SKILL_NAME, ', ') WITHIN GROUP (ORDER BY jes.SKILL_NAME) as skills_list,
    LISTAGG(DISTINCT jer.REQUIREMENT_VALUE, ', ') WITHIN GROUP (ORDER BY jer.REQUIREMENT_VALUE) as requirements_list,
    LISTAGG(DISTINCT jeb.BENEFIT_TYPE, ', ') WITHIN GROUP (ORDER BY jeb.BENEFIT_TYPE) as benefits_list
FROM JOBS j
LEFT JOIN JOB_EXTRACTED_SKILLS jes ON j.JOB_ID = jes.JOB_ID
LEFT JOIN JOB_EXTRACTED_REQUIREMENTS jer ON j.JOB_ID = jer.JOB_ID
LEFT JOIN JOB_EXTRACTED_BENEFITS jeb ON j.JOB_ID = jeb.JOB_ID
GROUP BY j.JOB_ID, j.TITLE, j.COMPANY, j.LOCATION, j.MIN_AMOUNT, j.MAX_AMOUNT;
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_top_skills_by_salary AS
SELECT
    jes.SKILL_NAME,
    sm.SKILL_CATEGORY,
    COUNT(DISTINCT j.JOB_ID) as job_count,
    AVG((j.MIN_AMOUNT + j.MAX_AMOUNT) / 2) as avg_salary,
    MIN(j.MIN_AMOUNT) as min_salary,
    MAX(j.MAX_AMOUNT) as max_salary
FROM JOB_EXTRACTED_SKILLS jes
JOIN SKILLS_MASTER sm ON jes.SKILL_ID = sm.SKILL_ID
JOIN JOBS j ON jes.JOB_ID = j.JOB_ID
WHERE j.MIN_AMOUNT IS NOT NULL
GROUP BY jes.SKILL_NAME, sm.SKILL_CATEGORY
ORDER BY avg_salary DESC;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create Python UDF for Skills Extraction
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION extract_skills_from_description(description STRING)
RETURNS ARRAY
LANGUAGE PYTHON
RUNTIME_VERSION = 3.9
HANDLER = 'extract_skills'
AS
$$
import re

def extract_skills(description):
    if not description:
        return []

    description_lower = description.lower()

    # Comprehensive skills list
    technical_skills = {
        # Programming Languages
        'python', 'java', 'javascript', 'typescript', 'c\\+\\+', 'c#', 'go', 'rust',
        'ruby', 'php', 'swift', 'kotlin', 'scala','matlab', 'perl',
        'sql', 'nosql', 'html', 'css',

        # Frameworks & Libraries
        'react', 'angular', 'vue\\.?js', 'node\\.?js', 'express', 'django',
        'flask', 'fastapi', 'spring boot', 'spring', '\\.net', 'asp\\.net',
        'laravel', 'tensorflow', 'pytorch', 'scikit-learn', 'pandas', 'numpy',

        # Databases
        'mysql', 'postgresql', 'postgres', 'mongodb', 'redis', 'cassandra',
        'oracle', 'dynamodb', 'elasticsearch', 'neo4j', 'snowflake', 'sql server',

        # Cloud & DevOps
        'aws', 'azure', 'gcp', 'google cloud', 'docker', 'kubernetes', 'k8s',
        'jenkins', 'terraform', 'ansible', 'gitlab', 'github', 'ci/cd',

        # Data & Analytics
        'spark', 'hadoop', 'airflow', 'kafka', 'tableau', 'power bi', 'looker',
        'etl', 'data warehousing', 'big data',

        # Tools
        'git', 'jira', 'confluence', 'slack', 'figma', 'postman', 'linux',
        'unix', 'windows', 'rest api', 'graphql', 'microservices',

        # Methodologies
        'agile', 'scrum', 'kanban', 'devops', 'ci/cd', 'tdd', 'bdd'
    }

    found_skills = []

    for skill in technical_skills:
        pattern = r'\b' + skill + r'\b'
        if re.search(pattern, description_lower, re.IGNORECASE):
            # Clean up the skill name for output
            clean_skill = skill.replace('\\b', '').replace('\\+\\+', '++').replace('\\.', '.')
            if clean_skill not in found_skills:
                found_skills.append(clean_skill.title())

    return found_skills
$$;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create Python UDF for Requirements Extraction
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION extract_requirements_from_description(description STRING)
RETURNS OBJECT
LANGUAGE PYTHON
RUNTIME_VERSION = 3.9
HANDLER = 'extract_requirements'
AS
$$
import re

def extract_requirements(description):
    if not description:
        return {}

    requirements = {
        'education': [],
        'experience_years': None,
        'certifications': []
    }

    description_lower = description.lower()

    # Education
    if re.search(r'\b(bachelor|bachelors|b\.s\.|b\.a\.)\b', description_lower):
        requirements['education'].append("Bachelor's Degree")

    if re.search(r'\b(master|masters|m\.s\.|m\.a\.)\b', description_lower):
        requirements['education'].append("Master's Degree")

    if re.search(r'\b(phd|ph\.d\.|doctorate|doctoral)\b', description_lower):
        requirements['education'].append('PhD')

    # Experience years
    exp_match = re.search(r'(\d+)[\s-]*\+?\s*(?:to\s*(\d+))?\s*years?\s*(?:of)?\s*(?:experience)?', description_lower)
    if exp_match:
        min_years = exp_match.group(1)
        max_years = exp_match.group(2) if exp_match.group(2) else None
        if max_years:
            requirements['experience_years'] = f"{min_years}-{max_years} years"
        else:
            requirements['experience_years'] = f"{min_years}+ years"

    # Certifications
    if re.search(r'\b(aws certified|aws certification)\b', description_lower):
        requirements['certifications'].append('AWS Certified')

    if re.search(r'\b(pmp|project management professional)\b', description_lower):
        requirements['certifications'].append('PMP')

    if re.search(r'\b(scrum master|csm|certified scrum)\b', description_lower):
        requirements['certifications'].append('Scrum Master')

    if re.search(r'\b(azure certified|azure certification)\b', description_lower):
        requirements['certifications'].append('Azure Certified')

    return requirements
$$;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create Python UDF for Benefits Extraction
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION extract_benefits_from_description(description STRING)
RETURNS ARRAY
LANGUAGE PYTHON
RUNTIME_VERSION = 3.9
HANDLER = 'extract_benefits'
AS
$$
import re

def extract_benefits(description):
    if not description:
        return []

    benefits = []
    description_lower = description.lower()

    benefit_patterns = {
        'Health Insurance': [r'health insurance', r'medical coverage', r'health benefits', r'medical insurance'],
        '401k/Retirement': [r'401k', r'retirement plan', r'pension'],
        'Remote Work': [r'remote work', r'work from home', r'\bwfh\b', r'remote-first', r'fully remote'],
        'Flexible Hours': [r'flexible hours', r'flexible schedule', r'flex time', r'flexible working'],
        'Paid Time Off': [r'paid time off', r'\bpto\b', r'vacation days', r'paid leave', r'unlimited pto'],
        'Professional Development': [r'professional development', r'training', r'learning budget', r'education reimbursement', r'conference'],
        'Stock Options': [r'stock options', r'equity', r'\brsu\b', r'restricted stock', r'esop'],
        'Dental Insurance': [r'dental insurance', r'dental coverage'],
        'Vision Insurance': [r'vision insurance', r'vision coverage'],
        'Life Insurance': [r'life insurance'],
        'Parental Leave': [r'parental leave', r'maternity leave', r'paternity leave'],
        'Gym Membership': [r'gym membership', r'fitness', r'wellness program'],
        'Free Food': [r'free lunch', r'free food', r'catered meals', r'snacks'],
        'Commuter Benefits': [r'commuter benefits', r'transportation', r'parking']
    }

    for benefit, patterns in benefit_patterns.items():
        for pattern in patterns:
            if re.search(pattern, description_lower):
                if benefit not in benefits:
                    benefits.append(benefit)
                break

    return benefits
$$;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create Error Log Table
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CREATE TABLE IF NOT EXISTS ERROR_LOG (
--     ERROR_ID INTEGER AUTOINCREMENT PRIMARY KEY,
--     JOB_ID INTEGER,
--     ERROR_MESSAGE STRING,
--     ERROR_TIME TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
-- );

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure to Extract Single Job using Python UDFs
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_python_extract_single_job(job_id_param INTEGER)
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    description_text STRING;
    skills_array ARRAY;
    requirements_obj OBJECT;
    benefits_array ARRAY;
BEGIN
    -- Get job description
    SELECT DESCRIPTION INTO :description_text
    FROM JOBS
    WHERE JOB_ID = :job_id_param;

    IF (:description_text IS NULL) THEN
        RETURN 'Job ID ' || :job_id_param || ' has no description';
    END IF;

    -- Delete existing extractions
    DELETE FROM JOB_EXTRACTED_SKILLS WHERE JOB_ID = :job_id_param;
    DELETE FROM JOB_EXTRACTED_REQUIREMENTS WHERE JOB_ID = :job_id_param;
    DELETE FROM JOB_EXTRACTED_BENEFITS WHERE JOB_ID = :job_id_param;

    -- Extract and insert skills
    INSERT INTO JOB_EXTRACTED_SKILLS (JOB_ID, SKILL_ID, SKILL_NAME, MENTION_COUNT, CONFIDENCE_SCORE)
    SELECT
        :job_id_param,
        sm.SKILL_ID,
        f.VALUE::STRING,
        1,
        0.8
    FROM TABLE(FLATTEN(extract_skills_from_description(:description_text))) f,
         SKILLS_MASTER sm
    WHERE UPPER(sm.SKILL_NAME) = UPPER(f.VALUE::STRING);

    -- Extract and insert requirements
    SELECT extract_requirements_from_description(:description_text) INTO :requirements_obj;

    -- Insert education
    INSERT INTO JOB_EXTRACTED_REQUIREMENTS (JOB_ID, REQUIREMENT_TYPE, REQUIREMENT_VALUE)
    SELECT :job_id_param, 'Education', f.VALUE::STRING
    FROM TABLE(FLATTEN(:requirements_obj:education)) f;

    -- Insert experience
    INSERT INTO JOB_EXTRACTED_REQUIREMENTS (JOB_ID, REQUIREMENT_TYPE, REQUIREMENT_VALUE)
    SELECT :job_id_param, 'Experience Years', :requirements_obj:experience_years::STRING
    WHERE :requirements_obj:experience_years IS NOT NULL;

    -- Insert certifications
    INSERT INTO JOB_EXTRACTED_REQUIREMENTS (JOB_ID, REQUIREMENT_TYPE, REQUIREMENT_VALUE)
    SELECT :job_id_param, 'Certification', f.VALUE::STRING
    FROM TABLE(FLATTEN(:requirements_obj:certifications)) f;

    -- Extract and insert benefits
    INSERT INTO JOB_EXTRACTED_BENEFITS (JOB_ID, BENEFIT_TYPE, BENEFIT_DESCRIPTION)
    SELECT
        :job_id_param,
        f.VALUE::STRING,
        f.VALUE::STRING || ' mentioned'
    FROM TABLE(FLATTEN(extract_benefits_from_description(:description_text))) f;

    RETURN 'Successfully extracted data for Job ID: ' || :job_id_param;

EXCEPTION
    WHEN OTHER THEN
        RETURN 'Error: ' || SQLERRM;
END;
$$;

-- Extract for single job
-- CALL sp_python_extract_single_job(2);
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Update all jobs with extracted skills using SQL
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO JOB_EXTRACTED_SKILLS (JOB_ID, SKILL_ID, SKILL_NAME, MENTION_COUNT, CONFIDENCE_SCORE)
SELECT
    j.JOB_ID,
    sm.SKILL_ID,
    f.VALUE::STRING,
    1,
    0.8
FROM JOBS j,
     TABLE(FLATTEN(extract_skills_from_description(j.DESCRIPTION))) f,
     SKILLS_MASTER sm
WHERE UPPER(sm.SKILL_NAME) = UPPER(f.VALUE::STRING)
AND j.JOB_ID NOT IN (SELECT DISTINCT JOB_ID FROM JOB_EXTRACTED_SKILLS);

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Update all jobs with extracted benefits using SQL
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO JOB_EXTRACTED_BENEFITS (JOB_ID, BENEFIT_TYPE, BENEFIT_DESCRIPTION, EXTRACTED_AT )
SELECT
    j.JOB_ID,
    f.VALUE::STRING AS BENEFIT,
    f.VALUE::STRING || ' mentioned' AS BENEFIT_DESCRIPTION,
    current_timestamp
FROM JOBS j,
     TABLE(FLATTEN(extract_benefits_from_description(j.DESCRIPTION))) f;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Update all jobs with extracted benefits using SQL
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO JOB_EXTRACTED_REQUIREMENTS (JOB_ID, REQUIREMENT_TYPE, REQUIREMENT_VALUE)
WITH req AS (
    SELECT
        j.JOB_ID,
        extract_requirements_from_description(j.DESCRIPTION) AS req_obj
    FROM JOBS j
)
-- Education
SELECT
    r.JOB_ID,
    'Education' AS REQUIREMENT_TYPE,
    f.VALUE::STRING AS REQUIREMENT_VALUE
FROM req r,
TABLE(FLATTEN(r.req_obj:education)) f

UNION ALL

-- Experience
SELECT
    r.JOB_ID,
    'Experience Years',
    r.req_obj:experience_years::STRING
FROM req r
WHERE r.req_obj:experience_years IS NOT NULL

UNION ALL

-- Certifications
SELECT
    r.JOB_ID,
    'Certification',
    f.VALUE::STRING
FROM req r,
     TABLE(FLATTEN(r.req_obj:certifications)) f;
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM
