-- Day 1: Run in MySQL Workbench before importing data/financial_loan_clean.csv.
CREATE DATABASE IF NOT EXISTS bank_loan_db;
USE bank_loan_db;

-- The archive has no public loan ID. loan_record_key preserves its source row number.
CREATE TABLE IF NOT EXISTS financial_loan (
    loan_record_key INT NOT NULL PRIMARY KEY,
    issue_date DATE NOT NULL,
    loan_status VARCHAR(20) NOT NULL,
    grade CHAR(1) NOT NULL,
    sub_grade CHAR(2) NOT NULL,
    purpose VARCHAR(80) NOT NULL,
    home_ownership VARCHAR(30) NOT NULL,
    annual_income DECIMAL(14, 2) NULL,
    dti DECIMAL(7, 4) NOT NULL,
    int_rate DECIMAL(7, 4) NOT NULL,
    loan_amount DECIMAL(14, 2) NOT NULL,
    funded_amount DECIMAL(14, 2) NOT NULL,
    total_payment DECIMAL(14, 2) NOT NULL,
    term VARCHAR(20) NOT NULL,
    emp_length VARCHAR(20) NOT NULL,
    address_state CHAR(2) NOT NULL
);
