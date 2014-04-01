--$Id: set_search_path.sql 9690 2012-04-29 01:06:06Z robe $
 /*** 
 * 
 * Copyright (C) 2012 Regina Obe and Leo Hsu (Paragon Corporation)
 **/
-- Adds a schema to  the front of search path so that functions, tables etc get installed by default in set schema
-- but if people have postgis and other things installed in non-public, it will still keep those in path
-- Example usage: SELECT tiger.SetSearchPathForInstall('tiger');
CREATE OR REPLACE FUNCTION tiger.SetSearchPathForInstall(a_schema_name varchar)
RETURNS text
AS
$$
DECLARE
	var_result text;
	var_cur_search_path text;
BEGIN
	SELECT reset_val INTO var_cur_search_path FROM pg_settings WHERE name = 'search_path';

	EXECUTE 'SET search_path = ' || quote_ident(a_schema_name) || ', ' || var_cur_search_path; 
	var_result := a_schema_name || ' has been made primary for install ';
  RETURN var_result;
END
$$
LANGUAGE 'plpgsql' VOLATILE STRICT;
CREATE OR REPLACE FUNCTION utmzone(geometry) RETURNS integer AS
$BODY$
DECLARE
    geomgeog geometry;
    zone int;
    pref int;
BEGIN
    geomgeog:=ST_Transform($1,4326);
    IF (ST_Y(geomgeog))>0 THEN
        pref:=32600;
    ELSE
        pref:=32700;
    END IF;
    zone:=floor((ST_X(geomgeog)+180)/6)+1;
    RETURN zone+pref;
END;
$BODY$ LANGUAGE 'plpgsql' immutable;
-- Returns the value passed, or an empty string if null.
-- This is used to concatinate values that may be null.
CREATE OR REPLACE FUNCTION cull_null(VARCHAR) RETURNS VARCHAR
AS $_$
    SELECT coalesce($1,'');
$_$ LANGUAGE sql IMMUTABLE;
-- This function take two arguements.  The first is the "given string" and
-- must not be null.  The second arguement is the "compare string" and may
-- or may not be null.  If the second string is null, the value returned is
-- 3, otherwise it is the levenshtein difference between the two.
-- Change 2010-10-18 Regina Obe - name verbose to var_verbose since get compile error in PostgreSQL 9.0
CREATE OR REPLACE FUNCTION nullable_levenshtein(VARCHAR, VARCHAR) RETURNS INTEGER
AS $_$
DECLARE
  given_string VARCHAR;
  result INTEGER := 3;
  var_verbose BOOLEAN := FALSE; /**change from verbose to param_verbose since its a keyword and get compile error in 9.0 **/
BEGIN
  IF $1 IS NULL THEN
    IF var_verbose THEN
      RAISE NOTICE 'nullable_levenshtein - given string is NULL!';
    END IF;
    RETURN NULL;
  ELSE
    given_string := $1;
  END IF;

  IF $2 IS NOT NULL AND $2 != '' THEN
    result := levenshtein_ignore_case(given_string, $2);
  END IF;

  RETURN result;
END
$_$ LANGUAGE plpgsql IMMUTABLE COST 10;
-- This function determines the levenshtein distance irespective of case.
CREATE OR REPLACE FUNCTION levenshtein_ignore_case(VARCHAR, VARCHAR) RETURNS INTEGER
AS $_$
  SELECT levenshtein(upper($1), upper($2));
$_$ LANGUAGE sql IMMUTABLE;
-- Runs the soundex function on the last word in the string provided.
-- Words are allowed to be seperated by space, comma, period, new-line
-- tab or form feed.
CREATE OR REPLACE FUNCTION end_soundex(VARCHAR) RETURNS VARCHAR
AS $_$
DECLARE
  tempString VARCHAR;
BEGIN
  tempString := substring($1, E'[ ,.\n\t\f]([a-zA-Z0-9]*)$');
  IF tempString IS NOT NULL THEN
    tempString := soundex(tempString);
  ELSE
    tempString := soundex($1);
  END IF;
  return tempString;
END;
$_$ LANGUAGE plpgsql IMMUTABLE;
-- Determine the number of words in a string.  Words are allowed to
-- be seperated only by spaces, but multiple spaces between
-- words are allowed.
CREATE OR REPLACE FUNCTION count_words(VARCHAR) RETURNS INTEGER
AS $_$
DECLARE
  tempString VARCHAR;
  tempInt INTEGER;
  count INTEGER := 1;
  lastSpace BOOLEAN := FALSE;
BEGIN
  IF $1 IS NULL THEN
    return -1;
  END IF;
  tempInt := length($1);
  IF tempInt = 0 THEN
    return 0;
  END IF;
  FOR i IN 1..tempInt LOOP
    tempString := substring($1 from i for 1);
    IF tempString = ' ' THEN
      IF NOT lastSpace THEN
        count := count + 1;
      END IF;
      lastSpace := TRUE;
    ELSE
      lastSpace := FALSE;
    END IF;
  END LOOP;
  return count;
END;
$_$ LANGUAGE plpgsql IMMUTABLE;
-- state_extract(addressStringLessZipCode)
-- Extracts the state from end of the given string.
--
-- This function uses the state_lookup table to determine which state
-- the input string is indicating.  First, an exact match is pursued,
-- and in the event of failure, a word-by-word fuzzy match is attempted.
--
-- The result is the state as given in the input string, and the approved
-- state abbreviation, seperated by a colon.
CREATE OR REPLACE FUNCTION state_extract(rawInput VARCHAR) RETURNS VARCHAR
AS $_$
DECLARE
  tempInt INTEGER;
  tempString VARCHAR;
  state VARCHAR;
  stateAbbrev VARCHAR;
  result VARCHAR;
  rec RECORD;
  test BOOLEAN;
  ws VARCHAR;
  var_verbose boolean := false;
BEGIN
  ws := E'[ ,.\t\n\f\r]';

  -- If there is a trailing space or , get rid of it
  -- this is to handle case where people use , instead of space to separate state and zip
  -- such as '2450 N COLORADO ST, PHILADELPHIA, PA, 19132' instead of '2450 N COLORADO ST, PHILADELPHIA, PA 19132'
  
  --tempString := regexp_replace(rawInput, E'(.*)' || ws || '+', E'\\1');
  tempString := btrim(rawInput, ', ');
  -- Separate out the last word of the state, and use it to compare to
  -- the state lookup table to determine the entire name, as well as the
  -- abbreviation associated with it.  The zip code may or may not have
  -- been found.
  tempString := substring(tempString from ws || E'+([^ ,.\t\n\f\r0-9]*?)$');
  IF var_verbose THEN RAISE NOTICE 'state_extract rawInput: % tempString: %', rawInput, tempString; END IF;
  SELECT INTO tempInt count(*) FROM (select distinct abbrev from state_lookup
      WHERE upper(abbrev) = upper(tempString)) as blah;
  IF tempInt = 1 THEN
    state := tempString;
    SELECT INTO stateAbbrev abbrev FROM (select distinct abbrev from
        state_lookup WHERE upper(abbrev) = upper(tempString)) as blah;
  ELSE
    SELECT INTO tempInt count(*) FROM state_lookup WHERE upper(name)
        like upper('%' || tempString);
    IF tempInt >= 1 THEN
      FOR rec IN SELECT name from state_lookup WHERE upper(name)
          like upper('%' || tempString) LOOP
        SELECT INTO test texticregexeq(rawInput, name) FROM state_lookup
            WHERE rec.name = name;
        IF test THEN
          SELECT INTO stateAbbrev abbrev FROM state_lookup
              WHERE rec.name = name;
          state := substring(rawInput, '(?i)' || rec.name);
          EXIT;
        END IF;
      END LOOP;
    ELSE
      -- No direct match for state, so perform fuzzy match.
      SELECT INTO tempInt count(*) FROM state_lookup
          WHERE soundex(tempString) = end_soundex(name);
      IF tempInt >= 1 THEN
        FOR rec IN SELECT name, abbrev FROM state_lookup
            WHERE soundex(tempString) = end_soundex(name) LOOP
          tempInt := count_words(rec.name);
          tempString := get_last_words(rawInput, tempInt);
          test := TRUE;
          FOR i IN 1..tempInt LOOP
            IF soundex(split_part(tempString, ' ', i)) !=
               soundex(split_part(rec.name, ' ', i)) THEN
              test := FALSE;
            END IF;
          END LOOP;
          IF test THEN
            state := tempString;
            stateAbbrev := rec.abbrev;
            EXIT;
          END IF;
        END LOOP;
      END IF;
    END IF;
  END IF;

  IF state IS NOT NULL AND stateAbbrev IS NOT NULL THEN
    result := state || ':' || stateAbbrev;
  END IF;

  RETURN result;
END;
$_$ LANGUAGE plpgsql STABLE;
-- Returns a string consisting of the last N words.  Words are allowed
-- to be seperated only by spaces, but multiple spaces between
-- words are allowed.  Words must be alphanumberic.
-- If more words are requested than exist, the full input string is
-- returned.
CREATE OR REPLACE FUNCTION get_last_words(
    inputString VARCHAR,
    count INTEGER
) RETURNS VARCHAR
AS $_$
DECLARE
  tempString VARCHAR;
  result VARCHAR := '';
BEGIN
  FOR i IN 1..count LOOP
    tempString := substring(inputString from '((?: )+[a-zA-Z0-9_]*)' || result || '$');

    IF tempString IS NULL THEN
      RETURN inputString;
    END IF;

    result := tempString || result;
  END LOOP;

  result := trim(both from result);

  RETURN result;
END;
$_$ LANGUAGE plpgsql IMMUTABLE COST 10;
-- location_extract_countysub_exact(string, stateAbbrev)
-- This function checks the place_lookup table to find a potential match to
-- the location described at the end of the given string.  If an exact match
-- fails, a fuzzy match is performed.  The location as found in the given
-- string is returned.
CREATE OR REPLACE FUNCTION location_extract_countysub_exact(
    fullStreet VARCHAR,
    stateAbbrev VARCHAR
) RETURNS VARCHAR
AS $_$
DECLARE
  ws VARCHAR;
  location VARCHAR;
  tempInt INTEGER;
  lstate VARCHAR;
  rec RECORD;
BEGIN
  ws := E'[ ,.\n\f\t]';

  -- No hope of determining the location from place. Try countysub.
  IF stateAbbrev IS NOT NULL THEN
    lstate := statefp FROM state WHERE stusps = stateAbbrev;
    SELECT INTO tempInt count(*) FROM cousub
        WHERE cousub.statefp = lstate
        AND texticregexeq(fullStreet, '(?i)' || name || '$');
  ELSE
    SELECT INTO tempInt count(*) FROM cousub
        WHERE texticregexeq(fullStreet, '(?i)' || name || '$');
  END IF;

  IF tempInt > 0 THEN
    IF stateAbbrev IS NOT NULL THEN
      FOR rec IN SELECT substring(fullStreet, '(?i)('
          || name || ')$') AS value, name FROM cousub
          WHERE cousub.statefp = lstate
          AND texticregexeq(fullStreet, '(?i)' || ws || name ||
          '$') ORDER BY length(name) DESC LOOP
        -- Only the first result is needed.
        location := rec.value;
        EXIT;
      END LOOP;
    ELSE
      FOR rec IN SELECT substring(fullStreet, '(?i)('
          || name || ')$') AS value, name FROM cousub
          WHERE texticregexeq(fullStreet, '(?i)' || ws || name ||
          '$') ORDER BY length(name) DESC LOOP
        -- again, only the first is needed.
        location := rec.value;
        EXIT;
      END LOOP;
    END IF;
  END IF;

  RETURN location;
END;
$_$ LANGUAGE plpgsql STABLE COST 10;
-- location_extract_countysub_fuzzy(string, stateAbbrev)
-- This function checks the place_lookup table to find a potential match to
-- the location described at the end of the given string.  If an exact match
-- fails, a fuzzy match is performed.  The location as found in the given
-- string is returned.
CREATE OR REPLACE FUNCTION location_extract_countysub_fuzzy(
    fullStreet VARCHAR,
    stateAbbrev VARCHAR
) RETURNS VARCHAR
AS $_$
DECLARE
  ws VARCHAR;
  tempString VARCHAR;
  location VARCHAR;
  tempInt INTEGER;
  word_count INTEGER;
  rec RECORD;
  test BOOLEAN;
  lstate VARCHAR;
BEGIN
  ws := E'[ ,.\n\f\t]';

  -- Fuzzy matching.
  tempString := substring(fullStreet, '(?i)' || ws ||
      '([a-zA-Z0-9]+)$');
  IF tempString IS NULL THEN
    tempString := fullStreet;
  END IF;

  IF stateAbbrev IS NOT NULL THEN
    lstate := statefp FROM state WHERE stusps = stateAbbrev;
    SELECT INTO tempInt count(*) FROM cousub
        WHERE cousub.statefp = lstate
        AND soundex(tempString) = end_soundex(name);
  ELSE
    SELECT INTO tempInt count(*) FROM cousub
        WHERE soundex(tempString) = end_soundex(name);
  END IF;

  IF tempInt > 0 THEN
    tempInt := 50;
    -- Some potentials were found.  Begin a word-by-word soundex on each.
    IF stateAbbrev IS NOT NULL THEN
      FOR rec IN SELECT name FROM cousub
          WHERE cousub.statefp = lstate
          AND soundex(tempString) = end_soundex(name) LOOP
        word_count := count_words(rec.name);
        test := TRUE;
        tempString := get_last_words(fullStreet, word_count);
        FOR i IN 1..word_count LOOP
          IF soundex(split_part(tempString, ' ', i)) !=
            soundex(split_part(rec.name, ' ', i)) THEN
            test := FALSE;
          END IF;
        END LOOP;
        IF test THEN
          -- The soundex matched, determine if the distance is better.
          IF levenshtein_ignore_case(rec.name, tempString) < tempInt THEN
                location := tempString;
            tempInt := levenshtein_ignore_case(rec.name, tempString);
          END IF;
        END IF;
      END LOOP;
    ELSE
      FOR rec IN SELECT name FROM cousub
          WHERE soundex(tempString) = end_soundex(name) LOOP
        word_count := count_words(rec.name);
        test := TRUE;
        tempString := get_last_words(fullStreet, word_count);
        FOR i IN 1..word_count LOOP
          IF soundex(split_part(tempString, ' ', i)) !=
            soundex(split_part(rec.name, ' ', i)) THEN
            test := FALSE;
          END IF;
        END LOOP;
        IF test THEN
          -- The soundex matched, determine if the distance is better.
          IF levenshtein_ignore_case(rec.name, tempString) < tempInt THEN
                location := tempString;
            tempInt := levenshtein_ignore_case(rec.name, tempString);
          END IF;
        END IF;
      END LOOP;
    END IF;
  END IF; -- If no fuzzys were found, leave location null.

  RETURN location;
END;
$_$ LANGUAGE plpgsql;
--$Id: location_extract_place_exact.sql 9324 2012-02-27 22:08:12Z pramsey $-
-- location_extract_place_exact(string, stateAbbrev)
-- This function checks the place_lookup table to find a potential match to
-- the location described at the end of the given string.  If an exact match
-- fails, a fuzzy match is performed.  The location as found in the given
-- string is returned.
CREATE OR REPLACE FUNCTION location_extract_place_exact(
    fullStreet VARCHAR,
    stateAbbrev VARCHAR
) RETURNS VARCHAR
AS $_$
DECLARE
  ws VARCHAR;
  location VARCHAR;
  tempInt INTEGER;
  lstate VARCHAR;
  rec RECORD;
BEGIN
--$Id: location_extract_place_exact.sql 9324 2012-02-27 22:08:12Z pramsey $-
  ws := E'[ ,.\n\f\t]';

  -- Try for an exact match against places
  IF stateAbbrev IS NOT NULL THEN
    lstate := statefp FROM state WHERE stusps = stateAbbrev;
    SELECT INTO tempInt count(*) FROM place
        WHERE place.statefp = lstate AND fullStreet ILIKE '%' || name || '%'
        AND texticregexeq(fullStreet, '(?i)' || name || '$');
  ELSE
    SELECT INTO tempInt count(*) FROM place
        WHERE fullStreet ILIKE '%' || name || '%' AND
        	texticregexeq(fullStreet, '(?i)' || name || '$');
  END IF;

  IF tempInt > 0 THEN
    -- Some matches were found.  Look for the last one in the string.
    IF stateAbbrev IS NOT NULL THEN
      FOR rec IN SELECT substring(fullStreet, '(?i)('
          || name || ')$') AS value, name FROM place
          WHERE place.statefp = lstate AND fullStreet ILIKE '%' || name || '%'
          AND texticregexeq(fullStreet, '(?i)'
          || name || '$') ORDER BY length(name) DESC LOOP
        -- Since the regex is end of string, only the longest (first) result
        -- is useful.
        location := rec.value;
        EXIT;
      END LOOP;
    ELSE
      FOR rec IN SELECT substring(fullStreet, '(?i)('
          || name || ')$') AS value, name FROM place
          WHERE fullStreet ILIKE '%' || name || '%' AND texticregexeq(fullStreet, '(?i)'
          || name || '$') ORDER BY length(name) DESC LOOP
        -- Since the regex is end of string, only the longest (first) result
        -- is useful.
        location := rec.value;
        EXIT;
      END LOOP;
    END IF;
  END IF;

  RETURN location;
END;
$_$ LANGUAGE plpgsql STABLE COST 100;
--$Id: location_extract_place_fuzzy.sql 9324 2012-02-27 22:08:12Z pramsey $-
-- location_extract_place_fuzzy(string, stateAbbrev)
-- This function checks the place_lookup table to find a potential match to
-- the location described at the end of the given string.  If an exact match
-- fails, a fuzzy match is performed.  The location as found in the given
-- string is returned.
CREATE OR REPLACE FUNCTION location_extract_place_fuzzy(
    fullStreet VARCHAR,
    stateAbbrev VARCHAR
) RETURNS VARCHAR
AS $_$
DECLARE
  ws VARCHAR;
  tempString VARCHAR;
  location VARCHAR;
  tempInt INTEGER;
  word_count INTEGER;
  rec RECORD;
  test BOOLEAN;
  lstate VARCHAR;
