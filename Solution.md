# Solution to Project Requirements

## Task 1

### Question: Refresh the address table in the oracle database with the addresses in the master table. You will need to transform some data types and generate a sequential id for the address. Also note that the ids of some addresses will be used as foreign key in donation table your solution should accommodate this fact.
NOTE: For the below csv files results, not all the results are included in the screenshots in order to make this document more readable. Also the code snippets below are NOT screenshots, you can copy and paste the text.

### Solution to Task 1

![image](https://user-images.githubusercontent.com/47337941/72447738-dad72e00-3783-11ea-9b43-6409caf4a188.png)

Here a tDBInput component is used to extract the addresses from the SQLServer master table and is connected to a tMap component and an Oracle tDBOutput component. 

**tMap_1**
![image](https://user-images.githubusercontent.com/47337941/72447886-1a057f00-3784-11ea-9729-d1965d8fd09d.png)

In the tMap component, a numeric sequence is used for the ADDRESS_ID. Also the code in the expression filter:

```
  row1.STREET_TYPE != null && (row1.STREET_DIR.equals("N") || row1.STREET_DIR.equals("E")
  || row1.STREET_DIR.equals("S") || row1.STREET_DIR.equals("W"))
```

will make sure that only addresses that have a street direction and a street type will be entered into the oracle database address table.  This is because there is a unique constraint that requires the address table to have a value of N,E,S or W in the STREET_DIRECTION column of the oracle database.

CITY is also converted to uppercase when entered into the oracle database to make for easy comparisons in the future. 
`row1.PROVINCE.toLowerCase().matches("ontario|on") ? "ON" : "" `
PROVINCE is converted to lowercase and then checked to see if it matches either Ontario or ON. The default text is then set to ON or is left blank (which means it will be rejected in the future).


## Task 2

### Question: Create a process that loads the donations list to the central donations table: In this task you will load the file into the central repository (Oracle tables). You need to make sure that only the donations with valid addresses are inserted into the table. Donation records with erroneous addresses must be rejected. Also make sure to reject the donations that have nulls for the mandatory columns in your database (Not null columns). You must generate csv files to the volunteer group leaders with the records that were rejected in their area.

### Solution to Task 2

![image](https://user-images.githubusercontent.com/47337941/72448684-6c936b00-3785-11ea-8553-f1bfc476a466.png)

Here the donationslist.csv is connected to a tMap with 3 possible tFileOutputDelimited.csv output files. The first one cleansedDonations.csv will keep track of donation records with only ONE name in STREET_NAME. TwoWordDonationsCleansed.csv will keep track of donations with TWO street names.  RejectedDonations1.csv will store donations that do not fit the criteria of cleansedDonations.csv or TwoWordDonationsCleansed.csv.

**tMap_1**

![image](https://user-images.githubusercontent.com/47337941/72448756-8fbe1a80-3785-11ea-8473-6f7636dc1241.png)

**Expression filter for tMap1:**

```row1.Address.split(" ").length == 6 && row1.Address.split(" ")[2].toLowerCase().matches("blvd.|rd.|pky.|lane.|dr.|st.") && row1.Address.split(" ")[5].toLowerCase().matches("on|ontario") && row1.Address.split(" ")[4].toLowerCase().matches("oakville")```

Here the expression filter checks to see if the length is equal to 6. The reason for this is because a valid donation entry when split using a single space should have exactly a length of 6 if it only has one word for its STREET_NAME. Next using 
`SELECT UNIQUE(STREET_TYPE) FROM ADDRESS;`
in Sql Developer, we figured out that the only valid street types are: BLVD, RD, PKY, LANE, DR, and ST. Therefore, records without these street types are rejected. Next a match for the province and city are also used to make sure the correct information is in the correct columns. 

**tMap1 CleansedDonations.csv:**

![image](https://user-images.githubusercontent.com/47337941/72448994-f6dbcf00-3785-11ea-98c8-a9f0eca7cb53.png)

Next for STREET_DIR in tMap1 the following code was used to make sure the correct direction was entered in a record.
```
row1.Address.split(" ")[3].toLowerCase().matches("n.|e.|s.|w.|north|east|south|west") ? row1.Address.split(" ")[3].toUpperCase().charAt(0) + "" : ""   
```

charAt(0) is used here to get the first letter of the direction in upper case.
CITY and PROVINCE are replaced with “OAKVILLE” and “ON” for easy comparisons in the future (and they are already validated by the expression filter).
For the DonorName, if the length after splitting is greater than 1 then that means there is a last name which is added to the LastName column for cleansedDonations.csv.
`row1.DonorName.split(" ").length > 1 ? row1.DonorName.split(" ")[1] : ""`

Finally Talend’s build-in date parser is used to extract and output the date correct in cleansedDonations.csv.
`TalendDate.parseDate("MMM dd yyyyhh:mm a", row1.Date + row1.Time)`

**tMap1 twoWordStreetNameDonations.csv**
Here most of the code is the same as the cleansedDonations.csv file however, the expression filter checks to see if the length == 7 because a valid entry after splitting must be a length of 7 if there are two words used in the STREET_NAME.
```
row1.Address.split(" ").length == 7 && row1.Address.split(" ")[3].toLowerCase().matches("blvd.|rd.|pky.|lane.|dr.|st.")  && row1.Address.split(" ")[6].toLowerCase().matches("on|ontario") && row1.Address.split(" ")[5].toLowerCase().matches("oakville")
```

For the columns, only the indexes have changed.

![image](https://user-images.githubusercontent.com/47337941/72450548-8d10f480-3788-11ea-9d81-1c2c31270b95.png)


**tMap1 rejectedDonations1.csv**

Here the donationslist.csv records that have been rejected by the other two expression filters are stored. Because there are an extremely large number of ways incorrect information can be stored in the donationslist.csv, the address has not been split. 
![image](https://user-images.githubusercontent.com/47337941/72450714-d3feea00-3788-11ea-8a96-d56a93b4ba88.png)

**tMap2**

![image](https://user-images.githubusercontent.com/47337941/72450759-deb97f00-3788-11ea-84ae-a43952fe56fa.png)

tMap2 is used to validate the address in the cleansedDonations.csv by comparing it using the ADDRESS table as a lookup (tDBInput). 
![image](https://user-images.githubusercontent.com/47337941/72450785-eed15e80-3788-11ea-99cd-6fdbe42035b8.png)

Here the settings are set to unique match and inner join so that only the matching expression keys with the oracle ADDRESS table will be output into the oracle DONATION table.
```
//STREET_TYPE
row2.STREET_TYPE.indexOf(".") >= 0 ? row2.STREET_TYPE.replace(".", "").toUpperCase() : row2.STREET_TYPE
//STREET_DIR
row2.STREET_DIR.indexOf(".") >= 0 ? row2.STREET_DIR.replace(".", "").toUpperCase() : row2.STREET_DIR  
```
For the STREET_TYPE and STREET_DIR, the replace method is used to get rid of the period at the end of a street type or direction and replace it with an empty string. 

**tMap2 Connection to Donation Table Oracle Database (tDBOutput)**
All of the records that match the lookup entries are sent to the database to be stored in the oracle Donations table. Something interesting to note is that there is no id column in the tMap2 component for the validaddress output table.
![image](https://user-images.githubusercontent.com/47337941/72451071-630c0200-3789-11ea-849a-9d0b18e054f0.png)

The reason for this is because I wanted to use a sequence that I created in my Oracle DB so that when I run my third job (to add records with two words in their street name) they will have the next sequence value as their DON_ID.  Nocache was included here because the LAST_NUMBER would skip several values.
```
CREATE SEQUENCE donation_id;
nocache;
```

In order to accomplish this, I found a method that allowed me to use a sequence from Oracle:
![image](https://user-images.githubusercontent.com/47337941/72451164-7e770d00-3789-11ea-9bca-2570a31bfddf.png)

Here I created an additional column and set the SQL expression to use sequence(NEXTVAL) that I created in the Oracle DB. Now even when running a third job for street names with two words, the correct sequence will be used.
This is the result in the Oracle database after the job has finished.
`SELECT * FROM DONATION;`
![image](https://user-images.githubusercontent.com/47337941/72451215-98185480-3789-11ea-98dd-d4a9e6e7a77b.png)


**tMap2 RejectedDonations2.csv**
In this file, the rejected entries are stored if they did not match any of the addresses in the lookup to the oracle database ADDRESS table.  
![image](https://user-images.githubusercontent.com/47337941/72451264-a8303400-3789-11ea-9b19-3195874da691.png)

The reason why there is a second rejected donations list is because this one stores addresses that are formatted correctly (have a STREET_TYPE, STREET_DIR, are in Oakville and in Ontario, and have a street type that exists in the oracle ADDRESS table: BLVD, RD, PKY, LANE, DR, and ST), but the STREET_NUM/STREET_NAME/STREET_TYPE/STREET_DIR combination do not exist in the oracle ADDRESS table.
![image](https://user-images.githubusercontent.com/47337941/72451346-c5fd9900-3789-11ea-90d1-173d4ee30cfe.png)


![image](https://user-images.githubusercontent.com/47337941/72451370-d01f9780-3789-11ea-9324-2a13410839c7.png)
This job handles donation records that have 2 words in their street name. The donationsListTwoWord.csv was created in the loadDonations job and imported as metadata for this job. Here the process is nearly identical to the second tMap in the loadDonations job except the donationsListWord.csv has two words for the street address. 
**tMap1**
![image](https://user-images.githubusercontent.com/47337941/72451431-e9284880-3789-11ea-8457-bdd142c87ec5.png)

Here the tDBOutput for the Oracle Donation table once again uses the sequence defined in the oracle database.
![image](https://user-images.githubusercontent.com/47337941/72451590-2ab8f380-378a-11ea-9420-d6b65b30a5df.png)

Next, the result in the oracle database DONATION table after the job has completed:
![image](https://user-images.githubusercontent.com/47337941/72451636-3b696980-378a-11ea-9e4c-861fa76eebd7.png)

As we can see the correct sequence is being used and the two word street names are added to the DONATION table.

**tMap1 RejectedDonations3.csv**
![image](https://user-images.githubusercontent.com/47337941/72451701-520fc080-378a-11ea-885a-f789656c4922.png)




## Task 3

### Question: Create a star schema for the donations. The grain of the schema should be the combination of day, address, and volunteer

### Solution for Task 3:

For creating the star schema, because the address and volunteer tables do not use sequential ids, new dimensional tables and sequences need to be created. 

### Creating Dimensional Tables and Sequences

**Volunteer Table and Sequence**
The difference between this dimension volunteer table and the regular VOLUNTEER table is that a new id(v_id) has been created to be used with a sequence. The reason for this is because the regular volunteer_id seems to be based of some other information because it starts from 100 and skips to 141 for its next record. All columns from the VOLUNTEER table can be included as they are all descriptive data. Volunteer_id must be defined as a primary key or the constraint will not work.
```
CREATE SEQUENCE dim_volunteer_id;

CREATE TABLE dim_volunteer(
    v_id 	    NUMBER,
    volunteer_id   NUMBER PRIMARY KEY,
    first_name     VARCHAR2(16),
    last_name      VARCHAR2(16),
    group_leader,
    CONSTRAINT fk_dim_vol_lead FOREIGN KEY(group_leader)
        REFERENCES dim_volunteer(volunteer_id)
)
```

**Address Table and Sequence**
This dimensional table is basically identical to the regular ADDRESS table. Although it looks like a sequence was already used for the ADDRESS table address_id column, we will create a new dimensional table and sequence just to separate them for the star schema. The sequence will be used for the a_id column. Also, the unit_num and postal_code have not been as they are not used in the regular ADDRESS table.
```
CREATE SEQUENCE dim_address_id;

CREATE TABLE dim_address(
    a_id		 NUMBER
    ,address_id         NUMBER
    ,street_number      NUMBER NOT NULL
    ,street_name        VARCHAR2(24)NOT NULL
    ,street_type        VARCHAR2(12)NOT NULL
    ,street_direction   CHAR(1)
    ,city               VARCHAR2(16)NOT NULL
    ,province           CHAR(2)NOT NULL
    ,CONSTRAINT dim_st_dir CHECK(street_direction IN('E' ,'W' ,'N' ,'S'))
);
```

**Day Table and Sequence**
This dimensional table will be used as reference to get the day of the donation for the facts table. Therefore this dimensional table will be named dim_donation_day and use dim_day_id for the sequential id.

```
CREATE SEQUENCE dim_day_id;
 
CREATE TABLE dim_donation_day (
    day_id              NUMBER
    ,donation_day       NUMBER
    ,donation_month	 NUMBER
    ,donation_year      NUMBER
);
```

**Fact Table**
The fact table contains foreign keys to all dimensional tables together as a surrogate key. It will also hold quantitative information which in this case is the donation amount from the DONATION table.
```
CREATE TABLE fact_donation(
    v_id NUMBER,
    a_id NUMBER,
    day_id NUMBER,
    donation_amount NUMBER(7,1)
);
```


## Task 4

### Question: Create a process to load the data to the star schema from the central donation repository

### Solution to Task 4

#### Inserting Table Data into the Star Schema

**Inserting into the Dimensonal Volunteer Table**
```
INSERT INTO dim_volunteer
    SELECT 
        dim_volunteer_id.NEXTVAL,
        volunteer_id,
        first_name,
        last_name,
        group_leader
    FROM 
        volunteer; 
```
20 rows inserted.

**Inserting into the Dimensional Address Table**
```
INSERT INTO dim_address 
    SELECT
        dim_address_id.NEXTVAL,
        address_id,
        street_number,
        street_name,
        street_type,
        street_direction,
        city,
        province
    FROM
        address;
```
2,221 rows inserted.

**Inserting into the Dimensional Donation Day Table**
```
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
``` 
5 rows inserted.

**Inserting into the Fact Donation Table**
```
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
 19 rows inserted.
```

## Task 5

### Question: 5.	Create views that show
####  o	The average and sum of the donation by day, month, year
####  o	The average and sum of the donations by address, postal code
####  o	The average and sum of the donations by volunteer and volunteer group leader

### Solution to Task 5

**Donations by Day, Month, and Year**
```
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
```

**Donations By Address and Postal Code**
Postal code was not included in any address meaning that the SUM and AVG will return no rows and therefore no view was created.
```
CREATE OR REPLACE VIEW DONATIONS_BY_ADDRESS AS
    SELECT a.address_id, 
        SUM(donation_amount) AS "Total Donation", 
        ROUND(AVG(donation_amount),2) AS "Average Donation"
    FROM dim_address a
    JOIN fact_donation d
        ON a.a_id = d.a_id
    GROUP BY a.address_id
    ORDER BY 1;
```
        
**Donations By Volunteer and Volunteer Leader**
```
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
```

## Task 6

### Question: 6.	Basic Security
####    o	Create a user named DMLUser and give the user permissions to       implement all DML on address, donation, and volunteer tables
####    o	Create a user named Dashboard and give the user read permissions on the views

### Solution to Task 6:

```
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
```

**DMLUSER:**
![image](https://user-images.githubusercontent.com/47337941/72452910-52a95680-378c-11ea-9be1-74d793dd2828.png)

**DASHBOARD**
![image](https://user-images.githubusercontent.com/47337941/72452965-63f26300-378c-11ea-9feb-9a3c8f833092.png)



