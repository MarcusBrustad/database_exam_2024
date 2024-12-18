/*
 Setting up the database with utf8mb4 character set to support
 special characters, including emojis and extended Unicode symbols.
 utf8mb4 is the recommended choice over utf8
 as it fully supports 4-byte characters.

 "utf8mb4_unicode_ci" is added for case-insensitive sorting
 and compatibility with characters from international languages.
 */

DROP DATABASE IF EXISTS MotorbikeClub;
CREATE DATABASE MotorbikeClub
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

use MotorbikeClub;


# --------------------------------------------------------------------------- #
-- Question 1.1 Create database tables.

/*
 Normalized database to avoid redundancy in City and Country fields.
 This design improves scalability and adheres to best practices
 in database normalization.

 Because this DB stores a very small amount of data there is no indexing for
 foreign keys. This could be considered to keep the DB performing better if
 the scaling were to increase.

 All foreign keys have on update cascade to make sure that data transfers
 in case of changes to one table.

 !!!
 There are a few tables with "CASCADE SET NULL" and others without NOT NULL values.
 Queries will have to handle this problem when it comes to getting information.
 Example handling:
    SELECT *
    FROM Member
    WHERE ChapterID IS NOT NULL;
 !!!
 */

-- Country table for consistent data.
DROP TABLE IF EXISTS Country;
CREATE TABLE Country
(
    CountryID INT NOT NULL AUTO_INCREMENT,
    CountryName VARCHAR(20) NOT NULL,

    PRIMARY KEY (CountryID)
);

-- City table with foreign Key to Country.
DROP TABLE IF EXISTS City;
CREATE TABLE City
(
    CityID INT NOT NULL AUTO_INCREMENT,
    CityName VARCHAR(20) NOT NULL,
    CountryID INT NOT NULL,

    PRIMARY KEY (CityID),
    FOREIGN KEY (CountryID) REFERENCES Country(CountryID)
    ON UPDATE CASCADE
    -- ON DELETE CASCADE: Removes the data from current table. No cities
    -- if there is no country.
    ON DELETE CASCADE
);


/*
 Chapter table, foreign key to city table, will also give it a country.

 The chapter table is only using cityID instead of "city" and "country"
 this is to keep data integrity in the normalized DB.
 Info about city and country can be read with a query.
 */
DROP TABLE if exists Chapter;
CREATE TABLE Chapter
(
    ChapterID INT NOT NULL AUTO_INCREMENT,
    ChapterName VARCHAR(50) NOT NULL,
    CityID INT,
    CreationDate DATE NOT NULL,

    PRIMARY KEY (ChapterID),
    FOREIGN KEY (CityID) REFERENCES City(CityID)
    ON UPDATE CASCADE
    -- ON DELETE SET NULL: In case a city is deleted the chapter might
    -- still exist, and the city might change after.
    ON DELETE SET NULL
);


/*
 Member table with foreign key to Chapter table.
 Birthdate is not set to NOT NULL because not all bikers are honest.

 It uses ENUM('Chairman', 'Admin', 'Regular', 'Novice') for MemberRank to ensure
 that the given ranks are within expectations from the exam description.
 */

DROP TABLE IF EXISTS Member;
CREATE TABLE Member
(
    MemberID INT NOT NULL AUTO_INCREMENT,
    Name VARCHAR(50) NOT NULL,
    Birthdate DATE,
    JoinDate DATE NOT NULL,
    MemberRank ENUM('Chairman', 'Admin', 'Regular', 'Novice') NOT NULL,
    ChapterID INT,

    PRIMARY KEY (MemberID),
    FOREIGN KEY (ChapterID) REFERENCES Chapter(ChapterID)
    ON UPDATE CASCADE
    -- ON DELETE SET NULL: Saves the data in current table, but removes
    -- connection to "parent" table. A member can be a biker even though
    -- the chapter might close and be deleted.
    ON DELETE SET NULL
);


/*
 Date doesn't have "NOT NULL", to allow an event to be created
 before it is perfectly planned to the date, for marketing etc.

 Two foreign Keys to city and Chapter.
 This uses both in case the event is not in the same city as
 the chapter is located.

 The Event table is also only using cityID instead of "city" and "country"
 this is to keep data integrity in the normalized DB.
 Info about city and country can be read with a query.
 */
