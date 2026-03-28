-- Hospital Management System SQL Project
-- Queries Part 2


-- 1 Emergency appointments with patient name, dob, and age-group
SELECT p.patient_name,p.dob,
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, p.dob, CURDATE()) <= 18 THEN 'Pediatric'
        WHEN TIMESTAMPDIFF(YEAR, p.dob, CURDATE()) BETWEEN 19 AND 64 THEN 'Adult'
        ELSE 'Geriatric'
    END AS age_group
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
WHERE a.reason = 'Emergency';

-- 2 Show all departments of Green Valley Medical Center
SELECT d.department_name
FROM departments d
JOIN hospitals h ON d.hospital_id = h.hospital_id
WHERE h.hospital_name = 'Green Valley Medical Center';

-- 3 Find patientss who have never had a prescription
SELECT p.patient_id, p.patient_name
FROM patients p
LEFT JOIN prescriptions pr ON p.patient_id = pr.patient_id
WHERE pr.prescription_id IS NULL;

-- 4 Patients with appointments in more than one hospital
SELECT p.patient_name, p.address, p.phone_number
FROM patients p
JOIN appointments a ON p.patient_id = a.patient_id
JOIN doctors d ON a.doctor_id = d.doctor_id
JOIN hospitals h ON d.hospital_id = h.hospital_id
GROUP BY p.patient_name, p.address, p.phone_number
HAVING COUNT(DISTINCT h.hospital_id) > 1;

-- 5 Show the latest appointment for each patient
SELECT p.patient_id, p.patient_name, 
    CASE 
        WHEN MAX(a.appointment_date) IS NULL THEN 'No appointment'
        ELSE DATE_FORMAT(MAX(a.appointment_date), '%Y-%m-%d')
    END AS latest_appointment
FROM patients p
LEFT JOIN appointments a ON p.patient_id = a.patient_id
GROUP BY p.patient_id, p.patient_name
ORDER BY p.patient_id;

-- 6 Show the 3rd most frequently prescribed medications
WITH med_counts AS (
    SELECT m.medication_id, m.Medication_name, COUNT(pres.prescription_id) AS total_prescribed,
           DENSE_RANK() OVER (ORDER BY COUNT(pres.prescription_id) DESC) AS rnk
    FROM medications m
    JOIN prescriptions pres ON m.medication_id = pres.medication_id
    GROUP BY m.medication_id, m.Medication_name
)
SELECT medication_id, Medication_name, total_prescribed
FROM med_counts
WHERE rnk = 3;

-- 7 Show all hospitals with the lowest doctor count
WITH doctor_counts AS (
    SELECT h.hospital_id, h.hospital_name, COUNT(d.doctor_id) AS doctor_count
    FROM hospitals h
    LEFT JOIN doctors d ON h.hospital_id = d.hospital_id
    GROUP BY h.hospital_id, h.hospital_name
),
min_val AS (
    SELECT MIN(doctor_count) AS min_count FROM doctor_counts
)
SELECT dc.hospital_name, dc.doctor_count
FROM doctor_counts dc, min_val
WHERE dc.doctor_count = min_val.min_count;

-- 8 Department with second largest room capacity in each hospital
WITH dept_capacity AS (
    SELECT d.hospital_id, d.department_id, d.department_name,
           SUM(r.capacity) AS total_capacity
    FROM departments d
    JOIN rooms r ON d.department_id = r.department_id
    GROUP BY d.hospital_id, d.department_id, d.department_name
),
ranked AS (
    SELECT hospital_id, department_name, total_capacity,
           DENSE_RANK() OVER (PARTITION BY hospital_id ORDER BY total_capacity DESC) AS rnk
    FROM dept_capacity
)
SELECT hospital_id, department_name, total_capacity
FROM ranked
WHERE rnk = 2;