BEGIN
--$Id: location_extract_place_fuzzy.sql 9324 2012-02-27 22:08:12Z pramsey $-
  ws := E'[ ,.\n\f\t]';

  tempString := substring(fullStreet, '(?i)' || ws
      || '([a-zA-Z0-9]+)$');
  IF tempString IS NULL THEN
      tempString := fullStreet;
  END IF;

  IF stateAbbrev IS NOT NULL THEN
    lstate := statefp FROM state WHERE stusps = stateAbbrev;
    SELECT into tempInt count(*) FROM place
        WHERE place.statefp = lstate
        AND soundex(tempString) = end_soundex(name);
  ELSE
    SELECT into tempInt count(*) FROM place
        WHERE soundex(tempString) = end_soundex(name);
  END IF;

  IF tempInt > 0 THEN
    -- Some potentials were found.  Begin a word-by-word soundex on each.
    tempInt := 50;
    IF stateAbbrev IS NOT NULL THEN
      FOR rec IN SELECT name FROM place
          WHERE place.statefp = lstate
          AND soundex(tempString) = end_soundex(name) LOOP
        word_count := count_words(rec.name);
        test := TRUE;
        tempString := get_last_words(fullStreet, word_count);
        FOR i IN 1..word_count LOOP
          IF soundex(split_part(tempString, ' ', i)) !=
            soundex(split_part(rec.name, ' ', i)) THEN
            test := FALSE;
          END IF;
        END LOOP;
          IF test THEN
            -- The soundex matched, determine if the distance is better.
            IF levenshtein_ignore_case(rec.name, tempString) < tempInt THEN
              location := tempString;
              tempInt := levenshtein_ignore_case(rec.name, tempString);
            END IF;
          END IF;
      END LOOP;
    ELSE
      FOR rec IN SELECT name FROM place
          WHERE soundex(tempString) = end_soundex(name) LOOP
        word_count := count_words(rec.name);
        test := TRUE;
        tempString := get_last_words(fullStreet, word_count);
        FOR i IN 1..word_count LOOP
          IF soundex(split_part(tempString, ' ', i)) !=
            soundex(split_part(rec.name, ' ', i)) THEN
            test := FALSE;
          END IF;
        END LOOP;
          IF test THEN
            -- The soundex matched, determine if the distance is better.
            IF levenshtein_ignore_case(rec.name, tempString) < tempInt THEN
              location := tempString;
            tempInt := levenshtein_ignore_case(rec.name, tempString);
          END IF;
        END IF;
      END LOOP;
    END IF;
  END IF;

  RETURN location;
END;
$_$ LANGUAGE plpgsql STABLE;
-- location_extract(streetAddressString, stateAbbreviation)
-- This function extracts a location name from the end of the given string.
-- The first attempt is to find an exact match against the place_lookup
-- table.  If this fails, a word-by-word soundex match is tryed against the
-- same table.  If multiple candidates are found, the one with the smallest
-- levenshtein distance from the given string is assumed the correct one.
-- If no match is found against the place_lookup table, the same tests are
-- run against the countysub_lookup table.
--
-- The section of the given string corresponding to the location found is
-- returned, rather than the string found from the tables.  All the searching
-- is done largely to determine the length (words) of the location, to allow
-- the intended street name to be correctly identified.
CREATE OR REPLACE FUNCTION location_extract(fullStreet VARCHAR, stateAbbrev VARCHAR) RETURNS VARCHAR
AS $_$
DECLARE
  ws VARCHAR;
  location VARCHAR;
  lstate VARCHAR;
  stmt VARCHAR;
  street_array text[];
  word_count INTEGER;
  rec RECORD;
  best INTEGER := 0;
  tempString VARCHAR;
BEGIN
  IF fullStreet IS NULL THEN
    RETURN NULL;
  END IF;

  ws := E'[ ,.\n\f\t]';

  IF stateAbbrev IS NOT NULL THEN
    lstate := statefp FROM state_lookup WHERE abbrev = stateAbbrev;
  END IF;
  lstate := COALESCE(lstate,'');

  street_array := regexp_split_to_array(fullStreet,ws);
  word_count := array_upper(street_array,1);

  tempString := '';
  FOR i IN 1..word_count LOOP
    CONTINUE WHEN street_array[word_count-i+1] IS NULL OR street_array[word_count-i+1] = '';

    tempString := COALESCE(street_array[word_count-i+1],'') || tempString;

    stmt := ' SELECT'
         || '   1,'
         || '   name,'
         || '   levenshtein_ignore_case(' || quote_literal(tempString) || ',name) as rating,'
         || '   length(name) as len'
         || ' FROM place'
         || ' WHERE ' || CASE WHEN stateAbbrev IS NOT NULL THEN 'statefp = ' || quote_literal(lstate) || ' AND ' ELSE '' END
         || '   soundex(' || quote_literal(tempString) || ') = soundex(name)'
         || '   AND levenshtein_ignore_case(' || quote_literal(tempString) || ',name) <= 2 '
         || ' UNION ALL SELECT'
         || '   2,'
         || '   name,'
         || '   levenshtein_ignore_case(' || quote_literal(tempString) || ',name) as rating,'
         || '   length(name) as len'
         || ' FROM cousub'
         || ' WHERE ' || CASE WHEN stateAbbrev IS NOT NULL THEN 'statefp = ' || quote_literal(lstate) || ' AND ' ELSE '' END
         || '   soundex(' || quote_literal(tempString) || ') = soundex(name)'
         || '   AND levenshtein_ignore_case(' || quote_literal(tempString) || ',name) <= 2 '
         || ' ORDER BY '
         || '   3 ASC, 1 ASC, 4 DESC'
         || ' LIMIT 1;'
         ;

    EXECUTE stmt INTO rec;

    IF rec.rating >= best THEN
      location := tempString;
      best := rec.rating;
    END IF;

    tempString := ' ' || tempString;
  END LOOP;

  location := replace(location,' ',ws || '+');
  location := substring(fullStreet,'(?i)' || location || '$');

  RETURN location;
END;
$_$ LANGUAGE plpgsql STABLE COST 100;
--$Id: normalize_address.sql 9823 2012-05-27 18:28:48Z robe $-
-- normalize_address(addressString)
-- This takes an address string and parses it into address (internal/street)
-- street name, type, direction prefix and suffix, location, state and
-- zip code, depending on what can be found in the string.
--
-- The US postal address standard is used:
-- <Street Number> <Direction Prefix> <Street Name> <Street Type>
-- <Direction Suffix> <Internal Address> <Location> <State> <Zip Code>
--
-- State is assumed to be included in the string, and MUST be matchable to
-- something in the state_lookup table.  Fuzzy matching is used if no direct
-- match is found.
--
-- Two formats of zip code are acceptable: five digit, and five + 4.
--
-- The internal addressing indicators are looked up from the
-- secondary_unit_lookup table.  A following identifier is accepted
-- but it must start with a digit.
--
-- The location is parsed from the string using other indicators, such
-- as street type, direction suffix or internal address, if available.
-- If these are not, the location is extracted using comparisons against
-- the places_lookup table, then the countysub_lookup table to determine
-- what, in the original string, is intended to be the location.  In both
-- cases, an exact match is first pursued, then a word-by-word fuzzy match.
-- The result is not the name of the location from the tables, but the
-- section of the given string that corresponds to the name from the tables.
--
-- Zip codes and street names are not validated.
--
-- Direction indicators are extracted by comparison with the direction_lookup
-- table.
--
-- Street addresses are assumed to be a single word, starting with a number.
-- Address is manditory; if no address is given, and the street is numbered,
-- the resulting address will be the street name, and the street name
-- will be an empty string.
--
-- In some cases, the street type is part of the street name.
-- eg State Hwy 22a.  As long as the word following the type starts with a
-- number (this is usually the case) this will be caught.  Some street names
-- include a type name, and have a street type that differs.  This will be
-- handled properly, so long as both are given.  If the street type is
-- omitted, the street names included type will be parsed as the street type.
--
-- The output is currently a colon seperated list of values:
-- InternalAddress:StreetAddress:DirectionPrefix:StreetName:StreetType:
-- DirectionSuffix:Location:State:ZipCode
-- This returns each element as entered.  It's mainly meant for debugging.
-- There is also another option that returns:
-- StreetAddress:DirectionPrefixAbbreviation:StreetName:StreetTypeAbbreviation:
-- DirectionSuffixAbbreviation:Location:StateAbbreviation:ZipCode
-- This is more standardized and better for use with a geocoder.
CREATE OR REPLACE FUNCTION normalize_address(in_rawinput character varying)
  RETURNS norm_addy AS
$$
DECLARE
  debug_flag boolean := get_geocode_setting('debug_normalize_address')::boolean;
  result norm_addy;
  addressString VARCHAR;
  zipString VARCHAR;
  preDir VARCHAR;
  postDir VARCHAR;
  fullStreet VARCHAR;
  reducedStreet VARCHAR;
  streetType VARCHAR;
  state VARCHAR;
  tempString VARCHAR;
  tempInt INTEGER;
  rec RECORD;
  ws VARCHAR;
  rawInput VARCHAR;
  -- is this a highway 
  -- (we treat these differently since the road name often comes after the streetType)
  isHighway boolean := false; 
