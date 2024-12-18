/*
 Question 3.1
Write an SQL script that creates a stored procedure that can be used to
create a new city record when only the required data is provided.

Question 3.2
Write an SQL script that creates a stored procedure that can be used to
update the population of a city when only it’s name and country code is
provided.
(Assume that countries do not have duplicate city names within their
borders.)

Question 3.3
Write an SQL script that creates a stored procedure that can used to find
the name and position (latitude and longitude) of all cities in a country that
have an airport.

Question 3.4
Write an SQL script that creates a stored procedure that can used to
create a new user (when given a username and password). The procedure
must provide the new user with only read access to the city table in the
destinations database.

 city id INT(11) PRIMARY KEY, AUTO INCREMENT & Unique ID
 city VARCHAR(50) NOT NULL | City name
 lat DECIMAL(9,6) NOT NULL | Latitude
 lng DECIMAL(9,6) NOT NULL | Longitude
 country VARCHAR(25) NOT NULL | Full country name
 country iso VARCHAR(2) NOT NULL | Country ISO code
 population INT(11) | Estimated population
 has airport TINYINT(1) | 0 for no, and 1 for yes
 */

DELIMITER //
# --------------------------------------------------------------------------- #
-- 3.1
/*
 This procedure will not run if unless you fill in all the parameters.
 It does not include city_id as that would require the user to know
 what the next ID in the line is, and there is no use for that here
 as the table primary key is set to AUTO_INCREMENT
 */
CREATE PROCEDURE Create_New_City(IN city_name VARCHAR(50),
                                 IN latitude DECIMAL(9,6),
                                 IN longitude DECIMAL(9,6),
                                 IN country_name VARCHAR(50),
                                 IN countryiso VARCHAR(2),
                                 IN population_est INT(11),
                                 IN hasairport TINYINT(1))

BEGIN
    /*
     Checks if the city already exists, before creating a new one.
     We are told to that there are no duplicate cities in countries.
     "(Assume that countries do not have duplicate city names within their
     borders.)"
     */
    IF NOT EXISTS (SELECT 1 FROM City WHERE city = city_name AND country_iso = countryiso) THEN
    -- Inserts given parameters into the right place.
    INSERT INTO City(city, lat, lng, country, country_iso, population, has_airport)
    VALUES (city_name, latitude, longitude,
            country_name, countryiso,
            population_est, hasairport);

    ELSE
        -- Error message if the city exists already.
        -- SQLSTATE '45000' for user error
        SIGNAL SQLSTATE '45000'
            -- CONCAT to show what argument(s) caused error.
            SET MESSAGE_TEXT = CONCAT('Error: City "', city_name,'" in country "',
                                      country_name, '" already exists in database');
    END IF;

END //

# --------------------------------------------------------------------------- #
-- 3.2
/*
 Takes parameters "city_name" and "countryiso" to use in WHERE clause.
 Takes parameter population_est to update the estimated population for
 given city.
 */
CREATE PROCEDURE Update_City_Population_By_Name_CountryISO(IN city_name VARCHAR(50),
                                                           IN countryiso VARCHAR(50),
                                                           IN population_est INT(11))

BEGIN
    /*
     Checks if the city already exists, before updating it.
     It uses IF EXISTS rather than ON DUPLICATE KEY UPDATE.
     We are told to that there are no duplicate cities in countries.
     "(Assume that countries do not have duplicate city names within their
     borders.)"
     */
    IF EXISTS (SELECT 1 FROM City WHERE City = city_name AND Country_ISO = countryiso) THEN
    -- Updates city with given argument and given parameters for WHERE clause.
    UPDATE City
    SET population = population_est
    WHERE city = city_name
    AND country_iso = countryiso;

    ELSE
        -- Returns an error if city doesn't exist.
        -- SQLSTATE '45000' for user error
        SIGNAL SQLSTATE '45000'
            -- CONCAT to show what argument(s) caused error.
            SET MESSAGE_TEXT = CONCAT('Error: City "', city_name, '" with ISO "',
                                      countryiso,'" not found in database.');

    END IF;

END //


# --------------------------------------------------------------------------- #
-- 3.3
/*
 Gets city name in one column, then uses CONCAT for latitude and longitude
 into a standard format.
 */
CREATE PROCEDURE Get_Name_And_Position_From_CountryISO_If_Airport(IN countryiso VARCHAR(2))

BEGIN
    /*
     If exists to check if there is any cities that matches the country ISO given.
     Concat gives format: (1.1234, 5.6789)
     */
    IF EXISTS (SELECT 1 FROM City WHERE country_iso = countryiso) THEN
        SELECT city AS `City name`, CONCAT('(', lat, ',', lng, ')') AS `Position`
        FROM City
        WHERE country_iso = countryiso
        -- 1 = True
        AND has_airport = 1;
    ELSE
        -- Error message if no city has given ISO.
        -- SQLSTATE '45000' for user error
        SIGNAL SQLSTATE '45000'
            -- CONCAT to show what argument(s) caused error.
            SET MESSAGE_TEXT = CONCAT('Error: No cities corresponding with ISO "',
                                      countryiso, '" Found in database.');
    END IF;

END //


# --------------------------------------------------------------------------- #
-- 3.4
/*
 This is the first attempt, read more up on it, and found the right solution
 as far as I can understand below.
 Decided to keep this one in, to show the process on the one that probably
 took me the most time to learn.
 */
CREATE PROCEDURE Create_User_Read_City(IN username VARCHAR(25),
                                       IN pswrd VARCHAR(20))

BEGIN
    -- First attempt.
    -- Creating user by username, standard procedure.
    CREATE USER username@'localhost' IDENTIFIED BY pswrd;
    -- Granting privileges to newly created user.
    GRANT SELECT ON destinations.City TO 'username'@'localhost';
    -- Flushing to commit privileges to the new user.
    FLUSH PRIVILEGES;

END //

/*
 This one took a lot of reading up to be able to find the "cleanest"
 solution for, there is way too much "misinformation" out there.
 */
CREATE PROCEDURE Create_User_Read_City(IN `username` VARCHAR(25),
                                       IN password VARCHAR(20))
BEGIN
    /*
     Declaring a local variable for username with concat to be able
     to run query
     @user is a locally constructed version of the input parameter 'username'.
     */
    SET @user := CONCAT('\'', username, '\'@\'localhost\'');

    -- Declaring local variable for creating user statement.
    SET @create := CONCAT('CREATE USER ', @user, ' IDENTIFIED BY "', password, '"');
    -- Preparing statement, executing then deallocating prepare.
    PREPARE create_stmt FROM @create;
    EXECUTE create_stmt;
    DEALLOCATE PREPARE create_stmt;

    -- Declaring local variable for granting privileges statement.
    SET @grant := CONCAT('GRANT SELECT ON destinations.City TO ', @user);
    -- Preparing statement, executing then deallocating prepare.
    PREPARE grant_stmt FROM @grant;
    EXECUTE grant_stmt;
    DEALLOCATE PREPARE grant_stmt;

    -- Flushing privileges to commit grants to newly created user.
    FLUSH PRIVILEGES;

END //

# --------------------------------------------------------------------------- #
DELIMITER ;