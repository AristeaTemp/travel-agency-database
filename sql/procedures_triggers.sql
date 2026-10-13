-- Stored procedures and triggers for the travel_agency database.
-- Run AFTER schema_and_data.sql:  mysql -u root -p < sql/schema_and_data.sql ; mysql -u root -p travel_agency < sql/procedures_triggers.sql
-- (These are corrected versions of the originals written for the course report.)

USE travel_agency;

-- ---------------------------------------------------------------- PROCEDURES

DELIMITER $$

-- 1. Hire a new driver and assign them to the branch that currently has the fewest drivers.
DROP PROCEDURE IF EXISTS addNewDriver$$
CREATE PROCEDURE addNewDriver(
    IN drvAT CHAR(10), IN drName VARCHAR(20), IN lastName VARCHAR(20),
    IN salary FLOAT(7,2), IN license ENUM('A','B','C','D'),
    IN route ENUM('LOCAL','ABROAD'), IN experience TINYINT)
BEGIN
    DECLARE branchID INT;

    SELECT b.br_code INTO branchID
    FROM branch b
    ORDER BY (SELECT COUNT(*) FROM driver d
              JOIN worker w ON w.wrk_AT = d.drv_AT
              WHERE w.wrk_br_code = b.br_code) ASC
    LIMIT 1;

    INSERT INTO worker (wrk_AT, wrk_name, wrk_lname, wrk_salary, wrk_br_code)
    VALUES (drvAT, drName, lastName, salary, branchID);

    INSERT INTO driver (drv_AT, drv_license, drv_route, drv_experience)
    VALUES (drvAT, license, route, experience);
END$$

-- 2. Find the trips of a branch that depart within a given period.
DROP PROCEDURE IF EXISTS FindingTrip$$
CREATE PROCEDURE FindingTrip(IN branchcode INT, IN start_date DATETIME, IN end_date DATETIME)
BEGIN
    SELECT t.tr_id, t.tr_cost, t.tr_maxseats, t.tr_gui_AT AS guide, t.tr_drv_AT AS driver,
           t.tr_departure, t.tr_return,
           t.tr_maxseats - COUNT(r.res_tr_id) AS free_seats
    FROM trip t
    LEFT JOIN reservation r ON r.res_tr_id = t.tr_id
    WHERE t.tr_br_code = branchcode
      AND t.tr_departure BETWEEN start_date AND end_date
    GROUP BY t.tr_id;
END$$

-- 3. Delete a worker, unless they are an administrative employee.
DROP PROCEDURE IF EXISTS delete_worker$$
CREATE PROCEDURE delete_worker(IN p_name VARCHAR(20), IN p_lname VARCHAR(20))
BEGIN
    DECLARE v_at CHAR(10);
    DECLARE v_type VARCHAR(20) DEFAULT NULL;

    SELECT wrk_AT INTO v_at FROM worker
    WHERE wrk_name = p_name AND wrk_lname = p_lname LIMIT 1;

    SELECT adm_type INTO v_type FROM admin WHERE adm_AT = v_at;

    IF v_at IS NULL THEN
        SELECT 'Worker not found' AS message;
    ELSEIF v_type = 'ADMINISTRATIVE' THEN
        SELECT 'Cannot delete administrative worker' AS message;
    ELSE
        DELETE FROM worker WHERE wrk_AT = v_at;
        SELECT 'Worker deleted' AS message;
    END IF;
END$$

-- 4a. Customers whose advance payment is within [minimum, maximum].
DROP PROCEDURE IF EXISTS PrePayment$$
CREATE PROCEDURE PrePayment(IN minimum INT, IN maximum INT)
BEGIN
    SELECT ro.reservation_name, ro.reservation_lname, ro.advance, o.offers_id
    FROM reservation_offers ro
    JOIN offers o ON ro.res_offers_id = o.offers_id
    WHERE ro.advance BETWEEN minimum AND maximum;
END$$

-- 4b. Number of reservations per offer for customers with a given last name.
DROP PROCEDURE IF EXISTS CustomerReservations$$
CREATE PROCEDURE CustomerReservations(IN customer_lname VARCHAR(20))
BEGIN
    SELECT ro.reservation_name, ro.reservation_lname, ro.res_offers_id AS offer,
           COUNT(*) AS reservations
    FROM reservation_offers ro
    JOIN offers o ON o.offers_id = ro.res_offers_id
    WHERE ro.reservation_lname = customer_lname
    GROUP BY ro.reservation_name, ro.reservation_lname, ro.res_offers_id;
END$$

DELIMITER ;

-- ------------------------------------------------------------------ TRIGGERS
-- Audit log: every INSERT / UPDATE / DELETE on the tables below is recorded in IT_log.
-- The acting IT user is taken from the session variable @it_user (default: 'W456').

