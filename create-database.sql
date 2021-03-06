DROP TABLE division;
DROP TABLE match;
DROP TABLE powerfactor;
DROP TABLE shooter;
DROP TABLE shooter_match;
DROP TABLE stage;
DROP TABLE stage_score;
DROP TABLE category;
DROP TABLE club;

CREATE TABLE category(
    ID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
    NAME STRING,
    SHORT_NAME STRING);
INSERT INTO category(ID, NAME,SHORT_NAME) VALUES(1, 'Lady','L');
INSERT INTO category(ID, NAME,SHORT_NAME) VALUES(2, 'Senior','S');
INSERT INTO category(ID, NAME,SHORT_NAME) VALUES(3, 'SuperSenior','SS');
INSERT INTO category(ID, NAME,SHORT_NAME) VALUES(4, 'Junior','J');
INSERT INTO category(ID, NAME,SHORT_NAME) VALUES(5, 'None','-');
            
CREATE TABLE division(
    ID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
    NAME STRING);
INSERT INTO division(ID, NAME) VALUES(1,'Open');
INSERT INTO division(ID, NAME) VALUES(2,'Production');
INSERT INTO division(ID, NAME) VALUES(3,'Standard');
INSERT INTO division(ID, NAME) VALUES(4,'Classic');
INSERT INTO division(ID, NAME) VALUES(5,'Revolver');

CREATE TABLE powerfactor(
    ID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
    NAME STRING,
    CSCORE INTEGER,
    DSCORE INTEGER);
INSERT INTO powerfactor(ID,NAME,CSCORE,DSCORE) VALUES(1,'MAJOR',4,2);
INSERT INTO powerfactor(ID,NAME,CSCORE,DSCORE) VALUES(2,'MINOR',3,1);

CREATE TABLE club(
    ID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
    NAME STRING);

CREATE TABLE match(
    ID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
    NAME STRING,
    DATE DATE,
    LEVEL INTEGER,
    SSI_URL STRING);

CREATE TABLE shooter(
    ID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
    NAME STRING,
    IPSCNUMBER INTEGER,
    SSI_URL STRING);

CREATE TABLE shooter_match(
    ID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
    SHOOTER_START_ID INTEGER,
    SHOOTER_ID INTEGER,
    POWERFACTOR_ID INTEGER,
    POWERFACTOR_ID_WHATIF INTEGER,
    DIVISION_ID INTEGER,
    DIVISION_ID_WHATIF INTEGER,
    MATCH_ID INTEGER,
    CLUB_ID INTEGER,
    SQUAD INTEGER,
    NAME STRING,
    CATEGORY_ID,
    DQ BOOLEAN DEFAULT (0));

CREATE TABLE stage(
    ID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
    MATCH_ID INTEGER,
    NAME STRING,
    MAXROUNDS INTEGER,
    STAGE_URL STRING);

CREATE TABLE stage_score(
    ID INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL,
    STAGE_ID INTEGER,
    SHOOTER_MATCH_ID INTEGER,
    A INTEGER,
    A_WHATIF INTEGER,
    C INTEGER,
    C_WHATIF INTEGER,
    D INTEGER,
    D_WHATIF INTEGER,
    MISS INTEGER,
    MISS_WHATIF INTEGER,
    NS INTEGER,
    NS_WHATIF INTEGER,
    PROC INTEGER,
    PROC_WHATIF INTEGER,
    TIME DECIMAL,
    TIME_WHATIF DECIMAL);