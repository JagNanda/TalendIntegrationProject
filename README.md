# Talend Integration Project
The purpose of this project was to combine data from different databases using **TALEND** and filter the results into a .csv file based on project requirements to get the desired output. Please note that although this was a group project, it was completed individually by myself. See **[Solution.md](Solution.md)** for the solution for this project.

## Project Requirements

The project for this course is worth 25% of your mark and you have the option to do it in a group of three or four people. A Group Contract must be assigned by each group

### Introduction

In this project you will assist a pet rescue charity with managing their donations related data. The charity organizes an annual donation drive. The city is divided to donations areas (every donation area is approximately 6 postal codes) and assign a group of volunteers to every area. The volunteers will go door to door in their designated areas in order to collect donations from the residents. They can collect cash, checks, or credit card payments. At the end of every week the volunteering group leaders will fill in a list with the donation record that were collected in their area, and send it to the charity main office. The staff in the main office will load the list to a central table after rejecting non-valid entries and then use the data to perform analysis.

### Data Sources

#### Central Donations Repository
The tables created by projectTables.sql script resides in the charity’s oracle database server as well as the list of the volunteers.

#### Donation List
The list of donors is stored in a comma separated file named donorsList.csv. This is the list that the volunteer group lead sends to the main office. It shows the schema and contains only two entries, but each member of the group (presumably a volunteer with a distinct volunteer no) must provide a separate list for their "area" with at least 15 entries. As a result each group will have three (or four) donor lists that contain 15 additional entries in the donors list. Make sure that there are both valid and invalid entries. The invalid entries will be rejected and sent back to the volunteer coordinator.

#### Master Addresses Table
The address table that the charity maintains is not updated and it often gets out of date. However, there is another department in the organization has an address table that they regularly update and keep current. The table is in SQLServer database and below is the connection information to the server
Server Name: dbr.fast.sheridanc.on.ca
Port: 1433
Database name: Integration
Schema Name: dbo
User Name: DataIntegrator
Password: Sher1dan

### Tasks

1.	Refresh the address table in the oracle database with the addresses in the master table. You will need to transform some data types and generate a sequential id for the address. Also note that the ids of some addresses will be used as foreign key in donation table your solution should accommodate this fact.

2.	Create a process that loads the donations list to the central donations table: In this task you will load the file into the central repository (Oracle tables). You need to make sure that only the donations with valid addresses are inserted into the table. Donation records with erroneous addresses must be rejected. Also make sure to reject the donations that have nulls for the mandatory columns in your database (Not null columns). You must generate csv files to the volunteer group leaders with the records that were rejected in their area.

3.	Create a star schema for the donations. The grain of the schema should be the combination of day, address, and volunteer

4.	Create a process to load the data to the star schema from the central donation repository

5.	Create views that shows

  o	The average and sum of the donation by day, month, year
  
  o	The average and sum of the donations by address, postal code
  
  o	The average and sum of the donations by volunteer and volunteer group leader
  
6.	Basic Security

  o	Create a user named DMLUser and give the user permissions to implement all DML on address, donation, and volunteer tables
  
  o	Create a user named Dashboard and give the user read permissions on the views