BEGIN
--$Id: normalize_address.sql 9823 2012-05-27 18:28:48Z robe $-
  result.parsed := FALSE;

  rawInput := trim(in_rawInput);

  IF rawInput IS NULL THEN
    RETURN result;
  END IF;

  ws := E'[ ,.\t\n\f\r]';

  IF debug_flag THEN
    raise notice '% input: %', clock_timestamp(), rawInput;
  END IF;

  -- Assume that the address begins with a digit, and extract it from
  -- the input string.
  addressString := substring(rawInput from E'^([0-9].*?)[ ,/.]');

  IF debug_flag THEN
    raise notice '% addressString: %', clock_timestamp(), addressString;
  END IF;

  -- There are two formats for zip code, the normal 5 digit , and
  -- the nine digit zip-4.  It may also not exist.
  
  zipString := substring(rawInput from ws || E'([0-9]{5})$');
  IF zipString IS NULL THEN
    -- Check if the zip is just a partial or a one with -s
    -- or one that just has more than 5 digits
    zipString := COALESCE(substring(rawInput from ws || '([0-9]{5})-[0-9]{0,4}$'), 
                substring(rawInput from ws || '([0-9]{2,5})$'),
                substring(rawInput from ws || '([0-9]{6,14})$'));
   
     -- Check if all we got was a zipcode, of either form
    IF zipString IS NULL THEN
      zipString := substring(rawInput from '^([0-9]{5})$');
      IF zipString IS NULL THEN
        zipString := substring(rawInput from '^([0-9]{5})-[0-9]{4}$');
      END IF;
      -- If it was only a zipcode, then just return it.
      IF zipString IS NOT NULL THEN
        result.zip := zipString;
        result.parsed := TRUE;
        RETURN result;
      END IF;
    END IF;
  END IF;

  IF debug_flag THEN
    raise notice '% zipString: %', clock_timestamp(), zipString;
  END IF;

  IF zipString IS NOT NULL THEN
    fullStreet := substring(rawInput from '(.*)'
        || ws || '+' || cull_null(zipString) || '[- ]?([0-9]{4})?$');
    /** strip off any trailing  spaces or ,**/
    fullStreet :=  btrim(fullStreet, ' ,');
    
  ELSE
    fullStreet := rawInput;
  END IF;

  IF debug_flag THEN
    raise notice '% fullStreet: %', clock_timestamp(), fullStreet;
  END IF;

  -- FIXME: state_extract should probably be returning a record so we can
  -- avoid having to parse the result from it.
  tempString := state_extract(fullStreet);
  IF tempString IS NOT NULL THEN
    state := split_part(tempString, ':', 1);
    result.stateAbbrev := split_part(tempString, ':', 2);
  END IF;

  IF debug_flag THEN
    raise notice '% stateAbbrev: %', clock_timestamp(), result.stateAbbrev;
  END IF;

  -- The easiest case is if the address is comma delimited.  There are some
  -- likely cases:
  --   street level, location, state
  --   street level, location state
  --   street level, location
  --   street level, internal address, location, state
  --   street level, internal address, location state
  --   street level, internal address location state
  --   street level, internal address, location
  --   street level, internal address location
  -- The first three are useful.

  tempString := substring(fullStreet, '(?i),' || ws || '+(.*?)(,?' || ws ||
      '*' || cull_null(state) || '$)');
  IF tempString = '' THEN tempString := NULL; END IF;
  IF tempString IS NOT NULL THEN
    IF tempString LIKE '%,%' THEN -- if it has a comma probably has suite, strip it from location
        result.location := trim(split_part(tempString,',',2));
    ELSE
        result.location := tempString;
    END IF;
    IF addressString IS NOT NULL THEN
      fullStreet := substring(fullStreet, '(?i)' || addressString || ws ||
          '+(.*),' || ws || '+' || result.location);
    ELSE
      fullStreet := substring(fullStreet, '(?i)(.*),' || ws || '+' ||
          result.location);
    END IF;
  END IF;

  IF debug_flag THEN
    raise notice '% fullStreet: %',  clock_timestamp(), fullStreet;
    raise notice '% location: %', clock_timestamp(), result.location;
  END IF;

  -- Pull out the full street information, defined as everything between the
  -- address and the state.  This includes the location.
  -- This doesnt need to be done if location has already been found.
  IF result.location IS NULL THEN
    IF addressString IS NOT NULL THEN
      IF state IS NOT NULL THEN
        fullStreet := substring(fullStreet, '(?i)' || addressString ||
            ws || '+(.*?)' || ws || '+' || state);
      ELSE
        fullStreet := substring(fullStreet, '(?i)' || addressString ||
            ws || '+(.*?)');
      END IF;
    ELSE
      IF state IS NOT NULL THEN
        fullStreet := substring(fullStreet, '(?i)(.*?)' || ws ||
            '+' || state);
      ELSE
        fullStreet := substring(fullStreet, '(?i)(.*?)');
      END IF;
    END IF;

    IF debug_flag THEN
      raise notice '% fullStreet: %', clock_timestamp(),fullStreet;
    END IF;

    IF debug_flag THEN
      raise notice '% start location extract', clock_timestamp();
    END IF;
    result.location := location_extract(fullStreet, result.stateAbbrev);

    IF debug_flag THEN
      raise notice '% end location extract', clock_timestamp();
    END IF;

    -- A location can't be a street type, sorry.
    IF lower(result.location) IN (SELECT lower(name) FROM street_type_lookup) THEN
        result.location := NULL;
    END IF;

    -- If the location was found, remove it from fullStreet
    IF result.location IS NOT NULL THEN
      fullStreet := substring(fullStreet, '(?i)(.*)' || ws || '+' ||
          result.location);
    END IF;
  END IF;

  IF debug_flag THEN
    raise notice 'fullStreet: %', fullStreet;
    raise notice 'location: %', result.location;
  END IF;

  -- Determine if any internal address is included, such as apartment
  -- or suite number.
  -- this count is surprisingly slow by itself but much faster if you add an ILIKE AND clause
  SELECT INTO tempInt count(*) FROM secondary_unit_lookup
      WHERE fullStreet ILIKE '%' || name || '%' AND texticregexeq(fullStreet, '(?i)' || ws || name || '('
          || ws || '|$)');
  IF tempInt = 1 THEN
    result.internal := substring(fullStreet, '(?i)' || ws || '('
        || name ||  ws || '*#?' || ws
        || '*(?:[0-9][-0-9a-zA-Z]*)?' || ')(?:' || ws || '|$)')
        FROM secondary_unit_lookup
        WHERE fullStreet ILIKE '%' || name || '%' AND texticregexeq(fullStreet, '(?i)' || ws || name || '('
        || ws || '|$)');
    ELSIF tempInt > 1 THEN
    -- In the event of multiple matches to a secondary unit designation, we
    -- will assume that the last one is the true one.
    tempInt := 0;
    FOR rec in SELECT trim(substring(fullStreet, '(?i)' || ws || '('
        || name || '(?:' || ws || '*#?' || ws
        || '*(?:[0-9][-0-9a-zA-Z]*)?)' || ws || '?|$)')) as value
        FROM secondary_unit_lookup
        WHERE fullStreet ILIKE '%' || name || '%' AND  texticregexeq(fullStreet, '(?i)' || ws || name || '('
        || ws || '|$)') LOOP
      IF tempInt < position(rec.value in fullStreet) THEN
        tempInt := position(rec.value in fullStreet);
        result.internal := rec.value;
      END IF;
    END LOOP;
  END IF;

  IF debug_flag THEN
    raise notice 'internal: %', result.internal;
  END IF;

  IF result.location IS NULL THEN
    -- If the internal address is given, the location is everything after it.
    result.location := trim(substring(fullStreet, result.internal || ws || '+(.*)$'));
  END IF;

  IF debug_flag THEN
    raise notice 'location: %', result.location;
  END IF;

  -- Pull potential street types from the full street information
  -- this count is surprisingly slow by itself but much faster if you add an ILIKE AND clause
  -- difference of 98ms vs 16 ms for example
  -- Put a space in front to make regex easier can always count on it starting with space
  -- Reject all street types where the fullstreet name is equal to the name
  fullStreet := ' ' || trim(fullStreet);
  tempInt := count(*) FROM street_type_lookup
      WHERE fullStreet ILIKE '%' || name || '%' AND 
        trim(upper(fullStreet)) != name AND
        texticregexeq(fullStreet, '(?i)' || ws || '(' || name
      || ')(?:' || ws || '|$)');
  IF tempInt = 1 THEN
    SELECT INTO rec abbrev, substring(fullStreet, '(?i)' || ws || '('
        || name || ')(?:' || ws || '|$)') AS given, is_hw FROM street_type_lookup
        WHERE fullStreet ILIKE '%' || name || '%' AND 
             trim(upper(fullStreet)) != name AND
            texticregexeq(fullStreet, '(?i)' || ws || '(' || name
        || ')(?:' || ws || '|$)')  ;
    streetType := rec.given;
    result.streetTypeAbbrev := rec.abbrev;
    isHighway :=  rec.is_hw;
    IF debug_flag THEN
    	   RAISE NOTICE 'street Type: %, street Type abbrev: %', rec.given, rec.abbrev;
    END IF;
  ELSIF tempInt > 1 THEN
    tempInt := 0;
    -- the last matching abbrev in the string is the most likely one
    FOR rec IN SELECT * FROM 
    	(SELECT abbrev, name, substring(fullStreet, '(?i)' || ws || '?('
        || name || ')(?:' || ws || '|$)') AS given, is_hw ,
        		RANK() OVER( ORDER BY position(name IN upper(trim(fullStreet))) ) As n_start,
        		RANK() OVER( ORDER BY position(name IN upper(trim(fullStreet))) + length(name) ) As n_end,
        		COUNT(*) OVER() As nrecs, position(name IN upper(trim(fullStreet)))
        		FROM street_type_lookup
        WHERE fullStreet ILIKE '%' || name || '%'  AND 
            trim(upper(fullStreet)) != name AND 
            (texticregexeq(fullStreet, '(?i)' || ws || '(' || name 
            -- we only consider street types that are regular and not at beginning of name or are highways (since those can be at beg or end)
            -- we take the one that is the longest e.g Country Road would be more correct than Road
        || ')(?:' || ws || '|$)') OR (is_hw AND fullstreet ILIKE name || ' %') )
     AND ((NOT is_hw AND position(name IN upper(trim(fullStreet))) > 1 OR is_hw) )
        ) As foo
        -- N_start - N_end - ensure we first get the one with the most overlapping sub types 
        -- Then of those get the one that ends last and then starts first
        ORDER BY n_start - n_end, n_end DESC, n_start LIMIT 1  LOOP
      -- If we have found an internal address, make sure the type
      -- precedes it.
      /** TODO: I don't think we need a loop anymore since we are just returning one and the one in the last position
      * I'll leave for now though **/
      IF result.internal IS NOT NULL THEN
        IF position(rec.given IN fullStreet) < position(result.internal IN fullStreet) THEN
          IF tempInt < position(rec.given IN fullStreet) THEN
            streetType := rec.given;
            result.streetTypeAbbrev := rec.abbrev;
            isHighway := rec.is_hw;
            tempInt := position(rec.given IN fullStreet);
          END IF;
        END IF;
      ELSIF tempInt < position(rec.given IN fullStreet) THEN
        streetType := rec.given;
        result.streetTypeAbbrev := rec.abbrev;
        isHighway := rec.is_hw;
        tempInt := position(rec.given IN fullStreet);
        IF debug_flag THEN
        	RAISE NOTICE 'street Type: %, street Type abbrev: %', rec.given, rec.abbrev;
        END IF;
      END IF;
    END LOOP;
  END IF;

  IF debug_flag THEN
    raise notice '% streetTypeAbbrev: %', clock_timestamp(), result.streetTypeAbbrev;
  END IF;

  -- There is a little more processing required now.  If the word after the
  -- street type begins with a number, then its most likely a highway like State Route 225a.  If
  -- In Tiger 2010+ the reduced Street name just has the number
  -- the next word starts with a char, then everything after the street type
  -- will be considered location.  If there is no street type, then I'm sad.
  IF streetType IS NOT NULL THEN
    -- Check if the fullStreet contains the streetType and ends in just numbers
    -- If it does its a road number like a country road or state route or other highway
    -- Just set the number to be the name of street
    
    tempString := NULL;
    IF isHighway THEN
        tempString :=  substring(fullStreet, streetType || ws || '+' || E'([0-9a-zA-Z]+)' || ws || '*');
    END IF;    
    IF tempString > '' AND result.location IS NOT NULL THEN
        reducedStreet := tempString;
        result.streetName := reducedStreet;
        IF debug_flag THEN
        	RAISE NOTICE 'reduced Street: %', result.streetName;
        END IF;
        -- the post direction might be portion of fullStreet after reducedStreet and type
		-- reducedStreet: 24  fullStreet: Country Road 24, N or fullStreet: Country Road 24 N
		tempString := regexp_replace(fullStreet, streetType || ws || '+' || reducedStreet,'');
		IF tempString > '' THEN
			IF debug_flag THEN
				RAISE NOTICE 'remove reduced street: % + streetType: % from fullstreet: %', reducedStreet, streetType, fullStreet;
			END IF;
			tempString := abbrev FROM direction_lookup WHERE
			 tempString ILIKE '%' || name || '%'  AND texticregexeq(reducedStreet || ws || '+' || streetType, '(?i)(' || name || ')' || ws || '+|$')
			 	ORDER BY length(name) DESC LIMIT 1;
			IF tempString IS NOT NULL THEN
				result.postDirAbbrev = trim(tempString);
				IF debug_flag THEN
					RAISE NOTICE 'postDirAbbre of highway: %', result.postDirAbbrev;
				END IF;
			END IF;
		END IF;
    ELSE
        tempString := substring(fullStreet, streetType || ws ||
            E'+([0-9][^ ,.\t\r\n\f]*?)' || ws);
        IF tempString IS NOT NULL THEN
          IF result.location IS NULL THEN
            result.location := substring(fullStreet, streetType || ws || '+'
                     || tempString || ws || '+(.*)$');
          END IF;
          reducedStreet := substring(fullStreet, '(.*)' || ws || '+'
                        || result.location || '$');
          streetType := NULL;
          result.streetTypeAbbrev := NULL;
        ELSE
          IF result.location IS NULL THEN
            result.location := substring(fullStreet, streetType || ws || '+(.*)$');
          END IF;
          reducedStreet := substring(fullStreet, '^(.*)' || ws || '+'
                        || streetType);
          IF COALESCE(trim(reducedStreet),'') = '' THEN --reduced street can't be blank
            reducedStreet := fullStreet;
            streetType := NULL;
            result.streetTypeAbbrev := NULL;
          END IF;
        END IF;
		-- the post direction might be portion of fullStreet after reducedStreet
		-- reducedStreet: Main  fullStreet: Main St, N or fullStreet: Main St N
		tempString := trim(regexp_replace(fullStreet,  reducedStreet ||  ws || '+' || streetType,''));
		IF tempString > '' THEN
		  tempString := abbrev FROM direction_lookup WHERE
			 tempString ILIKE '%' || name || '%'  
			 AND texticregexeq(fullStreet || ' ', '(?i)' || reducedStreet || ws || '+' || streetType || ws || '+(' || name || ')' || ws || '+')
			ORDER BY length(name) DESC LIMIT 1;
		  IF tempString IS NOT NULL THEN
			result.postDirAbbrev = trim(tempString);
		  END IF;
		END IF;
 

		IF debug_flag THEN
			raise notice '% reduced street: %', clock_timestamp(), reducedStreet;
		END IF;
		
		-- The pre direction should be at the beginning of the fullStreet string.
		-- The post direction should be at the beginning of the location string
		-- if there is no internal address
		reducedStreet := trim(reducedStreet);
		tempString := trim(regexp_replace(fullStreet,  ws || '+' || reducedStreet ||  ws || '+',''));
		IF tempString > '' THEN
			tempString := substring(reducedStreet, '(?i)(^' || name
				|| ')' || ws) FROM direction_lookup WHERE
				 reducedStreet ILIKE '%' || name || '%'  AND texticregexeq(reducedStreet, '(?i)(^' || name || ')' || ws)
				ORDER BY length(name) DESC LIMIT 1;
		END IF;
		IF tempString > '' THEN
		  preDir := tempString;
		  result.preDirAbbrev := abbrev FROM direction_lookup
			  where reducedStreet ILIKE '%' || name '%' AND texticregexeq(reducedStreet, '(?i)(^' || name || ')' || ws)
			  ORDER BY length(name) DESC LIMIT 1;
		  result.streetName := trim(substring(reducedStreet, '^' || preDir || ws || '(.*)'));
		ELSE
		  result.streetName := trim(reducedStreet);
		END IF;
    END IF;
    IF texticregexeq(result.location, '(?i)' || result.internal || '$') THEN
      -- If the internal address is at the end of the location, then no
      -- location was given.  We still need to look for post direction.
      SELECT INTO rec abbrev,
          substring(result.location, '(?i)^(' || name || ')' || ws) as value
          FROM direction_lookup 
            WHERE result.location ILIKE '%' || name || '%' AND texticregexeq(result.location, '(?i)^'
          || name || ws) ORDER BY length(name) desc LIMIT 1;
      IF rec.value IS NOT NULL THEN
        postDir := rec.value;
        result.postDirAbbrev := rec.abbrev;
      END IF;
      result.location := null;
    ELSIF result.internal IS NULL THEN
      -- If no location is given, the location string will be the post direction
      SELECT INTO tempInt count(*) FROM direction_lookup WHERE
          upper(result.location) = upper(name);
      IF tempInt != 0 THEN
        postDir := result.location;
        SELECT INTO result.postDirAbbrev abbrev FROM direction_lookup WHERE
            upper(postDir) = upper(name);
        result.location := NULL;
        
        IF debug_flag THEN
            RAISE NOTICE '% postDir exact match: %', clock_timestamp(), result.postDirAbbrev;
        END IF;
      ELSE
        -- postDirection is not equal location, but may be contained in it
        -- It is only considered a postDirection if it is not preceded by a ,
        SELECT INTO tempString substring(result.location, '(?i)(^' || name
            || ')' || ws) FROM direction_lookup WHERE
            result.location ILIKE '%' || name || '%' AND texticregexeq(result.location, '(?i)(^' || name || ')' || ws)
            	AND NOT  texticregexeq(rawInput, '(?i)(,' || ws || '+' || result.location || ')' || ws)
            ORDER BY length(name) desc LIMIT 1;
            
        IF debug_flag THEN
            RAISE NOTICE '% location trying to extract postdir: %, tempstring: %, rawInput: %', clock_timestamp(), result.location, tempString, rawInput;
        END IF;
        IF tempString IS NOT NULL THEN
            postDir := tempString;
            SELECT INTO result.postDirAbbrev abbrev FROM direction_lookup
              WHERE result.location ILIKE '%' || name || '%' AND texticregexeq(result.location, '(?i)(^' || name || ')' || ws) ORDER BY length(name) DESC LIMIT 1;
              result.location := substring(result.location, '^' || postDir || ws || '+(.*)');
            IF debug_flag THEN
                  RAISE NOTICE '% postDir: %', clock_timestamp(), result.postDirAbbrev;
            END IF;
        END IF;
        
      END IF;
    ELSE
      -- internal is not null, but is not at the end of the location string
      -- look for post direction before the internal address
        IF debug_flag THEN
            RAISE NOTICE '%fullstreet before extract postdir: %', clock_timestamp(), fullStreet;
        END IF;
        SELECT INTO tempString substring(fullStreet, '(?i)' || streetType
          || ws || '+(' || name || ')' || ws || '+' || result.internal)
          FROM direction_lookup 
          WHERE fullStreet ILIKE '%' || name || '%' AND texticregexeq(fullStreet, '(?i)'
          || ws || name || ws || '+' || result.internal) ORDER BY length(name) desc LIMIT 1;
        IF tempString IS NOT NULL THEN
            postDir := tempString;
            SELECT INTO result.postDirAbbrev abbrev FROM direction_lookup
                WHERE texticregexeq(fullStreet, '(?i)' || ws || name || ws);
        END IF;
    END IF;
  ELSE
  -- No street type was found

    -- If an internal address was given, then the split becomes easy, and the
    -- street name is everything before it, without directions.
    IF result.internal IS NOT NULL THEN
      reducedStreet := substring(fullStreet, '(?i)^(.*?)' || ws || '+'
                    || result.internal);
      tempInt := count(*) FROM direction_lookup WHERE
          reducedStreet ILIKE '%' || name || '%' AND texticregexeq(reducedStreet, '(?i)' || ws || name || '$');
      IF tempInt > 0 THEN
        postDir := substring(reducedStreet, '(?i)' || ws || '('
            || name || ')' || '$') FROM direction_lookup
            WHERE reducedStreet ILIKE '%' || name || '%' AND texticregexeq(reducedStreet, '(?i)' || ws || name || '$');
        result.postDirAbbrev := abbrev FROM direction_lookup
            WHERE texticregexeq(reducedStreet, '(?i)' || ws || name || '$');
      END IF;
      tempString := substring(reducedStreet, '(?i)^(' || name
          || ')' || ws) FROM direction_lookup WHERE
           reducedStreet ILIKE '%' || name || '%' AND texticregexeq(reducedStreet, '(?i)^(' || name || ')' || ws)
          ORDER BY length(name) DESC;
      IF tempString IS NOT NULL THEN
        preDir := tempString;
        result.preDirAbbrev := abbrev FROM direction_lookup WHERE
             reducedStreet ILIKE '%' || name || '%' AND texticregexeq(reducedStreet, '(?i)(^' || name || ')' || ws)
            ORDER BY length(name) DESC;
        result.streetName := substring(reducedStreet, '(?i)^' || preDir || ws
                   || '+(.*?)(?:' || ws || '+' || cull_null(postDir) || '|$)');
      ELSE
        result.streetName := substring(reducedStreet, '(?i)^(.*?)(?:' || ws
                   || '+' || cull_null(postDir) || '|$)');
      END IF;
    ELSE

      -- If a post direction is given, then the location is everything after,
      -- the street name is everything before, less any pre direction.
      fullStreet := trim(fullStreet);
      tempInt := count(*) FROM direction_lookup
          WHERE fullStreet ILIKE '%' || name || '%' AND texticregexeq(fullStreet, '(?i)' || ws || name || '(?:'
              || ws || '|$)');

      IF tempInt = 1 THEN
        -- A single postDir candidate was found.  This makes it easier.
        postDir := substring(fullStreet, '(?i)' || ws || '('
            || name || ')(?:' || ws || '|$)') FROM direction_lookup WHERE
             fullStreet ILIKE '%' || name || '%' AND texticregexeq(fullStreet, '(?i)' || ws || name || '(?:'
            || ws || '|$)');
        result.postDirAbbrev := abbrev FROM direction_lookup
            WHERE fullStreet ILIKE '%' || name || '%' AND texticregexeq(fullStreet, '(?i)' || ws || name
            || '(?:' || ws || '|$)');
        IF result.location IS NULL THEN
          result.location := substring(fullStreet, '(?i)' || ws || postDir
                   || ws || '+(.*?)$');
        END IF;
        reducedStreet := substring(fullStreet, '^(.*?)' || ws || '+'
                      || postDir);
        tempString := substring(reducedStreet, '(?i)(^' || name
            || ')' || ws) FROM direction_lookup 
            WHERE
                reducedStreet ILIKE '%' || name || '%' AND texticregexeq(reducedStreet, '(?i)(^' || name || ')' || ws)
            ORDER BY length(name) DESC;
        IF tempString IS NOT NULL THEN
          preDir := tempString;
          result.preDirAbbrev := abbrev FROM direction_lookup WHERE
              reducedStreet ILIKE '%' || name || '%' AND texticregexeq(reducedStreet, '(?i)(^' || name || ')' || ws)
              ORDER BY length(name) DESC;
          result.streetName := trim(substring(reducedStreet, '^' || preDir || ws
                     || '+(.*)'));
        ELSE
          result.streetName := trim(reducedStreet);
        END IF;
      ELSIF tempInt > 1 THEN
        -- Multiple postDir candidates were found.  We need to find the last
        -- incident of a direction, but avoid getting the last word from
        -- a two word direction. eg extracting "East" from "North East"
        -- We do this by sorting by length, and taking the last direction
        -- in the results that is not included in an earlier one.
        -- This wont be a problem it preDir is North East and postDir is
        -- East as the regex requires a space before the direction.  Only
        -- the East will return from the preDir.
        tempInt := 0;
        FOR rec IN SELECT abbrev, substring(fullStreet, '(?i)' || ws || '('
            || name || ')(?:' || ws || '|$)') AS value
            FROM direction_lookup
            WHERE fullStreet ILIKE '%' || name || '%' AND texticregexeq(fullStreet, '(?i)' || ws || name
            || '(?:' || ws || '|$)')
            ORDER BY length(name) desc LOOP
          tempInt := 0;
          IF tempInt < position(rec.value in fullStreet) THEN
            IF postDir IS NULL THEN
              tempInt := position(rec.value in fullStreet);
              postDir := rec.value;
              result.postDirAbbrev := rec.abbrev;
            ELSIF NOT texticregexeq(postDir, '(?i)' || rec.value) THEN
              tempInt := position(rec.value in fullStreet);
              postDir := rec.value;
              result.postDirAbbrev := rec.abbrev;
             END IF;
          END IF;
        END LOOP;
        IF result.location IS NULL THEN
          result.location := substring(fullStreet, '(?i)' || ws || postDir || ws
                   || '+(.*?)$');
        END IF;
        reducedStreet := substring(fullStreet, '(?i)^(.*?)' || ws || '+'
                      || postDir);
        SELECT INTO tempString substring(reducedStreet, '(?i)(^' || name
            || ')' || ws) FROM direction_lookup WHERE
             reducedStreet ILIKE '%' || name || '%' AND  texticregexeq(reducedStreet, '(?i)(^' || name || ')' || ws)
            ORDER BY length(name) DESC;
        IF tempString IS NOT NULL THEN
          preDir := tempString;
          SELECT INTO result.preDirAbbrev abbrev FROM direction_lookup WHERE
              reducedStreet ILIKE '%' || name || '%' AND  texticregexeq(reducedStreet, '(?i)(^' || name || ')' || ws)
              ORDER BY length(name) DESC;
          result.streetName := substring(reducedStreet, '^' || preDir || ws
                     || '+(.*)');
        ELSE
          result.streetName := reducedStreet;
        END IF;
      ELSE

        -- There is no street type, directional suffix or internal address
        -- to allow distinction between street name and location.
        IF result.location IS NULL THEN
          IF debug_flag THEN
            raise notice 'fullStreet: %', fullStreet;
          END IF;

          result.location := location_extract(fullStreet, result.stateAbbrev);
          -- If the location was found, remove it from fullStreet
          IF result.location IS NOT NULL THEN
            fullStreet := substring(fullStreet, '(?i)(.*),' || ws || '+' ||
                result.location);
          END IF;
        END IF;

        -- Check for a direction prefix.
        SELECT INTO tempString substring(fullStreet, '(?i)(^' || name
            || ')' || ws) FROM direction_lookup WHERE
            texticregexeq(fullStreet, '(?i)(^' || name || ')' || ws)
            ORDER BY length(name);
        IF tempString IS NOT NULL THEN
          preDir := tempString;
          SELECT INTO result.preDirAbbrev abbrev FROM direction_lookup WHERE
              texticregexeq(fullStreet, '(?i)(^' || name || ')' || ws)
              ORDER BY length(name) DESC;
          IF result.location IS NOT NULL THEN
            -- The location may still be in the fullStreet, or may
            -- have been removed already
            result.streetName := substring(fullStreet, '^' || preDir || ws
                       || '+(.*?)(' || ws || '+' || result.location || '|$)');
          ELSE
            result.streetName := substring(fullStreet, '^' || preDir || ws
                       || '+(.*?)' || ws || '*');
          END IF;
        ELSE
          IF result.location IS NOT NULL THEN
            -- The location may still be in the fullStreet, or may
            -- have been removed already
            result.streetName := substring(fullStreet, '^(.*?)(' || ws
                       || '+' || result.location || '|$)');
          ELSE
            result.streetName := fullStreet;
          END IF;
        END IF;
      END IF;
    END IF;
  END IF;

 -- For address number only put numbers and stop if reach a non-number e.g. 123-456 will return 123
  result.address := to_number(substring(addressString, '[0-9]+'), '99999999999');
   --get rid of extraneous spaces before we return
  result.zip := trim(zipString);
  result.streetName := trim(result.streetName);
  result.location := trim(result.location);
  result.postDirAbbrev := trim(result.postDirAbbrev);
  result.parsed := TRUE;
  RETURN result;
END
$$
  LANGUAGE plpgsql STABLE
  COST 100;-- helper function to determine if street type 
-- should be put before or after the street name
-- note in streettype lookup this is misnamed as is_hw
-- because I originally thought only highways had that behavior
-- it applies to foreign influenced roads like Camino (for road)
CREATE OR REPLACE FUNCTION is_pretype(text) RETURNS boolean AS
$$
    SELECT EXISTS(SELECT name FROM street_type_lookup WHERE name = upper($1) AND is_hw );
$$
LANGUAGE sql IMMUTABLE STRICT; /** I know this should be stable but it's practically immutable :) **/