DROP TABLE IF EXISTS Event;
CREATE TABLE Event
(
    EventID INT NOT NULL AUTO_INCREMENT,
    EventName VARCHAR(100) NOT NULL,
    EventDate DATE,
    CityID INT NOT NULL,
    ChapterID INT NOT NULL,

    PRIMARY KEY (EventID),
    FOREIGN KEY (CityID) REFERENCES City(CityID)
    ON UPDATE CASCADE,
    FOREIGN KEY (ChapterID) REFERENCES Chapter(ChapterID)
    ON UPDATE CASCADE
    -- ON DELETE CASCADE: Deletes linked events if the parent chapter is removed.
    ON DELETE CASCADE
);


-- The "Member_Event" table
-- This table links Members to Events (Many-to-Many relationship)
DROP TABLE IF EXISTS Member_Event;
CREATE TABLE Member_Event
(
    MemberID INT NOT NULL,
    EventID INT NOT NULL,

    -- Many-to-Many: A member can attend many events, and an event can have many members.
    PRIMARY KEY (MemberID, EventID),
    FOREIGN KEY (MemberID) REFERENCES Member(MemberID)
    ON UPDATE CASCADE
    -- ON DELETE CASCADE: If the member is removed there is no linked person to event.
    ON DELETE CASCADE,
    FOREIGN KEY (EventID) REFERENCES Event(EventID)
    ON UPDATE CASCADE
    -- ON DELETE CASCADE: If the event is removed there is no linked event to a person.
    ON DELETE CASCADE
);

/*
  Bike table links a bike with information to a member of a chapter.
 No NOT NULL set for year, because some members might have a bike that
 they do know the make and model of, but not exactly what year it was
 made
 */
DROP TABLE IF EXISTS Bike;
CREATE TABLE Bike
(
    BikeID INT NOT NULL AUTO_INCREMENT,
    MemberID INT,
    Model VARCHAR(50) NOT NULL,
    Make VARCHAR(25) NOT NULL,
    Year YEAR,
    LicensePlate VARCHAR(8) NOT NULL UNIQUE,

    PRIMARY KEY (BikeID),
    FOREIGN KEY (MemberID) REFERENCES Member(MemberID)
    ON UPDATE CASCADE
    -- ON DELETE SET NULL: Saves other data, but removes owner.
    -- There is data here that is usable even without a current owner.
    ON DELETE SET NULL
);


# --------------------------------------------------------------------------- #
-- Questions 1.2
/*
 Data for the tables have been found in attached CSV files for the exam.

 For the two extra tables added (City and Country), CityID and CountryID
 have been introduced to replace redundant text fields. This ensures a normalized
 database structure and maintains data integrity.
 */

-- There are 2 countries total in all the CSV files.
INSERT INTO Country(countryid, countryname)
VALUES
    (1, 'Norway'),
    (2, 'Sweden');


-- There are 6 cities, linked to two different countries.
INSERT INTO City(cityid, cityname, countryid)
VALUES
    (1, 'Bergen', 1),
    (2, 'Oslo', 1),
    (3, 'Tromsø', 1),
    (4, 'Gothenburg', 2),
    (5, 'Malmö', 2),
    (6, 'Stockholm', 2);


-- There are 3 chapters, 1 from Sweden and 2 from Norway. Linked by CityID
-- to the corresponding city and country from the data given.
INSERT INTO Chapter(chapterid, chaptername, cityid, creationdate)
VALUES
    (1, 'Vikings of the North', 2, '2010-06-15'),
    (2, 'Swedish Roadmasters', 6, '2015-09-23'),
    (3, 'Northern Riders', 1, '2021-02-10');


