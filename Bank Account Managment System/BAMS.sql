CREATE TABLE customers (
    cust_id NUMBER PRIMARY KEY,
    cust_name VARCHAR2(50),
    phone VARCHAR2(15)
);
CREATE TABLE accounts (
    acc_id NUMBER PRIMARY KEY,
    cust_id NUMBER,
    balance NUMBER,
    CONSTRAINT fk_cust FOREIGN KEY (cust_id) REFERENCES customers(cust_id)
);
CREATE TABLE transactions (
    txn_id NUMBER PRIMARY KEY,
    acc_id NUMBER,
    txn_type VARCHAR2(10),
    amount NUMBER,
    txn_date DATE
);

CREATE SEQUENCE cust_seq START WITH 1;
CREATE SEQUENCE acc_seq START WITH 1001;
CREATE SEQUENCE txn_seq START WITH 1;


INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Rishabh', '9876543210');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Samiksha', '9123456789');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Amit', '9988776655');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Neha', '9876501234');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Ravi', '9090909090');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Pooja', '9012345678');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Rahul', '9345678123');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Sneha', '9456123789');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Karan', '9567123489');
INSERT INTO customers VALUES (cust_seq.NEXTVAL, 'Anita', '9678234512');

INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 1, 5000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 2, 12000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 3, 8000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 4, 15000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 5, 3000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 6, 20000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 7, 7000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 8, 9000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 9, 11000);
INSERT INTO accounts VALUES (acc_seq.NEXTVAL, 10, 25000);

COMMIT;

CREATE OR REPLACE FUNCTION get_balance(p_acc_id NUMBER)
RETURN NUMBER IS
    v_balance NUMBER;
BEGIN
    SELECT balance INTO v_balance
    FROM accounts
    WHERE acc_id = p_acc_id;

    RETURN v_balance;
END;
/

SELECT get_balance(1001) FROM dual;


CREATE OR REPLACE PROCEDURE deposit_money (
    p_acc_id NUMBER,
    p_amount NUMBER
) IS
BEGIN
    UPDATE accounts
    SET balance = balance + p_amount
    WHERE acc_id = p_acc_id;

    DBMS_OUTPUT.PUT_LINE('Deposit successful');
END;
/

BEGIN
    deposit_money(1001, 2000);
END;
/

CREATE OR REPLACE PROCEDURE withdraw_money (
    p_acc_id NUMBER,
    p_amount NUMBER
) IS
    v_balance NUMBER;
BEGIN
    SELECT balance INTO v_balance
    FROM accounts
    WHERE acc_id = p_acc_id;

    IF v_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20001, 'Insufficient balance');
    END IF;

    UPDATE accounts
    SET balance = balance - p_amount
    WHERE acc_id = p_acc_id;

    DBMS_OUTPUT.PUT_LINE('Withdrawal successful');
END;
/

BEGIN
    withdraw_money(1001, 1000);
END;
/

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

SELECT * FROM transactions;



