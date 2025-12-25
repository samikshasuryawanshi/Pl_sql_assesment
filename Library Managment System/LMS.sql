CREATE TABLE books (
    book_id NUMBER PRIMARY KEY,
    title VARCHAR2(100),
    author VARCHAR2(50),
    available CHAR(1)  -- Y / N
);
CREATE TABLE members (
    member_id NUMBER PRIMARY KEY,
    member_name VARCHAR2(50),
    phone VARCHAR2(15)
);
CREATE TABLE issue_return (
    issue_id NUMBER PRIMARY KEY,
    book_id NUMBER,
    member_id NUMBER,
    issue_date DATE,
    return_date DATE,
    fine NUMBER
);

CREATE SEQUENCE book_seq START WITH 1;
CREATE SEQUENCE member_seq START WITH 1;
CREATE SEQUENCE issue_seq START WITH 1;

INSERT INTO books VALUES (book_seq.NEXTVAL, 'DBMS', 'Korth', 'Y');
INSERT INTO books VALUES (book_seq.NEXTVAL, 'PLSQL Programming', 'Oracle', 'Y');
INSERT INTO books VALUES (book_seq.NEXTVAL, 'Operating Systems', 'Galvin', 'Y');
INSERT INTO books VALUES (book_seq.NEXTVAL, 'Computer Networks', 'Tanenbaum', 'Y');
INSERT INTO books VALUES (book_seq.NEXTVAL, 'Data Structures', 'Sahni', 'Y');
INSERT INTO books VALUES (book_seq.NEXTVAL, 'Java Programming', 'Herbert Schildt', 'Y');
INSERT INTO books VALUES (book_seq.NEXTVAL, 'Python Basics', 'Guido', 'Y');
INSERT INTO books VALUES (book_seq.NEXTVAL, 'Software Engineering', 'Pressman', 'Y');
INSERT INTO books VALUES (book_seq.NEXTVAL, 'Artificial Intelligence', 'Russell', 'Y');
INSERT INTO books VALUES (book_seq.NEXTVAL, 'Machine Learning', 'Tom Mitchell', 'Y');


INSERT INTO members VALUES (member_seq.NEXTVAL, 'Rishabh', '9876543210');
INSERT INTO members VALUES (member_seq.NEXTVAL, 'Samiksha', '9123456789');
INSERT INTO members VALUES (member_seq.NEXTVAL, 'Amit', '9988776655');
INSERT INTO members VALUES (member_seq.NEXTVAL, 'Neha', '9876501234');
INSERT INTO members VALUES (member_seq.NEXTVAL, 'Ravi', '9090909090');
INSERT INTO members VALUES (member_seq.NEXTVAL, 'Pooja', '9012345678');
INSERT INTO members VALUES (member_seq.NEXTVAL, 'Rahul', '9345678123');
INSERT INTO members VALUES (member_seq.NEXTVAL, 'Sneha', '9456123789');
INSERT INTO members VALUES (member_seq.NEXTVAL, 'Karan', '9567123489');
INSERT INTO members VALUES (member_seq.NEXTVAL, 'Anita', '9678234512');


INSERT INTO issue_return VALUES (issue_seq.NEXTVAL, 1, 1, SYSDATE-10, NULL, 0);
INSERT INTO issue_return VALUES (issue_seq.NEXTVAL, 2, 2, SYSDATE-5, SYSDATE-2, 0);
INSERT INTO issue_return VALUES (issue_seq.NEXTVAL, 3, 3, SYSDATE-15, NULL, 0);
INSERT INTO issue_return VALUES (issue_seq.NEXTVAL, 4, 4, SYSDATE-3, SYSDATE, 0);
INSERT INTO issue_return VALUES (issue_seq.NEXTVAL, 5, 5, SYSDATE-20, NULL, 0);
INSERT INTO issue_return VALUES (issue_seq.NEXTVAL, 6, 6, SYSDATE-8, SYSDATE-1, 0);
INSERT INTO issue_return VALUES (issue_seq.NEXTVAL, 7, 7, SYSDATE-12, NULL, 0);
INSERT INTO issue_return VALUES (issue_seq.NEXTVAL, 8, 8, SYSDATE-4, SYSDATE, 0);
INSERT INTO issue_return VALUES (issue_seq.NEXTVAL, 9, 9, SYSDATE-18, NULL, 0);
INSERT INTO issue_return VALUES (issue_seq.NEXTVAL, 10, 10, SYSDATE-6, SYSDATE, 0);


COMMIT;

CREATE OR REPLACE FUNCTION calc_fine(p_issue_date DATE)
RETURN NUMBER IS
    v_days NUMBER;
BEGIN
    v_days := SYSDATE - p_issue_date;

    IF v_days > 7 THEN
        RETURN (v_days - 7) * 5;
    ELSE
        RETURN 0;
    END IF;
END;
/


CREATE OR REPLACE PACKAGE library_pkg IS
    PROCEDURE issue_book(p_book_id NUMBER, p_member_id NUMBER);
    PROCEDURE return_book(p_issue_id NUMBER);
END library_pkg;
/


CREATE OR REPLACE PACKAGE BODY library_pkg IS

PROCEDURE issue_book(p_book_id NUMBER, p_member_id NUMBER) IS
    v_status CHAR(1);
BEGIN
    SELECT available INTO v_status
    FROM books
    WHERE book_id = p_book_id;

    IF v_status = 'N' THEN
        RAISE_APPLICATION_ERROR(-20001, 'Book not available');
    END IF;

    INSERT INTO issue_return
    VALUES (issue_seq.NEXTVAL, p_book_id, p_member_id, SYSDATE, NULL, 0);

    UPDATE books
    SET available = 'N'
    WHERE book_id = p_book_id;

    DBMS_OUTPUT.PUT_LINE('Book issued successfully');
END;

PROCEDURE return_book(p_issue_id NUMBER) IS
    v_book_id NUMBER;
    v_issue_date DATE;
    v_fine NUMBER;
BEGIN
    SELECT book_id, issue_date
    INTO v_book_id, v_issue_date
    FROM issue_return
    WHERE issue_id = p_issue_id;

    v_fine := calc_fine(v_issue_date);

    UPDATE issue_return
    SET return_date = SYSDATE,
        fine = v_fine
    WHERE issue_id = p_issue_id;

    UPDATE books
    SET available = 'Y'
    WHERE book_id = v_book_id;

    DBMS_OUTPUT.PUT_LINE('Book returned. Fine = ' || v_fine);
END;

END library_pkg;
/

CREATE OR REPLACE TRIGGER trg_auto_fine
BEFORE UPDATE OF return_date ON issue_return
FOR EACH ROW
BEGIN
    :NEW.fine := calc_fine(:OLD.issue_date);
END;
/

SET SERVEROUTPUT ON;

DECLARE
    CURSOR overdue_cur IS
        SELECT m.member_name, b.title, i.issue_date
        FROM issue_return i
        JOIN members m ON i.member_id = m.member_id
        JOIN books b ON i.book_id = b.book_id
        WHERE i.return_date IS NULL
          AND SYSDATE - i.issue_date > 7;
BEGIN
    FOR rec IN overdue_cur LOOP
        DBMS_OUTPUT.PUT_LINE(
            rec.member_name || ' - ' ||
            rec.title || ' - Issued on: ' ||
            rec.issue_date
        );
    END LOOP;
END;
/


BEGIN
    library_pkg.issue_book(1, 1);
END;
/

BEGIN
    library_pkg.return_book(1);
END;
/
