CREATE OR REPLACE PACKAGE DOMIK.tasks
AS
    TYPE curs IS REF CURSOR;

    PROCEDURE task1;

    PROCEDURE CUSTOMERS (p_name IN VARCHAR2);
    
    procedure spisanie_so_scheta (p_xml in CLOB);
END tasks;
/


CREATE OR REPLACE PACKAGE BODY DOMIK.tasks
AS
    PROCEDURE task1
    IS
    BEGIN
        -- Собираем пропущенные числа
        FOR rec
            IN (SELECT num, LEAD (num) OVER (ORDER BY num) AS num_lead
                  FROM numbers)
        LOOP
            IF rec.num_lead IS NOT NULL
            THEN
                FOR i IN rec.num + 1 .. rec.num_lead - 1
                LOOP
                    INSERT INTO rec_task1
                         VALUES (i);
                END LOOP;
            END IF;
        END LOOP;
    END task1;

    PROCEDURE CUSTOMERS (p_name IN VARCHAR2)
    IS
        V_BONUS   NUMBER;
    BEGIN
        FOR rec
            IN (  SELECT c.CustomerID, c.Name, SUM (o.Amount) AS summa
                    FROM Customers c
                         LEFT JOIN Orders o ON c.CustomerID = o.CustomerID
                   WHERE c.NAME = p_name
                GROUP BY c.CustomerID, c.Name)
        LOOP
            IF REC.SUMMA IS NULL
            THEN
                DBMS_OUTPUT.PUT_LINE (
                       RPAD ('Клиент ' || rec.Name, 30)
                    || 'не сделал заказов. Бонус 0.');
            ELSIF REC.SUMMA BETWEEN 0 AND 499
            THEN
                V_BONUS := 0;
            ELSIF REC.SUMMA BETWEEN 500 AND 999
            THEN
                V_BONUS := 50;
            ELSIF REC.SUMMA BETWEEN 1000 AND 1999
            THEN
                V_BONUS := 100;
            ELSIF REC.SUMMA >= 2000
            THEN
                V_BONUS := 200;
            END IF;

            IF REC.SUMMA IS NOT NULL
            THEN
                DBMS_OUTPUT.PUT_LINE (
                       RPAD ('Клиент ' || rec.Name, 30)
                    || 'Сумма заказов '
                    || LPAD (TO_CHAR (rec.summa, '9990.00'), 8)
                    || ', начисленный бонус '
                    || LPAD (V_BONUS, 8));
            END IF;
        END LOOP;
    END;

/* Formatted on 06/01/2026 11:47:06 (QP5 v5.423) */
PROCEDURE spisanie_so_scheta (p_xml IN CLOB)
IS
    v_client_sum clients.total_funds%TYPE;
    --v_total_funds   clients.total_funds%TYPE;
BEGIN
    FOR rec
        IN (SELECT client_id, client_sum
              FROM XMLTABLE (
                       '/ClientList/Client'
                       PASSING XMLType (p_xml)
                       COLUMNS client_id    NUMBER PATH 'id',
                               client_sum    varchar(50) PATH 'sum'))
    LOOP
        begin
        --select total_funds into v_total_funds from clients where clients.id = rec.client_id;
        --IF v_total_funds >= rec.client_sum then
        v_client_sum := TO_NUMBER(rec.client_sum);
        UPDATE clients s
           SET s.total_funds = s.total_funds - rec.client_sum
         WHERE s.ID = rec.client_id AND s.TOTAL_FUNDS >= rec.client_sum;

        IF SQL%ROWCOUNT = 1
        THEN
            INSERT INTO transactions
                 VALUES (seq_transaction.NEXTVAL,
                         rec.client_id,
                         rec.client_sum,
                         SYSTIMESTAMP);

            DBMS_OUTPUT.put_line (
                   'Списание произошло успешно: '
                || rec.client_id
                || ' sum: '
                || rec.client_sum);
        ELSE
            DBMS_OUTPUT.put_line (
                   'Недостаточно средств на счете: '
                || rec.client_id
                || ' sum: '
                || rec.client_sum);
        END IF;
        EXCEPTION 
            WHEN VALUE_ERROR THEN
                DBMS_OUTPUT.put_line (
                   'ERROR: '
                || rec.client_id
                || ' sum: '
                || rec.client_sum);
        end;
    END LOOP;
    COMMIT;
    
    
END;
END tasks;
/
