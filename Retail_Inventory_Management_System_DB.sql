-- PRODUCT table
CREATE TABLE Product (
    product_id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    price NUMBER(10,2) NOT NULL,
    quantity_in_stock NUMBER DEFAULT 0
);

-- SUPPLIER table
CREATE TABLE Supplier (
    supplier_id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    contact_info VARCHAR2(150)
);

-- LOCATION table
CREATE TABLE Location (
    location_id NUMBER PRIMARY KEY,
    location_name VARCHAR2(100)
);

-- INVENTORY table
CREATE TABLE Inventory (
    product_id NUMBER,
    location_id NUMBER,
    stock_level NUMBER DEFAULT 0,
    PRIMARY KEY (product_id, location_id),
    FOREIGN KEY (product_id) REFERENCES Product(product_id),
    FOREIGN KEY (location_id) REFERENCES Location(location_id)
);

-- SALE table
CREATE TABLE Sale (
    sale_id NUMBER PRIMARY KEY,
    sale_date DATE DEFAULT SYSDATE,
    product_id NUMBER,
    quantity_sold NUMBER,
    total_amount NUMBER(10,2),
    FOREIGN KEY (product_id) REFERENCES Product(product_id)
);

-- Insert into Supplier
INSERT INTO Supplier VALUES (1, 'Global Tech Supplies', 'info@globaltech.com');
INSERT INTO Supplier VALUES (2, 'QuickStock Ltd.', 'support@quickstock.com');

-- Insert into Product
INSERT INTO Product VALUES (101, 'Wireless Mouse', 25.99, 150);
INSERT INTO Product VALUES (102, 'USB Keyboard', 45.00, 90);
INSERT INTO Product VALUES (103, 'HDMI Cable', 12.50, 200);

-- Insert into Location
INSERT INTO Location VALUES (1, 'Main Store - Kigali');
INSERT INTO Location VALUES (2, 'Warehouse - Nyamirambo');

-- Insert into Inventory
INSERT INTO Inventory VALUES (101, 1, 80);
INSERT INTO Inventory VALUES (101, 2, 70);
INSERT INTO Inventory VALUES (102, 1, 50);
INSERT INTO Inventory VALUES (103, 2, 200);

-- Insert into Sale
INSERT INTO Sale VALUES (1001, TO_DATE('2025-05-15', 'YYYY-MM-DD'), 101, 3, 77.97);
INSERT INTO Sale VALUES (1002, TO_DATE('2025-05-16', 'YYYY-MM-DD'), 102, 2, 90.00);


CREATE OR REPLACE PROCEDURE record_sale (
    p_sale_id        IN NUMBER,
    p_product_id     IN NUMBER,
    p_quantity       IN NUMBER
) AS
    v_price          NUMBER;
    v_total_amount   NUMBER;
    v_stock_level    NUMBER;