CREATE OR REPLACE FUNCTION pprint_addy(
    input NORM_ADDY
) RETURNS VARCHAR
AS $_$
DECLARE
  result VARCHAR;
BEGIN
  IF NOT input.parsed THEN
    RETURN NULL;
  END IF;

  result := cull_null(input.address::text)
         || COALESCE(' ' || input.preDirAbbrev, '')
         || CASE WHEN is_pretype(input.streetTypeAbbrev) THEN ' ' || input.streetTypeAbbrev  ELSE '' END
         || COALESCE(' ' || input.streetName, '')
         || CASE WHEN NOT is_pretype(input.streetTypeAbbrev) THEN ' ' || input.streetTypeAbbrev  ELSE '' END
         || COALESCE(' ' || input.postDirAbbrev, '')
         || CASE WHEN
              input.address IS NOT NULL OR
              input.streetName IS NOT NULL
              THEN ', ' ELSE '' END
         || cull_null(input.internal)
         || CASE WHEN input.internal IS NOT NULL THEN ', ' ELSE '' END
         || cull_null(input.location)
         || CASE WHEN input.location IS NOT NULL THEN ', ' ELSE '' END
         || COALESCE(input.stateAbbrev || ' ' , '')
         || cull_null(input.zip);

  RETURN trim(result);

END;
$_$ LANGUAGE plpgsql IMMUTABLE;
--$Id: other_helper_functions.sql 9324 2012-02-27 22:08:12Z pramsey $
 /*** 
 * 
 * Copyright (C) 2011 Regina Obe and Leo Hsu (Paragon Corporation)
 **/
-- Note we are wrapping this in a function so we can make it immutable and thus useable in an index
-- It also allows us to shorten and possibly better cache the repetitive pattern in the code 
-- greatest(to_number(b.fromhn,''99999999''),to_number(b.tohn,''99999999'')) 
-- and least(to_number(b.fromhn,''99999999''),to_number(b.tohn,''99999999''))
CREATE OR REPLACE FUNCTION least_hn(fromhn varchar, tohn varchar)
  RETURNS integer AS
$$ SELECT least(to_number( CASE WHEN trim($1) ~ '^[0-9]+$' THEN $1 ELSE '0' END,'9999999'),to_number(CASE WHEN trim($2) ~ '^[0-9]+$' THEN $2 ELSE '0' END,'9999999') )::integer;  $$
  LANGUAGE sql IMMUTABLE
  COST 200;
  