DELIMITER $$

DROP TRIGGER IF EXISTS trip_insert_log$$
CREATE TRIGGER trip_insert_log AFTER INSERT ON trip
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('INSERT', 'trip', COALESCE(@it_user, 'W456'));
END$$

DROP TRIGGER IF EXISTS trip_update_log$$
CREATE TRIGGER trip_update_log AFTER UPDATE ON trip
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('UPDATE', 'trip', COALESCE(@it_user, 'W456'));
END$$

DROP TRIGGER IF EXISTS trip_delete_log$$
CREATE TRIGGER trip_delete_log AFTER DELETE ON trip
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('DELETE', 'trip', COALESCE(@it_user, 'W456'));
END$$

DROP TRIGGER IF EXISTS reservation_insert_log$$
CREATE TRIGGER reservation_insert_log AFTER INSERT ON reservation
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('INSERT', 'reservation', COALESCE(@it_user, 'W456'));
END$$

DROP TRIGGER IF EXISTS reservation_update_log$$
CREATE TRIGGER reservation_update_log AFTER UPDATE ON reservation
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('UPDATE', 'reservation', COALESCE(@it_user, 'W456'));
END$$

DROP TRIGGER IF EXISTS reservation_delete_log$$
CREATE TRIGGER reservation_delete_log AFTER DELETE ON reservation
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('DELETE', 'reservation', COALESCE(@it_user, 'W456'));
END$$

DROP TRIGGER IF EXISTS event_insert_log$$
CREATE TRIGGER event_insert_log AFTER INSERT ON event
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('INSERT', 'event', COALESCE(@it_user, 'W456'));
END$$

DROP TRIGGER IF EXISTS event_update_log$$
CREATE TRIGGER event_update_log AFTER UPDATE ON event
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('UPDATE', 'event', COALESCE(@it_user, 'W456'));
END$$

DROP TRIGGER IF EXISTS event_delete_log$$
CREATE TRIGGER event_delete_log AFTER DELETE ON event
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('DELETE', 'event', COALESCE(@it_user, 'W456'));
END$$

DROP TRIGGER IF EXISTS travel_to_insert_log$$
CREATE TRIGGER travel_to_insert_log AFTER INSERT ON travel_to
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('INSERT', 'travel_to', COALESCE(@it_user, 'W456'));
END$$

DROP TRIGGER IF EXISTS travel_to_update_log$$
CREATE TRIGGER travel_to_update_log AFTER UPDATE ON travel_to
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('UPDATE', 'travel_to', COALESCE(@it_user, 'W456'));
END$$

DROP TRIGGER IF EXISTS travel_to_delete_log$$
CREATE TRIGGER travel_to_delete_log AFTER DELETE ON travel_to
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('DELETE', 'travel_to', COALESCE(@it_user, 'W456'));
END$$

DROP TRIGGER IF EXISTS destination_insert_log$$
CREATE TRIGGER destination_insert_log AFTER INSERT ON destination
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('INSERT', 'destination', COALESCE(@it_user, 'W456'));
END$$

DROP TRIGGER IF EXISTS destination_update_log$$
CREATE TRIGGER destination_update_log AFTER UPDATE ON destination
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('UPDATE', 'destination', COALESCE(@it_user, 'W456'));
END$$

DROP TRIGGER IF EXISTS destination_delete_log$$
CREATE TRIGGER destination_delete_log AFTER DELETE ON destination
FOR EACH ROW
BEGIN
    INSERT INTO IT_log (action, table_name, user) VALUES ('DELETE', 'destination', COALESCE(@it_user, 'W456'));
END$$


-- Business rule 1: once a trip has reservations, its dates and cost can no longer change.
DROP TRIGGER IF EXISTS prevent_trip_update$$
CREATE TRIGGER prevent_trip_update BEFORE UPDATE ON trip
FOR EACH ROW
BEGIN
    DECLARE reservation_count INT DEFAULT 0;
    SELECT COUNT(*) INTO reservation_count FROM reservation WHERE res_tr_id = OLD.tr_id;
    IF reservation_count > 0 THEN
        SET NEW.tr_departure = OLD.tr_departure,
            NEW.tr_return    = OLD.tr_return,
            NEW.tr_cost      = OLD.tr_cost;
    END IF;
END$$

-- Business rule 2: a worker's salary can never be reduced.
DROP TRIGGER IF EXISTS prevent_salary_reduction$$
CREATE TRIGGER prevent_salary_reduction BEFORE UPDATE ON worker
FOR EACH ROW
BEGIN
    IF NEW.wrk_salary < OLD.wrk_salary THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot reduce worker salary';
    END IF;
END$$

DELIMITER ;
