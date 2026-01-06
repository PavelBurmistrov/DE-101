CREATE OR REPLACE PROCEDURE DOMIK.apply_bonus (p_min_balance     NUMBER, -- минимальный баланс для участия
                                         p_bonus_percent   NUMBER -- процент бонуса (например 5 = 5%)
                                                                 )
IS
    CURSOR curs IS
        SELECT c.ID, c.TOTAL_FUNDS
          FROM clients c
         WHERE c.TOTAL_FUNDS >= p_min_balance;

    v_client_id CLIENTS.ID%TYPE;
    v_total_funds  CLIENTS.TOTAL_FUNDS%TYPE; 
    v_bonus number;
    v_count number := 0;
BEGIN
    OPEN curs;

    LOOP
    BEGIN
        FETCH curs INTO v_client_id, v_total_funds;

        EXIT WHEN curs%NOTFOUND;
        
        v_bonus := v_total_funds * p_bonus_percent / 100;
        IF v_bonus >= 1 
            then
                update CLIENTS c 
                    set c.total_funds = c.total_funds + v_bonus
                    where c.id = v_client_id;
                 IF SQL%ROWCOUNT = 1
                    THEN
                        INSERT INTO transactions
                            VALUES (seq_transaction.NEXTVAL,
                                    v_client_id,
                                    v_bonus,
                                    SYSTIMESTAMP);
                end if;
                v_count := v_count + 1;
        end if;
        EXCEPTION
            WHEN VALUE_ERROR THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка значения: ' || SQLERRM || ' ' || SQLCODE);
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Нет данных: ' || SQLERRM || ' ' || SQLCODE);
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Другое исключение: ' || SQLERRM || ' ' || SQLCODE);
        
    END;              
    END LOOP;
    commit;
    DBMS_OUTPUT.PUT_LINE('Количество успешных начислений: ' || V_COUNT);
END;
/
