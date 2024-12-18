-- Use here to ensure we are using the correct DB for queries.
use MotorbikeClub;

# --------------------------------------------------------------------------- #
/*
    Questions 2.1

1. Which biker is the youngest?
2. List all bike manufactures and the total number of registered bikes of
that manufacturer.
3. Show all data for bikes manufactured by ‘Yamaha’
4. Display each of the chapters and the corresponding chairman.
5. For each member, list the make, model and registration of their bikes.
6. For all bikes manufactured before 2015, list the chapter name, license
plate, and year.
7. Select the newest member for each chapter, listing the chapter, member’s
name, and join date.
 */

# --------------------------------------------------------------------------- #
-- 1.
-- Which biker is the youngest?

/*
 Shows the "biker" or member that has the latest birthdate with birthdate.
 It includes the date of birth for context.
 */
SELECT Name AS `Youngest Biker`, Birthdate AS `Date of Birth`
FROM Member
ORDER BY Birthdate DESC
LIMIT 1;


# --------------------------------------------------------------------------- #
-- 2.
-- List all bike manufactures and the total number of registered bikes of
-- that manufacturer.

-- Counts all the different models of bikes from each manufacturer and prints
-- it out to the user with the name "Total Bikes"
SELECT Make AS `Manufacturer`, COUNT(Model) AS `Total Bikes`
FROM Bike
GROUP BY Make
ORDER BY `Total Bikes` DESC;


# --------------------------------------------------------------------------- #
-- 3.
-- Show all data for bikes manufactured by ‘Yamaha’
/*
 This query only uses information actually directly connected to the
 bike in the SELECT part.

 This ensures that only necessary data is actually being read by the DB.
 */
SELECT BikeID, Model, Make, Year, LicensePlate
FROM Bike
WHERE Make = 'Yamaha';

/*
 This query uses * To collect all the data on the Bikes made by "Yamaha"
 Reading this question I interpret it as meaning all data that is registered
 together with the bike. Could have Selected only;
 "BikeID, Model, Make, Year, LicensePlate" as shown above.
 */

SELECT *
FROM Bike
WHERE Make = 'Yamaha';


# --------------------------------------------------------------------------- #
-- 4.
-- Display each of the chapters and the corresponding chairman.

-- This query shows each chapter and their Chairman
-- Joins Member to get their RANK.
SELECT Chapter.ChapterName AS `Chapter`,
               Member.Name AS `Chairman`
FROM Chapter
JOIN Member ON Member.ChapterID = Chapter.ChapterID
WHERE Member.MemberRank = 'Chairman';

# --------------------------------------------------------------------------- #
-- 5.
-- For each member, list the make, model and registration of their bikes.

/*
 Gives out Make, Model and LicensePlate for each member(name)
 Join between Member and Bike for Different Information,
 MemberID to link right information
 */
SELECT Member.Name AS `Biker`, Bike.Make AS `Manufacturer`,
       Bike.Model AS `Model`, Bike.LicensePlate `Registration`
FROM Member
JOIN Bike ON Member.MemberID = Bike.MemberID;

# --------------------------------------------------------------------------- #
-- 6.
-- For all bikes manufactured before 2015, list the chapter name, license
-- plate, and year.
/*
 Selects Chapter, licensePlate, and year to show user. Two Joins to get all
 wanted information out correctly and not printing just ID for chapter or
 biker.
 */
SELECT Chapter.ChapterName AS `Chapter`, Bike.LicensePlate AS `Registration`,
       Bike.Year AS `Production Year`
FROM Bike
JOIN Member ON Bike.MemberID = Member.MemberID
JOIN Chapter ON Member.ChapterID = Chapter.ChapterID
WHERE Bike.Year < 2015;

# --------------------------------------------------------------------------- #
-- 7.
-- Select the newest member for each chapter, listing the chapter, member’s
-- name, and join date.
/*
 The correlated subquery runs for each row, which can be slower on large datasets.
 The IN-based solution avoids this by precomputing the MAX(JoinDate) for each chapter.
 */
SELECT Chapter.ChapterName AS `Chapter`, Member.Name AS `Member Name`,
       Member.JoinDate AS `Date of joining chapter`
FROM Member
JOIN Chapter ON Member.ChapterID = Chapter.ChapterID
WHERE Member.JoinDate IN (SELECT MAX(JoinDate)
                          FROM Member
                          GROUP BY ChapterID);

/*
 This uses a correlated subquery to get only one per chapter, will do whichever
 was last added to the db, this uses chapter in the subquery which will
 be a bit slower than just using a "nested IN"
 */
SELECT Chapter.ChapterName AS `Chapter`, Member.Name AS `Member Name`,
       Member.JoinDate AS `Date of joining chapter`
