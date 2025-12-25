/*========================================
  ENABLE OUTPUT
========================================*/
SET SERVEROUTPUT ON;

/*========================================
  DROP OBJECTS (OPTIONAL – IF RE-RUNNING)
========================================*/
-- DROP TABLE transactions;
-- DROP TABLE accounts;
-- DROP TABLE customers;
-- DROP SEQUENCE cust_seq;
-- DROP SEQUENCE acc_seq;
-- DROP SEQUENCE txn_seq;

/*========================================
  1. TABLES
========================================*/
CREATE TABLE customers (
    cust_id    NUMBER PRIMARY KEY,
    cust_name  VARCHAR2(50),
    phone      VARCHAR2(15)
);

CREATE TABLE accounts (
    acc_id   NUMBER PRIMARY KEY,
    cust_id  NUMBER,
    balance  NUMBER,
    CONSTRAINT fk_customer
        FOREIGN KEY (cust_id)
        REFERENCES customers(cust_id)
);

CREATE TABLE transactions (
    txn_id    NUMBER PRIMARY KEY,
    acc_id    NUMBER,
    txn_type  VARCHAR2(10),
    amount    NUMBER,
    txn_date  DATE
);

/*========================================
  2. SEQUENCES
========================================*/
CREATE SEQUENCE cust_seq START WITH 1;
CREATE SEQUENCE acc_seq  START WITH 1001;
CREATE SEQUENCE txn_seq  START WITH 1;

/*========================================
  3. SAMPLE DATA (10 RECORDS)
========================================*/
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Rishabh',  '9876543210');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Samiksha', '9123456789');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Amit',     '9988776655');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Neha',     '9876501234');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Ravi',     '9090909090');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Pooja',    '9012345678');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Rahul',    '9345678123');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Sneha',    '9456123789');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Karan',    '9567123489');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Anita',    '9678234512');

INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 1,  5000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 2, 12000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 3,  8000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 4, 15000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 5,  3000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 6, 20000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 7,  7000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 8,  9000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 9, 11000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL,10, 25000);

COMMIT;

/*========================================
  4. FUNCTION – GET BALANCE
========================================*/
CREATE OR REPLACE FUNCTION get_balance (
    p_acc_id NUMBER
)
RETURN NUMBER
IS
    v_balance NUMBER;
BEGIN
    SELECT balance
    INTO   v_balance
    FROM   accounts
    WHERE  acc_id = p_acc_id;

    RETURN v_balance;
END;
/

/*========================================
  5. PROCEDURE – DEPOSIT MONEY
========================================*/
CREATE OR REPLACE PROCEDURE deposit_money (
    p_acc_id NUMBER,
    p_amount NUMBER
)
IS
BEGIN
    UPDATE accounts
    SET balance = balance + p_amount
    WHERE acc_id = p_acc_id;

    DBMS_OUTPUT.PUT_LINE('DEPOSIT SUCCESSFUL');
    DBMS_OUTPUT.PUT_LINE('  Account : ' || p_acc_id);
    DBMS_OUTPUT.PUT_LINE('  Amount  : ' || p_amount);
END;
/

/*========================================
  6. PROCEDURE – WITHDRAW MONEY
========================================*/
CREATE OR REPLACE PROCEDURE withdraw_money (
    p_acc_id NUMBER,
    p_amount NUMBER
)
IS
    v_balance NUMBER;
BEGIN
    SELECT balance
    INTO   v_balance
    FROM   accounts
    WHERE  acc_id = p_acc_id;

    IF v_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20001, '❌Insufficient Balance');
    END IF;

    UPDATE accounts
    SET balance = balance - p_amount
    WHERE acc_id = p_acc_id;

    DBMS_OUTPUT.PUT_LINE('WITHDRAWAL SUCCESSFUL');
    DBMS_OUTPUT.PUT_LINE('  Account : ' || p_acc_id);
    DBMS_OUTPUT.PUT_LINE('  Amount  : ' || p_amount);
END;
/

/*========================================
  7. TRIGGER – AUTO TRANSACTION LOG
========================================*/
CREATE OR REPLACE TRIGGER trg_transaction_log
AFTER UPDATE OF balance ON accounts
FOR EACH ROW
BEGIN
    INSERT INTO transactions
    VALUES (
        txn_seq.NEXTVAL,
        :NEW.acc_id,
        CASE
            WHEN :NEW.balance > :OLD.balance THEN 'DEPOSIT'
            ELSE 'WITHDRAW'
        END,
        ABS(:NEW.balance - :OLD.balance),
        SYSDATE
    );
END;
/

/*========================================
  8. TEST EXECUTION (DEMO)
========================================*/
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- INITIAL BALANCE ---');
    DBMS_OUTPUT.PUT_LINE(get_balance(1002));

    deposit_money(1002, 2000);
    withdraw_money(1002, 1000);

    DBMS_OUTPUT.PUT_LINE('--- FINAL BALANCE ---');
    DBMS_OUTPUT.PUT_LINE(get_balance(1002));
END;
/
