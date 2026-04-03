--Create Database

--Create Staging Table (Raw CSV Load)

CREATE TABLE healthcare_raw (
    name TEXT,
    age INT,
    gender TEXT,
    blood_type TEXT,
    medical_condition TEXT,
    date_of_admission DATE,
    doctor TEXT,
    hospital TEXT,
    insurance_provider TEXT,
    billing_amount NUMERIC,
    room_number INT,
    admission_type TEXT,
    discharge_date DATE,
    medication TEXT,
    test_results TEXT
);
Select * From healthcare_raw


--Create Clean Tables

CREATE TABLE patients (
    patient_id SERIAL PRIMARY KEY,
    name TEXT,
    age INT,
    gender TEXT,
    blood_type TEXT
);

CREATE TABLE hospitals (
    hospital_id SERIAL PRIMARY KEY,
    hospital_name TEXT,
    doctor_name TEXT
);

CREATE TABLE admissions (
    admission_id SERIAL PRIMARY KEY,
    patient_id INT,
    hospital_id INT,
    admission_date DATE,
    discharge_date DATE,
    admission_type TEXT,
    room_number INT,
    billing_amount NUMERIC,
    insurance_provider TEXT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id)
);

CREATE TABLE medical_records (
    record_id SERIAL PRIMARY KEY,
    patient_id INT,
    medical_condition TEXT,
    medication TEXT,
    test_results TEXT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
);

UPDATE healthcare_raw
SET insurance_provider = 'Unknown'
WHERE insurance_provider IS NULL;


--Gender Form Update

UPDATE healthcare_raw
SET gender = 
CASE 
    WHEN LOWER(gender) = 'male' THEN 'Male'
    WHEN LOWER(gender) = 'female' THEN 'Female'
    ELSE 'Other'
END;


--Remove Negative Billing

DELETE FROM healthcare_raw
WHERE billing_amount < 0;


--Capitalize Names

UPDATE healthcare_raw
SET name = INITCAP(name);


--Insert Clean Data into Tables

INSERT INTO patients (name, age, gender, blood_type)
SELECT DISTINCT name, age, gender, blood_type
FROM healthcare_raw;

--Insert Hospitals

INSERT INTO hospitals (hospital_name, doctor_name)
SELECT DISTINCT hospital, doctor
FROM healthcare_raw;


--Insert Admissions

INSERT INTO admissions (
    patient_id,
    hospital_id,
    admission_date,
    discharge_date,
    admission_type,
    room_number,
    billing_amount,
    insurance_provider
)
SELECT 
    p.patient_id,
    h.hospital_id,
    r.date_of_admission,
    r.discharge_date,
    r.admission_type,
    r.room_number,
    r.billing_amount,
    r.insurance_provider
FROM healthcare_raw r
JOIN patients p 
    ON r.name = p.name AND r.age = p.age
JOIN hospitals h 
    ON r.hospital = h.hospital_name AND r.doctor = h.doctor_name;

--Insert Medical Records

INSERT INTO medical_records (
    patient_id,
    medical_condition,
    medication,
    test_results
)
SELECT 
    p.patient_id,
    r.medical_condition,
    r.medication,
    r.test_results
FROM healthcare_raw r
JOIN patients p 
    ON r.name = p.name AND r.age = p.age;

--1.Total Patients
SELECT COUNT(*) FROM patients;

--2.Average Age
SELECT ROUND(AVG(age),2) FROM patients;

--3.Gender Distribution
SELECT gender, COUNT(*) 
FROM patients
GROUP BY gender;

--4.Total Revenue
SELECT SUM(billing_amount) FROM admissions;

--5.Top Diseases
SELECT medical_condition, COUNT(*) AS total
FROM medical_records
GROUP BY medical_condition
ORDER BY total DESC
LIMIT 5;

--6.Avg Billing
SELECT ROUND(AVG(billing_amount),2) FROM admissions;

--7.Hospital Revenue
SELECT h.hospital_name, SUM(a.billing_amount) AS revenue
FROM admissions a
JOIN hospitals h ON a.hospital_id = h.hospital_id
GROUP BY h.hospital_name
ORDER BY revenue DESC;

--8.Admission Type Count
SELECT admission_type, COUNT(*) 
FROM admissions
GROUP BY admission_type;

--9.Avg Stay Days
SELECT ROUND(AVG(discharge_date - admission_date),2)
FROM admissions;

--10.Insurance Count
SELECT insurance_provider, COUNT(*) 
FROM admissions
GROUP BY insurance_provider;

--11.Top Medication
SELECT medication, COUNT(*) 
FROM medical_records
GROUP BY medication
ORDER BY COUNT(*) DESC
LIMIT 1;

--12.Test Results Distribution
SELECT test_results, COUNT(*) 
FROM medical_records
GROUP BY test_results;

--13.Doctor Workload
SELECT h.doctor_name, COUNT(*) AS patients
FROM hospitals h
JOIN admissions a ON h.hospital_id = a.hospital_id
GROUP BY h.doctor_name
ORDER BY patients DESC;

--14.Highest Billing Patient
SELECT p.name, MAX(a.billing_amount) AS max_bill
FROM patients p
JOIN admissions a ON p.patient_id = a.patient_id
GROUP BY p.name
ORDER BY max_bill DESC
LIMIT 1;

--15.Monthly Trend
SELECT DATE_TRUNC('month', admission_date) AS month,
       COUNT(*) 
FROM admissions
GROUP BY month
ORDER BY month;

--End of Report--