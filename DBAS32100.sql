DROP TABLE address;

DROP TABLE donation;
DROP TABLE volunteer;
DROP SEQUENCE donation_id;

/*1. Address Table
This is an address lookup table. It has a list of all the known addresses */
CREATE TABLE address(
    address_id          NUMBER PRIMARY KEY
    ,unit_num           VARCHAR2(6)
    ,street_number      NUMBER NOT NULL
    ,street_name        VARCHAR2(24)NOT NULL
    ,street_type        VARCHAR2(12)NOT NULL
    ,street_direction   CHAR(1)
    ,postal_code        CHAR(7)
    ,city               VARCHAR2(16)NOT NULL
    ,province           CHAR(2)NOT NULL
    ,CONSTRAINT st_dir CHECK(street_direction IN('E' ,'W' ,'N' ,'S'))
);

/*2.	Volunteer Table
This table has information on the volunteers */
CREATE TABLE volunteer(
    volunteer_id    NUMBER PRIMARY KEY
    ,first_name     VARCHAR2(16)
    ,last_name      VARCHAR2(16)
    ,group_leader
    ,CONSTRAINT fk_vol_lead FOREIGN KEY(group_leader)
        REFERENCES volunteer(volunteer_id)
);


/* 3. Donation table
Every row in this table is a donation made by a donor. Below is the script that creates donation table */
CREATE TABLE donation (
    don_id              NUMBER PRIMARY KEY
    ,donor_first_name   VARCHAR2(16)
    ,donor_last_name    VARCHAR2(16)
    ,donation_date      DATE NOT NULL
    ,donation_amount    NUMBER(7,1)NOT NULL
    ,type_of_donation   VARCHAR2(12)
    ,address_id NOT NULL
    ,volunteer_id NOT NULL
    ,CONSTRAINT fk_don_add FOREIGN KEY(address_id)
        REFERENCES address(address_id)
    ,CONSTRAINT fk_don_vol FOREIGN KEY(volunteer_id)
        REFERENCES volunteer(volunteer_id)
);


/*4 Insert data in volunteer table */
INSERT INTO volunteer
VALUES (100, 'Alexander', 'Hunold', null);

INSERT INTO volunteer
VALUES (141, 'Bruce', 'Ernst', 100);

INSERT INTO volunteer
VALUES (142, 'David', 'Hunold', 100);

INSERT INTO volunteer
VALUES (143, 'Valli', 'Pataballa', 100);

INSERT INTO volunteer
VALUES (144, 'Alexander', 'Hunold', 100);

INSERT INTO volunteer
VALUES (145, 'Alexander', 'Hunold', 100);

INSERT INTO volunteer
VALUES (146, 'Diana', 'Lorentz', 100);

INSERT INTO volunteer
VALUES (147, 'Daniel', 'Daniel', 100);

INSERT INTO volunteer
VALUES (148, 'Shanta', 'Vollman', 100);

INSERT INTO volunteer
VALUES (149, 'Julia', 'Nayer', 100);

INSERT INTO volunteer
VALUES (200, 'Ismael', 'Sciarra', null);

INSERT INTO volunteer
VALUES (241, 'Jose Manuel', 'Hurman', 200);

INSERT INTO volunteer
VALUES (242, 'Luis', ' Popp', 200);

INSERT INTO volunteer
VALUES (243, 'Alexander', 'Khoo', 200);

INSERT INTO volunteer
VALUES (244, 'Shelli', 'Baida', 200);

INSERT INTO volunteer
VALUES (245, 'Sigal', 'Tobias', 200);

INSERT INTO volunteer
VALUES (246, 'Guy', 'Himuro', 200);

INSERT INTO volunteer
VALUES (247, 'Karen', 'Colmenares', 200);

INSERT INTO volunteer
VALUES (248, 'Matthew', 'Weiss', 200);

INSERT INTO volunteer
VALUES (249, 'Payam', 'Kaufling', 200);

CREATE SEQUENCE donation_id
nocache;

COMMIT;


/*Task 3*/

DROP TABLE dim_volunteer;
DROP TABLE dim_address;
DROP TABLE dim_donation_day;
DROP TABLE fact_donation;
DROP SEQUENCE dim_address_id;
DROP SEQUENCE dim_day_id;
DROP SEQUENCE dim_volunteer_id;

CREATE SEQUENCE dim_volunteer_id;