-- Members are linked to chapters via ChapterID, as per CSV files.
INSERT INTO Member(memberid, name, birthdate, joindate, memberrank, chapterid)
VALUES
    (1, 'Erik Nilsen', '1985-03-12',
     '2015-04-01', 'Chairman', 1),
    (2, 'Ingrid Larsson', '1990-07-22',
     '2017-08-10', 'Admin', 2),
    (3, 'Bjorn Andersen', '1978-11-05',
     '2012-12-01', 'Regular', 1),
    (4, 'Karin Svensson', '1992-02-18',
     '2018-03-15', 'Regular', 2),
    (5, 'Harald Johansen', '1988-05-09',
     '2016-09-20', 'Admin', 1),
    (6, 'Sofia Lindgren', '1995-01-30',
     '2019-10-05', 'Novice', 2),
    (7, 'Olav Pedersen', '1982-08-14',
     '2010-05-14', 'Chairman', 2),
    (8, 'Mats Bergström', '1994-11-21',
     '2020-07-18', 'Novice', 2),
    (9, 'Lars Johansen', '1984-04-11',
     '2020-01-20', 'Regular', 3),
    (10, 'Astrid Karlsson', '1987-10-05',
     '2020-09-15', 'Novice', 3),
    (11, 'Peter Nilsson', '1983-06-22',
     '2021-11-10', 'Regular', 1),
    (12, 'Hanna Svensson', '1991-12-03',
     '2022-03-25', 'Admin', 2),
    (13, 'Johan Eriksson', '1975-01-28',
     '2018-07-12', 'Chairman', 3),
    (14, 'Freya Hansen', '1996-08-14',
     '2021-05-16', 'Novice', 1),
    (15, 'Olaf Svendsen', '1990-03-09',
     '2023-01-10', 'Regular', 2),
    (16, 'Greta Lindahl', '1989-09-17',
     '2021-12-04', 'Regular', 3);


/*
 The Event table is also only using cityID instead of "city" and "country"
 this is to keep data integrity in the normalized DB.
 Info about city and country can be read with a query.
 */
INSERT INTO Event(EventID, EventName, EventDate, CityID, ChapterID)
VALUES
    (1, 'Midnight Sun Rally',
     '2022-06-24', 3, 1),
    (2, 'Swedish Coastline Ride',
     '2023-07-18', 4, 2),
    (3, 'Nordic Thunder',
     '2022-08-12', 2, 1),
    (4, 'Scandinavian Roadtrip',
     '2023-05-03', 5, 2),
    (5, 'Bergen Biker Fest',
     '2023-09-15', 1, 3);



INSERT INTO Member_Event(MemberID, EventID)
VALUES
    (1, 1),
    (3, 1),
    (11, 1),
    (14, 1),
    (2, 2),
    (4, 2),
    (12, 2),
    (15, 2),
    (1, 3),
    (5, 3),
    (7, 3),
    (2, 4),
    (6, 4),
    (8, 4),
    (9, 5),
    (10, 5),
    (13, 5),
    (16, 5);


INSERT INTO Bike (BikeID, MemberID, Model, Make, Year, LicensePlate)
VALUES
    (1, 1, 'Night Rod Special',
     'Harley Davidson', 2013, 'OSL12345'),
    (2, 2, 'Softail Slim',
     'Harley Davidson', 2016, 'STH56789'),
    (3, 3, 'Vulcan S',
     'Kawasaki', 2015, 'OSL98765'),
    (4, 4, 'Bonneville T120',
     'Triumph', 2018, 'STH54321'),
    (5, 5, 'Indian Scout',
     'Indian', 2017, 'OSL24680'),
    (6, 6, 'Street Triple RS',
     'Triumph', 2019, 'STH13579'),
    (7, 7, 'Sportster Iron 883',
     'Harley Davidson', 2011, 'OSL11223'),
    (8, 8, 'Rebel 500',
     'Honda', 2020, 'STH97531'),
    (9, 9, 'MT-07',
     'Yamaha', 2020, 'BER12345'),
    (10, 10, 'Z900',
     'Kawasaki', 2021, 'BER54321'),
    (11, 11, 'Street Glide',
     'Harley Davidson', 2018, 'OSL67890'),
    (12, 12, 'Dyna Fat Bob',
     'Harley Davidson', 2019, 'STH09876'),
    (13, 13, 'Ninja 650',
     'Kawasaki', 2022, 'BER24680'),
    (14, 14, 'Scrambler Icon',
     'Ducati', 2023, 'OSL11234'),
    (15, 15, 'FZ6',
     'Yamaha', 2020, 'STH98765'),
    (16, 16, 'Husqvarna Vitpilen 701',
     'Husqvarna', 2021, 'BER43210');