BEGIN
    -- Get product price and check stock
    SELECT price, quantity_in_stock INTO v_price, v_stock_level
    FROM Product
    WHERE product_id = p_product_id;

    IF v_stock_level < p_quantity THEN
        RAISE_APPLICATION_ERROR(-20001, 'Not enough stock.');
    END IF;

    -- Calculate total
    v_total_amount := v_price * p_quantity;

    -- Insert into Sale
    INSERT INTO Sale (sale_id, sale_date, product_id, quantity_sold, total_amount)
    VALUES (p_sale_id, SYSDATE, p_product_id, p_quantity, v_total_amount);

    -- Update stock
    UPDATE Product
    SET quantity_in_stock = quantity_in_stock - p_quantity
    WHERE product_id = p_product_id;

    DBMS_OUTPUT.PUT_LINE('Sale recorded successfully.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;








DECLARE
    CURSOR product_cursor IS
        SELECT product_id, name, quantity_in_stock
        FROM Product;

    v_pid Product.product_id%TYPE;
    v_name Product.name%TYPE;
    v_qty Product.quantity_in_stock%TYPE;
BEGIN
    OPEN product_cursor;
    LOOP
        FETCH product_cursor INTO v_pid, v_name, v_qty;
        EXIT WHEN product_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(v_name || ' (ID: ' || v_pid || ') has ' || v_qty || ' items in stock.');
    END LOOP;
    CLOSE product_cursor;
END;








CREATE OR REPLACE PACKAGE sale_pkg AS
    PROCEDURE record_sale(p_sale_id IN NUMBER, p_product_id IN NUMBER, p_quantity IN NUMBER);
END;
/

CREATE OR REPLACE PACKAGE BODY sale_pkg AS
    PROCEDURE record_sale(p_sale_id IN NUMBER, p_product_id IN NUMBER, p_quantity IN NUMBER) IS
        v_price NUMBER;
        v_total NUMBER;
        v_stock NUMBER;
    BEGIN
        SELECT price, quantity_in_stock INTO v_price, v_stock
        FROM Product WHERE product_id = p_product_id;

        IF v_stock < p_quantity THEN
            RAISE_APPLICATION_ERROR(-20001, 'Insufficient stock.');
        END IF;

        v_total := v_price * p_quantity;

        INSERT INTO Sale VALUES (p_sale_id, SYSDATE, p_product_id, p_quantity, v_total);

        UPDATE Product
        SET quantity_in_stock = quantity_in_stock - p_quantity
        WHERE product_id = p_product_id;
    END;
END;










CREATE TABLE Holiday (
  holiday_date DATE PRIMARY KEY,
  name VARCHAR2(100)
);

INSERT INTO Holiday VALUES (TO_DATE('2025-01-01', 'YYYY-MM-DD'), 'New Year’s Day');
INSERT INTO Holiday VALUES (TO_DATE('2025-02-01', 'YYYY-MM-DD'), 'National Heroes Day');
INSERT INTO Holiday VALUES (TO_DATE('2025-04-07', 'YYYY-MM-DD'), 'Genocide Against the Tutsi Memorial Day');
INSERT INTO Holiday VALUES (TO_DATE('2025-04-18', 'YYYY-MM-DD'), 'Good Friday');
INSERT INTO Holiday VALUES (TO_DATE('2025-05-01', 'YYYY-MM-DD'), 'Labour Day');
INSERT INTO Holiday VALUES (TO_DATE('2025-07-01', 'YYYY-MM-DD'), 'Independence Day');
INSERT INTO Holiday VALUES (TO_DATE('2025-07-04', 'YYYY-MM-DD'), 'Liberation Day');
INSERT INTO Holiday VALUES (TO_DATE('2025-08-15', 'YYYY-MM-DD'), 'Assumption Day');
INSERT INTO Holiday VALUES (TO_DATE('2025-12-25', 'YYYY-MM-DD'), 'Christmas Day');
INSERT INTO Holiday VALUES (TO_DATE('2025-12-26', 'YYYY-MM-DD'), 'Boxing Day');






CREATE TABLE Audit_Log (
    audit_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_name VARCHAR2(50),
    operation VARCHAR2(20),
    table_name VARCHAR2(50),
    action_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    status VARCHAR2(10)
);




CREATE OR REPLACE TRIGGER trg_block_edits
BEFORE INSERT OR UPDATE OR DELETE ON Product
DECLARE
    v_day VARCHAR2(10);
    v_today DATE := TRUNC(SYSDATE);
    v_holiday_count NUMBER;
BEGIN
    -- Check for weekday
    v_day := TO_CHAR(v_today, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH');

    -- Check if today is a holiday
    SELECT COUNT(*) INTO v_holiday_count
    FROM Holiday
    WHERE holiday_date = v_today;

    IF v_day IN ('MON', 'TUE', 'WED', 'THU', 'FRI') OR v_holiday_count > 0 THEN
        -- Audit the blocked action
        INSERT INTO Audit_Log (user_name, operation, table_name, status)
        VALUES (USER, 'BLOCKED_OP', 'PRODUCT', 'DENIED');
        COMMIT;
        RAISE_APPLICATION_ERROR(-20002, 'Edits are blocked on weekdays and public holidays.');
    END IF;
END;









CREATE OR REPLACE PACKAGE audit_pkg AS
    PROCEDURE log_success(op VARCHAR2, tbl VARCHAR2);
    PROCEDURE log_failure(op VARCHAR2, tbl VARCHAR2);
END;
/

CREATE OR REPLACE PACKAGE BODY audit_pkg AS
    PROCEDURE log_success(op VARCHAR2, tbl VARCHAR2) IS
    BEGIN
        INSERT INTO Audit_Log (user_name, operation, table_name, status)
        VALUES (USER, op, tbl, 'ALLOWED');
        COMMIT;
    END;

    PROCEDURE log_failure(op VARCHAR2, tbl VARCHAR2) IS
    BEGIN
        INSERT INTO Audit_Log (user_name, operation, table_name, status)
        VALUES (USER, op, tbl, 'DENIED');
        COMMIT;
    END;
END;
/




SELECT * FROM Audit_Log ORDER BY audit_id DESC;


INSERT INTO Product VALUES (101, 'toyota', 25.99, 150);

ALTER TABLE AUDIT_LOG MODIFY USER_NAME VARCHAR2(60);

INSERT INTO Product VALUES (101, 'toyota', 25.99, 150);















CREATE OR REPLACE FUNCTION get_discount_price(
    p_product_id IN NUMBER
) RETURN NUMBER IS
    v_price NUMBER;
    v_discount NUMBER := 0.10; -- 10% discount
BEGIN
    SELECT price INTO v_price FROM Product WHERE product_id = p_product_id;
    RETURN v_price * (1 - v_discount);
END;











SELECT product_id, product_name, get_discount_price(product_id) AS discounted_price
FROM Product;



SELECT 
    product_id,
    product_name,
    SUM(quantity_sold) AS total_sold,
    RANK() OVER (ORDER BY SUM(quantity_sold) DESC) AS rank
FROM Sales
GROUP BY product_id, product_name;





CREATE OR REPLACE TRIGGER trg_block_edits
BEFORE INSERT OR UPDATE OR DELETE ON Product
DECLARE
    v_day VARCHAR2(10);
    v_today DATE := TRUNC(SYSDATE);
    v_holiday_count NUMBER;
BEGIN
    -- Get current day (MON, TUE, etc.)
    v_day := TO_CHAR(v_today, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH');

    -- Check if today is a holiday
    SELECT COUNT(*) INTO v_holiday_count
    FROM Holiday
    WHERE holiday_date = v_today;

    -- BLOCK if weekday or public holiday
    IF v_day IN ('MON', 'TUE', 'WED', 'THU', 'FRI') OR v_holiday_count > 0 THEN
        -- Log to audit first
        INSERT INTO Audit_Log (user_name, operation, table_name, status)
        VALUES (USER, 'BLOCKED_OP', 'PRODUCT', 'DENIED');
        COMMIT;

        -- THEN raise error
        RAISE_APPLICATION_ERROR(-20002, 'Edits are blocked on weekdays and public holidays.');
    END IF;
END;
/







SELECT TO_CHAR(SYSDATE, 'DY'), TO_CHAR(SYSDATE, 'YYYY-MM-DD') FROM dual;
SELECT * FROM Holiday WHERE holiday_date = TRUNC(SYSDATE);




UPDATE Product SET price = price + 1 WHERE product_id = 101;

SELECT * FROM Audit_Log ORDER BY audit_id DESC;



SELECT trigger_name, table_name, status 
FROM user_triggers 
WHERE table_name = 'PRODUCT';



BEGIN
  INSERT INTO Audit_Log (user_name, operation, table_name, status)
  VALUES (USER, 'TEST_INSERT', 'PRODUCT', 'DENIED');
  COMMIT;
END;
/

SELECT * FROM Audit_Log;






DECLARE
    v_day VARCHAR2(10);
    v_today DATE := TRUNC(SYSDATE);
    v_holiday_count NUMBER;
BEGIN
    v_day := TO_CHAR(v_today, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH');

    SELECT COUNT(*) INTO v_holiday_count
    FROM Holiday
    WHERE holiday_date = v_today;

    DBMS_OUTPUT.PUT_LINE('DAY = ' || v_day);
    DBMS_OUTPUT.PUT_LINE('HOLIDAYS FOUND = ' || v_holiday_count);

    IF v_day IN ('MON', 'TUE', 'WED', 'THU', 'FRI') OR v_holiday_count > 0 THEN
        INSERT INTO Audit_Log (user_name, operation, table_name, status)
        VALUES (USER, 'BLOCKED_OP', 'PRODUCT', 'DENIED');
        COMMIT;
        RAISE_APPLICATION_ERROR(-20002, 'Edits are blocked.');
    END IF;
END;
/






CREATE OR REPLACE FUNCTION get_total_sales(p_product_id NUMBER)
RETURN NUMBER IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(total_amount), 0)
    INTO v_total
    FROM Sale
    WHERE product_id = p_product_id;

    RETURN v_total;
END;
/







SELECT 
    product_id,
    SUM(quantity_sold) AS total_qty,
    RANK() OVER (ORDER BY SUM(quantity_sold) DESC) AS sales_rank
FROM Sale
GROUP BY product_id;