CREATE TABLE dim_volunteer(
    v_id            NUMBER,
    volunteer_id    NUMBER PRIMARY KEY,
    first_name     VARCHAR2(16),
    last_name      VARCHAR2(16),
    group_leader,
    CONSTRAINT fk_dim_vol_lead FOREIGN KEY(group_leader)
        REFERENCES dim_volunteer(volunteer_id)
);


CREATE SEQUENCE dim_address_id;

CREATE TABLE dim_address (
    a_id                NUMBER
    ,address_id         NUMBER 
    ,street_number      NUMBER NOT NULL
    ,street_name        VARCHAR2(24)NOT NULL
    ,street_type        VARCHAR2(12)NOT NULL
    ,street_direction   CHAR(1)
    ,city               VARCHAR2(16)NOT NULL
    ,province           CHAR(2)NOT NULL
    ,CONSTRAINT dim_st_dir CHECK(street_direction IN('E' ,'W' ,'N' ,'S'))
);

CREATE SEQUENCE dim_day_id;

CREATE TABLE dim_donation_day (
    day_id              NUMBER
    ,donation_day        NUMBER
    ,donation_month      NUMBER
    ,donation_year       NUMBER
);

CREATE TABLE fact_donation(
    v_id NUMBER,
    a_id NUMBER,
    day_id NUMBER,
    donation_amount NUMBER(7,1)
);



/*TASK 4*/
INSERT INTO dim_volunteer
    SELECT dim_volunteer_id.NEXTVAL, volunteer_id, first_name, last_name, group_leader
    FROM volunteer;
        
INSERT INTO dim_address 
    SELECT dim_address_id.NEXTVAL, address_id, street_number, street_name, street_type, street_direction, city, province
    FROM address;

INSERT INTO dim_donation_day
    SELECT 
        dim_day_id.NEXTVAL, 
        donation_day,
        donation_month,
        donation_year
    FROM
        (
            SELECT DISTINCT 
                EXTRACT (DAY FROM donation_date) AS donation_day,
                EXTRACT (MONTH FROM donation_date) AS donation_month,
                EXTRACT (YEAR FROM donation_date) AS donation_year
            FROM 
                donation
        );

INSERT INTO fact_donation
    SELECT
          v_id,
          a_id,
          day_id,
          donation_amount
    FROM
        donation d
        JOIN dim_address a 
            ON a.address_id = d.address_id
        JOIN dim_volunteer v
            ON v.volunteer_id = d.volunteer_id
        JOIN dim_donation_day dd
            ON dd.donation_day = EXTRACT(DAY FROM d.donation_date);
        
COMMIT;


/*Task 5*/
CREATE OR REPLACE VIEW DONATIONS_BY_DATE AS
    SELECT 
        donation_year,
        donation_month,
        donation_day,
        SUM(donation_amount) AS "Total Donations", 
        ROUND(AVG(donation_amount),2) AS "Average Donation"
        FROM dim_donation_day d
        JOIN fact_donation f
            ON d.day_id = f.day_id
        GROUP BY ROLLUP(donation_year,donation_month,donation_day)
        ORDER BY 1,2;


CREATE OR REPLACE VIEW DONATIONS_BY_ADDRESS AS
    SELECT a.address_id, 
        SUM(donation_amount) AS "Total Donation", 
        ROUND(AVG(donation_amount),2) AS "Average Donation"
    FROM dim_address a
    JOIN fact_donation d
        ON a.a_id = d.a_id
    GROUP BY a.address_id
    ORDER BY 1;



CREATE OR REPLACE VIEW DONATIONS_BY_VOLUNTEER AS
    SELECT 
        v.group_leader,
        v.volunteer_id,
        SUM(donation_amount) AS "Total Donation",
        ROUND(AVG(donation_amount),2) AS "Average Donation"
    FROM dim_volunteer v
    JOIN fact_donation d
        ON v.v_id = d.v_id
    GROUP BY ROLLUP (v.group_leader,v.volunteer_id)
    ORDER BY 1;

COMMIT;

/*Task 6*/
CREATE USER DMLUser
IDENTIFIED BY pass;

GRANT SELECT, UPDATE, INSERT, DELETE ON address TO DMLUser;
GRANT SELECT, UPDATE, INSERT, DELETE ON volunteer TO DMLUser;
GRANT SELECT, UPDATE, INSERT, DELETE ON donation TO DMLUser;

CREATE USER Dashboard
IDENTIFIED BY pass;
GRANT SELECT ON donations_by_address TO Dashboard;
GRANT SELECT ON donations_by_date TO Dashboard;
GRANT SELECT ON donations_by_volunteer TO Dashboard;


COMMIT;