FROM Member
JOIN Chapter ON Member.ChapterID = Chapter.ChapterID
WHERE Member.JoinDate = (SELECT MAX(Member.JoinDate)
                         FROM Member
                         WHERE Member.ChapterID = Chapter.ChapterID);


# --------------------------------------------------------------------------- #
-- Question 2.2
/*

 1. Create a new event using the following data:
 Whale Tour, 2023-06-12, Sandefjord, Norway, Vikings of the North
 2. Update all ‘Novice’ members (in all chapters) who have been members
 since before 1st September 2020; they should become ‘Regular’ members
 3. ‘Bjorn Andersen’ has sold his only motorbike (it’s a Kawasaki) and it
 should be deleted from the database

 Since the database is normalized some of these tasks will be less
 straight forward and there will be stored procedure as there are
 multiple steps to ensure data structure and handling.
 */

# --------------------------------------------------------------------------- #
-- 1.
/*
 Because of the tables City, and country this will be first check if the city
 exists and is linked to a country before adding the event.

 This Procedure takes Event information using names, instead of ID's so it
 is easier for the actual user, but then translates and validates to something
 the database can use to create event.
 */
DELIMITER //
-- Procedure set up with parameters from the exam text.
CREATE PROCEDURE Create_New_Event_With_Names(IN event_name VARCHAR(100),
                                             IN event_date DATE,
                                             IN city_name VARCHAR(20),
                                             IN country_name VARCHAR(20),
                                             IN chapter_name VARCHAR(50))

BEGIN

    -- Declaring local variables needed for insert later and or to be used
    -- for checking different tables if data exists.
    -- Keeps up data integrity
    DECLARE country_id INT;
    DECLARE city_id INT;
    DECLARE chapter_id INT;

    -- 1. Check if country exists. Otherwise, add to DB.
    -- Uses SELECT 'wanted info' INTO (local variable) for later use.
    SELECT CountryID INTO country_id
    FROM Country
    WHERE CountryName = country_name;

    -- Uses previously declared variable to check if data exists.
    -- If the data didn't exist in the correct table (Country),
    -- the data will be added.
    IF country_id IS NULL THEN
        INSERT INTO Country(CountryName)
        VALUES (country_name);
        SET country_id = LAST_INSERT_ID();
    end if;

    -- 2. Check if city exists. Otherwise, add to DB.
    -- Uses SELECT 'wanted info' INTO (local variable) for later use.
    SELECT CityID INTO city_id
    FROM City
    WHERE CityName = city_name
    AND CountryID = country_id;

    -- Uses previously declared variable to check if data exists.
    -- If the data didn't exist in the correct table (City),
    -- the data will be added.
    IF city_id IS NULL THEN
        INSERT INTO City(CityName, CountryID)
        VALUES (city_name, country_id);
        SET city_id = LAST_INSERT_ID();
    end if;

    -- 3. Check if Chapter exists. Otherwise, add to DB.
    -- Uses SELECT 'wanted info' INTO (local variable) for later use.
    SELECT ChapterID INTO chapter_id
    FROM Chapter
    WHERE ChapterName = chapter_name
    AND CityID = city_id;

    -- Uses previously declared variable to check if data exists.
    -- If the data didn't exist in the correct table (Chapter),
    -- the data will be added.
    IF chapter_id IS NULL THEN
        INSERT INTO Chapter(ChapterName, CityID, CreationDate)
        VALUES (chapter_name, city_id, event_date);
        SET chapter_id = LAST_INSERT_ID();
    end if;

    -- After confirming that given data exists or has been added,
    -- the insert will commit.
    INSERT INTO Event(EventName, EventDate, CityID, ChapterID)
    VALUES(event_name,event_date,city_id,chapter_id );

end //
DELIMITER ;


-- Using the Stored Procedure to create the event from the exam text.
CALL Create_New_Event_With_Names('Whale Tour',
                                 '2023-06-12',
                                 'Sandefjord',
                                 'Norway',
                                 'Vikings of the North');


# --------------------------------------------------------------------------- #
-- 2.
/*
 Updates all MemberRank info for people who still are novices, and joined
 before the 1. September 2020.
 */

UPDATE Member
SET MemberRank = 'Regular'
WHERE MemberRank = 'Novice'
AND JoinDate < '2020-09-01';


# --------------------------------------------------------------------------- #
-- 3.
/*
 This DELETES a row from bike, and uses a nested IN statement to get memberID
 with the member Name we now have.
 */
DELETE FROM Bike
WHERE Bike.MemberID IN (SELECT MemberID
                        FROM Member
                        WHERE Name = 'Bjorn Andersen');


# --------------------------------------------------------------------------- #