-- Note we are wrapping this in a function so we can make it immutable (for some reason least and greatest aren't considered immutable)
-- and thu useable in an index or cacheable for multiple calls
CREATE OR REPLACE FUNCTION greatest_hn(fromhn varchar, tohn varchar)
  RETURNS integer AS
$$ SELECT greatest(to_number( CASE WHEN trim($1) ~ '^[0-9]+$' THEN $1 ELSE '0' END,'99999999'),to_number(CASE WHEN trim($2) ~ '^[0-9]+$' THEN $2 ELSE '0' END,'99999999') )::integer;  $$
  LANGUAGE sql IMMUTABLE
  COST 200;
  
-- Returns an absolute difference between two zips
-- This is generally more efficient than doing levenshtein
-- Since when people get the wrong zip, its usually off by one or 2 numeric distance
-- We only consider the first 5 digits
CREATE OR REPLACE FUNCTION diff_zip(zip1 varchar, zip2 varchar)
  RETURNS integer AS
$$ SELECT abs(to_number( CASE WHEN trim(substring($1,1,5)) ~ '^[0-9]+$' THEN $1 ELSE '0' END,'99999')::integer - to_number( CASE WHEN trim(substring($2,1,5)) ~ '^[0-9]+$' THEN $2 ELSE '0' END,'99999')::integer )::integer;  $$
  LANGUAGE sql IMMUTABLE STRICT
  COST 200;
  
-- function return  true or false if 2 numeric streets are equal such as 15th St, 23rd st
-- it compares just the numeric part of the street for equality
-- PURPOSE: handle bad formats such as 23th St so 23th St = 23rd St
-- as described in: http://trac.osgeo.org/postgis/ticket/1068
-- This will always return false if one of the streets is not a numeric street
-- By numeric it must start with numbers (allow fractions such as 1/2 and spaces such as 12 1/2th) and be less than 10 characters
CREATE OR REPLACE FUNCTION numeric_streets_equal(input_street varchar, output_street varchar)
    RETURNS boolean AS
$$
    SELECT COALESCE(length($1) < 10 AND length($2) < 10 
            AND $1 ~ E'^[0-9\/\s]+' AND $2 ~ E'^[0-9\/\s]+' 
            AND  trim(substring($1, E'^[0-9\/\s]+')) = trim(substring($2, E'^[0-9\/\s]+')), false); 
$$
LANGUAGE sql IMMUTABLE
COST 5;


-- Generate script to drop all non-primary unique indexes on tiger and tiger_data tables
CREATE OR REPLACE FUNCTION drop_indexes_generate_script(tiger_data_schema text DEFAULT 'tiger_data')
RETURNS text AS
$$
SELECT array_to_string(ARRAY(SELECT 'DROP INDEX ' || schemaname || '.' || indexname || ';' 
FROM pg_catalog.pg_indexes  where schemaname IN('tiger',$1)  AND indexname NOT LIKE 'uidx%' AND indexname NOT LIKE 'pk_%' AND indexname NOT LIKE '%key'), E'\n');
$$
LANGUAGE sql STABLE;
-- Generate script to create missing indexes in tiger tables. 
-- This will generate sql you can run to index commonly used join columns in geocoder for tiger and tiger_data schemas --
CREATE OR REPLACE FUNCTION missing_indexes_generate_script()
RETURNS text AS
$$
SELECT array_to_string(ARRAY(
-- create unique index on faces for tfid seems to perform better --
SELECT 'CREATE UNIQUE INDEX uidx_' || c.table_schema || '_' || c.table_name || '_' || c.column_name || ' ON ' || c.table_schema || '.' || c.table_name || ' USING btree(' || c.column_name || ');' As index
FROM (SELECT table_name, table_schema  FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE') As t  INNER JOIN
	(SELECT * FROM information_schema.columns WHERE column_name IN('tfid') ) AS c  
		ON (t.table_name = c.table_name AND t.table_schema = c.table_schema)
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = c.table_name AND i.schemaname = c.table_schema 
				AND  indexname LIKE 'uidx%' || c.column_name || '%' ) 
WHERE i.tablename IS NULL AND c.table_schema IN('tiger','tiger_data') AND c.table_name LIKE '%faces'
UNION ALL
-- basic btree regular indexes
SELECT 'CREATE INDEX idx_' || c.table_schema || '_' || c.table_name || '_' || c.column_name || ' ON ' || c.table_schema || '.' || c.table_name || ' USING btree(' || c.column_name || ');' As index
FROM (SELECT table_name, table_schema  FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE') As t  INNER JOIN
	(SELECT * FROM information_schema.columns WHERE column_name IN('countyfp', 'tlid', 'tfidl', 'tfidr', 'tfid', 'zip', 'placefp', 'cousubfp') ) AS c  
		ON (t.table_name = c.table_name AND t.table_schema = c.table_schema)
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = c.table_name AND i.schemaname = c.table_schema 
				AND  indexdef LIKE '%' || c.column_name || '%' ) 
WHERE i.tablename IS NULL AND c.table_schema IN('tiger','tiger_data')  AND (NOT c.table_name LIKE '%faces')
-- Gist spatial indexes --
UNION ALL
SELECT 'CREATE INDEX idx_' || c.table_schema || '_' || c.table_name || '_' || c.column_name || '_gist ON ' || c.table_schema || '.' || c.table_name || ' USING gist(' || c.column_name || ');' As index
FROM (SELECT table_name, table_schema FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE') As t  INNER JOIN
	(SELECT * FROM information_schema.columns WHERE column_name IN('the_geom', 'geom') ) AS c  
		ON (t.table_name = c.table_name AND t.table_schema = c.table_schema)
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = c.table_name AND i.schemaname = c.table_schema 
				AND  indexdef LIKE '%' || c.column_name || '%') 
WHERE i.tablename IS NULL AND c.table_schema IN('tiger','tiger_data')
-- Soundex indexes --
UNION ALL
SELECT 'CREATE INDEX idx_' || c.table_schema || '_' || c.table_name || '_snd_' || c.column_name || ' ON ' || c.table_schema || '.' || c.table_name || ' USING btree(soundex(' || c.column_name || '));' As index
FROM (SELECT table_name, table_schema FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE') As t  INNER JOIN
	(SELECT * FROM information_schema.columns WHERE column_name IN('name', 'place', 'city') ) AS c  
		ON (t.table_name = c.table_name AND t.table_schema = c.table_schema)
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = c.table_name AND i.schemaname = c.table_schema 
				AND  indexdef LIKE '%soundex(%' || c.column_name || '%' AND indexdef LIKE '%_snd_' || c.column_name || '%' ) 
WHERE i.tablename IS NULL AND c.table_schema IN('tiger','tiger_data') 
    AND (c.table_name LIKE '%county%' OR c.table_name LIKE '%featnames'
    OR c.table_name  LIKE '%place' or c.table_name LIKE '%zip%'  or c.table_name LIKE '%cousub') 
-- Lower indexes --
UNION ALL
SELECT 'CREATE INDEX idx_' || c.table_schema || '_' || c.table_name || '_lower_' || c.column_name || ' ON ' || c.table_schema || '.' || c.table_name || ' USING btree(lower(' || c.column_name || '));' As index
FROM (SELECT table_name, table_schema FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE') As t  INNER JOIN
	(SELECT * FROM information_schema.columns WHERE column_name IN('name', 'place', 'city') ) AS c  
		ON (t.table_name = c.table_name AND t.table_schema = c.table_schema)
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = c.table_name AND i.schemaname = c.table_schema 
				AND  indexdef LIKE '%btree%(%lower(%' || c.column_name || '%') 
WHERE i.tablename IS NULL AND c.table_schema IN('tiger','tiger_data') 
    AND (c.table_name LIKE '%county%' OR c.table_name LIKE '%featnames' OR c.table_name  LIKE '%place' or c.table_name LIKE '%zip%' or c.table_name LIKE '%cousub') 
-- Least address index btree least_hn(fromhn, tohn)
UNION ALL
SELECT 'CREATE INDEX idx_' || c.table_schema || '_' || c.table_name || '_least_address' || ' ON ' || c.table_schema || '.' || c.table_name || ' USING btree(least_hn(fromhn, tohn));' As index
FROM (SELECT table_name, table_schema FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE' AND table_name LIKE '%addr' AND table_schema IN('tiger','tiger_data')) As t  INNER JOIN
	(SELECT * FROM information_schema.columns WHERE column_name IN('fromhn') ) AS c  
		ON (t.table_name = c.table_name AND t.table_schema = c.table_schema)
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = c.table_name AND i.schemaname = c.table_schema 
				AND  indexdef LIKE '%least_hn(%' || c.column_name || '%') 
WHERE i.tablename IS NULL
-- var_ops lower --
UNION ALL
SELECT 'CREATE INDEX idx_' || c.table_schema || '_' || c.table_name || '_l' || c.column_name || '_var_ops' || ' ON ' || c.table_schema || '.' || c.table_name || ' USING btree(lower(' || c.column_name || ') varchar_pattern_ops);' As index
FROM (SELECT table_name, table_schema FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE' AND (table_name LIKE '%featnames' or table_name LIKE '%place' or table_name LIKE '%zip_lookup_base' or table_name LIKE '%zip_state_loc') AND table_schema IN('tiger','tiger_data')) As t  INNER JOIN
	(SELECT * FROM information_schema.columns WHERE column_name IN('name', 'city', 'place', 'fullname') ) AS c  
		ON (t.table_name = c.table_name AND t.table_schema = c.table_schema)
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = c.table_name AND i.schemaname = c.table_schema 
				AND  indexdef LIKE '%btree%(%lower%' || c.column_name || ')%varchar_pattern_ops%') 
WHERE i.tablename IS NULL
-- var_ops mtfcc --
/** UNION ALL
SELECT 'CREATE INDEX idx_' || c.table_schema || '_' || c.table_name || '_' || c.column_name || '_var_ops' || ' ON ' || c.table_schema || '.' || c.table_name || ' USING btree(' || c.column_name || ' varchar_pattern_ops);' As index
FROM (SELECT table_name, table_schema FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE' AND (table_name LIKE '%featnames' or table_name LIKE '%edges') AND table_schema IN('tiger','tiger_data')) As t  INNER JOIN
	(SELECT * FROM information_schema.columns WHERE column_name IN('mtfcc') ) AS c  
		ON (t.table_name = c.table_name AND t.table_schema = c.table_schema)
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = c.table_name AND i.schemaname = c.table_schema 
				AND  indexdef LIKE '%btree%(' || c.column_name || '%varchar_pattern_ops%') 
WHERE i.tablename IS NULL **/
-- zipl zipr on edges --
UNION ALL
SELECT 'CREATE INDEX idx_' || c.table_schema || '_' || c.table_name || '_' || c.column_name || ' ON ' || c.table_schema || '.' || c.table_name || ' USING btree(' || c.column_name || ' );' As index
FROM (SELECT table_name, table_schema FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE' AND table_name LIKE '%edges' AND table_schema IN('tiger','tiger_data')) As t  INNER JOIN
	(SELECT * FROM information_schema.columns WHERE column_name IN('zipl', 'zipr') ) AS c  
		ON (t.table_name = c.table_name AND t.table_schema = c.table_schema)
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = c.table_name AND i.schemaname = c.table_schema 
				AND  indexdef LIKE '%btree%(' || c.column_name || '%)%') 
WHERE i.tablename IS NULL

-- unique index on tlid state county --
/*UNION ALL
SELECT 'CREATE UNIQUE INDEX uidx_' || t.table_schema || '_' || t.table_name || '_tlid_statefp_countyfp ON ' || t.table_schema || '.' || t.table_name || ' USING btree(tlid,statefp,countyfp);' As index
FROM (SELECT table_name, table_schema FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE' AND table_name LIKE '%edges' AND table_schema IN('tiger','tiger_data')) As t  
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = t.table_name AND i.schemaname = t.table_schema 
				AND  indexdef LIKE '%btree%(%tlid,%statefp%countyfp%)%') 
WHERE i.tablename IS NULL*/
--full text indexes on name field--
/**UNION ALL
SELECT 'CREATE INDEX idx_' || c.table_schema || '_' || c.table_name || '_fullname_ft_gist' || ' ON ' || c.table_schema || '.' || c.table_name || ' USING gist(to_tsvector(''english'',fullname))' As index
FROM (SELECT table_name, table_schema FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE' AND table_name LIKE '%featnames' AND table_schema IN('tiger','tiger_data')) As t  INNER JOIN
	(SELECT * FROM information_schema.columns WHERE column_name IN('fullname') ) AS c  
		ON (t.table_name = c.table_name AND t.table_schema = c.table_schema)
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = c.table_name AND i.schemaname = c.table_schema 
				AND  indexdef LIKE '%to_tsvector(%' || c.column_name || '%') 
WHERE i.tablename IS NULL **/

-- trigram index --
/**UNION ALL
SELECT 'CREATE INDEX idx_' || c.table_schema || '_' || c.table_name || '_' || c.column_name || '_trgm_gist' || ' ON ' || c.table_schema || '.' || c.table_name || ' USING gist(' || c.column_name || ' gist_trgm_ops);' As index
FROM (SELECT table_name, table_schema FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE' AND table_name LIKE '%featnames' AND table_schema IN('tiger','tiger_data')) As t  INNER JOIN
	(SELECT * FROM information_schema.columns WHERE column_name IN('fullname', 'name') ) AS c  
		ON (t.table_name = c.table_name AND t.table_schema = c.table_schema)
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = c.table_name AND i.schemaname = c.table_schema 
				AND  indexdef LIKE '%gist%(' || c.column_name || '%gist_trgm_ops%') 
WHERE i.tablename IS NULL **/ 
ORDER BY 1), E'\r');
$$
LANGUAGE sql VOLATILE;


CREATE OR REPLACE FUNCTION install_missing_indexes() RETURNS boolean
AS
$$
DECLARE var_sql text = missing_indexes_generate_script();
BEGIN
	EXECUTE(var_sql);
	RETURN true;
END
$$
language plpgsql;


CREATE OR REPLACE FUNCTION drop_dupe_featnames_generate_script() RETURNS text 
AS
$$

SELECT array_to_string(ARRAY(SELECT 'CREATE TEMPORARY TABLE dup AS
SELECT min(f.gid) As min_gid, f.tlid, lower(f.fullname) As fname
	FROM ONLY ' || t.table_schema || '.' || t.table_name || ' As f
	GROUP BY f.tlid, lower(f.fullname) 
	HAVING count(*) > 1;
	
DELETE FROM ' || t.table_schema || '.' || t.table_name || ' AS feat
WHERE EXISTS (SELECT tlid FROM dup WHERE feat.tlid = dup.tlid AND lower(feat.fullname) = dup.fname
		AND feat.gid > dup.min_gid);
DROP TABLE dup;
CREATE INDEX idx_' || t.table_schema || '_' || t.table_name || '_tlid ' || ' ON ' || t.table_schema || '.' || t.table_name || ' USING btree(tlid); 
' As drop_sql_create_index
FROM (SELECT table_name, table_schema FROM 
	information_schema.tables WHERE table_type = 'BASE TABLE' AND (table_name LIKE '%featnames' ) AND table_schema IN('tiger','tiger_data')) As t 
		LEFT JOIN pg_catalog.pg_indexes i ON 
			(i.tablename = t.table_name AND i.schemaname = t.table_schema 
				AND  indexdef LIKE '%btree%(%tlid%') 
WHERE i.tablename IS NULL) ,E'\r');

$$
LANGUAGE sql VOLATILE;

--DROP FUNCTION IF EXISTS zip_range(text,integer,integer);
-- Helper function that useful for catch slight mistakes in zip position given a 5 digit zip code
-- will return a range of zip codes that are between zip - num_before and zip - num_after
-- e.g. usage -> zip_range('02109', -1,+1) -> {'02108', '02109', '02110'}
CREATE OR REPLACE FUNCTION zip_range(zip text, range_start integer, range_end integer) RETURNS varchar[] AS
$$
   SELECT ARRAY(
        SELECT lpad((to_number( CASE WHEN trim(substring($1,1,5)) ~ '^[0-9]+$' THEN $1 ELSE '0' END,'99999')::integer + i)::text, 5, '0')::varchar
        FROM generate_series($2, $3) As i );
$$
LANGUAGE sql IMMUTABLE STRICT;--$Id: rate_attributes.sql 9324 2012-02-27 22:08:12Z pramsey $
-- rate_attributes(dirpA, dirpB, streetNameA, streetNameB, streetTypeA,
-- streetTypeB, dirsA, dirsB, locationA, locationB)
-- Rates the street based on the given attributes.  The locations must be
-- non-null.  The other eight values are handled by the other rate_attributes
-- function, so it's requirements must also be met.
-- changed: 2010-10-18 Regina Obe - all references to verbose to var_verbose since causes compile errors in 9.0
-- changed: 2011-06-25 revise to use real named args and fix direction rating typo
CREATE OR REPLACE FUNCTION rate_attributes(dirpA VARCHAR, dirpB VARCHAR, streetNameA VARCHAR, streetNameB VARCHAR,
    streetTypeA VARCHAR, streetTypeB VARCHAR, dirsA VARCHAR, dirsB VARCHAR,  locationA VARCHAR, locationB VARCHAR, prequalabr VARCHAR) RETURNS INTEGER
AS $_$
DECLARE
--$Id: rate_attributes.sql 9324 2012-02-27 22:08:12Z pramsey $
  result INTEGER := 0;
  locationWeight INTEGER := 14;
  var_verbose BOOLEAN := FALSE;
BEGIN
  IF locationA IS NOT NULL AND locationB IS NOT NULL THEN
    result := levenshtein_ignore_case(locationA, locationB);
  ELSE
    IF var_verbose THEN
      RAISE NOTICE 'rate_attributes() - Location names cannot be null!';
    END IF;
    RETURN NULL;
  END IF;
  result := result + rate_attributes($1, $2, streetNameA, streetNameB, $5, $6, $7, $8,prequalabr);
  RETURN result;
END;
$_$ LANGUAGE plpgsql IMMUTABLE;

-- rate_attributes(dirpA, dirpB, streetNameA, streetNameB, streetTypeA,
-- streetTypeB, dirsA, dirsB)
-- Rates the street based on the given attributes.  Only streetNames are
-- required.  If any others are null (either A or B) they are treated as
-- empty strings.
CREATE OR REPLACE FUNCTION rate_attributes(dirpA VARCHAR, dirpB VARCHAR, streetNameA VARCHAR, streetNameB VARCHAR,
    streetTypeA VARCHAR, streetTypeB VARCHAR, dirsA VARCHAR, dirsB VARCHAR, prequalabr VARCHAR) RETURNS INTEGER
AS $_$
DECLARE
  result INTEGER := 0;
  directionWeight INTEGER := 2;
  nameWeight INTEGER := 10;
  typeWeight INTEGER := 5;
  var_verbose BOOLEAN := false;
BEGIN
  result := result + levenshtein_ignore_case(cull_null($1), cull_null($2)) * directionWeight;
  IF var_verbose THEN
    RAISE NOTICE 'streetNameA: %, streetNameB: %', streetNameA, streetNameB;
  END IF;
  IF streetNameA IS NOT NULL AND streetNameB IS NOT NULL THEN
    -- We want to treat numeric streets that have numerics as equal 
    -- and not penalize if they are spelled different e.g. have ND instead of TH
    IF NOT numeric_streets_equal(streetNameA, streetNameB) THEN
        IF prequalabr IS NOT NULL THEN
            -- If the reference address (streetNameB) has a prequalabr streetNameA (prequalabr) - note: streetNameB usually comes thru without prequalabr
            -- and the input street (streetNameA) is lacking the prequal -- only penalize a little
            result := (result + levenshtein_ignore_case( trim( trim( lower(streetNameA),lower(prequalabr) ) ), trim( trim( lower(streetNameB),lower(prequalabr) ) ) )*nameWeight*0.75 + levenshtein_ignore_case(trim(streetNameA),prequalabr || ' ' ||  streetNameB) * nameWeight*0.25)::integer;
        ELSE
            result := result + levenshtein_ignore_case(streetNameA, streetNameB) * nameWeight;
        END IF;
    ELSE 
    -- Penalize for numeric streets if one is completely numeric and the other is not
    -- This is to minimize on highways like 3A being matched with numbered streets since streets are usually number followed by 2 characters e.g nth ave and highways are just number with optional letter for name
        IF  (streetNameB ~ E'[a-zA-Z]{2,10}' AND NOT (streetNameA ~ E'[a-zA-Z]{2,10}') ) OR (streetNameA ~ E'[a-zA-Z]{2,10}' AND NOT (streetNameB ~ E'[a-zA-Z]{2,10}') ) THEN
            result := result + levenshtein_ignore_case(streetNameA, streetNameB) * nameWeight;
        END IF;
    END IF;
  ELSE
    IF var_verbose THEN
      RAISE NOTICE 'rate_attributes() - Street names cannot be null!';
    END IF;
    RETURN NULL;
  END IF;
  result := result + levenshtein_ignore_case(cull_null(streetTypeA), cull_null(streetTypeB)) *
      typeWeight;
  result := result + levenshtein_ignore_case(cull_null(dirsA), cull_null(dirsB)) *
      directionWeight;
  return result;
END;
$_$ LANGUAGE plpgsql IMMUTABLE;
--$Id: includes_address.sql 9324 2012-02-27 22:08:12Z pramsey $
-- This function requires the addresses to be grouped, such that the second and
-- third arguments are from one side of the street, and the fourth and fifth
-- from the other.
CREATE OR REPLACE FUNCTION includes_address(
    given_address INTEGER,
    addr1 INTEGER,
    addr2 INTEGER,
    addr3 INTEGER,
    addr4 INTEGER
) RETURNS BOOLEAN
AS $_$
DECLARE
  lmaxaddr INTEGER := -1;
  rmaxaddr INTEGER := -1;
  lminaddr INTEGER := -1;
  rminaddr INTEGER := -1;
  maxaddr INTEGER := -1;
  minaddr INTEGER := -1;
  verbose BOOLEAN := false;
BEGIN
  IF addr1 IS NOT NULL THEN
    maxaddr := addr1;
    minaddr := addr1;
    lmaxaddr := addr1;
    lminaddr := addr1;
  END IF;

  IF addr2 IS NOT NULL THEN
    IF addr2 < minaddr OR minaddr = -1 THEN
      minaddr := addr2;
    END IF;
    IF addr2 > maxaddr OR maxaddr = -1 THEN
      maxaddr := addr2;
    END IF;
    IF addr2 > lmaxaddr OR lmaxaddr = -1 THEN
      lmaxaddr := addr2;
    END IF;
    IF addr2 < lminaddr OR lminaddr = -1 THEN
      lminaddr := addr2;
    END IF;
  END IF;

  IF addr3 IS NOT NULL THEN
    IF addr3 < minaddr OR minaddr = -1 THEN
      minaddr := addr3;
    END IF;
    IF addr3 > maxaddr OR maxaddr = -1 THEN
      maxaddr := addr3;
    END IF;
    rmaxaddr := addr3;
    rminaddr := addr3;
  END IF;

  IF addr4 IS NOT NULL THEN
    IF addr4 < minaddr OR minaddr = -1 THEN
      minaddr := addr4;
    END IF;
    IF addr4 > maxaddr OR maxaddr = -1 THEN
      maxaddr := addr4;
    END IF;
    IF addr4 > rmaxaddr OR rmaxaddr = -1 THEN
      rmaxaddr := addr4;
    END IF;
    IF addr4 < rminaddr OR rminaddr = -1 THEN
      rminaddr := addr4;
    END IF;
  END IF;

  IF minaddr = -1 OR maxaddr = -1 THEN
    -- No addresses were non-null, return FALSE (arbitrary)
    RETURN FALSE;
  ELSIF given_address >= minaddr AND given_address <= maxaddr THEN
    -- The address is within the given range
    IF given_address >= lminaddr AND given_address <= lmaxaddr THEN
      -- This checks to see if the address is on this side of the
      -- road, ie if the address is even, the street range must be even
      IF (given_address % 2) = (lminaddr % 2)
          OR (given_address % 2) = (lmaxaddr % 2) THEN
        RETURN TRUE;
      END IF;
    END IF;
    IF given_address >= rminaddr AND given_address <= rmaxaddr THEN
      -- See above
      IF (given_address % 2) = (rminaddr % 2)
          OR (given_address % 2) = (rmaxaddr % 2) THEN
        RETURN TRUE;
      END IF;
    END IF;
  END IF;
  -- The address is not within the range
  RETURN FALSE;
END;
$_$ LANGUAGE plpgsql IMMUTABLE COST 100;
-- interpolate_from_address(local_address, from_address_l, to_address_l, from_address_r, to_address_r, local_road)
-- This function returns a point along the given geometry (must be linestring)
-- corresponding to the given address.  If the given address is not within
-- the address range of the road, null is returned.
-- This function requires that the address be grouped, such that the second and
-- third arguments are from one side of the street, while the fourth and
-- fifth are from the other.
-- in_side Side of street -- either 'L', 'R' or if blank ignores side of road
-- in_offset_m -- number of meters offset to the side
CREATE OR REPLACE FUNCTION interpolate_from_address(given_address INTEGER, in_addr1 VARCHAR, in_addr2 VARCHAR, in_road GEOMETRY, 
	in_side VARCHAR DEFAULT '',in_offset_m float DEFAULT 10) RETURNS GEOMETRY
AS $_$
DECLARE
  addrwidth INTEGER;
  part DOUBLE PRECISION;
  road GEOMETRY;
  result GEOMETRY;
  var_addr1 INTEGER; var_addr2 INTEGER;
  center_pt GEOMETRY; cl_pt GEOMETRY;
  npos integer;
  delx float; dely float;  x0 float; y0 float; x1 float; y1 float; az float;
  var_dist float; dir integer;
BEGIN
    IF in_road IS NULL THEN
        RETURN NULL;
    END IF;
    
	var_addr1 := to_number(in_addr1, '999999');
	var_addr2 := to_number(in_addr2, '999999');

    IF geometrytype(in_road) = 'LINESTRING' THEN
      road := ST_Transform(in_road, utmzone(ST_StartPoint(in_road)) );
    ELSIF geometrytype(in_road) = 'MULTILINESTRING' THEN
    	road := ST_GeometryN(in_road,1);
    	road := ST_Transform(road, utmzone(ST_StartPoint(road)) );
    ELSE
      RETURN NULL;
    END IF;

    addrwidth := greatest(var_addr1,var_addr2) - least(var_addr1,var_addr2);
    IF addrwidth = 0 or addrwidth IS NULL THEN
        addrwidth = 1;
    END IF;
    part := (given_address - least(var_addr1,var_addr2)) / trunc(addrwidth, 1);

    IF var_addr1 > var_addr2 THEN
        part := 1 - part;
    END IF;

    IF part < 0 OR part > 1 OR part IS NULL THEN
        part := 0.5;
    END IF;

    center_pt = ST_Line_Interpolate_Point(road, part);
    IF in_side > '' AND in_offset_m > 0 THEN
    /** Compute point the point to the in_side of the geometry **/
    /**Take into consideration non-straight so we consider azimuth 
    	of the 2 points that straddle the center location**/ 
    	IF part = 0 THEN
    		az := ST_Azimuth (ST_StartPoint(road), ST_PointN(road,2));
    	ELSIF part = 1 THEN
    		az := ST_Azimuth (ST_PointN(road,ST_NPoints(road) - 1), ST_EndPoint(road));
    	ELSE 
    		/** Find the largest nth point position that is before the center point
    			This will be the start of our azimuth calc **/
    		SELECT i INTO npos
    			FROM generate_series(1,ST_NPoints(road)) As i 
    					WHERE part > ST_Line_Locate_Point(road,ST_PointN(road,i)) 
    					ORDER BY i DESC;
    		IF npos < ST_NPoints(road) THEN				
    			az := ST_Azimuth (ST_PointN(road,npos), ST_PointN(road, npos + 1));
    		ELSE
    			az := ST_Azimuth (center_pt, ST_PointN(road, npos));
    		END IF;
    	END IF;
    	
        dir := CASE WHEN az < pi() THEN -1 ELSE 1 END;
        --dir := 1;
        var_dist := in_offset_m*CASE WHEN in_side = 'L' THEN -1 ELSE 1 END;
        delx := ABS(COS(az)) * var_dist * dir;
        dely := ABS(SIN(az)) * var_dist * dir;
        IF az > pi()/2 AND az < pi() OR az > 3 * pi()/2 THEN
			result := ST_Translate(center_pt, delx, dely) ;
		ELSE
			result := ST_Translate(center_pt, -delx, dely);
		END IF;
    ELSE
    	result := center_pt;
    END IF;
    result :=  ST_Transform(result, ST_SRID(in_road));
    --RAISE NOTICE 'start: %, center: %, new: %, side: %, offset: %, az: %', ST_AsText(ST_Transform(ST_StartPoint(road),ST_SRID(in_road))), ST_AsText(ST_Transform(center_pt,ST_SRID(in_road))),ST_AsText(result), in_side, in_offset_m, az;
    RETURN result;
END;
$_$ LANGUAGE plpgsql IMMUTABLE COST 10;
--$Id: geocode_address.sql 10310 2012-09-20 13:32:14Z robe $
--DROP FUNCTION IF EXISTS geocode_address(norm_addy, integer , geometry);
CREATE OR REPLACE FUNCTION geocode_address(IN parsed norm_addy, max_results integer DEFAULT 10, restrict_geom geometry DEFAULT NULL, OUT addy norm_addy, OUT geomout geometry, OUT rating integer)
  RETURNS SETOF record AS
$$
DECLARE
  results RECORD;
  zip_info RECORD;
  stmt VARCHAR;
  in_statefp VARCHAR;
  exact_street boolean := false;
  var_debug boolean := get_geocode_setting('debug_geocode_address')::boolean;
  var_sql text := '';
  var_n integer := 0;
  var_restrict_geom geometry := NULL;
  var_bfilter text := null;
  var_bestrating integer := NULL;
BEGIN
  IF parsed.streetName IS NULL THEN
    -- A street name must be given.  Think about it.
    RETURN;
  END IF;

  ADDY.internal := parsed.internal;

  IF parsed.stateAbbrev IS NOT NULL THEN
    in_statefp := statefp FROM state_lookup As s WHERE s.abbrev = parsed.stateAbbrev;
  END IF;
  
  IF in_statefp IS NULL THEN 
  --if state is not provided or was bogus, just pick the first where the zip is present
    in_statefp := statefp FROM zip_lookup_base WHERE zip = substring(parsed.zip,1,5) LIMIT 1;
  END IF;
  
  IF restrict_geom IS NOT NULL THEN
  		IF ST_SRID(restrict_geom) < 1 OR ST_SRID(restrict_geom) = 4236 THEN 
  		-- basically has no srid or if wgs84 close enough to NAD 83 -- assume same as data
  			var_restrict_geom = ST_SetSRID(restrict_geom,4269);
  		ELSE
  		--transform and snap
  			var_restrict_geom = ST_SnapToGrid(ST_Transform(restrict_geom, 4269), 0.000001);
  		END IF;
  END IF;
  var_bfilter := ' SELECT zcta5ce FROM zcta5 AS zc  
                    WHERE zc.statefp = ' || quote_nullable(in_statefp) || ' 
                        AND ST_Intersects(zc.the_geom, ' || quote_literal(var_restrict_geom::text) || '::geometry)  ' ;

  SELECT NULL::varchar[] As zip INTO zip_info;
 
  IF parsed.zip IS NOT NULL  THEN
  -- Create an array of 5 zips containing 2 before and 2 after our target if our streetName is longer
    IF length(parsed.streetName) > 7 THEN
        SELECT zip_range(parsed.zip, -2, 2) As zip INTO zip_info;
    ELSE
    -- If our street name is short, we'll run into many false positives so reduce our zip window a bit
        SELECT zip_range(parsed.zip, -1, 1) As zip INTO zip_info;
    END IF;
    --This signals bad zip input, only use the range if it falls in the place zip range
    IF length(parsed.zip) != 5 AND parsed.location IS NOT NULL THEN 
         stmt := 'SELECT ARRAY(SELECT DISTINCT zip
          FROM zip_lookup_base AS z
         WHERE z.statefp = $1
               AND  z.zip = ANY($3) AND lower(z.city) LIKE lower($2) || ''%''::text '  || COALESCE(' AND z.zip IN(' || var_bfilter || ')', '') || ')::varchar[] AS zip ORDER BY zip' ;
         EXECUTE stmt INTO zip_info USING in_statefp, parsed.location, zip_info.zip;
         IF var_debug THEN
            RAISE NOTICE 'Bad zip newzip range: %', quote_nullable(zip_info.zip);
         END IF;
        IF array_upper(zip_info.zip,1) = 0 OR array_upper(zip_info.zip,1) IS NULL THEN
        -- zips do not fall in city ignore them
            IF var_debug THEN
                RAISE NOTICE 'Ignore new zip range that is bad too: %', quote_nullable(zip_info.zip);
            END IF;
            zip_info.zip = NULL::varchar[];
        END IF;
    END IF;
  END IF;
  IF zip_info.zip IS NULL THEN
  -- If no good zips just include all for the location
  -- We do a like instead of absolute check since tiger sometimes tacks things like Town at end of places
    stmt := 'SELECT ARRAY(SELECT DISTINCT zip
          FROM zip_lookup_base AS z
         WHERE z.statefp = $1
               AND  lower(z.city) LIKE lower($2) || ''%''::text '  || COALESCE(' AND z.zip IN(' || var_bfilter || ')', '') || ')::varchar[] AS zip ORDER BY zip' ;
    EXECUTE stmt INTO zip_info USING in_statefp, parsed.location;
    IF var_debug THEN
        RAISE NOTICE 'Zip range based on only considering city: %', quote_nullable(zip_info.zip);
    END IF;
  END IF;
   -- Brute force -- try to find perfect matches and exit if we have one
   -- we first pull all the names in zip and rank by if zip matches input zip and streetname matches street
  stmt := 'WITH a AS
  	( SELECT * 
  		FROM (SELECT f.*, ad.side, ad.zip, ad.fromhn, ad.tohn,
  					RANK() OVER(ORDER BY ' || CASE WHEN parsed.zip > '' THEN ' diff_zip(ad.zip,$7) + ' ELSE '' END
						||' CASE WHEN lower(f.name) = lower($2) THEN 0 ELSE levenshtein_ignore_case(f.name, lower($2) )  END + 
						levenshtein_ignore_case(f.fullname, lower($2 || '' '' || COALESCE($4,'''')) ) 
						+ CASE WHEN (greatest_hn(ad.fromhn,ad.tohn) % 2)::integer = ($1 % 2)::integer THEN 0 ELSE 1 END
						+ CASE WHEN $1::integer BETWEEN least_hn(ad.fromhn,ad.tohn) AND greatest_hn(ad.fromhn, ad.tohn) 
							THEN 0 ELSE 4 END 
							+ CASE WHEN lower($4) = lower(f.suftypabrv) OR lower($4) = lower(f.pretypabrv) THEN 0 ELSE 1 END
							+ rate_attributes($5, f.predirabrv,'
         || '    $2,  f.name , $4,'
         || '    suftypabrv , $6,'
         || '    sufdirabrv, prequalabr)  
							)
						As rank
                		FROM featnames As f INNER JOIN addr As ad ON (f.tlid = ad.tlid) 
                    WHERE $10 = f.statefp AND $10 = ad.statefp 
                    	'
                    || CASE WHEN length(parsed.streetName) > 5  THEN ' AND (lower(f.fullname) LIKE (COALESCE($5 || '' '','''') || lower($2) || ''%'')::text OR lower(f.name) = lower($2) OR soundex(f.name) = soundex($2) ) ' ELSE  ' AND lower(f.name) = lower($2) ' END 
                    || CASE WHEN zip_info.zip IS NOT NULL THEN '    AND ( ad.zip = ANY($9::varchar[]) )  ' ELSE '' END 
            || ' ) AS foo ORDER BY rank LIMIT ' || max_results*3 || ' ) 
  	SELECT * FROM ( 
    SELECT DISTINCT ON (sub.predirabrv,sub.fename,COALESCE(sub.suftypabrv, sub.pretypabrv) ,sub.sufdirabrv,sub.place,s.stusps,sub.zip)'
         || '    sub.predirabrv   as fedirp,'
         || '    sub.fename,'
         || '    COALESCE(sub.suftypabrv, sub.pretypabrv)   as fetype,'
         || '    sub.sufdirabrv   as fedirs,'
         || '    sub.place ,'
         || '    s.stusps as state,'
         || '    sub.zip as zip,'
         || '    interpolate_from_address($1, sub.fromhn,'
         || '        sub.tohn, sub.the_geom, sub.side) as address_geom,'
         || '       sub.sub_rating + '
         || CASE WHEN parsed.zip > '' THEN '  least(coalesce(diff_zip($7 , sub.zip),0), 10)::integer  '
            ELSE '1' END::text 
         || ' + coalesce(levenshtein_ignore_case($3, sub.place),5)'
         || '    as sub_rating,'
         || '    sub.exact_address as exact_address, sub.tohn, sub.fromhn '
         || ' FROM ('
         || '  SELECT tlid, predirabrv, COALESCE(b.prequalabr || '' '','''' ) || b.name As fename, suftypabrv, sufdirabrv, fromhn, tohn, 
                    side,  zip, rate_attributes($5, predirabrv,'
         || '    $2,  b.name , $4,'
         || '    suftypabrv , $6,'
         || '    sufdirabrv, prequalabr) + '
         || '    CASE '
         || '        WHEN $1::integer IS NULL OR b.fromhn IS NULL THEN 20'
         || '        WHEN $1::integer >= least_hn(b.fromhn, b.tohn) '
         || '            AND $1::integer <= greatest_hn(b.fromhn,b.tohn)'
         || '            AND ($1::integer % 2) = (to_number(b.fromhn,''99999999'') % 2)::integer'
         || '            THEN 0'
         || '        WHEN $1::integer >= least_hn(b.fromhn,b.tohn)'
         || '            AND $1::integer <= greatest_hn(b.fromhn,b.tohn)'
         || '            THEN 2'
         || '        ELSE'
         || '            ((1.0 - '
         ||              '(least_hn($1::text,least_hn(b.fromhn,b.tohn)::text)::numeric /'
         ||              ' (greatest(1,greatest_hn($1::text,greatest_hn(b.fromhn,b.tohn)::text))) )'
         ||              ') * 5)::integer + 5'
         || '        END'
         || '    as sub_rating,$1::integer >= least_hn(b.fromhn,b.tohn) '
         || '            AND $1::integer <= greatest_hn(b.fromhn,b.tohn) '
         || '            AND ($1 % 2)::numeric::integer = (to_number(b.fromhn,''99999999'') % 2)'
         || '    as exact_address, b.name, b.prequalabr, b.pretypabrv, b.tfidr, b.tfidl, b.the_geom, b.place '
         || '  FROM 
             (SELECT   a.tlid, a.fullname, a.name, a.predirabrv, a.suftypabrv, a.sufdirabrv, a.prequalabr, a.pretypabrv, 
                b.the_geom, tfidr, tfidl,
                a.side ,
                a.fromhn,
                a.tohn,
                a.zip,
                p.name as place

                FROM  a INNER JOIN edges As b ON (a.statefp = b.statefp AND a.tlid = b.tlid  '
               || ')
                    INNER JOIN faces AS f ON ($10 = f.statefp AND ( (b.tfidl = f.tfid AND a.side = ''L'') OR (b.tfidr = f.tfid AND a.side = ''R'' ) )) 
                    INNER JOIN place p ON ($10 = p.statefp AND f.placefp = p.placefp ' 
          || CASE WHEN parsed.location > '' AND zip_info.zip IS NULL THEN ' AND ( lower(p.name) LIKE (lower($3::text) || ''%'')  ) ' ELSE '' END          
          || ')
                WHERE a.statefp = $10  AND  b.statefp = $10   '
             ||   CASE WHEN var_restrict_geom IS NOT NULL THEN ' AND ST_Intersects(b.the_geom, $8::geometry) '  ELSE '' END 
             || '

          )   As b  
           ORDER BY 10 ,  11 DESC 
           LIMIT 20 
            ) AS sub 
          JOIN state s ON ($10 = s.statefp) 
            ORDER BY 1,2,3,4,5,6,7,9 
          LIMIT 20) As foo ORDER BY sub_rating, exact_address DESC LIMIT  ' || max_results ;
         
  IF var_debug THEN
         RAISE NOTICE 'stmt: %', 
            replace(replace( replace(
                replace(
                replace(replace( replace(replace(replace(replace(stmt, '$10', quote_nullable(in_statefp) ), '$2',quote_nullable(parsed.streetName)),'$3', 
                quote_nullable(parsed.location)), '$4', quote_nullable(parsed.streetTypeAbbrev) ), 
                '$5', quote_nullable(parsed.preDirAbbrev) ),
                   '$6', quote_nullable(parsed.postDirAbbrev) ),
                   '$7', quote_nullable(parsed.zip) ),
                   '$8', quote_nullable(var_restrict_geom::text) ),
                   '$9', quote_nullable(zip_info.zip) ), '$1', quote_nullable(parsed.address) );
        --RAISE NOTICE 'PREPARE query_base_geo(integer, varchar,varchar,varchar,varchar,varchar,varchar,geometry,varchar[]) As %', stmt;
        --RAISE NOTICE 'EXECUTE query_base_geo(%,%,%,%,%,%,%,%,%); ', parsed.address,quote_nullable(parsed.streetName), quote_nullable(parsed.location), quote_nullable(parsed.streetTypeAbbrev), quote_nullable(parsed.preDirAbbrev), quote_nullable(parsed.postDirAbbrev), quote_nullable(parsed.zip), quote_nullable(var_restrict_geom::text), quote_nullable(zip_info.zip);
        --RAISE NOTICE 'DEALLOCATE query_base_geo;';
    END IF;
    FOR results IN EXECUTE stmt USING parsed.address,parsed.streetName, parsed.location, parsed.streetTypeAbbrev, parsed.preDirAbbrev, parsed.postDirAbbrev, parsed.zip, var_restrict_geom, zip_info.zip, in_statefp LOOP
      
        -- If we found a match with an exact street, then don't bother
        -- trying to do non-exact matches
    
        exact_street := true;    
        
        IF results.exact_address THEN
            ADDY.address := parsed.address;
        ELSE
            ADDY.address := CASE WHEN parsed.address > to_number(results.tohn,'99999999') AND parsed.address > to_number(results.fromhn, '99999999') THEN greatest_hn(results.fromhn, results.tohn)::integer
                ELSE least_hn(results.fromhn, results.tohn)::integer END ;
        END IF;
        
        ADDY.preDirAbbrev     := results.fedirp;
        ADDY.streetName       := results.fename;
        ADDY.streetTypeAbbrev := results.fetype;
        ADDY.postDirAbbrev    := results.fedirs;
        ADDY.location         := results.place;
        ADDY.stateAbbrev      := results.state;
        ADDY.zip              := results.zip;
        ADDY.parsed := TRUE;
        
        GEOMOUT := results.address_geom;
        RATING := results.sub_rating;
        var_n := var_n + 1;
        
        IF var_bestrating IS NULL THEN
            var_bestrating := RATING; /** the first record to come is our best rating we will ever get **/
        END IF;
        
        -- Only consider matches with decent ratings
        IF RATING < 90 THEN
            RETURN NEXT;
        END IF;
        
        -- If we get an exact match, then just return that
        IF RATING = 0 THEN
            RETURN;
        END IF;
    
        IF var_n >= max_results  THEN --we have exceeded our desired limit
            RETURN;
        END IF;
    
    END LOOP;
    
    IF var_bestrating < 30 THEN --if we already have a match with a rating of 30 or less, its unlikely we can do any better
        RETURN;
    END IF;
    

-- There are a couple of different things to try, from the highest preference and falling back
  -- to lower-preference options.
  -- We start out with zip-code matching, where the zip code could possibly be in more than one
  -- state.  We loop through each state its in.
  -- Next, we try to find the location in our side-table, which is based off of the 'place' data exact first then sounds like
  -- Next, we look up the location/city and use the zip code which is returned from that
  -- Finally, if we didn't get a zip code or a city match, we fall back to just a location/street
  -- lookup to try and find *something* useful.
  -- In the end, we *have* to find a statefp, one way or another.
  var_sql := 
  ' SELECT statefp,location,a.zip,exact,min(pref) FROM
    (SELECT zip_state.statefp as statefp,$1 as location, true As exact, ARRAY[zip_state.zip] as zip,1 as pref
        FROM zip_state WHERE zip_state.zip = $2 
            AND (' || quote_nullable(in_statefp) || ' IS NULL OR zip_state.statefp = ' || quote_nullable(in_statefp) || ')
          ' || COALESCE(' AND zip_state.zip IN(' || var_bfilter || ')', '') ||
        ' UNION SELECT zip_state_loc.statefp,zip_state_loc.place As location,false As exact, array_agg(zip_state_loc.zip) AS zip,1 + abs(COALESCE(diff_zip(max(zip), $2),0) - COALESCE(diff_zip(min(zip), $2),0)) As pref
              FROM zip_state_loc
             WHERE zip_state_loc.statefp = ' || quote_nullable(in_statefp) || ' 
                   AND lower($1) = lower(zip_state_loc.place) '  || COALESCE(' AND zip_state_loc.zip IN(' || var_bfilter || ')', '') ||
        '     GROUP BY zip_state_loc.statefp,zip_state_loc.place
      UNION SELECT zip_state_loc.statefp,zip_state_loc.place As location,false As exact, array_agg(zip_state_loc.zip),3
              FROM zip_state_loc
             WHERE zip_state_loc.statefp = ' || quote_nullable(in_statefp) || '
                   AND soundex($1) = soundex(zip_state_loc.place)
             GROUP BY zip_state_loc.statefp,zip_state_loc.place
      UNION SELECT zip_lookup_base.statefp,zip_lookup_base.city As location,false As exact, array_agg(zip_lookup_base.zip),4
              FROM zip_lookup_base
             WHERE zip_lookup_base.statefp = ' || quote_nullable(in_statefp) || '
                         AND (soundex($1) = soundex(zip_lookup_base.city) OR soundex($1) = soundex(zip_lookup_base.county))
             GROUP BY zip_lookup_base.statefp,zip_lookup_base.city
      UNION SELECT ' || quote_nullable(in_statefp) || ' As statefp,$1 As location,false As exact,NULL, 5) as a ' 
      ' WHERE a.statefp IS NOT NULL 
      GROUP BY statefp,location,a.zip,exact, pref ORDER BY exact desc, pref, zip';
  /** FOR zip_info IN     SELECT statefp,location,zip,exact,min(pref) FROM
    (SELECT zip_state.statefp as statefp,parsed.location as location, true As exact, ARRAY[zip_state.zip] as zip,1 as pref
        FROM zip_state WHERE zip_state.zip = parsed.zip 
            AND (in_statefp IS NULL OR zip_state.statefp = in_statefp)
        UNION SELECT zip_state_loc.statefp,parsed.location,false As exact, array_agg(zip_state_loc.zip),2 + diff_zip(zip[1], parsed.zip)
              FROM zip_state_loc
             WHERE zip_state_loc.statefp = in_statefp
                   AND lower(parsed.location) = lower(zip_state_loc.place)
             GROUP BY zip_state_loc.statefp,parsed.location
      UNION SELECT zip_state_loc.statefp,parsed.location,false As exact, array_agg(zip_state_loc.zip),3
              FROM zip_state_loc
             WHERE zip_state_loc.statefp = in_statefp
                   AND soundex(parsed.location) = soundex(zip_state_loc.place)
             GROUP BY zip_state_loc.statefp,parsed.location
      UNION SELECT zip_lookup_base.statefp,parsed.location,false As exact, array_agg(zip_lookup_base.zip),4
              FROM zip_lookup_base
             WHERE zip_lookup_base.statefp = in_statefp
                         AND (soundex(parsed.location) = soundex(zip_lookup_base.city) OR soundex(parsed.location) = soundex(zip_lookup_base.county))
             GROUP BY zip_lookup_base.statefp,parsed.location
      UNION SELECT in_statefp,parsed.location,false As exact,NULL, 5) as a
        --JOIN (VALUES (true),(false)) as b(exact) on TRUE
      WHERE statefp IS NOT NULL
      GROUP BY statefp,location,zip,exact, pref ORDER BY exact desc, pref, zip  **/
  FOR zip_info IN EXECUTE var_sql USING parsed.location, parsed.zip  LOOP
  -- For zip distance metric we consider both the distance of zip based on numeric as well aa levenshtein
  -- We use the prequalabr (these are like Old, that may or may not appear in front of the street name)
  -- We also treat pretypabr as fetype since in normalize we treat these as streetypes  and highways usually have the type here
  -- In pprint_addy we changed to put it in front if it is a is_hw type
    stmt := 'SELECT DISTINCT ON (sub.predirabrv,sub.fename,COALESCE(sub.suftypabrv, sub.pretypabrv) ,sub.sufdirabrv,coalesce(p.name,zip.city,cs.name,co.name),s.stusps,sub.zip)'
         || '    sub.predirabrv   as fedirp,'
         || '    sub.fename,'
         || '    COALESCE(sub.suftypabrv, sub.pretypabrv)   as fetype,'
         || '    sub.sufdirabrv   as fedirs,'
         || '    coalesce(p.name,zip.city,cs.name,co.name)::varchar as place,'
         || '    s.stusps as state,'
         || '    sub.zip as zip,'
         || '    interpolate_from_address($1, sub.fromhn,'
         || '        sub.tohn, e.the_geom, sub.side) as address_geom,'
         || '       sub.sub_rating + '
         || CASE WHEN parsed.zip > '' THEN '  least((coalesce(diff_zip($7 , sub.zip),0) *1.00/2)::integer, coalesce(levenshtein_ignore_case($7, sub.zip),0) ) '
            ELSE '3' END::text 
         || ' + coalesce(least(levenshtein_ignore_case($3, coalesce(p.name,zip.city,cs.name,co.name)), levenshtein_ignore_case($3, coalesce(cs.name,co.name))),5)'
         || '    as sub_rating,'
         || '    sub.exact_address as exact_address '
         || ' FROM ('
         || '  SELECT a.tlid, predirabrv, COALESCE(a.prequalabr || '' '','''' ) || a.name As fename, suftypabrv, sufdirabrv, fromhn, tohn, 
                    side, a.statefp, zip, rate_attributes($5, a.predirabrv,'
         || '    $2,  a.name , $4,'
         || '    a.suftypabrv , $6,'
         || '    a.sufdirabrv, a.prequalabr) + '
         || '    CASE '
         || '        WHEN $1::integer IS NULL OR b.fromhn IS NULL THEN 20'
         || '        WHEN $1::integer >= least_hn(b.fromhn, b.tohn) '
         || '            AND $1::integer <= greatest_hn(b.fromhn,b.tohn)'
         || '            AND ($1::integer % 2) = (to_number(b.fromhn,''99999999'') % 2)::integer'
         || '            THEN 0'
         || '        WHEN $1::integer >= least_hn(b.fromhn,b.tohn)'
         || '            AND $1::integer <= greatest_hn(b.fromhn,b.tohn)'
         || '            THEN 2'
         || '        ELSE'
         || '            ((1.0 - '
         ||              '(least_hn($1::text,least_hn(b.fromhn,b.tohn)::text)::numeric /'
         ||              ' greatest(1,greatest_hn($1::text,greatest_hn(b.fromhn,b.tohn)::text)))'
         ||              ') * 5)::integer + 5'
         || '        END'
         || '    as sub_rating,$1::integer >= least_hn(b.fromhn,b.tohn) '
         || '            AND $1::integer <= greatest_hn(b.fromhn,b.tohn) '
         || '            AND ($1 % 2)::numeric::integer = (to_number(b.fromhn,''99999999'') % 2)'
         || '    as exact_address, a.name, a.prequalabr, a.pretypabrv '
         || '  FROM featnames a join addr b ON (a.tlid = b.tlid AND a.statefp = b.statefp  )'
         || '  WHERE'
         || '        a.statefp = ' || quote_literal(zip_info.statefp) || ' AND a.mtfcc LIKE ''S%''  '
         || coalesce('    AND b.zip IN (''' || array_to_string(zip_info.zip,''',''') || ''') ','')
         || CASE WHEN zip_info.exact
                 THEN '    AND ( lower($2) = lower(a.name) OR  ( a.prequalabr > '''' AND trim(lower($2), lower(a.prequalabr) || '' '') = lower(a.name) ) OR numeric_streets_equal($2, a.name) ) '
                 ELSE '    AND ( soundex($2) = soundex(a.name)  OR ( (length($2) > 15 or (length($2) > 7 AND a.prequalabr > '''') ) AND lower(a.fullname) LIKE lower(substring($2,1,15)) || ''%'' ) OR  numeric_streets_equal($2, a.name) ) '
            END
         || '  ORDER BY 11'
         || '  LIMIT 20'
         || '    ) AS sub'
         || '  JOIN edges e ON (' || quote_literal(zip_info.statefp) || ' = e.statefp AND sub.tlid = e.tlid AND e.mtfcc LIKE ''S%'' ' 
         ||   CASE WHEN var_restrict_geom IS NOT NULL THEN ' AND ST_Intersects(e.the_geom, $8) '  ELSE '' END || ') '
         || '  JOIN state s ON (' || quote_literal(zip_info.statefp) || ' = s.statefp)'
         || '  JOIN faces f ON (' || quote_literal(zip_info.statefp) || ' = f.statefp AND (e.tfidl = f.tfid OR e.tfidr = f.tfid))'
         || '  LEFT JOIN zip_lookup_base zip ON (sub.zip = zip.zip AND zip.statefp=' || quote_literal(zip_info.statefp) || ')'
         || '  LEFT JOIN place p ON (' || quote_literal(zip_info.statefp) || ' = p.statefp AND f.placefp = p.placefp)'
         || '  LEFT JOIN county co ON (' || quote_literal(zip_info.statefp) || ' = co.statefp AND f.countyfp = co.countyfp)'
         || '  LEFT JOIN cousub cs ON (' || quote_literal(zip_info.statefp) || ' = cs.statefp AND cs.cosbidfp = sub.statefp || co.countyfp || f.cousubfp)'
         || ' WHERE'
         || '  ( (sub.side = ''L'' and e.tfidl = f.tfid) OR (sub.side = ''R'' and e.tfidr = f.tfid) ) '
         || ' ORDER BY 1,2,3,4,5,6,7,9'
         || ' LIMIT 10'
         ;
    IF var_debug THEN
        RAISE NOTICE '%', stmt;
        RAISE NOTICE 'PREPARE query_base_geo(integer, varchar,varchar,varchar,varchar,varchar,varchar,geometry) As %', stmt;
        RAISE NOTICE 'EXECUTE query_base_geo(%,%,%,%,%,%,%,%); ', parsed.address,quote_nullable(parsed.streetName), quote_nullable(parsed.location), quote_nullable(parsed.streetTypeAbbrev), quote_nullable(parsed.preDirAbbrev), quote_nullable(parsed.postDirAbbrev), quote_nullable(parsed.zip), quote_nullable(var_restrict_geom::text);
        RAISE NOTICE 'DEALLOCATE query_base_geo;';
    END IF;
    -- If we got an exact street match then when we hit the non-exact
    -- set of tests, just drop out.
    IF NOT zip_info.exact AND exact_street THEN
        RETURN;
    END IF;

    FOR results IN EXECUTE stmt USING parsed.address,parsed.streetName, parsed.location, parsed.streetTypeAbbrev, parsed.preDirAbbrev, parsed.postDirAbbrev, parsed.zip, var_restrict_geom LOOP

      -- If we found a match with an exact street, then don't bother
      -- trying to do non-exact matches
      IF zip_info.exact THEN
        exact_street := true;
      END IF;

      IF results.exact_address THEN
        ADDY.address := parsed.address;
      ELSE
        ADDY.address := NULL;
      END IF;

      ADDY.preDirAbbrev     := results.fedirp;
      ADDY.streetName       := results.fename;
      ADDY.streetTypeAbbrev := results.fetype;
      ADDY.postDirAbbrev    := results.fedirs;
      ADDY.location         := results.place;
      ADDY.stateAbbrev      := results.state;
      ADDY.zip              := results.zip;
      ADDY.parsed := TRUE;

      GEOMOUT := results.address_geom;
      RATING := results.sub_rating;
      var_n := var_n + 1;
      
      -- If our ratings go above 99 exit because its a really bad match
      IF RATING > 99 THEN
        RETURN;
      END IF;

      RETURN NEXT;

      -- If we get an exact match, then just return that
      IF RATING = 0 THEN
        RETURN;
      END IF;

    END LOOP;
    IF var_n > max_results  THEN --we have exceeded our desired limit
        RETURN;
    END IF;
  END LOOP;

  RETURN;
END;
$$
  LANGUAGE 'plpgsql' STABLE COST 1000 ROWS 50;
ALTER FUNCTION geocode_address(IN norm_addy, IN integer, IN geometry) SET join_collapse_limit='2';

--$Id: geocode_location.sql 9324 2012-02-27 22:08:12Z pramsey $
CREATE OR REPLACE FUNCTION geocode_location(
    parsed NORM_ADDY,
    restrict_geom geometry DEFAULT null,
    OUT ADDY NORM_ADDY,
    OUT GEOMOUT GEOMETRY,
    OUT RATING INTEGER
) RETURNS SETOF RECORD
AS $_$
DECLARE
  result RECORD;
  in_statefp VARCHAR;
  stmt VARCHAR;
  var_debug boolean := false;
BEGIN

  in_statefp := statefp FROM state WHERE state.stusps = parsed.stateAbbrev;

  IF var_debug THEN
    RAISE NOTICE 'geocode_location starting: %', clock_timestamp();
  END IF;
  FOR result IN
    SELECT
        coalesce(zip.city)::varchar as place,
        zip.zip as zip,
        ST_Centroid(zcta5.the_geom) as address_geom,
        stusps as state,
        100::integer + coalesce(levenshtein_ignore_case(coalesce(zip.city), parsed.location),0) as in_rating
    FROM
      zip_lookup_base zip
      JOIN zcta5 ON (zip.zip = zcta5.zcta5ce AND zip.statefp = zcta5.statefp)
      JOIN state ON (state.statefp=zip.statefp)
    WHERE
      parsed.zip = zip.zip OR
      (soundex(zip.city) = soundex(parsed.location) and zip.statefp = in_statefp)
    ORDER BY levenshtein_ignore_case(coalesce(zip.city), parsed.location), zip.zip
  LOOP
    ADDY.location := result.place;
    ADDY.stateAbbrev := result.state;
    ADDY.zip := result.zip;
    ADDY.parsed := true;
    GEOMOUT := result.address_geom;
    RATING := result.in_rating;

    RETURN NEXT;

    IF RATING = 100 THEN
      RETURN;
    END IF;

  END LOOP;

  IF parsed.location IS NULL THEN
    parsed.location := city FROM zip_lookup_base WHERE zip_lookup_base.zip = parsed.zip ORDER BY zip_lookup_base.zip LIMIT 1;
    in_statefp := statefp FROM zip_lookup_base WHERE zip_lookup_base.zip = parsed.zip ORDER BY zip_lookup_base.zip LIMIT 1;
  END IF;

  stmt := 'SELECT '
       || ' pl.name as place, '
       || ' state.stusps as stateAbbrev, '
       || ' ST_Centroid(pl.the_geom) as address_geom, '
       || ' 100::integer + levenshtein_ignore_case(coalesce(pl.name), ' || quote_literal(coalesce(parsed.location,'')) || ') as in_rating '
       || ' FROM (SELECT * FROM place WHERE statefp = ' ||  quote_literal(coalesce(in_statefp,'')) || ' ' || COALESCE(' AND ST_Intersects(' || quote_literal(restrict_geom::text) || '::geometry, the_geom)', '') || ') AS pl '
       || ' INNER JOIN state ON(pl.statefp = state.statefp)'
       || ' WHERE soundex(pl.name) = soundex(' || quote_literal(coalesce(parsed.location,'')) || ') and pl.statefp = ' || quote_literal(COALESCE(in_statefp,''))
       || ' ORDER BY levenshtein_ignore_case(coalesce(pl.name), ' || quote_literal(coalesce(parsed.location,'')) || ');'
       ;

  IF var_debug THEN
    RAISE NOTICE 'geocode_location stmt: %', stmt;
  END IF;     
  FOR result IN EXECUTE stmt
  LOOP

    ADDY.location := result.place;
    ADDY.stateAbbrev := result.stateAbbrev;
    ADDY.zip = parsed.zip;
    ADDY.parsed := true;
    GEOMOUT := result.address_geom;
    RATING := result.in_rating;

    RETURN NEXT;

    IF RATING = 100 THEN
      RETURN;
      IF var_debug THEN
        RAISE NOTICE 'geocode_location ending hit 100 rating result: %', clock_timestamp();
      END IF;
    END IF;
  END LOOP;
  
  IF var_debug THEN
    RAISE NOTICE 'geocode_location ending: %', clock_timestamp();
  END IF;

  RETURN;

END;
$_$ LANGUAGE plpgsql STABLE COST 100;
--$Id: geocode_intersection.sql 10310 2012-09-20 13:32:14Z robe $
 /*** 
 * 
 * Copyright (C) 2011 Regina Obe and Leo Hsu (Paragon Corporation)
 **/
-- This function given two roadways, state and optional city, zip
-- Will return addresses that are at the intersecton of those roadways
-- The address returned will be the address on the first road way
-- Use case example an address at the intersection of 2 streets: 
-- SELECT pprint_addy(addy), st_astext(geomout),rating FROM geocode_intersection('School St', 'Washington St', 'MA', 'Boston','02117');
--DROP FUNCTION tiger.geocode_intersection(text,text,text,text,text,integer);
CREATE OR REPLACE FUNCTION geocode_intersection(IN roadway1 text, IN roadway2 text, IN in_state text, IN in_city text DEFAULT '', IN in_zip text DEFAULT '', 
IN num_results integer DEFAULT 10,  OUT ADDY NORM_ADDY,
    OUT GEOMOUT GEOMETRY,
    OUT RATING INTEGER) RETURNS SETOF record AS
$$
DECLARE
    var_na_road norm_addy;
    var_na_inter1 norm_addy;
    var_sql text := '';
    var_zip varchar(5)[];
    in_statefp varchar(2) ; 
    var_debug boolean := get_geocode_setting('debug_geocode_intersection')::boolean;
    results record;
BEGIN
    IF COALESCE(roadway1,'') = '' OR COALESCE(roadway2,'') = '' THEN
        -- not enough to give a result just return
        RETURN ;
    ELSE
        var_na_road := normalize_address('0 ' || roadway1 || ', ' || COALESCE(in_city,'') || ', ' || in_state || ' ' || in_zip);
        var_na_inter1  := normalize_address('0 ' || roadway2 || ', ' || COALESCE(in_city,'') || ', ' || in_state || ' ' || in_zip);
    END IF;
    in_statefp := statefp FROM state_lookup As s WHERE s.abbrev = upper(in_state);
    IF COALESCE(in_zip,'') > '' THEN -- limit search to 2 plus or minus the input zip
        var_zip := zip_range(in_zip, -2,2);
    END IF;

    IF var_zip IS NULL AND in_city > '' THEN
        var_zip := array_agg(zip) FROM zip_lookup_base WHERE statefp = in_statefp AND lower(city) = lower(in_city);
    END IF;
    
    -- if we don't have a city or zip, don't bother doing the zip check, just keep as null
    IF var_zip IS NULL AND in_city > '' THEN
        var_zip := array_agg(zip) FROM zip_lookup_base WHERE statefp = in_statefp AND lower(city) LIKE lower(in_city) || '%'  ;
    END IF; 
    IF var_debug THEN
		RAISE NOTICE 'var_zip: %, city: %', quote_nullable(var_zip), quote_nullable(in_city);	
    END IF;
    var_sql := '
    WITH 
    	a1 AS (SELECT f.*, addr.fromhn, addr.tohn, addr.side , addr.zip
    				FROM (SELECT * FROM featnames 
    							WHERE statefp = $1 AND ( lower(name) = $2  ' ||
    							CASE WHEN length(var_na_road.streetName) > 5 THEN ' or  lower(fullname) LIKE $6 || ''%'' ' ELSE '' END || ')' 
    							|| ')  AS f LEFT JOIN (SELECT * FROM addr WHERE addr.statefp = $1) As addr ON (addr.tlid = f.tlid AND addr.statefp = f.statefp)
    					WHERE $5::text[] IS NULL OR addr.zip = ANY($5::text[]) OR addr.zip IS NULL 
    				ORDER BY CASE WHEN lower(f.fullname) = $6 THEN 0 ELSE 1 END
    				LIMIT 5000
    			  ),
        a2 AS (SELECT f.*, addr.fromhn, addr.tohn, addr.side , addr.zip
    				FROM (SELECT * FROM featnames 
    							WHERE statefp = $1 AND ( lower(name) = $4 ' || 
    							CASE WHEN length(var_na_inter1.streetName) > 5 THEN ' or lower(fullname) LIKE $7 || ''%'' ' ELSE '' END || ')' 
    							|| ' )  AS f LEFT JOIN (SELECT * FROM addr WHERE addr.statefp = $1) AS addr ON (addr.tlid = f.tlid AND addr.statefp = f.statefp)
    					WHERE $5::text[] IS NULL OR addr.zip = ANY($5::text[])  or addr.zip IS NULL 
    			ORDER BY CASE WHEN lower(f.fullname) = $7 THEN 0 ELSE 1 END
    				LIMIT 5000
    			  ),
    	 e1 AS (SELECT e.the_geom, e.tnidf, e.tnidt, a.*,
    	 			CASE WHEN a.side = ''L'' THEN e.tfidl ELSE e.tfidr END AS tfid
    	 			FROM a1 As a
    					INNER JOIN  edges AS e ON (e.statefp = a.statefp AND a.tlid = e.tlid)
    				WHERE e.statefp = $1 
    				ORDER BY CASE WHEN lower(a.name) = $4 THEN 0 ELSE 1 END + CASE WHEN lower(e.fullname) = $7 THEN 0 ELSE 1 END
    				LIMIT 1000) ,
    	e2 AS (SELECT e.the_geom, e.tnidf, e.tnidt, a.*,
    	 			CASE WHEN a.side = ''L'' THEN e.tfidl ELSE e.tfidr END AS tfid
    				FROM (SELECT * FROM edges WHERE statefp = $1) AS e INNER JOIN a2 AS a ON (e.statefp = a.statefp AND a.tlid = e.tlid)
    					INNER JOIN e1 ON (e.statefp = e1.statefp AND ST_Intersects(e.the_geom, e1.the_geom) 
    					AND ARRAY[e.tnidf, e.tnidt] && ARRAY[e1.tnidf, e1.tnidt] )
    					
    				WHERE (lower(e.fullname) = $7 or lower(a.name) LIKE $4 || ''%'')
    				ORDER BY CASE WHEN lower(a.name) = $4 THEN 0 ELSE 1 END + CASE WHEN lower(e.fullname) = $7 THEN 0 ELSE 1 END
    				LIMIT 100
    				), 
    	segs AS (SELECT DISTINCT ON(e1.tlid, e1.side)
                   CASE WHEN e1.tnidf = e2.tnidf OR e1.tnidf = e2.tnidt THEN
                                e1.fromhn
                            ELSE
                                e1.tohn END As address, e1.predirabrv As fedirp, COALESCE(e1.prequalabr || '' '','''' ) || e1.name As fename, 
                             COALESCE(e1.suftypabrv,e1.pretypabrv)  As fetype, e1.sufdirabrv AS fedirs, 
                               p.name As place, e1.zip,
                             CASE WHEN e1.tnidf = e2.tnidf OR e1.tnidf = e2.tnidt THEN
                                ST_StartPoint(ST_GeometryN(ST_Multi(e1.the_geom),1))
                             ELSE ST_EndPoint(ST_GeometryN(ST_Multi(e1.the_geom),1)) END AS geom ,   
                                CASE WHEN lower(p.name) = $3 THEN 0 ELSE 1 END  
                                + levenshtein_ignore_case(p.name, $3) 
                                + levenshtein_ignore_case(e1.name || COALESCE('' '' || e1.sufqualabr, ''''),$2) +
                                CASE WHEN e1.fullname = $6 THEN 0 ELSE levenshtein_ignore_case(e1.fullname, $6) END +
                                + levenshtein_ignore_case(e2.name || COALESCE('' '' || e2.sufqualabr, ''''),$4)
                                AS a_rating  
                    FROM e1 
                            INNER JOIN e2 ON (
                                    ST_Intersects(e1.the_geom, e2.the_geom)  ) 
                             INNER JOIN (SELECT * FROM faces WHERE statefp = $1) As fa1 ON (e1.tfid = fa1.tfid  )
                          LEFT JOIN place AS p ON (fa1.placefp = p.placefp AND p.statefp = $1 )
                       ORDER BY e1.tlid, e1.side, a_rating LIMIT $9*4 )
    SELECT address, fedirp , fename, fetype,fedirs,place, zip , geom, a_rating 
        FROM segs ORDER BY a_rating LIMIT  $9';

    IF var_debug THEN
        RAISE NOTICE 'sql: %', replace(replace(replace(
        	replace(replace(replace(
                replace(
                    replace(
                        replace(var_sql, '$1', quote_nullable(in_statefp)), 
                              '$2', quote_nullable(lower(var_na_road.streetName) ) ),
                      '$3', quote_nullable(lower(in_city)) ),
                      '$4', quote_nullable(lower(var_na_inter1.streetName) ) ),
                      '$5', quote_nullable(var_zip) ),
                      '$6', quote_nullable(lower(var_na_road.streetName || ' ' || COALESCE(var_na_road.streetTypeAbbrev,'') )) ) ,
                      '$7', quote_nullable(trim(lower(var_na_inter1.streetName || ' ' || COALESCE(var_na_inter1.streetTypeAbbrev,'') )) ) ) ,
		 '$8', quote_nullable(in_state ) ),  '$9', num_results::text );
    END IF;

    FOR results IN EXECUTE var_sql USING in_statefp, trim(lower(var_na_road.streetName)), lower(in_city), lower(var_na_inter1.streetName), var_zip,
		trim(lower(var_na_road.streetName || ' ' || COALESCE(var_na_road.streetTypeAbbrev,''))),
		trim(lower(var_na_inter1.streetName || ' ' || COALESCE(var_na_inter1.streetTypeAbbrev,''))), in_state, num_results LOOP
		ADDY.preDirAbbrev     := results.fedirp;
        ADDY.streetName       := results.fename;
        ADDY.streetTypeAbbrev := results.fetype;
        ADDY.postDirAbbrev    := results.fedirs;
        ADDY.location         := results.place;
        ADDY.stateAbbrev      := in_state;
        ADDY.zip              := results.zip;
        ADDY.parsed := TRUE;
        ADDY.address := results.address;
        
        GEOMOUT := results.geom;
        RATING := results.a_rating;
		RETURN NEXT; 
	END LOOP;
	RETURN;
END;
$$
  LANGUAGE plpgsql IMMUTABLE
  COST 1000
  ROWS 10;
ALTER FUNCTION geocode_intersection(IN text, IN text, IN text, IN text, IN text, IN integer) SET join_collapse_limit='2';
--$Id: geocode.sql 9324 2012-02-27 22:08:12Z pramsey $
CREATE OR REPLACE FUNCTION geocode(
    input VARCHAR, max_results integer DEFAULT 10,
    restrict_geom geometry DEFAULT NULL,
    OUT ADDY NORM_ADDY,
    OUT GEOMOUT GEOMETRY,
    OUT RATING INTEGER
) RETURNS SETOF RECORD
AS $_$
DECLARE
  rec RECORD;
BEGIN

  IF input IS NULL THEN
    RETURN;
  END IF;

  -- Pass the input string into the address normalizer
  ADDY := normalize_address(input);
  IF NOT ADDY.parsed THEN
    RETURN;
  END IF;

/*  FOR rec IN SELECT * FROM geocode(ADDY)
  LOOP

    ADDY := rec.addy;
    GEOMOUT := rec.geomout;
    RATING := rec.rating;

    RETURN NEXT;
  END LOOP;*/
 
  RETURN QUERY SELECT g.addy, g.geomout, g.rating FROM geocode(ADDY, max_results, restrict_geom) As g ORDER BY g.rating;

END;
$_$ LANGUAGE plpgsql STABLE;


CREATE OR REPLACE FUNCTION geocode(
    IN_ADDY NORM_ADDY, 
    max_results integer DEFAULT 10,
    restrict_geom geometry DEFAULT null,
    OUT ADDY NORM_ADDY,
    OUT GEOMOUT GEOMETRY,
    OUT RATING INTEGER
) RETURNS SETOF RECORD
AS $_$
DECLARE
  rec RECORD;
BEGIN

  IF NOT IN_ADDY.parsed THEN
    RETURN;
  END IF;

  -- Go for the full monty if we've got enough info
  IF IN_ADDY.streetName IS NOT NULL AND
      (IN_ADDY.zip IS NOT NULL OR IN_ADDY.stateAbbrev IS NOT NULL) THEN

    FOR rec IN
        SELECT *
        FROM
          (SELECT
            DISTINCT ON (
              (a.addy).address,
              (a.addy).predirabbrev,
              (a.addy).streetname,
              (a.addy).streettypeabbrev,
              (a.addy).postdirabbrev,
              (a.addy).internal,
              (a.addy).location,
              (a.addy).stateabbrev,
              (a.addy).zip
              )
            *
           FROM
             geocode_address(IN_ADDY, max_results, restrict_geom) a
           ORDER BY
              (a.addy).address,
              (a.addy).predirabbrev,
              (a.addy).streetname,
              (a.addy).streettypeabbrev,
              (a.addy).postdirabbrev,
              (a.addy).internal,
              (a.addy).location,
              (a.addy).stateabbrev,
              (a.addy).zip,
              a.rating
          ) as b
        ORDER BY b.rating LIMIT max_results
    LOOP

      ADDY := rec.addy;
      GEOMOUT := rec.geomout;
      RATING := rec.rating;

      RETURN NEXT;

      IF RATING = 0 THEN
        RETURN;
      END IF;

    END LOOP;

    IF RATING IS NOT NULL THEN
      RETURN;
    END IF;
  END IF;

  -- No zip code, try state/location, need both or we'll get too much stuffs.
  IF IN_ADDY.zip IS NOT NULL OR (IN_ADDY.stateAbbrev IS NOT NULL AND IN_ADDY.location IS NOT NULL) THEN
    FOR rec in SELECT * FROM geocode_location(IN_ADDY, restrict_geom) As b ORDER BY b.rating LIMIT max_results
    LOOP
      ADDY := rec.addy;
      GEOMOUT := rec.geomout;
      RATING := rec.rating;

      RETURN NEXT;
      IF RATING = 100 THEN
        RETURN;
      END IF;
    END LOOP;

  END IF;

  RETURN;

END;
$_$ LANGUAGE plpgsql STABLE
  COST 1000;
--$Id: reverse_geocode.sql 10149 2012-08-01 03:47:18Z robe $
 /*** 
 * 
 * Copyright (C) 2011-2012 Regina Obe and Leo Hsu (Paragon Corporation)
 **/
-- This function given a point try to determine the approximate street address (norm_addy form)
-- and array of cross streets, as well as interpolated points along the streets
-- Use case example an address at the intersection of 3 streets: SELECT pprint_addy(r.addy[1]) As st1, pprint_addy(r.addy[2]) As st2, pprint_addy(r.addy[3]) As st3, array_to_string(r.street, ',') FROM reverse_geocode(ST_GeomFromText('POINT(-71.057811 42.358274)',4269)) As r;
--set search_path=tiger,public;

CREATE OR REPLACE FUNCTION reverse_geocode(IN pt geometry, IN include_strnum_range boolean DEFAULT false, OUT intpt geometry[], OUT addy norm_addy[], OUT street character varying[])
  RETURNS record AS
$BODY$
DECLARE
  var_redge RECORD;
  var_state text := NULL;
  var_stusps text := NULL;
  var_countyfp text := NULL;
  var_addy NORM_ADDY;
  var_addy_alt NORM_ADDY;
  var_nstrnum numeric(10);
  var_primary_line geometry := NULL;
  var_primary_dist numeric(10,2) ;
  var_pt geometry;
  var_place varchar;
  var_county varchar;
  var_stmt text;
  var_debug boolean =  get_geocode_setting('debug_reverse_geocode')::boolean;
  var_rating_highway integer = COALESCE(get_geocode_setting('reverse_geocode_numbered_roads')::integer,0);/**0 no preference, 1 prefer highway number, 2 prefer local name **/
  var_zip varchar := NULL;
  var_primary_fullname varchar := '';
BEGIN
	--$Id: reverse_geocode.sql 10149 2012-08-01 03:47:18Z robe $
	IF pt IS NULL THEN
		RETURN;
	ELSE
		IF ST_SRID(pt) = 4269 THEN
			var_pt := pt;
		ELSIF ST_SRID(pt) > 0 THEN
			var_pt := ST_Transform(pt, 4269); 
		ELSE --If srid is unknown, assume its 4269
			var_pt := ST_SetSRID(pt, 4269);
		END IF;
		var_pt := ST_SnapToGrid(var_pt, 0.00005); /** Get rid of floating point junk that would prevent intersections **/
	END IF;
	-- Determine state tables to check 
	-- this is needed to take advantage of constraint exclusion
	IF var_debug THEN
		RAISE NOTICE 'Get matching states start: %', clock_timestamp();
	END IF;
	SELECT statefp, stusps INTO var_state, var_stusps FROM state WHERE ST_Intersects(the_geom, var_pt) LIMIT 1;
	IF var_debug THEN
		RAISE NOTICE 'Get matching states end: % -  %', var_state, clock_timestamp();
	END IF;
	IF var_state IS NULL THEN
		-- We don't have any data for this state
		RETURN;
	END IF;
	IF var_debug THEN
		RAISE NOTICE 'Get matching counties start: %', clock_timestamp();
	END IF;
	-- locate county
	var_stmt := 'SELECT countyfp, name  FROM  county WHERE  statefp =  $1 AND ST_Intersects(the_geom, $2) LIMIT 1;';
	EXECUTE var_stmt INTO var_countyfp, var_county USING var_state, var_pt ;

	--locate zip
	var_stmt := 'SELECT zcta5ce  FROM zcta5 WHERE statefp = $1 AND ST_Intersects(the_geom, $2)  LIMIT 1;';
	EXECUTE var_stmt INTO var_zip USING var_state, var_pt;
	-- locate city
	IF var_zip > '' THEN
	      var_addy.zip := var_zip ;
	END IF;
	
	var_stmt := 'SELECT z.name  FROM place As z WHERE  z.statefp =  $1 AND ST_Intersects(the_geom, $2) LIMIT 1;';
	EXECUTE var_stmt INTO var_place USING var_state, var_pt ;
	IF var_place > '' THEN
			var_addy.location := var_place;
	ELSE
		var_stmt := 'SELECT z.name  FROM cousub As z WHERE  z.statefp =  $1 AND ST_Intersects(the_geom, $2) LIMIT 1;';
		EXECUTE var_stmt INTO var_place USING var_state, var_pt ;
		IF var_place > '' THEN
			var_addy.location := var_place;
		-- ELSIF var_zip > '' THEN
		-- 	SELECT z.city INTO var_place FROM zip_lookup_base As z WHERE  z.statefp =  var_state AND z.county = var_county AND z.zip = var_zip LIMIT 1;
		-- 	var_addy.location := var_place;
		END IF;
	END IF;

	IF var_debug THEN
		RAISE NOTICE 'Get matching counties end: % - %',var_countyfp,  clock_timestamp();
	END IF;
	IF var_countyfp IS NULL THEN
		-- We don't have any data for this county
		RETURN;
	END IF;
	
	var_addy.stateAbbrev = var_stusps;

	-- Find the street edges that this point is closest to with tolerance of 0.005 but only consider the edge if the point is contained in the right or left face
	-- Then order addresses by proximity to road
	IF var_debug THEN
		RAISE NOTICE 'Get matching edges start: %', clock_timestamp();
	END IF;

	var_stmt := '
	    WITH ref AS (
	        SELECT ' || quote_literal(var_pt::text) || '::geometry As ref_geom ) , 
			f AS 
			( SELECT faces.* FROM faces  CROSS JOIN ref
			WHERE faces.statefp = ' || quote_literal(var_state) || ' AND faces.countyfp = ' || quote_literal(var_countyfp) || ' 
				AND ST_Intersects(faces.the_geom, ref_geom)
				    ),
			e AS 
			( SELECT edges.tlid , edges.statefp, edges.the_geom, CASE WHEN edges.tfidr = f.tfid THEN ''R'' WHEN edges.tfidl = f.tfid THEN ''L'' ELSE NULL END::varchar As eside,
                    ST_ClosestPoint(edges.the_geom,ref_geom) As center_pt, ref_geom
				FROM edges INNER JOIN f ON (f.statefp = edges.statefp AND (edges.tfidr = f.tfid OR edges.tfidl = f.tfid)) 
				    CROSS JOIN ref
			WHERE edges.statefp = ' || quote_literal(var_state) || ' AND edges.countyfp = ' || quote_literal(var_countyfp) || ' 
				AND ST_DWithin(edges.the_geom, ref.ref_geom, 0.01) AND (edges.mtfcc LIKE ''S%'') --only consider streets and roads
				  )	,
			ea AS 
			(SELECT e.statefp, e.tlid, a.fromhn, a.tohn, e.center_pt, ref_geom, a.zip, a.side, e.the_geom
				FROM e LEFT JOIN addr As a ON (a.statefp = ' || quote_literal(var_state) || '  AND e.tlid = a.tlid and e.eside = a.side) 
				)
		SELECT * 
		FROM (SELECT DISTINCT ON(tlid,side)  foo.fullname, foo.streetname, foo.streettypeabbrev, foo.zip,  foo.center_pt,
			  side, to_number(fromhn, ''999999'') As fromhn, to_number(tohn, ''999999'') As tohn, ST_GeometryN(ST_Multi(line),1) As line, 
			   dist
		FROM 
		  (SELECT e.tlid, e.the_geom As line, n.fullname, COALESCE(n.prequalabr || '' '','''')  || n.name AS streetname, n.predirabrv, COALESCE(suftypabrv, pretypabrv) As streettypeabbrev,
		      n.sufdirabrv, e.zip, e.side, e.fromhn, e.tohn , e.center_pt,
		          ST_Distance_Sphere(ST_SetSRID(e.center_pt,4326),ST_SetSRID(ref_geom,4326)) As dist
				FROM ea AS e 
					LEFT JOIN (SELECT featnames.* FROM featnames 
			    WHERE featnames.statefp = ' || quote_literal(var_state) ||'   ) AS n ON (n.statefp =  e.statefp AND n.tlid = e.tlid) 
				ORDER BY dist LIMIT 50 ) As foo 
				ORDER BY foo.tlid, foo.side, ';
				
	    -- for numbered street/road use var_rating_highway to determine whether to prefer numbered or not (0 no pref, 1 prefer numbered, 2 prefer named)
		var_stmt := var_stmt || ' CASE $1 WHEN 0 THEN 0  WHEN 1 THEN CASE WHEN foo.fullname ~ ''[0-9]+'' THEN 0 ELSE 1 END ELSE CASE WHEN foo.fullname > '''' AND NOT (foo.fullname ~ ''[0-9]+'') THEN 0 ELSE 1 END END ';
		var_stmt := var_stmt || ',  foo.fullname ASC NULLS LAST, dist LIMIT 50) As f ORDER BY f.dist, CASE WHEN fullname > '''' THEN 0 ELSE 1 END '; --don't bother penalizing for distance if less than 20 meters
				
	IF var_debug = true THEN
	    RAISE NOTICE 'Statement 1: %', replace(var_stmt, '$1', var_rating_highway::text);
	END IF;

    FOR var_redge IN EXECUTE var_stmt USING var_rating_highway LOOP
        IF var_debug THEN
            RAISE NOTICE 'Start Get matching edges loop: %,%', var_primary_line, clock_timestamp();
        END IF;
        IF var_primary_line IS NULL THEN --this is the first time in the loop and our primary guess
            var_primary_line := var_redge.line;
            var_primary_dist := var_redge.dist;
        END IF;
  
        IF var_redge.fullname IS NOT NULL AND COALESCE(var_primary_fullname,'') = '' THEN -- this is the first non-blank name we are hitting grab info
            var_primary_fullname := var_redge.fullname;
            var_addy.streetname = var_redge.streetname;
            var_addy.streettypeabbrev := var_redge.streettypeabbrev;
        END IF;
       
        IF ST_Intersects(var_redge.line, var_primary_line) THEN
            var_addy.streetname := var_redge.streetname; 
            
            var_addy.streettypeabbrev := var_redge.streettypeabbrev;
            var_addy.address := var_nstrnum;
            IF  var_redge.fromhn IS NOT NULL THEN
                --interpolate the number -- note that if fromhn > tohn we will be subtracting which is what we want
                var_nstrnum := (var_redge.fromhn + ST_Line_Locate_Point(var_redge.line, var_pt)*(var_redge.tohn - var_redge.fromhn))::numeric(10);
                -- The odd even street number side of street rule
                IF (var_nstrnum  % 2)  != (var_redge.tohn % 2) THEN
                    var_nstrnum := CASE WHEN var_nstrnum + 1 NOT BETWEEN var_redge.fromhn AND var_redge.tohn THEN var_nstrnum - 1 ELSE var_nstrnum + 1 END;
                END IF;
                var_addy.address := var_nstrnum;
            END IF;
            IF var_redge.zip > ''  THEN
                var_addy.zip := var_redge.zip;
            ELSE
                var_addy.zip := var_zip;
            END IF;
            -- IF var_redge.location > '' THEN
            --     var_addy.location := var_redge.location;
            -- ELSE
            --     var_addy.location := var_place;
            -- END IF;  
            
            -- This is a cross streets - only add if not the primary adress street
            IF var_redge.fullname > '' AND var_redge.fullname <> var_primary_fullname THEN
                street := array_append(street, (CASE WHEN include_strnum_range THEN COALESCE(var_redge.fromhn::varchar, '')::varchar || COALESCE(' - ' || var_redge.tohn::varchar,'')::varchar || ' '::varchar  ELSE '' END::varchar ||  COALESCE(var_redge.fullname::varchar,''))::varchar);
            END IF;    
            
            -- consider this a potential address
            IF (var_redge.dist < var_primary_dist*1.1 OR var_redge.dist < 20)   THEN
                 -- We only consider this a possible address if it is really close to our point
                 intpt := array_append(intpt,var_redge.center_pt); 
                -- note that ramps don't have names or addresses but they connect at the edge of a range
                -- so for ramps the address of connecting is still useful
                IF var_debug THEN
                    RAISE NOTICE 'Current addresses: %, last added, %, street: %, %', addy, var_addy, var_addy.streetname, clock_timestamp();
                END IF;
                 addy := array_append(addy, var_addy);

                -- Use current values streetname for previous value if previous value has no streetname
				IF var_addy.streetname > '' AND array_upper(addy,1) > 1 AND COALESCE(addy[array_upper(addy,1) - 1].streetname, '') = ''  THEN
					-- the match is probably an offshoot of some sort
					-- replace prior entry with streetname of new if prior had no streetname
					var_addy_alt := addy[array_upper(addy,1)- 1];
					IF var_debug THEN
						RAISE NOTICE 'Replacing answer : %, %', addy[array_upper(addy,1) - 1], clock_timestamp();
					END IF;
					var_addy_alt.streetname := var_addy.streetname;
					var_addy_alt.streettypeabbrev := var_addy.streettypeabbrev;
					addy[array_upper(addy,1) - 1 ] := var_addy_alt; 
					IF var_debug THEN
						RAISE NOTICE 'Replaced with : %, %', var_addy_alt, clock_timestamp();
					END IF;
				END IF;
				
				IF var_debug THEN
					RAISE NOTICE 'End Get matching edges loop: %', clock_timestamp();
					RAISE NOTICE 'Final addresses: %, %', addy, clock_timestamp();
				END IF;

            END IF;
        END IF;
     
    END LOOP;
 
    -- not matching roads or streets, just return basic info
    IF NOT FOUND THEN
        addy := array_append(addy,var_addy);
        IF var_debug THEN
            RAISE NOTICE 'No address found: adding: % street: %, %', var_addy, var_addy.streetname, clock_timestamp();
        END IF;
    END IF;
    IF var_debug THEN
        RAISE NOTICE 'current array count : %, %', array_upper(addy,1), clock_timestamp();
    END IF;

    RETURN;   
END;
$BODY$
  LANGUAGE plpgsql STABLE
  COST 1000;
--$Id: census_tracts_functions.sql 7996 2011-10-21 12:01:12Z robe $
 /*** 
 * 
 * Copyright (C) 2012 Regina Obe and Leo Hsu (Paragon Corporation)
 **/
-- This function given a geometry try will try to determine the tract.
-- It defaults to returning the tract name but can be changed to return track geoid id.
-- pass in 'tract_id' to get the full geoid, 'name' to get the short decimal name

CREATE OR REPLACE FUNCTION get_tract(IN loc_geom geometry, output_field text DEFAULT 'name')
  RETURNS text AS
$$
DECLARE
  var_state text := NULL;
  var_stusps text := NULL;
  var_result text := NULL;
  var_loc_geom geometry;
  var_stmt text;
  var_debug boolean = false;
BEGIN
	--$Id: census_tracts_functions.sql 7996 2011-10-21 12:01:12Z robe $
	IF loc_geom IS NULL THEN
		RETURN null;
	ELSE
		IF ST_SRID(loc_geom) = 4269 THEN
			var_loc_geom := loc_geom;
		ELSIF ST_SRID(loc_geom) > 0 THEN
			var_loc_geom := ST_Transform(loc_geom, 4269); 
		ELSE --If srid is unknown, assume its 4269
			var_loc_geom := ST_SetSRID(loc_geom, 4269);
		END IF;
		IF GeometryType(var_loc_geom) != 'POINT' THEN
			var_loc_geom := ST_Centroid(var_loc_geom);
		END IF;
	END IF;
	-- Determine state tables to check 
	-- this is needed to take advantage of constraint exclusion
	IF var_debug THEN
		RAISE NOTICE 'Get matching states start: %', clock_timestamp();
	END IF;
	SELECT statefp, stusps INTO var_state, var_stusps FROM state WHERE ST_Intersects(the_geom, var_loc_geom) LIMIT 1;
	IF var_debug THEN
		RAISE NOTICE 'Get matching states end: % -  %', var_state, clock_timestamp();
	END IF;
	IF var_state IS NULL THEN
		-- We don't have any data for this state
		RAISE NOTICE 'No data for this state';
		RETURN NULL;
	END IF;
	-- locate county
	var_stmt := 'SELECT ' || quote_ident(output_field) || ' FROM tract WHERE statefp =  $1 AND ST_Intersects(the_geom, $2) LIMIT 1;';
	EXECUTE var_stmt INTO var_result USING var_state, var_loc_geom ;
	RETURN var_result;
END;
$$
  LANGUAGE plpgsql IMMUTABLE
  COST 500;
