/*=====================================================
  ENABLE OUTPUT
=====================================================*/
SET SERVEROUTPUT ON;

/*=====================================================
  (OPTIONAL) DROP OBJECTS – use if re-running
=====================================================*/
-- DROP TABLE salary_audit;
-- DROP TABLE salary_details;
-- DROP TABLE employees;
-- DROP TABLE departments;
-- DROP SEQUENCE emp_seq;
-- DROP SEQUENCE dept_seq;

/*=====================================================
  1. TABLE CREATION
=====================================================*/
CREATE TABLE departments (
    dept_id   NUMBER PRIMARY KEY,
    dept_name VARCHAR2(50)
);

CREATE TABLE employees (
    emp_id        NUMBER PRIMARY KEY,
    emp_name      VARCHAR2(50),
    basic_salary  NUMBER,
    dept_id       NUMBER,
    CONSTRAINT fk_dept FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id)
);

CREATE TABLE salary_details (
    emp_id       NUMBER,
    hra          NUMBER,
    bonus        NUMBER,
    tax          NUMBER,
    net_salary   NUMBER,
    salary_month VARCHAR2(20)
);

CREATE TABLE salary_audit (
    emp_id      NUMBER,
    old_salary  NUMBER,
    new_salary  NUMBER,
    change_date DATE
);

/*=====================================================
  2. SEQUENCES
=====================================================*/
CREATE SEQUENCE dept_seq START WITH 1;
CREATE SEQUENCE emp_seq  START WITH 101;

/*=====================================================
  3. INSERT MASTER DATA
=====================================================*/
-- Departments
INSERT INTO departments VALUES (dept_seq.NEXTVAL, 'HR');
INSERT INTO departments VALUES (dept_seq.NEXTVAL, 'IT');
INSERT INTO departments VALUES (dept_seq.NEXTVAL, 'FINANCE');
INSERT INTO departments VALUES (dept_seq.NEXTVAL, 'SALES');
INSERT INTO departments VALUES (dept_seq.NEXTVAL, 'OPERATIONS');

-- Employees
INSERT INTO employees VALUES (emp_seq.NEXTVAL, 'Rishabh', 40000, 2);
INSERT INTO employees VALUES (emp_seq.NEXTVAL, 'Samiksha',35000, 1);
INSERT INTO employees VALUES (emp_seq.NEXTVAL, 'Amit',    50000, 3);
INSERT INTO employees VALUES (emp_seq.NEXTVAL, 'Neha',    28000, 1);
INSERT INTO employees VALUES (emp_seq.NEXTVAL, 'Ravi',    45000, 2);
INSERT INTO employees VALUES (emp_seq.NEXTVAL, 'Pooja',   30000, 4);
INSERT INTO employees VALUES (emp_seq.NEXTVAL, 'Rahul',   55000, 3);
INSERT INTO employees VALUES (emp_seq.NEXTVAL, 'Sneha',   32000, 2);
INSERT INTO employees VALUES (emp_seq.NEXTVAL, 'Karan',   60000, 5);
INSERT INTO employees VALUES (emp_seq.NEXTVAL, 'Anita',   37000, 4);
INSERT INTO employees VALUES (emp_seq.NEXTVAL, 'Vikas',   42000, 5);

COMMIT;

/*=====================================================
  4. FUNCTION – TAX CALCULATION
=====================================================*/
CREATE OR REPLACE FUNCTION calc_tax(p_basic NUMBER)
RETURN NUMBER IS
BEGIN
    IF p_basic <= 30000 THEN
        RETURN p_basic * 0.05;
    ELSE
        RETURN p_basic * 0.10;
    END IF;
END;
/

/*=====================================================
  5. PACKAGE – PAYROLL LOGIC
=====================================================*/
CREATE OR REPLACE PACKAGE payroll_pkg IS
    PROCEDURE calculate_salary(p_month VARCHAR2);
END payroll_pkg;
/

CREATE OR REPLACE PACKAGE BODY payroll_pkg IS

PROCEDURE calculate_salary(p_month VARCHAR2) IS
    CURSOR emp_cur IS
        SELECT emp_id, basic_salary FROM employees;

    v_hra   NUMBER;
    v_bonus NUMBER;
    v_tax   NUMBER;
    v_net   NUMBER;
BEGIN
    -- Prevent duplicate payroll for same month
    DELETE FROM salary_details WHERE salary_month = p_month;

    FOR rec IN emp_cur LOOP
        v_hra   := rec.basic_salary * 0.20;
        v_bonus := rec.basic_salary * 0.10;
        v_tax   := calc_tax(rec.basic_salary);
        v_net   := rec.basic_salary + v_hra + v_bonus - v_tax;

        INSERT INTO salary_details
        VALUES (rec.emp_id, v_hra, v_bonus, v_tax, v_net, p_month);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('✔ Payroll calculated for ' || p_month);
END;

END payroll_pkg;
/

/*=====================================================
  6. RUN PAYROLL
=====================================================*/
BEGIN
    payroll_pkg.calculate_salary('DEC-2025');
END;
/

/*=====================================================
  7. DEPARTMENT-WISE SALARY REPORT (FORMATTED)
=====================================================*/
DECLARE
    CURSOR dept_report IS
        SELECT d.dept_name, e.emp_id, e.emp_name, s.net_salary
        FROM employees e
        JOIN departments d ON e.dept_id = d.dept_id
        JOIN salary_details s ON e.emp_id = s.emp_id
        ORDER BY d.dept_name, e.emp_name;
BEGIN
    DBMS_OUTPUT.PUT_LINE('======================================================');
    DBMS_OUTPUT.PUT_LINE('           DEPARTMENT WISE SALARY REPORT');
    DBMS_OUTPUT.PUT_LINE('======================================================');
    DBMS_OUTPUT.PUT_LINE(
        RPAD('DEPT',15) ||
        RPAD('EMP_ID',8) ||
        RPAD('EMP_NAME',15) ||
        'NET SALARY'
    );
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------');

    FOR rec IN dept_report LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.dept_name,15) ||
            RPAD(rec.emp_id,8) ||
            RPAD(rec.emp_name,15) ||
            '₹' || rec.net_salary
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('======================================================');
END;
/

/*=====================================================
  8. TRIGGER – SALARY AUDIT
=====================================================*/
CREATE OR REPLACE TRIGGER trg_salary_audit
AFTER UPDATE OF basic_salary ON employees
FOR EACH ROW
BEGIN
    INSERT INTO salary_audit
    VALUES (
        :OLD.emp_id,
        :OLD.basic_salary,
        :NEW.basic_salary,
        SYSDATE
    );
END;
/

/*=====================================================
  9. UPDATE SALARY (TEST TRIGGER)
=====================================================*/
UPDATE employees
SET basic_salary = 47000
WHERE emp_id = 102;

/*=====================================================
  10. SALARY AUDIT REPORT (FORMATTED)
=====================================================*/
DECLARE
    CURSOR audit_cur IS
        SELECT emp_id, old_salary, new_salary, change_date
        FROM salary_audit;
BEGIN
    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE('           SALARY AUDIT REPORT');
    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE(
        RPAD('EMP_ID',8) ||
        RPAD('OLD SAL',12) ||
        RPAD('NEW SAL',12) ||
        'DATE'
    );
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------');

    FOR rec IN audit_cur LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.emp_id,8) ||
            RPAD('₹'||rec.old_salary,12) ||
            RPAD('₹'||rec.new_salary,12) ||
            TO_CHAR(rec.change_date,'DD-MON-YYYY')
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('==============================================');
END;
/
