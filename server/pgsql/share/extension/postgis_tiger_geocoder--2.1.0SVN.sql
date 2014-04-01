CREATE TYPE norm_addy AS (
    address INTEGER,
    preDirAbbrev VARCHAR,
    streetName VARCHAR,
    streetTypeAbbrev VARCHAR,
    postDirAbbrev VARCHAR,
    internal VARCHAR,
    location VARCHAR,
    stateAbbrev VARCHAR,
    zip VARCHAR,
    parsed BOOLEAN);
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
--$Id: geocode_settings.sql 9861 2012-06-08 04:14:56Z robe $
--
-- PostGIS - Spatial Types for PostgreSQL
-- http://www.postgis.org
--
-- Copyright (C) 2010, 2011 Regina Obe and Leo Hsu
--
-- This is free software; you can redistribute and/or modify it under
-- the terms of the GNU General Public Licence. See the COPYING file.
--
-- Author: Regina Obe and Leo Hsu <lr@pcorp.us>
--  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--
SELECT tiger.SetSearchPathForInstall('tiger');

CREATE OR REPLACE FUNCTION install_geocode_settings() 
	RETURNS void AS
$$
DECLARE var_temp text;
BEGIN
	var_temp := tiger.SetSearchPathForInstall('tiger'); /** set set search path to have tiger in front **/
	IF NOT EXISTS(SELECT table_name FROM information_schema.columns WHERE table_schema = 'tiger' AND table_name = 'geocode_settings')  THEN
		CREATE TABLE geocode_settings(name text primary key, setting text, unit text, category text, short_desc text);
		GRANT SELECT ON geocode_settings TO public;
	END IF;
	--add missing settings
	INSERT INTO geocode_settings(name,setting,unit,category,short_desc)
		SELECT f.*
		FROM 
		(VALUES ('debug_geocode_address', 'false', 'boolean','debug', 'outputs debug information in notice log such as queries when geocode_addresss is called if true')
			, ('debug_geocode_intersection', 'false', 'boolean','debug', 'outputs debug information in notice log such as queries when geocode_intersection is called if true')
			, ('debug_normalize_address', 'false', 'boolean','debug', 'outputs debug information in notice log such as queries and intermediate expressions when normalize_address is called if true')
			, ('debug_reverse_geocode', 'false', 'boolean','debug', 'if true, outputs debug information in notice log such as queries and intermediate expressions when reverse_geocode')
			, ('reverse_geocode_numbered_roads', '0', 'integer','rating', 'For state and county highways, 0 - no preference in name, 1 - prefer the numbered highway name, 2 - prefer local state/county name')
		) f(name,setting,unit,category,short_desc)
		WHERE f.name NOT IN(SELECT name FROM geocode_settings);
END;
$$
language plpgsql;

SELECT install_geocode_settings(); /** create the table if it doesn't exist **/

CREATE OR REPLACE FUNCTION get_geocode_setting(setting_name text)
RETURNS text AS
$$
SELECT setting FROM geocode_settings WHERE name = $1;
$$
language sql STABLE;

CREATE OR REPLACE FUNCTION set_geocode_setting(setting_name text, setting_value text)
RETURNS text AS
$$
UPDATE geocode_settings SET setting = $2 WHERE name = $1
	RETURNING setting;
$$
language sql VOLATILE;
--$Id: lookup_tables_2011.sql 10394 2012-10-10 22:30:55Z robe $
--SET search_path TO tiger, public;
SELECT tiger.SetSearchPathForInstall('tiger');
-- Create direction lookup table
DROP TABLE IF EXISTS tiger.direction_lookup;
CREATE TABLE direction_lookup (name VARCHAR(20) PRIMARY KEY, abbrev VARCHAR(3));
INSERT INTO direction_lookup (name, abbrev) VALUES('WEST', 'W');
INSERT INTO direction_lookup (name, abbrev) VALUES('W', 'W');
INSERT INTO direction_lookup (name, abbrev) VALUES('SW', 'SW');
INSERT INTO direction_lookup (name, abbrev) VALUES('SOUTH-WEST', 'SW');
INSERT INTO direction_lookup (name, abbrev) VALUES('SOUTHWEST', 'SW');
INSERT INTO direction_lookup (name, abbrev) VALUES('SOUTH-EAST', 'SE');
INSERT INTO direction_lookup (name, abbrev) VALUES('SOUTHEAST', 'SE');
INSERT INTO direction_lookup (name, abbrev) VALUES('SOUTH_WEST', 'SW');
INSERT INTO direction_lookup (name, abbrev) VALUES('SOUTH_EAST', 'SE');
INSERT INTO direction_lookup (name, abbrev) VALUES('SOUTH', 'S');
INSERT INTO direction_lookup (name, abbrev) VALUES('SOUTH WEST', 'SW');
INSERT INTO direction_lookup (name, abbrev) VALUES('SOUTH EAST', 'SE');
INSERT INTO direction_lookup (name, abbrev) VALUES('SE', 'SE');
INSERT INTO direction_lookup (name, abbrev) VALUES('S', 'S');
INSERT INTO direction_lookup (name, abbrev) VALUES('NW', 'NW');
INSERT INTO direction_lookup (name, abbrev) VALUES('NORTH-WEST', 'NW');
INSERT INTO direction_lookup (name, abbrev) VALUES('NORTHWEST', 'NW');
INSERT INTO direction_lookup (name, abbrev) VALUES('NORTH-EAST', 'NE');
INSERT INTO direction_lookup (name, abbrev) VALUES('NORTHEAST', 'NE');
INSERT INTO direction_lookup (name, abbrev) VALUES('NORTH_WEST', 'NW');
INSERT INTO direction_lookup (name, abbrev) VALUES('NORTH_EAST', 'NE');
INSERT INTO direction_lookup (name, abbrev) VALUES('NORTH', 'N');
INSERT INTO direction_lookup (name, abbrev) VALUES('NORTH WEST', 'NW');
INSERT INTO direction_lookup (name, abbrev) VALUES('NORTH EAST', 'NE');
INSERT INTO direction_lookup (name, abbrev) VALUES('NE', 'NE');
INSERT INTO direction_lookup (name, abbrev) VALUES('N', 'N');
INSERT INTO direction_lookup (name, abbrev) VALUES('EAST', 'E');
INSERT INTO direction_lookup (name, abbrev) VALUES('E', 'E');
CREATE INDEX direction_lookup_abbrev_idx ON direction_lookup (abbrev);



-- Create secondary unit lookup table
DROP TABLE IF EXISTS tiger.secondary_unit_lookup;
CREATE TABLE secondary_unit_lookup (name VARCHAR(20) PRIMARY KEY, abbrev VARCHAR(5));
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('APARTMENT', 'APT');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('APT', 'APT');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('BASEMENT', 'BSMT');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('BSMT', 'BSMT');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('BUILDING', 'BLDG');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('BLDG', 'BLDG');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('DEPARTMENT', 'DEPT');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('DEPT', 'DEPT');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('FLOOR', 'FL');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('FL', 'FL');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('FRONT', 'FRNT');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('FRNT', 'FRNT');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('HANGAR', 'HNGR');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('HNGR', 'HNGR');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('LOBBY', 'LBBY');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('LBBY', 'LBBY');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('LOT', 'LOT');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('LOWER', 'LOWR');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('LOWR', 'LOWR');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('OFFICE', 'OFC');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('OFC', 'OFC');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('PENTHOUSE', 'PH');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('PH', 'PH');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('PIER', 'PIER');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('REAR', 'REAR');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('ROOM', 'RM');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('RM', 'RM');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('SIDE', 'SIDE');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('SLIP', 'SLIP');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('SPACE', 'SPC');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('SPC', 'SPC');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('STOP', 'STOP');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('SUITE', 'STE');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('STE', 'STE');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('TRAILER', 'TRLR');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('TRLR', 'TRLR');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('UNIT', 'UNIT');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('UPPER', 'UPPR');
INSERT INTO secondary_unit_lookup (name, abbrev) VALUES ('UPPR', 'UPPR');
CREATE INDEX secondary_unit_lookup_abbrev_idx ON secondary_unit_lookup (abbrev);



-- Create state lookup table
DROP TABLE IF EXISTS tiger.state_lookup;
CREATE TABLE state_lookup (st_code INTEGER PRIMARY KEY, name VARCHAR(40) UNIQUE, abbrev VARCHAR(3) UNIQUE, statefp char(2) UNIQUE);
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Alabama', 'AL', '01');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Alaska', 'AK', '02');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('American Samoa', 'AS', '60');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Arizona', 'AZ', '04');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Arkansas', 'AR', '05');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('California', 'CA', '06');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Colorado', 'CO', '08');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Connecticut', 'CT', '09');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Delaware', 'DE', '10');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('District of Columbia', 'DC', '11');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Federated States of Micronesia', 'FM', '64');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Florida', 'FL', '12');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Georgia', 'GA', '13');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Guam', 'GU', '66');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Hawaii', 'HI', '15');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Idaho', 'ID', '16');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Illinois', 'IL', '17');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Indiana', 'IN', '18');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Iowa', 'IA', '19');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Kansas', 'KS', '20');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Kentucky', 'KY', '21');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Louisiana', 'LA', '22');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Maine', 'ME', '23');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Marshall Islands', 'MH', '68');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Maryland', 'MD', '24');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Massachusetts', 'MA', '25');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Michigan', 'MI', '26');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Minnesota', 'MN', '27');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Mississippi', 'MS', '28');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Missouri', 'MO', '29');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Montana', 'MT', '30');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Nebraska', 'NE', '31');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Nevada', 'NV', '32');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('New Hampshire', 'NH', '33');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('New Jersey', 'NJ', '34');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('New Mexico', 'NM', '35');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('New York', 'NY', '36');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('North Carolina', 'NC', '37');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('North Dakota', 'ND', '38');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Northern Mariana Islands', 'MP', '69');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Ohio', 'OH', '39');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Oklahoma', 'OK', '40');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Oregon', 'OR', '41');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Palau', 'PW', '70');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Pennsylvania', 'PA', '42');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Puerto Rico', 'PR', '72');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Rhode Island', 'RI', '44');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('South Carolina', 'SC', '45');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('South Dakota', 'SD', '46');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Tennessee', 'TN', '47');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Texas', 'TX', '48');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Utah', 'UT', '49');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Vermont', 'VT', '50');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Virgin Islands', 'VI', '78');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Virginia', 'VA', '51');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Washington', 'WA', '53');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('West Virginia', 'WV', '54');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Wisconsin', 'WI', '55');
INSERT INTO state_lookup (name, abbrev, st_code) VALUES ('Wyoming', 'WY', '56');
-- NOTE: fix later -- this is wrong for those - state code ones
UPDATE state_lookup SET statefp = lpad(st_code::text,2,'0');


-- Create street type lookup table
DROP TABLE IF EXISTS tiger.street_type_lookup;
CREATE TABLE street_type_lookup (name VARCHAR(50) PRIMARY KEY, abbrev VARCHAR(50), is_hw boolean NOT NULL DEFAULT false);
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ALLEE', 'Aly');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ALLEY', 'Aly');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ALLY', 'Aly');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ALY', 'Aly');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ANEX', 'Anx');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ANNEX', 'Anx');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ANNX', 'Anx');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ANX', 'Anx');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ARC', 'Arc');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ARCADE', 'Arc');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('AV', 'Ave');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('AVE', 'Ave');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('AVEN', 'Ave');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('AVENU', 'Ave');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('AVENUE', 'Ave');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('AVN', 'Ave');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('AVNUE', 'Ave');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BAYOO', 'Byu');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BAYOU', 'Byu');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BCH', 'Bch');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BEACH', 'Bch');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BEND', 'Bnd');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BND', 'Bnd');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BLF', 'Blf');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BLUF', 'Blf');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BLUFF', 'Blf');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BLUFFS', 'Blfs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BOT', 'Btm');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BOTTM', 'Btm');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BOTTOM', 'Btm');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BTM', 'Btm');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BLVD', 'Blvd');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BOUL', 'Blvd');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BOULEVARD', 'Blvd');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BOULV', 'Blvd');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BR', 'Br');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BRANCH', 'Br');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BRNCH', 'Br');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BRDGE', 'Brg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BRG', 'Brg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BRIDGE', 'Brg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BRK', 'Brk');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BROOK', 'Brk');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BROOKS', 'Brks');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BURG', 'Bg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BURGS', 'Bgs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BYP', 'Byp');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BYPA', 'Byp');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BYPAS', 'Byp');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BYPASS', 'ByP');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BYPS', 'Byp');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CAMP', 'Cp');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CMP', 'Cp');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CP', 'Cp');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CANYN', 'Cyn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CANYON', 'Cyn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CNYN', 'Cyn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CYN', 'Cyn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CAPE', 'Cpe');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CPE', 'Cpe');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CAUSEWAY', 'Cswy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CAUSWAY', 'Cswy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CSWY', 'Cswy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CEN', 'Ctr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CENT', 'Ctr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CENTER', 'Ctr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CENTR', 'Ctr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CENTRE', 'Ctr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CNTER', 'Ctr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CNTR', 'Ctr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CTR', 'Ctr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CENTERS', 'Ctrs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CIR', 'Cir');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CIRC', 'Cir');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CIRCL', 'Cir');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CIRCLE', 'Cir');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRCL', 'Cir');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRCLE', 'Cir');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CIRCLES', 'Cirs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CLF', 'Clf');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CLIFF', 'Clf');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CLFS', 'Clfs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CLIFFS', 'Clfs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CLB', 'Clb');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CLUB', 'Clb');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('COMMON', 'Cmn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('COR', 'Cor');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CORNER', 'Cor');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CORNERS', 'Cors');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CORS', 'Cors');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('COURSE', 'Crse');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRSE', 'Crse');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('COURT', 'Ct');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRT', 'Ct');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CT', 'Ct');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('COURTS', 'Cts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('COVE', 'Cv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CV', 'Cv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('COVES', 'Cvs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CK', 'Crk');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CR', 'Crk');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CREEK', 'Crk');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRK', 'Crk');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRECENT', 'Cres');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRES', 'Cres');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRESCENT', 'Cres');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRESENT', 'Cres');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRSCNT', 'Cres');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRSENT', 'Cres');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRSNT', 'Cres');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CREST', 'Crst');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CROSSING', 'Xing');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRSSING', 'Xing');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRSSNG', 'Xing');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('XING', 'Xing');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CROSSROAD', 'Xrd');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CURVE', 'Curv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('DALE', 'Dl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('DL', 'Dl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('DAM', 'Dm');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('DM', 'Dm');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('DIV', 'Dv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('DIVIDE', 'Dv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('DV', 'Dv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('DVD', 'Dv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('DR', 'Dr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('DRIV', 'Dr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('DRIVE', 'Dr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('DRV', 'Dr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('DRIVES', 'Drs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('EST', 'Est');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ESTATE', 'Est');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ESTATES', 'Ests');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ESTS', 'Ests');
--INSERT INTO street_type_lookup (name, abbrev) VALUES ('EXP', 'Expy');
--INSERT INTO street_type_lookup (name, abbrev) VALUES ('EXPR', 'Expy');
--INSERT INTO street_type_lookup (name, abbrev) VALUES ('EXPRESS', 'Expy');
--INSERT INTO street_type_lookup (name, abbrev) VALUES ('EXPRESSWAY', 'Expy');
--INSERT INTO street_type_lookup (name, abbrev) VALUES ('EXPW', 'Expy');
--INSERT INTO street_type_lookup (name, abbrev) VALUES ('EXPY', 'Expy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('EXT', 'Ext');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('EXTENSION', 'Ext');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('EXTN', 'Ext');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('EXTNSN', 'Ext');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('EXTENSIONS', 'Exts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('EXTS', 'Exts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FALL', 'Fall');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FALLS', 'Fls');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FLS', 'Fls');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FERRY', 'Fry');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FRRY', 'Fry');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FRY', 'Fry');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FIELD', 'Fld');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FLD', 'Fld');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FIELDS', 'Flds');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FLDS', 'Flds');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FLAT', 'Flt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FLT', 'Flt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FLATS', 'Flts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FLTS', 'Flts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FORD', 'Frd');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FRD', 'Frd');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FORDS', 'Frds');
--INSERT INTO street_type_lookup (name, abbrev) VALUES ('FOREST', 'Frst');
--INSERT INTO street_type_lookup (name, abbrev) VALUES ('FORESTS', 'Frst');
--INSERT INTO street_type_lookup (name, abbrev) VALUES ('FRST', 'Frst');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FORG', 'Frg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FORGE', 'Frg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FRG', 'Frg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FORGES', 'Frgs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FORK', 'Frk');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FRK', 'Frk');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FORKS', 'Frks');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FRKS', 'Frks');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FORT', 'Ft');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FRT', 'Ft');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FT', 'Ft');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GARDEN', 'Gdn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GARDN', 'Gdn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GDN', 'Gdn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GRDEN', 'Gdn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GRDN', 'Gdn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GARDENS', 'Gdns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GDNS', 'Gdns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GRDNS', 'Gdns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GATEWAY', 'Gtwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GATEWY', 'Gtwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GATWAY', 'Gtwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GTWAY', 'Gtwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GTWY', 'Gtwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GLEN', 'Gln');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GLN', 'Gln');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GLENS', 'Glns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GREEN', 'Grn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GRN', 'Grn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GREENS', 'Grns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GROV', 'Grv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GROVE', 'Grv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GRV', 'Grv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GROVES', 'Grvs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HARB', 'Hbr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HARBOR', 'Hbr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HARBR', 'Hbr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HBR', 'Hbr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HRBOR', 'Hbr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HARBORS', 'Hbrs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HAVEN', 'Hvn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HAVN', 'Hvn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HVN', 'Hvn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HEIGHT', 'Hts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HEIGHTS', 'Hts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HGTS', 'Hts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HT', 'Hts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HTS', 'Hts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HILL', 'Hl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HL', 'Hl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HILLS', 'Hls');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HLS', 'Hls');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HLLW', 'Holw');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HOLLOW', 'Holw');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HOLLOWS', 'Holw');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HOLW', 'Holw');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HOLWS', 'Holw');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('INLET', 'Inlt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('INLT', 'Inlt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('IS', 'Is');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ISLAND', 'Is');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ISLND', 'Is');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ISLANDS', 'Iss');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ISLNDS', 'Iss');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ISS', 'Iss');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ISLE', 'Isle');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ISLES', 'Isle');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('JCT', 'Jct');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('JCTION', 'Jct');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('JCTN', 'Jct');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('JUNCTION', 'Jct');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('JUNCTN', 'Jct');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('JUNCTON', 'Jct');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('JCTNS', 'Jcts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('JCTS', 'Jcts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('JUNCTIONS', 'Jcts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('KEY', 'Ky');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('KY', 'Ky');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('KEYS', 'Kys');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('KYS', 'Kys');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('KNL', 'Knl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('KNOL', 'Knl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('KNOLL', 'Knl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('KNLS', 'Knls');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('KNOLLS', 'Knls');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LAKE', 'Lk');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LK', 'Lk');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LAKES', 'Lks');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LKS', 'Lks');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LAND', 'Land');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LANDING', 'Lndg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LNDG', 'Lndg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LNDNG', 'Lndg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LA', 'Ln');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LANE', 'Ln');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LANES', 'Ln');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LN', 'Ln');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LGT', 'Lgt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LIGHT', 'Lgt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LIGHTS', 'Lgts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LF', 'Lf');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LOAF', 'Lf');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LCK', 'Lck');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LOCK', 'Lck');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LCKS', 'Lcks');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LOCKS', 'Lcks');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LDG', 'Ldg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LDGE', 'Ldg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LODG', 'Ldg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LODGE', 'Ldg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LOOP', 'Loop');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LOOPS', 'Loop');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MALL', 'Mall');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MANOR', 'Mnr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MNR', 'Mnr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MANORS', 'Mnrs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MNRS', 'Mnrs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MDW', 'Mdw');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MEADOW', 'Mdw');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MDWS', 'Mdws');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MEADOWS', 'Mdws');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MEDOWS', 'Mdws');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MEWS', 'Mews');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MILL', 'Ml');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ML', 'Ml');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MILLS', 'Mls');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MLS', 'Mls');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MISSION', 'Msn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MISSN', 'Msn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MSN', 'Msn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MSSN', 'Msn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MOTORWAY', 'Mtwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MNT', 'Mt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MOUNT', 'Mt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MT', 'Mt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MNTAIN', 'Mtn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MNTN', 'Mtn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MOUNTAIN', 'Mtn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MOUNTIN', 'Mtn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MTIN', 'Mtn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MTN', 'Mtn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MNTNS', 'Mtns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MOUNTAINS', 'Mtns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('NCK', 'Nck');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('NECK', 'Nck');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ORCH', 'Orch');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ORCHARD', 'Orch');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ORCHRD', 'Orch');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('OVAL', 'Oval');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('OVL', 'Oval');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('OVERPASS', 'Opas');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PARK', 'Park');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PK', 'Park');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PRK', 'Park');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PARKS', 'Park');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PARKWAY', 'Pkwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PARKWY', 'Pkwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PKWAY', 'Pkwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PKWY', 'Pkwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PKY', 'Pkwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PARKWAYS', 'Pkwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PKWYS', 'Pkwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PASS', 'Pass');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PASSAGE', 'Psge');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PATH', 'Path');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PATHS', 'Path');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PIKE', 'Pike');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PIKES', 'Pike');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PINE', 'Pne');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PINES', 'Pnes');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PNES', 'Pnes');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PL', 'Pl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PLACE', 'Pl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PLAIN', 'Pln');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PLN', 'Pln');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PLAINES', 'Plns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PLAINS', 'Plns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PLNS', 'Plns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PLAZA', 'Plz');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PLZ', 'Plz');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PLZA', 'Plz');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('POINT', 'Pt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PT', 'Pt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('POINTS', 'Pts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PTS', 'Pts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PORT', 'Prt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PRT', 'Prt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PORTS', 'Prts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PRTS', 'Prts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PR', 'Pr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PRAIRIE', 'Pr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PRARIE', 'Pr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PRR', 'Pr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RAD', 'Radl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RADIAL', 'Radl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RADIEL', 'Radl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RADL', 'Radl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RAMP', 'Ramp');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RANCH', 'Rnch');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RANCHES', 'Rnch');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RNCH', 'Rnch');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RNCHS', 'Rnch');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RAPID', 'Rpd');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RPD', 'Rpd');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RAPIDS', 'Rpds');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RPDS', 'Rpds');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('REST', 'Rst');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RST', 'Rst');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RDG', 'Rdg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RDGE', 'Rdg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RIDGE', 'Rdg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RDGS', 'Rdgs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RIDGES', 'Rdgs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RIV', 'Riv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RIVER', 'Riv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RIVR', 'Riv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RVR', 'Riv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RD', 'Rd');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ROAD', 'Rd');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RDS', 'Rds');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ROADS', 'Rds');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ROW', 'Row');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RUE', 'Rue');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RUN', 'Run');
-- Start newly added 2011-7-12 --
INSERT INTO street_type_lookup (name, abbrev)
 VALUES 
 ('SERVICE DRIVE', 'Svc Dr'),
 ('SERVICE DR', 'Svc Dr'),
 ('SERVICE ROAD', 'Svc Rd'),
 ('SERVICE RD', 'Svc Rd') ;
-- end newly added 2011-07-12 --
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SHL', 'Shl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SHOAL', 'Shl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SHLS', 'Shls');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SHOALS', 'Shls');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SHOAR', 'Shr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SHORE', 'Shr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SHR', 'Shr');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SHOARS', 'Shrs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SHORES', 'Shrs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SHRS', 'Shrs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SKYWAY', 'Skwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SPG', 'Spg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SPNG', 'Spg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SPRING', 'Spg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SPRNG', 'Spg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SPGS', 'Spgs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SPNGS', 'Spgs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SPRINGS', 'Spgs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SPRNGS', 'Spgs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SPUR', 'Spur');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SPURS', 'Spur');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SQ', 'Sq');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SQR', 'Sq');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SQRE', 'Sq');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SQU', 'Sq');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SQUARE', 'Sq');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SQRS', 'Sqs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SQUARES', 'Sqs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STA', 'Sta');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STATION', 'Sta');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STATN', 'Sta');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STN', 'Sta');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STRA', 'Stra');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STRAV', 'Stra');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STRAVE', 'Stra');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STRAVEN', 'Stra');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STRAVENUE', 'Stra');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STRAVN', 'Stra');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STRVN', 'Stra');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STRVNUE', 'Stra');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STREAM', 'Strm');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STREME', 'Strm');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STRM', 'Strm');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('ST', 'St');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STR', 'St');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STREET', 'St');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STRT', 'St');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STREETS', 'Sts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SMT', 'Smt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SUMIT', 'Smt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SUMITT', 'Smt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SUMMIT', 'Smt');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TER', 'Ter');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TERR', 'Ter');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TERRACE', 'Ter');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('THROUGHWAY', 'Trwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRACE', 'Trce');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRACES', 'Trce');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRCE', 'Trce');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRACK', 'Trak');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRACKS', 'Trak');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRAK', 'Trak');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRK', 'Trak');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRKS', 'Trak');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRAFFICWAY', 'Trfy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRFY', 'Trfy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TR', 'Trl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRAIL', 'Trl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRAILS', 'Trl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRL', 'Trl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRLS', 'Trl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TUNEL', 'Tunl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TUNL', 'Tunl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TUNLS', 'Tunl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TUNNEL', 'Tunl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TUNNELS', 'Tunl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TUNNL', 'Tunl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('UNDERPASS', 'Upas');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('UN', 'Un');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('UNION', 'Un');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('UNIONS', 'Uns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VALLEY', 'Vly');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VALLY', 'Vly');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VLLY', 'Vly');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VLY', 'Vly');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VALLEYS', 'Vlys');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VLYS', 'Vlys');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VDCT', 'Via');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VIA', 'Via');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VIADCT', 'Via');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VIADUCT', 'Via');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VIEW', 'Vw');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VW', 'Vw');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VIEWS', 'Vws');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VWS', 'Vws');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VILL', 'Vlg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VILLAG', 'Vlg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VILLAGE', 'Vlg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VILLG', 'Vlg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VILLIAGE', 'Vlg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VLG', 'Vlg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VILLAGES', 'Vlgs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VLGS', 'Vlgs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VILLE', 'Vl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VL', 'Vl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VIS', 'Vis');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VIST', 'Vis');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VISTA', 'Vis');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VST', 'Vis');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('VSTA', 'Vis');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('WALK', 'Walk');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('WALKS', 'Walk');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('WALL', 'Wall');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('WAY', 'Way');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('WY', 'Way');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('WAYS', 'Ways');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('WELL', 'Wl');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('WELLS', 'Wls');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('WLS', 'Wls');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BYU', 'Byu');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BLFS', 'Blfs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BRKS', 'Brks');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BG', 'Bg');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('BGS', 'Bgs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CTRS', 'Ctrs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CIRS', 'Cirs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CMN', 'Cmn');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CTS', 'Cts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CVS', 'Cvs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CRST', 'Crst');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('XRD', 'Xrd');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('CURV', 'Curv');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('DRS', 'Drs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FRDS', 'Frds');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('FRGS', 'Frgs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GLNS', 'Glns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GRNS', 'Grns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('GRVS', 'Grvs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('HBRS', 'Hbrs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('LGTS', 'Lgts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MTWY', 'Mtwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('MTNS', 'Mtns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('OPAS', 'Opas');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PSGE', 'Psge');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('PNE', 'Pne');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('RTE', 'Rte');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SKWY', 'Skwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('SQS', 'Sqs');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('STS', 'Sts');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('TRWY', 'Trwy');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('UPAS', 'Upas');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('UNS', 'Uns');
INSERT INTO street_type_lookup (name, abbrev) VALUES ('WL', 'Wl');

-- prefix and suffix street names for highways and foreign named roads 
-- where street type is at front of streetname instead of after
-- these usually have numbers for street names and often have spaces in type
INSERT INTO street_type_lookup (name, abbrev, is_hw) 
SELECT name, abbrev, true
    FROM (VALUES
        ('CAM', 'Cam'),
        ('CAM.', 'Cam'),
        ('CAMINO', 'Cam'),
        ('CO HWY', 'Co Hwy'),
        ('COUNTY HWY', 'Co Hwy'),
        ('COUNTY HIGHWAY', 'Co Hwy'),
        ('COUNTY HIGH WAY', 'Co Hwy'),
        ('COUNTY ROAD', 'Co Rd'),
        ('COUNTY RD', 'Co Rd'),
        ('CO RD', 'Co Rd'),
        ('CORD', 'Co Rd'),
        ('CO RTE', 'Co Rte'),
        ('COUNTY ROUTE', 'Co Rte'),
        ('CO ST AID HWY', 'Co St Aid Hwy'),
        ('EXP', 'Expy'),
        ('EXPR', 'Expy'),
        ('EXPRESS', 'Expy'),
        ('EXPRESSWAY', 'Expy'),
        ('EXPW', 'Expy'),
        ('EXPY', 'Expy'),
        ('FARM RD', 'Farm Rd'),
        ('FIRE RD', 'Fire Rd'),
        ('FOREST RD', 'Forest Rd'),
        ('FOREST ROAD', 'Forest Rd'),
        ('FOREST RTE', 'Forest Rte'),
        ('FOREST ROUTE', 'Forest Rte'),
        ('FREEWAY', 'Fwy'),
        ('FREEWY', 'Fwy'),
        ('FRWAY', 'Fwy'),
        ('FRWY', 'Fwy'),
        ('FWY', 'Fwy'),
        ('HIGHWAY', 'Hwy'),
        ('HIGHWY', 'Hwy'),
        ('HIWAY', 'Hwy'),
        ('HIWY', 'Hwy'),
        ('HWAY', 'Hwy'),
        ('HWY', 'Hwy'),
        ('I', 'I-'),
        ('I-', 'I-'),
        ('INTERSTATE', 'I-'),
        ('INTERSTATE ROUTE', 'I-'),
        ('INTERSTATE RTE', 'I-'),
        ('INTERSTATE RTE.', 'I-'),
        ('INTERSTATE RT', 'I-'),
        ('LOOP', 'Loop'),
        ('ROUTE', 'Rte'),
        ('RTE', 'Rte'),
        ('RT', 'Rte'),
        ('STATE HWY', 'State Hwy'),
        ('STATE HIGHWAY', 'State Hwy'),
        ('STATE HIGH WAY', 'State Hwy'),
        ('STATE RD', 'State Rd'),
        ('STATE ROAD', 'State Rd'),
        ('STATE ROUTE', 'State Rte'),
        ('STATE RTE', 'State Rte'),
        ('TPK', 'Tpke'),
        ('TPKE', 'Tpke'),
        ('TRNPK', 'Tpke'),
        ('TRPK', 'Tpke'),
        ('TURNPIKE', 'Tpke'),
        ('TURNPK', 'Tpke'),
        ('US HWY', 'US Hwy'),
        ('US HIGHWAY', 'US Hwy'),
        ('US HIGH WAY', 'US Hwy'),
        ('U.S.', 'US Hwy'),
        ('US RTE', 'US Rte'),
        ('US ROUTE', 'US Rte'),
        ('US RT', 'US Rte'),
        ('USFS HWY', 'USFS Hwy'),
        ('USFS HIGHWAY', 'USFS Hwy'),
        ('USFS HIGH WAY', 'USFS Hwy'),
        ('USFS RD', 'USFS Rd'),
        ('USFS ROAD', 'USFS Rd')
           ) t(name, abbrev)
           WHERE t.name NOT IN(SELECT name FROM street_type_lookup);
CREATE INDEX street_type_lookup_abbrev_idx ON street_type_lookup (abbrev);

-- Create place and countysub lookup tables
DROP TABLE IF EXISTS tiger.place_lookup;
CREATE TABLE place_lookup (
    st_code INTEGER,
    state   VARCHAR(2),
    pl_code INTEGER,
    name    VARCHAR(90),
    PRIMARY KEY (st_code,pl_code)
);

/**
INSERT INTO place_lookup
  SELECT
    pl.state::integer   as st_code,
    sl.abbrev           as state,
    pl.placefp::integer as pl_code,
    pl.name             as name
  FROM
    pl99_d00 pl
    JOIN state_lookup sl ON (pl.state = lpad(sl.st_code,2,'0'))
  GROUP BY pl.state, sl.abbrev, pl.placefp, pl.name;
**/
CREATE INDEX place_lookup_name_idx ON place_lookup (soundex(name));
CREATE INDEX place_lookup_state_idx ON place_lookup (state);

DROP TABLE IF EXISTS tiger.county_lookup;
CREATE TABLE county_lookup (
    st_code INTEGER,
    state   VARCHAR(2),
    co_code INTEGER,
    name    VARCHAR(90),
    PRIMARY KEY (st_code, co_code)
);

/**
INSERT INTO county_lookup
  SELECT
    co.state::integer    as st_code,
    sl.abbrev            as state,
    co.county::integer   as co_code,
    co.name              as name
  FROM
    co99_d00 co
    JOIN state_lookup sl ON (co.state = lpad(sl.st_code,2,'0'))
  GROUP BY co.state, sl.abbrev, co.county, co.name;
**/
CREATE INDEX county_lookup_name_idx ON county_lookup (soundex(name));
CREATE INDEX county_lookup_state_idx ON county_lookup (state);

DROP TABLE IF EXISTS tiger.countysub_lookup;
CREATE TABLE countysub_lookup (
    st_code INTEGER,
    state   VARCHAR(2),
    co_code INTEGER,
    county  VARCHAR(90),
    cs_code INTEGER,
    name    VARCHAR(90),
    PRIMARY KEY (st_code, co_code, cs_code)
);

/**
INSERT INTO countysub_lookup
  SELECT
    cs.state::integer    as st_code,
    sl.abbrev            as state,
    cs.county::integer   as co_code,
    cl.name              as county,
    cs.cousubfp::integer as cs_code,
    cs.name              as name
  FROM
    cs99_d00 cs
    JOIN state_lookup sl ON (cs.state = lpad(sl.st_code,2,'0'))
    JOIN county_lookup cl ON (cs.state = lpad(cl.st_code,2,'0') AND cs.county = cl.co_code)
  GROUP BY cs.state, sl.abbrev, cs.county, cl.name, cs.cousubfp, cs.name;
**/
CREATE INDEX countysub_lookup_name_idx ON countysub_lookup (soundex(name));
CREATE INDEX countysub_lookup_state_idx ON countysub_lookup (state);

DROP TABLE IF EXISTS tiger.zip_lookup_all;
CREATE TABLE zip_lookup_all (
    zip     INTEGER,
    st_code INTEGER,
    state   VARCHAR(2),
    co_code INTEGER,
    county  VARCHAR(90),
    cs_code INTEGER,
    cousub  VARCHAR(90),
    pl_code INTEGER,
    place   VARCHAR(90),
    cnt     INTEGER
);

/** SET work_mem = '2GB';

INSERT INTO zip_lookup_all
  SELECT *,count(*) as cnt FROM
  (SELECT
    zipl                 as zip,
    rl.statel            as st_code,
    sl.abbrev            as state,
    rl.countyl           as co_code,
    cl.name              as county,
    rl.cousubl           as cs_code,
    cs.name              as countysub,
    rl.placel            as pl_code,
    pl.name              as place
  FROM
    roads_local rl
    JOIN state_lookup sl ON (rl.statel = lpad(sl.st_code,2,'0'))
    LEFT JOIN county_lookup cl ON (rl.statel = lpad(cl.st_code,2,'0') AND rl.countyl = cl.co_code)
    LEFT JOIN countysub_lookup cs ON (rl.statel = lpad(cs.st_code,2,'0') AND rl.countyl = cs.co_code AND rl.cousubl = cs.cs_code)
    LEFT JOIN place_lookup pl ON (rl.statel = lpad(pl.st_code,2,'0') AND rl.placel = pl.pl_code)
  WHERE zipl IS NOT NULL
  UNION ALL
  SELECT
    zipr                 as zip,
    rl.stater            as st_code,
    sl.abbrev            as state,
    rl.countyr           as co_code,
    cl.name              as county,
    rl.cousubr           as cs_code,
    cs.name              as countysub,
    rl.placer            as pl_code,
    pl.name              as place
  FROM
    roads_local rl
    JOIN state_lookup sl ON (rl.stater = lpad(sl.st_code,2,'0'))
    LEFT JOIN county_lookup cl ON (rl.stater = lpad(cl.st_code,2,'0') AND rl.countyr = cl.co_code)
    LEFT JOIN countysub_lookup cs ON (rl.stater = lpad(cs.st_code,2,'0') AND rl.countyr = cs.co_code AND rl.cousubr = cs.cs_code)
    LEFT JOIN place_lookup pl ON (rl.stater = lpad(pl.st_code,2,'0') AND rl.placer = pl.pl_code)
  WHERE zipr IS NOT NULL
  ) as subquery
  GROUP BY zip, st_code, state, co_code, county, cs_code, countysub, pl_code, place;
**/
DROP TABLE IF EXISTS tiger.zip_lookup_base;
CREATE TABLE zip_lookup_base (
    zip     varchar(5),
    state   VARCHAR(40),
    county  VARCHAR(90),
    city    VARCHAR(90),
    statefp varchar(2),
    PRIMARY KEY (zip)
);

-- INSERT INTO zip_lookup_base
-- Populate through magic
-- If anyone knows of a good, public, free, place to pull this information from, that'd be awesome to have...

DROP TABLE IF EXISTS tiger.zip_lookup;
CREATE TABLE zip_lookup (
    zip     INTEGER,
    st_code INTEGER,
    state   VARCHAR(2),
    co_code INTEGER,
    county  VARCHAR(90),
    cs_code INTEGER,
    cousub  VARCHAR(90),
    pl_code INTEGER,
    place   VARCHAR(90),
    cnt     INTEGER,
    PRIMARY KEY (zip)
);

DROP TABLE IF EXISTS tiger.zcta500;
/**
INSERT INTO zip_lookup
  SELECT
    DISTINCT ON (zip)
    zip,
    st_code,
    state,
    co_code,
    county,
    cs_code,
    cousub,
    pl_code,
    place,
    cnt
  FROM zip_lookup_all
  ORDER BY zip,cnt desc;
  **/
DROP TABLE IF EXISTS tiger.county;
CREATE TABLE county
(
  gid SERIAL NOT NULL,
  statefp character varying(2),
  countyfp character varying(3),
  countyns character varying(8),
  cntyidfp character varying(5) NOT NULL,
  "name" character varying(100),
  namelsad character varying(100),
  lsad character varying(2),
  classfp character varying(2),
  mtfcc character varying(5),
  csafp character varying(3),
  cbsafp character varying(5),
  metdivfp character varying(5),
  funcstat character varying(1),
  aland bigint,
  awater  double precision,
  intptlat character varying(11),
  intptlon character varying(12),
  the_geom geometry,
  CONSTRAINT uidx_county_gid UNIQUE (gid),
  CONSTRAINT pk_tiger_county PRIMARY KEY (cntyidfp),
  CONSTRAINT enforce_dims_geom CHECK (st_ndims(the_geom) = 2),
  CONSTRAINT enforce_geotype_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL),
  CONSTRAINT enforce_srid_geom CHECK (st_srid(the_geom) = 4269)
);
CREATE INDEX idx_tiger_county ON county USING btree (countyfp);

DROP TABLE IF EXISTS tiger.state;
CREATE TABLE state
(
  gid serial NOT NULL,
  region character varying(2),
  division character varying(2),
  statefp character varying(2),
  statens character varying(8),
  stusps character varying(2) NOT NULL,
  "name" character varying(100),
  lsad character varying(2),
  mtfcc character varying(5),
  funcstat character varying(1),
  aland bigint,
  awater bigint,
  intptlat character varying(11),
  intptlon character varying(12),
  the_geom geometry,
  CONSTRAINT uidx_tiger_state_stusps UNIQUE (stusps),
  CONSTRAINT uidx_tiger_state_gid UNIQUE (gid),
  CONSTRAINT pk_tiger_state PRIMARY KEY (statefp),
  CONSTRAINT enforce_dims_the_geom CHECK (st_ndims(the_geom) = 2),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 4269)
);
CREATE INDEX idx_tiger_state_the_geom_gist ON state USING gist(the_geom);

DROP TABLE IF EXISTS tiger.place;
CREATE TABLE place
(
  gid serial NOT NULL,
  statefp character varying(2),
  placefp character varying(5),
  placens character varying(8),
  plcidfp character varying(7) PRIMARY KEY,
  "name" character varying(100),
  namelsad character varying(100),
  lsad character varying(2),
  classfp character varying(2),
  cpi character varying(1),
  pcicbsa character varying(1),
  pcinecta character varying(1),
  mtfcc character varying(5),
  funcstat character varying(1),
  aland bigint,
  awater bigint,
  intptlat character varying(11),
  intptlon character varying(12),
  the_geom geometry,
  CONSTRAINT uidx_tiger_place_gid UNIQUE (gid),
  CONSTRAINT enforce_dims_the_geom CHECK (st_ndims(the_geom) = 2),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 4269)
);
CREATE INDEX tiger_place_the_geom_gist ON place USING gist(the_geom);

DROP TABLE IF EXISTS tiger.zip_state;
CREATE TABLE zip_state
(
  zip character varying(5) NOT NULL,
  stusps character varying(2) NOT NULL,
  statefp character varying(2),
  CONSTRAINT zip_state_pkey PRIMARY KEY (zip, stusps)
);

DROP TABLE IF EXISTS tiger.zip_state_loc;
CREATE TABLE zip_state_loc
(
  zip character varying(5) NOT NULL,
  stusps character varying(2) NOT NULL,
  statefp character varying(2),
  place varchar(100),
  CONSTRAINT zip_state_loc_pkey PRIMARY KEY (zip, stusps, place)
);

DROP TABLE IF EXISTS tiger.cousub;
CREATE TABLE cousub
(
  gid serial NOT NULL,
  statefp character varying(2),
  countyfp character varying(3),
  cousubfp character varying(5),
  cousubns character varying(8),
  cosbidfp character varying(10) NOT NULL PRIMARY KEY,
  "name" character varying(100),
  namelsad character varying(100),
  lsad character varying(2),
  classfp character varying(2),
  mtfcc character varying(5),
  cnectafp character varying(3),
  nectafp character varying(5),
  nctadvfp character varying(5),
  funcstat character varying(1),
  aland numeric(14),
  awater numeric(14),
  intptlat character varying(11),
  intptlon character varying(12),
  the_geom geometry,
  CONSTRAINT uidx_cousub_gid UNIQUE (gid),
  CONSTRAINT enforce_dims_the_geom CHECK (st_ndims(the_geom) = 2),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 4269)
);

CREATE INDEX tige_cousub_the_geom_gist ON cousub USING gist(the_geom);

DROP TABLE IF EXISTS tiger.edges;
CREATE TABLE edges
(
  gid SERIAL NOT NULL  PRIMARY KEY,
  statefp character varying(2),
  countyfp character varying(3),
  tlid bigint,
  tfidl numeric(10),
  tfidr numeric(10),
  mtfcc character varying(5),
  fullname character varying(100),
  smid character varying(22),
  lfromadd character varying(12),
  ltoadd character varying(12),
  rfromadd character varying(12),
  rtoadd character varying(12),
  zipl character varying(5),
  zipr character varying(5),
  featcat character varying(1),
  hydroflg character varying(1),
  railflg character varying(1),
  roadflg character varying(1),
  olfflg character varying(1),
  passflg character varying(1),
  divroad character varying(1),
  exttyp character varying(1),
  ttyp character varying(1),
  deckedroad character varying(1),
  artpath character varying(1),
  persist character varying(1),
  gcseflg character varying(1),
  offsetl character varying(1),
  offsetr character varying(1),
  tnidf numeric(10),
  tnidt numeric(10),
  the_geom geometry,
  CONSTRAINT enforce_dims_the_geom CHECK (st_ndims(the_geom) = 2),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'MULTILINESTRING'::text OR the_geom IS NULL),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 4269)
);
CREATE INDEX idx_edges_tlid ON edges USING btree(tlid);
CREATE INDEX idx_tiger_edges_countyfp ON edges USING btree(countyfp);
CREATE INDEX idx_tiger_edges_the_geom_gist ON edges USING gist(the_geom);

DROP TABLE IF EXISTS tiger.addrfeat;
CREATE TABLE addrfeat
(
  gid serial not null primary key,
  tlid bigint,
  statefp character varying(2) NOT NULL,
  aridl character varying(22),
  aridr character varying(22),
  linearid character varying(22),
  fullname character varying(100),
  lfromhn character varying(12),
  ltohn character varying(12),
  rfromhn character varying(12),
  rtohn character varying(12),
  zipl character varying(5),
  zipr character varying(5),
  edge_mtfcc character varying(5),
  parityl character varying(1),
  parityr character varying(1),
  plus4l character varying(4),
  plus4r character varying(4),
  lfromtyp character varying(1),
  ltotyp character varying(1),
  rfromtyp character varying(1),
  rtotyp character varying(1),
  offsetl character varying(1),
  offsetr character varying(1),
  the_geom geometry,
  CONSTRAINT enforce_dims_the_geom CHECK (st_ndims(the_geom) = 2),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'LINESTRING'::text OR the_geom IS NULL),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 4269)
);
CREATE INDEX idx_addrfeat_geom_gist ON addrfeat USING gist(the_geom );
CREATE INDEX idx_addrfeat_tlid ON addrfeat USING btree(tlid);
CREATE INDEX idx_addrfeat_zipl ON addrfeat USING btree(zipl);
CREATE INDEX idx_addrfeat_zipr ON addrfeat USING btree(zipr);


DROP TABLE IF EXISTS tiger.faces;
CREATE TABLE faces
(
gid serial NOT NULL PRIMARY KEY,
  tfid numeric(10,0),
  statefp00 varchar(2),
  countyfp00 varchar(3),
  tractce00 varchar(6),
  blkgrpce00 varchar(1),
  blockce00 varchar(4),
  cousubfp00 varchar(5),
  submcdfp00 varchar(5),
  conctyfp00 varchar(5),
  placefp00 varchar(5),
  aiannhfp00 varchar(5),
  aiannhce00 varchar(4),
  comptyp00 varchar(1),
  trsubfp00 varchar(5),
  trsubce00 varchar(3),
  anrcfp00 varchar(5),
  elsdlea00 varchar(5),
  scsdlea00 varchar(5),
  unsdlea00 varchar(5),
  uace00 varchar(5),
  cd108fp varchar(2),
  sldust00 varchar(3),
  sldlst00 varchar(3),
  vtdst00 varchar(6),
  zcta5ce00 varchar(5),
  tazce00 varchar(6),
  ugace00 varchar(5),
  puma5ce00 varchar(5),
  statefp varchar(2),
  countyfp varchar(3),
  tractce varchar(6),
  blkgrpce varchar(1),
  blockce varchar(4),
  cousubfp varchar(5),
  submcdfp varchar(5),
  conctyfp varchar(5),
  placefp varchar(5),
  aiannhfp varchar(5),
  aiannhce varchar(4),
  comptyp varchar(1),
  trsubfp varchar(5),
  trsubce varchar(3),
  anrcfp varchar(5),
  ttractce varchar(6),
  tblkgpce varchar(1),
  elsdlea varchar(5),
  scsdlea varchar(5),
  unsdlea varchar(5),
  uace varchar(5),
  cd111fp varchar(2),
  sldust varchar(3),
  sldlst varchar(3),
  vtdst varchar(6),
  zcta5ce varchar(5),
  tazce varchar(6),
  ugace varchar(5),
  puma5ce varchar(5),
  csafp varchar(3),
  cbsafp varchar(5),
  metdivfp varchar(5),
  cnectafp varchar(3),
  nectafp varchar(5),
  nctadvfp varchar(5),
  lwflag varchar(1),
  "offset" varchar(1),
  atotal double precision,
  intptlat varchar(11),
  intptlon varchar(12),
  the_geom geometry,
  CONSTRAINT enforce_dims_the_geom CHECK (st_ndims(the_geom) = 2),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 4269)
);
CREATE INDEX idx_tiger_faces_tfid ON faces USING btree (tfid);
CREATE INDEX idx_tiger_faces_countyfp ON faces USING btree(countyfp);
CREATE INDEX tiger_faces_the_geom_gist ON faces USING gist(the_geom);

DROP TABLE IF EXISTS tiger.featnames;
CREATE TABLE featnames
(
  gid SERIAL NOT NULL,
  tlid bigint,
  fullname character varying(100),
  "name" character varying(100),
  predirabrv character varying(15),
  pretypabrv character varying(50),
  prequalabr character varying(15),
  sufdirabrv character varying(15),
  suftypabrv character varying(50),
  sufqualabr character varying(15),
  predir character varying(2),
  pretyp character varying(3),
  prequal character varying(2),
  sufdir character varying(2),
  suftyp character varying(3),
  sufqual character varying(2),
  linearid character varying(22),
  mtfcc character varying(5),
  paflag character varying(1),
  CONSTRAINT featnames_pkey PRIMARY KEY (gid)
);
ALTER TABLE featnames ADD COLUMN statefp character varying(2);
CREATE INDEX idx_tiger_featnames_snd_name ON featnames USING btree (soundex(name));
CREATE INDEX idx_tiger_featnames_lname ON featnames USING btree (lower(name));
CREATE INDEX idx_tiger_featnames_tlid_statefp ON featnames USING btree (tlid,statefp);

CREATE TABLE addr
(
  gid SERIAL NOT NULL,
  tlid bigint,
  fromhn character varying(12),
  tohn character varying(12),
  side character varying(1),
  zip character varying(5),
  plus4 character varying(4),
  fromtyp character varying(1),
  totyp character varying(1),
  fromarmid integer,
  toarmid integer,
  arid character varying(22),
  mtfcc character varying(5),
  CONSTRAINT addr_pkey PRIMARY KEY (gid)
);
ALTER TABLE addr ADD COLUMN statefp character varying(2);

CREATE INDEX idx_tiger_addr_tlid_statefp ON addr USING btree(tlid,statefp);
CREATE INDEX idx_tiger_addr_zip ON addr USING btree (zip);

--DROP TABLE IF EXISTS tiger.zcta5;
CREATE TABLE zcta5
(
  gid serial NOT NULL,
  statefp character varying(2),
  zcta5ce character varying(5),
  classfp character varying(2),
  mtfcc character varying(5),
  funcstat character varying(1),
  aland double precision,
  awater double precision,
  intptlat character varying(11),
  intptlon character varying(12),
  partflg character varying(1),
  the_geom geometry,
  CONSTRAINT uidx_tiger_zcta5_gid UNIQUE (gid),
  CONSTRAINT enforce_dims_the_geom CHECK (st_ndims(the_geom) = 2),
  CONSTRAINT enforce_geotype_the_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 4269),
  CONSTRAINT pk_tiger_zcta5_zcta5ce PRIMARY KEY (zcta5ce,statefp)
 );
--$Id: tiger_loader_2012.sql 10633 2012-11-03 17:54:51Z robe $
--
-- PostGIS - Spatial Types for PostgreSQL
-- http://www.postgis.org
--
-- Copyright (C) 2010, 2011, 2012 Regina Obe and Leo Hsu 
-- Paragon Corporation
--
-- This is free software; you can redistribute and/or modify it under
-- the terms of the GNU General Public Licence. See the COPYING file.
--
-- Author: Regina Obe and Leo Hsu <lr@pcorp.us>
--  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--SET search_path TO tiger,public;
--ALTER TABLE tiger.faces RENAME cd111fp  TO cdfp;
SELECT tiger.SetSearchPathForInstall('tiger');

CREATE OR REPLACE FUNCTION loader_macro_replace(param_input text, param_keys text[],param_values text[]) 
RETURNS text AS
$$
	DECLARE var_result text = param_input;
	DECLARE var_count integer = array_upper(param_keys,1);
	BEGIN
		FOR i IN 1..var_count LOOP
			var_result := replace(var_result, '${' || param_keys[i] || '}', param_values[i]);
		END LOOP;
		return var_result;
	END;
$$
  LANGUAGE 'plpgsql' IMMUTABLE
  COST 100;

-- Helper function that generates script to drop all tables in a particular schema for a particular table
-- This is useful in case you need to reload a state
CREATE OR REPLACE FUNCTION drop_state_tables_generate_script(param_state text, param_schema text DEFAULT 'tiger_data')
  RETURNS text AS
$$
SELECT array_to_string(array_agg('DROP TABLE ' || quote_ident(table_schema) || '.' || quote_ident(table_name) || ';'),E'\n')
	FROM (SELECT * FROM information_schema.tables
	WHERE table_schema = $2 AND table_name like lower($1) || '_%' ORDER BY table_name) AS foo; 
;
$$
  LANGUAGE sql VOLATILE;
  
-- Helper function that generates script to drop all nation tables (county, state) in a particular schema 
-- This is useful for loading 2011 because state and county tables aren't broken out into separate state files
DROP FUNCTION IF EXISTS drop_national_tables_generate_script(text);
CREATE OR REPLACE FUNCTION drop_nation_tables_generate_script(param_schema text DEFAULT 'tiger_data')
  RETURNS text AS
$$
SELECT array_to_string(array_agg('DROP TABLE ' || quote_ident(table_schema) || '.' || quote_ident(table_name) || ';'),E'\n')
	FROM (SELECT * FROM information_schema.tables
	WHERE table_schema = $1 AND (table_name ~ E'^[a-z]{2}\_county' or table_name ~ E'^[a-z]{2}\_state' or table_name = 'state_all' or table_name LIKE 'county_all%') ORDER BY table_name) AS foo; 
;
$$
  LANGUAGE sql VOLATILE;
  


DROP TABLE IF EXISTS loader_platform;
CREATE TABLE loader_platform(os varchar(50) PRIMARY KEY, declare_sect text, pgbin text, wget text, unzip_command text, psql text, path_sep text, loader text, environ_set_command text, county_process_command text);
GRANT SELECT ON TABLE loader_platform TO public;
INSERT INTO loader_platform(os, wget, pgbin, declare_sect, unzip_command, psql,path_sep,loader, environ_set_command, county_process_command)
VALUES('windows', '%WGETTOOL%', '%PGBIN%', 
E'set TMPDIR=${staging_fold}\\temp\\
set UNZIPTOOL="C:\\Program Files\\7-Zip\\7z.exe"
set WGETTOOL="C:\\wget\\wget.exe"
set PGBIN=C:\\Program Files\\PostgreSQL\\8.4\\bin\\
set PGPORT=5432
set PGHOST=localhost
set PGUSER=postgres
set PGPASSWORD=yourpasswordhere
set PGDATABASE=geocoder
set PSQL="%PGBIN%psql"
set SHP2PGSQL="%PGBIN%shp2pgsql"
cd ${staging_fold}
', E'del %TMPDIR%\\*.* /Q
%PSQL% -c "DROP SCHEMA ${staging_schema} CASCADE;"
%PSQL% -c "CREATE SCHEMA ${staging_schema};"
for /r %%z in (*.zip) do %UNZIPTOOL% e %%z  -o%TMPDIR% 
cd %TMPDIR%', E'%PSQL%', E'\\', E'%SHP2PGSQL%', 'set ', 
'for /r %%z in (*${table_name}.dbf) do (${loader}  -s 4269 -g the_geom -W "latin1" %%z tiger_staging.${state_abbrev}_${table_name} | ${psql} & ${psql} -c "SELECT loader_load_staged_data(lower(''${state_abbrev}_${table_name}''), lower(''${state_abbrev}_${lookup_name}''));")'
);


INSERT INTO loader_platform(os, wget, pgbin, declare_sect, unzip_command, psql, path_sep, loader, environ_set_command, county_process_command)
VALUES('sh', 'wget', '', 
E'TMPDIR="${staging_fold}/temp/"
UNZIPTOOL=unzip
WGETTOOL="/usr/bin/wget"
export PGBIN=/usr/pgsql-9.0/bin
export PGPORT=5432
export PGHOST=localhost
export PGUSER=postgres
export PGPASSWORD=yourpasswordhere
export PGDATABASE=geocoder
PSQL=${PGBIN}/psql
SHP2PGSQL=${PGBIN}/shp2pgsql
cd ${staging_fold}
', E'rm -f ${TMPDIR}/*.*
${PSQL} -c "DROP SCHEMA tiger_staging CASCADE;"
${PSQL} -c "CREATE SCHEMA tiger_staging;"

for z in *.zip; do $UNZIPTOOL -o -d $TMPDIR $z; done
for z in */*.zip; do $UNZIPTOOL -o -d $TMPDIR $z; done
cd $TMPDIR;\n', '${PSQL}', '/', '${SHP2PGSQL}', 'export ',
'for z in *${table_name}.dbf; do 
${loader} -s 4269 -g the_geom -W "latin1" $z ${staging_schema}.${state_abbrev}_${table_name} | ${psql} 
${PSQL} -c "SELECT loader_load_staged_data(lower(''${state_abbrev}_${table_name}''), lower(''${state_abbrev}_${lookup_name}''));"
done');

-- variables table
DROP TABLE IF EXISTS loader_variables;
CREATE TABLE loader_variables(tiger_year varchar(4) PRIMARY KEY, website_root text, staging_fold text, data_schema text, staging_schema text);
INSERT INTO loader_variables(tiger_year, website_root , staging_fold, data_schema, staging_schema)
	VALUES('2012', 'ftp://ftp2.census.gov/geo/tiger/TIGER2012', '/gisdata', 'tiger_data', 'tiger_staging');
GRANT SELECT ON TABLE loader_variables TO public;

DROP TABLE IF EXISTS loader_lookuptables;
CREATE TABLE loader_lookuptables(process_order integer NOT NULL DEFAULT 1000, 
		lookup_name text primary key, 
		table_name text, single_mode boolean NOT NULL DEFAULT true, 
		load boolean NOT NULL DEFAULT true, 
		level_county boolean NOT NULL DEFAULT false, 
		level_state boolean NOT NULL DEFAULT false,
		level_nation boolean NOT NULL DEFAULT false,
		post_load_process text, single_geom_mode boolean DEFAULT false, 
		insert_mode char(1) NOT NULL DEFAULT 'c', 
		pre_load_process text,columns_exclude text[], website_root_override text);
		
GRANT SELECT ON TABLE loader_lookuptables TO public;
		
-- put in explanatory comments of what each column is for
COMMENT ON COLUMN loader_lookuptables.lookup_name IS 'This is the table name to inherit from and suffix of resulting output table -- how the table will be named --  edges here would mean -- ma_edges , pa_edges etc. except in the case of national tables. national level tables have no prefix';
COMMENT ON COLUMN loader_lookuptables.level_nation IS 'These are tables that contain all data for the whole US so there is just a single file';
COMMENT ON COLUMN loader_lookuptables.table_name IS 'suffix of the tables to load e.g.  edges would load all tables like *edges.dbf(shp)  -- so tl_2010_42129_edges.dbf .  ';
COMMENT ON COLUMN loader_lookuptables.load IS 'Whether or not to load the table.  For states and zcta5 (you may just want to download states10, zcta510 nationwide file manually) load your own into a single table that inherits from tiger.states, tiger.zcta5.  You''ll get improved performance for some geocoding cases.';
COMMENT ON COLUMN loader_lookuptables.columns_exclude IS 'List of columns to exclude as an array. This is excluded from both input table and output table and rest of columns remaining are assumed to be in same order in both tables. gid, geoid,cpi,suffix1ce are excluded if no columns are specified.';
COMMENT ON COLUMN loader_lookuptables.website_root_override IS 'Path to use for wget instead of that specified in year table.  Needed currently for zcta where they release that only for 2000 and 2010';

INSERT INTO loader_lookuptables(process_order, lookup_name, table_name, load, level_county, level_state,  level_nation, single_geom_mode, pre_load_process, post_load_process)
VALUES(2, 'county_all', 'county', true, false, false, true,
	false, '${psql} -c "CREATE TABLE ${data_schema}.${lookup_name}(CONSTRAINT pk_${data_schema}_${lookup_name} PRIMARY KEY (cntyidfp),CONSTRAINT uidx_${data_schema}_${lookup_name}_gid UNIQUE (gid)  ) INHERITS(county); " ',
	'${psql} -c "ALTER TABLE ${staging_schema}.${table_name} RENAME geoid TO cntyidfp;  SELECT loader_load_staged_data(lower(''${table_name}''), lower(''${lookup_name}''));"
	${psql} -c "CREATE INDEX ${data_schema}_${table_name}_the_geom_gist ON ${data_schema}.${lookup_name} USING gist(the_geom);"
	${psql} -c "CREATE UNIQUE INDEX uidx_${data_schema}_${lookup_name}_statefp_countyfp ON ${data_schema}.${lookup_name} USING btree(statefp,countyfp);"
	${psql} -c "CREATE TABLE ${data_schema}.${lookup_name}_lookup ( CONSTRAINT pk_${lookup_name}_lookup PRIMARY KEY (st_code, co_code)) INHERITS (county_lookup);"
	${psql} -c "VACUUM ANALYZE ${data_schema}.${lookup_name};"
	${psql} -c "INSERT INTO ${data_schema}.${lookup_name}_lookup(st_code, state, co_code, name) SELECT CAST(s.statefp as integer), s.abbrev, CAST(c.countyfp as integer), c.name FROM ${data_schema}.${lookup_name} As c INNER JOIN state_lookup As s ON s.statefp = c.statefp;"
	${psql} -c "VACUUM ANALYZE ${data_schema}.${lookup_name}_lookup;" ');
	
INSERT INTO loader_lookuptables(process_order, lookup_name, table_name, load, level_county, level_state, level_nation, single_geom_mode, insert_mode, pre_load_process, post_load_process )
VALUES(1, 'state_all', 'state', true, false, false,true,false, 'c', 
	'${psql} -c "CREATE TABLE ${data_schema}.${lookup_name}(CONSTRAINT pk_${lookup_name} PRIMARY KEY (statefp),CONSTRAINT uidx_${lookup_name}_stusps  UNIQUE (stusps), CONSTRAINT uidx_${lookup_name}_gid UNIQUE (gid) ) INHERITS(state); "',
	'${psql} -c "SELECT loader_load_staged_data(lower(''${table_name}''), lower(''${lookup_name}'')); "
	${psql} -c "CREATE INDEX ${data_schema}_${lookup_name}_the_geom_gist ON ${data_schema}.${lookup_name} USING gist(the_geom);"
	${psql} -c "VACUUM ANALYZE ${data_schema}.${lookup_name}"' );

INSERT INTO loader_lookuptables(process_order, lookup_name, table_name, load, level_county, level_state, single_geom_mode, insert_mode, pre_load_process, post_load_process )
VALUES(3, 'place', 'place', true, false, true,false, 'c', 
	'${psql} -c "CREATE TABLE ${data_schema}.${state_abbrev}_${lookup_name}(CONSTRAINT pk_${state_abbrev}_${table_name} PRIMARY KEY (plcidfp) ) INHERITS(place);" ',
	'${psql} -c "ALTER TABLE ${staging_schema}.${state_abbrev}_${table_name} RENAME geoid TO plcidfp;SELECT loader_load_staged_data(lower(''${state_abbrev}_${table_name}''), lower(''${state_abbrev}_${lookup_name}'')); ALTER TABLE ${data_schema}.${state_abbrev}_${lookup_name} ADD CONSTRAINT uidx_${state_abbrev}_${lookup_name}_gid UNIQUE (gid);"
${psql} -c "CREATE INDEX idx_${state_abbrev}_${lookup_name}_soundex_name ON ${data_schema}.${state_abbrev}_${lookup_name} USING btree (soundex(name));" 
${psql} -c "CREATE INDEX ${data_schema}_${state_abbrev}_${lookup_name}_the_geom_gist ON ${data_schema}.${state_abbrev}_${lookup_name} USING gist(the_geom);"
${psql} -c "ALTER TABLE ${data_schema}.${state_abbrev}_${lookup_name} ADD CONSTRAINT chk_statefp CHECK (statefp = ''${state_fips}'');"'  
	);

INSERT INTO loader_lookuptables(process_order, lookup_name, table_name, load, level_county, level_state, single_geom_mode, insert_mode, pre_load_process, post_load_process )
VALUES(4, 'cousub', 'cousub', true, false, true,false, 'c', 
	'${psql} -c "CREATE TABLE ${data_schema}.${state_abbrev}_${lookup_name}(CONSTRAINT pk_${state_abbrev}_${lookup_name} PRIMARY KEY (cosbidfp), CONSTRAINT uidx_${state_abbrev}_${lookup_name}_gid UNIQUE (gid)) INHERITS(${lookup_name});" ',
	'${psql} -c "ALTER TABLE ${staging_schema}.${state_abbrev}_${table_name} RENAME geoid TO cosbidfp;SELECT loader_load_staged_data(lower(''${state_abbrev}_${table_name}''), lower(''${state_abbrev}_${lookup_name}'')); ALTER TABLE ${data_schema}.${state_abbrev}_${lookup_name} ADD CONSTRAINT chk_statefp CHECK (statefp = ''${state_fips}'');"
${psql} -c "CREATE INDEX ${data_schema}_${state_abbrev}_${lookup_name}_the_geom_gist ON ${data_schema}.${state_abbrev}_${lookup_name} USING gist(the_geom);"
${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_${lookup_name}_countyfp ON ${data_schema}.${state_abbrev}_${lookup_name} USING btree(countyfp);"');
	
INSERT INTO loader_lookuptables(process_order, lookup_name, table_name, load, level_county, level_state, level_nation, single_geom_mode, insert_mode, pre_load_process, post_load_process, columns_exclude, website_root_override  )
-- this is a bit of a lie that its county.  It's really state but works better with column routine
VALUES(4, 'zcta5', 'zcta510', true,true, false,false, false, 'a', 
	'${psql} -c "CREATE TABLE ${data_schema}.${state_abbrev}_${lookup_name}(CONSTRAINT pk_${state_abbrev}_${lookup_name} PRIMARY KEY (zcta5ce,statefp), CONSTRAINT uidx_${state_abbrev}_${lookup_name}_gid UNIQUE (gid)) INHERITS(${lookup_name});" ',
	'${psql} -c "ALTER TABLE ${data_schema}.${state_abbrev}_${lookup_name} ADD CONSTRAINT chk_statefp CHECK (statefp = ''${state_fips}'');"
${psql} -c "CREATE INDEX ${data_schema}_${state_abbrev}_${lookup_name}_the_geom_gist ON ${data_schema}.${state_abbrev}_${lookup_name} USING gist(the_geom);"'
, ARRAY['gid','geoid','geoid10'], 'ftp://ftp2.census.gov/geo/tiger/TIGER2010/ZCTA5/2010');


INSERT INTO loader_lookuptables(process_order, lookup_name, table_name, load, level_county, level_state, single_geom_mode, insert_mode, pre_load_process, post_load_process )
VALUES(6, 'faces', 'faces', true, true, false,false, 'c', 
	'${psql} -c "CREATE TABLE ${data_schema}.${state_abbrev}_${table_name}(CONSTRAINT pk_${state_abbrev}_${lookup_name} PRIMARY KEY (gid)) INHERITS(${lookup_name});" ',
	'${psql} -c "CREATE INDEX ${data_schema}_${state_abbrev}_${table_name}_the_geom_gist ON ${data_schema}.${state_abbrev}_${lookup_name} USING gist(the_geom);"
	${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_${lookup_name}_tfid ON ${data_schema}.${state_abbrev}_${lookup_name} USING btree (tfid);"
	${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_${table_name}_countyfp ON ${data_schema}.${state_abbrev}_${table_name} USING btree (countyfp);"
	${psql} -c "ALTER TABLE ${data_schema}.${state_abbrev}_${lookup_name} ADD CONSTRAINT chk_statefp CHECK (statefp = ''${state_fips}'');"
	${psql} -c "vacuum analyze ${data_schema}.${state_abbrev}_${lookup_name};"');

INSERT INTO loader_lookuptables(process_order, lookup_name, table_name, load, level_county, level_state, single_geom_mode, insert_mode, pre_load_process, post_load_process, columns_exclude )
VALUES(7, 'featnames', 'featnames', true, true, false,false, 'a', 
'${psql} -c "CREATE TABLE ${data_schema}.${state_abbrev}_${table_name}(CONSTRAINT pk_${state_abbrev}_${table_name} PRIMARY KEY (gid)) INHERITS(${table_name});ALTER TABLE ${data_schema}.${state_abbrev}_${table_name} ALTER COLUMN statefp SET DEFAULT ''${state_fips}'';" ',
'${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_${lookup_name}_snd_name ON ${data_schema}.${state_abbrev}_${table_name} USING btree (soundex(name));"
${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_${lookup_name}_lname ON ${data_schema}.${state_abbrev}_${table_name} USING btree (lower(name));"
${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_${lookup_name}_tlid_statefp ON ${data_schema}.${state_abbrev}_${table_name} USING btree (tlid,statefp);"
${psql} -c "ALTER TABLE ${data_schema}.${state_abbrev}_${lookup_name} ADD CONSTRAINT chk_statefp CHECK (statefp = ''${state_fips}'');"
${psql} -c "vacuum analyze ${data_schema}.${state_abbrev}_${lookup_name};"', ARRAY['gid','statefp']);
	
INSERT INTO loader_lookuptables(process_order, lookup_name, table_name, load, level_county, level_state, single_geom_mode, insert_mode, pre_load_process, post_load_process )
VALUES(8, 'edges', 'edges', true, true, false,false, 'a', 
'${psql} -c "CREATE TABLE ${data_schema}.${state_abbrev}_${table_name}(CONSTRAINT pk_${state_abbrev}_${table_name} PRIMARY KEY (gid)) INHERITS(${table_name});" ',
'${psql} -c "ALTER TABLE ${data_schema}.${state_abbrev}_${table_name} ADD CONSTRAINT chk_statefp CHECK (statefp = ''${state_fips}'');"
${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_${lookup_name}_tlid ON ${data_schema}.${state_abbrev}_${table_name} USING btree (tlid);"
${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_${lookup_name}tfidr ON ${data_schema}.${state_abbrev}_${table_name} USING btree (tfidr);"
${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_${lookup_name}_tfidl ON ${data_schema}.${state_abbrev}_${table_name} USING btree (tfidl);"
${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_${lookup_name}_countyfp ON ${data_schema}.${state_abbrev}_${table_name} USING btree (countyfp);"
${psql} -c "CREATE INDEX ${data_schema}_${state_abbrev}_${table_name}_the_geom_gist ON ${data_schema}.${state_abbrev}_${table_name} USING gist(the_geom);"
${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_${lookup_name}_zipl ON ${data_schema}.${state_abbrev}_${lookup_name} USING btree (zipl);"
${psql} -c "CREATE TABLE ${data_schema}.${state_abbrev}_zip_state_loc(CONSTRAINT pk_${state_abbrev}_zip_state_loc PRIMARY KEY(zip,stusps,place)) INHERITS(zip_state_loc);"
${psql} -c "INSERT INTO ${data_schema}.${state_abbrev}_zip_state_loc(zip,stusps,statefp,place) SELECT DISTINCT e.zipl, ''${state_abbrev}'', ''${state_fips}'', p.name FROM ${data_schema}.${state_abbrev}_edges AS e INNER JOIN ${data_schema}.${state_abbrev}_faces AS f ON (e.tfidl = f.tfid OR e.tfidr = f.tfid) INNER JOIN ${data_schema}.${state_abbrev}_place As p ON(f.statefp = p.statefp AND f.placefp = p.placefp ) WHERE e.zipl IS NOT NULL;"
${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_zip_state_loc_place ON ${data_schema}.${state_abbrev}_zip_state_loc USING btree(soundex(place));"
${psql} -c "ALTER TABLE ${data_schema}.${state_abbrev}_zip_state_loc ADD CONSTRAINT chk_statefp CHECK (statefp = ''${state_fips}'');"
${psql} -c "vacuum analyze ${data_schema}.${state_abbrev}_${lookup_name};"
${psql} -c "vacuum analyze ${data_schema}.${state_abbrev}_zip_state_loc;"
${psql} -c "CREATE TABLE ${data_schema}.${state_abbrev}_zip_lookup_base(CONSTRAINT pk_${state_abbrev}_zip_state_loc_city PRIMARY KEY(zip,state, county, city, statefp)) INHERITS(zip_lookup_base);"
${psql} -c "INSERT INTO ${data_schema}.${state_abbrev}_zip_lookup_base(zip,state,county,city, statefp) SELECT DISTINCT e.zipl, ''${state_abbrev}'', c.name,p.name,''${state_fips}''  FROM ${data_schema}.${state_abbrev}_edges AS e INNER JOIN tiger.county As c  ON (e.countyfp = c.countyfp AND e.statefp = c.statefp AND e.statefp = ''${state_fips}'') INNER JOIN ${data_schema}.${state_abbrev}_faces AS f ON (e.tfidl = f.tfid OR e.tfidr = f.tfid) INNER JOIN ${data_schema}.${state_abbrev}_place As p ON(f.statefp = p.statefp AND f.placefp = p.placefp ) WHERE e.zipl IS NOT NULL;"
${psql} -c "ALTER TABLE ${data_schema}.${state_abbrev}_zip_lookup_base ADD CONSTRAINT chk_statefp CHECK (statefp = ''${state_fips}'');"
${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_zip_lookup_base_citysnd ON ${data_schema}.${state_abbrev}_zip_lookup_base USING btree(soundex(city));" ');
	
INSERT INTO loader_lookuptables(process_order, lookup_name, table_name, load, level_county, level_state, single_geom_mode, insert_mode, pre_load_process, post_load_process,columns_exclude )
VALUES(9, 'addr', 'addr', true, true, false,false, 'a', 
	'${psql} -c "CREATE TABLE ${data_schema}.${state_abbrev}_${lookup_name}(CONSTRAINT pk_${state_abbrev}_${table_name} PRIMARY KEY (gid)) INHERITS(${table_name});ALTER TABLE ${data_schema}.${state_abbrev}_${lookup_name} ALTER COLUMN statefp SET DEFAULT ''${state_fips}'';" ',
	'${psql} -c "ALTER TABLE ${data_schema}.${state_abbrev}_${lookup_name} ADD CONSTRAINT chk_statefp CHECK (statefp = ''${state_fips}'');"
	${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_${lookup_name}_least_address ON tiger_data.${state_abbrev}_addr USING btree (least_hn(fromhn,tohn) );"
	${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_${table_name}_tlid_statefp ON ${data_schema}.${state_abbrev}_${table_name} USING btree (tlid, statefp);"
	${psql} -c "CREATE INDEX idx_${data_schema}_${state_abbrev}_${table_name}_zip ON ${data_schema}.${state_abbrev}_${table_name} USING btree (zip);"
	${psql} -c "CREATE TABLE ${data_schema}.${state_abbrev}_zip_state(CONSTRAINT pk_${state_abbrev}_zip_state PRIMARY KEY(zip,stusps)) INHERITS(zip_state); "
	${psql} -c "INSERT INTO ${data_schema}.${state_abbrev}_zip_state(zip,stusps,statefp) SELECT DISTINCT zip, ''${state_abbrev}'', ''${state_fips}'' FROM ${data_schema}.${state_abbrev}_${lookup_name} WHERE zip is not null;"
	${psql} -c "ALTER TABLE ${data_schema}.${state_abbrev}_zip_state ADD CONSTRAINT chk_statefp CHECK (statefp = ''${state_fips}'');"
	${psql} -c "vacuum analyze ${data_schema}.${state_abbrev}_${lookup_name};"',  ARRAY['gid','statefp','fromarmid', 'toarmid']);
	
INSERT INTO loader_lookuptables(process_order, lookup_name, table_name, load, level_county, level_state, single_geom_mode, insert_mode, pre_load_process, post_load_process,columns_exclude )
VALUES(9, 'addrfeat', 'addrfeat', false, true, false,true, 'a', 
	'${psql} -c "CREATE TABLE ${data_schema}.${state_abbrev}_${lookup_name}(CONSTRAINT pk_${state_abbrev}_${table_name} PRIMARY KEY (gid)) INHERITS(${table_name});ALTER TABLE ${data_schema}.${state_abbrev}_${lookup_name} ALTER COLUMN statefp SET DEFAULT ''${state_fips}'';" ',
	'${psql} -c "ALTER TABLE ${data_schema}.${state_abbrev}_${lookup_name} ADD CONSTRAINT chk_statefp CHECK (statefp = ''${state_fips}'');"
	${psql} -c "vacuum analyze ${data_schema}.${state_abbrev}_${lookup_name};"',  ARRAY['gid','statefp','fromarmid', 'toarmid']);

CREATE OR REPLACE FUNCTION loader_generate_nation_script(os text)
  RETURNS SETOF text AS
$BODY$
WITH lu AS (SELECT lookup_name, table_name, pre_load_process,post_load_process, process_order, insert_mode, single_geom_mode, level_nation, level_county, level_state
    FROM  loader_lookuptables 
				WHERE level_nation = true AND load = true)
SELECT 
	loader_macro_replace(
		replace(
			loader_macro_replace(declare_sect
				, ARRAY['staging_fold', 'website_root', 'psql',  'data_schema', 'staging_schema'], 
				ARRAY[variables.staging_fold, variables.website_root, platform.psql, variables.data_schema, variables.staging_schema]
			), '/', platform.path_sep) || '
'  ||
	-- Nation level files
	array_to_string( ARRAY(SELECT loader_macro_replace('cd ' || replace(variables.staging_fold,'/', platform.path_sep) || '
' || platform.wget || ' ' || variables.website_root  || '/' || upper(table_name)  || '/ --no-parent --relative --recursive --level=1 --accept=zip --mirror --reject=html 
'
|| 'cd ' ||  replace(variables.staging_fold,'/', platform.path_sep) || '/' || replace(replace(variables.website_root, 'http://', ''),'ftp://','')  || '/' || upper(table_name)  || '
' || replace(platform.unzip_command, '*.zip', 'tl_*' || table_name || '.zip ') || '
' || COALESCE(lu.pre_load_process || E'\n', '') || platform.loader || ' -' ||  lu.insert_mode || ' -s 4269 -g the_geom ' 
		|| CASE WHEN lu.single_geom_mode THEN ' -S ' ELSE ' ' END::text || ' -W "latin1" tl_' || variables.tiger_year 
	|| '_us_' || lu.table_name || '.dbf tiger_staging.' || lu.table_name || ' | '::text || platform.psql 
		|| COALESCE(E'\n' || 
			lu.post_load_process , '') , ARRAY['loader','table_name', 'lookup_name'], ARRAY[platform.loader, lu.table_name, lu.lookup_name ]
			)
				FROM lu
				ORDER BY process_order, lookup_name), E'\n') ::text 
	, ARRAY['psql', 'data_schema','staging_schema', 'staging_fold', 'website_root'], 
	ARRAY[platform.psql,  variables.data_schema, variables.staging_schema, variables.staging_fold, variables.website_root])
			AS shell_code
FROM loader_variables As variables
	 CROSS JOIN loader_platform As platform
WHERE platform.os = $1 -- generate script for selected platform
;
$BODY$
  LANGUAGE sql VOLATILE;
  
CREATE OR REPLACE FUNCTION loader_generate_script(param_states text[], os text)
  RETURNS SETOF text AS
$BODY$
SELECT 
	loader_macro_replace(
		replace(
			loader_macro_replace(declare_sect
				, ARRAY['staging_fold', 'state_fold','website_root', 'psql', 'state_abbrev', 'data_schema', 'staging_schema', 'state_fips'], 
				ARRAY[variables.staging_fold, s.state_fold, variables.website_root, platform.psql, s.state_abbrev, variables.data_schema, variables.staging_schema, s.state_fips::text]
			), '/', platform.path_sep) || '
' ||
	-- State level files - if an override website is specified we use that instead of variable one
	array_to_string( ARRAY(SELECT 'cd ' || replace(variables.staging_fold,'/', platform.path_sep) || '
' || platform.wget || ' ' || COALESCE(lu.website_root_override,variables.website_root || '/' || upper(table_name)  ) || '/*_' || s.state_fips || '* --no-parent --relative --recursive --level=2 --accept=zip --mirror --reject=html 
'
|| 'cd ' ||  replace(variables.staging_fold,'/', platform.path_sep) || '/' || replace(replace(COALESCE(lu.website_root_override,variables.website_root || '/' || upper(table_name) ), 'http://', ''),'ftp://','')    || '
' || replace(platform.unzip_command, '*.zip', 'tl_*_' || s.state_fips || '*_' || table_name || '.zip ') || '
' ||loader_macro_replace(COALESCE(lu.pre_load_process || E'\n', '') || platform.loader || ' -' ||  lu.insert_mode || ' -s 4269 -g the_geom ' 
		|| CASE WHEN lu.single_geom_mode THEN ' -S ' ELSE ' ' END::text || ' -W "latin1" tl_' || variables.tiger_year || '_' || s.state_fips 
	|| '_' || lu.table_name || '.dbf tiger_staging.' || lower(s.state_abbrev) || '_' || lu.table_name || ' | '::text || platform.psql 
		|| COALESCE(E'\n' || 
			lu.post_load_process , '') , ARRAY['loader','table_name', 'lookup_name'], ARRAY[platform.loader, lu.table_name, lu.lookup_name ])
				FROM loader_lookuptables AS lu
				WHERE level_state = true AND load = true
				ORDER BY process_order, lookup_name), E'\n') ::text 
	-- County Level files
	|| E'\n' ||
		array_to_string( ARRAY(SELECT 'cd ' || replace(variables.staging_fold,'/', platform.path_sep) || '
' || platform.wget || ' ' || COALESCE(lu.website_root_override,variables.website_root || '/' || upper(table_name)  ) || '/*_' || s.state_fips || '* --no-parent --relative --recursive --level=2 --accept=zip --mirror --reject=html 
'
|| 'cd ' ||  replace(variables.staging_fold,'/', platform.path_sep) || '/' || replace(replace(COALESCE(lu.website_root_override,variables.website_root || '/' || upper(table_name)  || '/'), 'http://', ''),'ftp://','')  || '
' || replace(platform.unzip_command, '*.zip', 'tl_*_' || s.state_fips || '*_' || table_name || '.zip ') || '
' || loader_macro_replace(COALESCE(lu.pre_load_process || E'\n', '') || COALESCE(county_process_command || E'\n','')
				|| COALESCE(E'\n' ||lu.post_load_process , '') , ARRAY['loader','table_name','lookup_name'], ARRAY[platform.loader  || CASE WHEN lu.single_geom_mode THEN ' -S' ELSE ' ' END::text, lu.table_name, lu.lookup_name ]) 
				FROM loader_lookuptables AS lu
				WHERE level_county = true AND load = true
				ORDER BY process_order, lookup_name), E'\n') ::text 
	, ARRAY['psql', 'data_schema','staging_schema', 'staging_fold', 'state_fold', 'website_root', 'state_abbrev','state_fips'], 
	ARRAY[platform.psql,  variables.data_schema, variables.staging_schema, variables.staging_fold, s.state_fold,variables.website_root, s.state_abbrev, s.state_fips::text])
			AS shell_code
FROM loader_variables As variables
		CROSS JOIN (SELECT name As state, abbrev As state_abbrev, lpad(st_code::text,2,'0') As state_fips, 
			 lpad(st_code::text,2,'0') || '_' 
	|| replace(name, ' ', '_') As state_fold
FROM state_lookup) As s CROSS JOIN loader_platform As platform
WHERE $1 @> ARRAY[state_abbrev::text]      -- If state is contained in list of states input generate script for it
AND platform.os = $2  -- generate script for selected platform
;
$BODY$
  LANGUAGE sql VOLATILE;

CREATE OR REPLACE FUNCTION loader_load_staged_data(param_staging_table text, param_target_table text, param_columns_exclude text[]) RETURNS integer
AS
$$
DECLARE 
	var_sql text;
	var_staging_schema text; var_data_schema text;
	var_temp text;
	var_num_records bigint;
BEGIN
-- Add all the fields except geoid and gid
-- Assume all the columns are in same order as target
	SELECT staging_schema, data_schema INTO var_staging_schema, var_data_schema FROM loader_variables;
	var_sql := 'INSERT INTO ' || var_data_schema || '.' || quote_ident(param_target_table) || '(' ||
			array_to_string(ARRAY(SELECT quote_ident(column_name::text) 
				FROM information_schema.columns 
				 WHERE table_name = param_target_table
					AND table_schema = var_data_schema 
					AND column_name <> ALL(param_columns_exclude) ), ',') || ') SELECT ' 
					|| array_to_string(ARRAY(SELECT quote_ident(column_name::text) 
				FROM information_schema.columns 
				 WHERE table_name = param_staging_table
					AND table_schema = var_staging_schema 
					AND column_name <> ALL( param_columns_exclude) ), ',') ||' FROM ' 
					|| var_staging_schema || '.' || param_staging_table || ';';
	RAISE NOTICE '%', var_sql;
	EXECUTE (var_sql);
	GET DIAGNOSTICS var_num_records = ROW_COUNT;
	SELECT DropGeometryTable(var_staging_schema,param_staging_table) INTO var_temp;
	RETURN var_num_records;
END;
$$
LANGUAGE 'plpgsql' VOLATILE;

CREATE OR REPLACE FUNCTION loader_load_staged_data(param_staging_table text, param_target_table text) 
RETURNS integer AS
$$
-- exclude this set list of columns if no exclusion list is specified 
   SELECT  loader_load_staged_data($1, $2,(SELECT COALESCE(columns_exclude,ARRAY['gid', 'geoid','cpi','suffix1ce', 'statefp00', 'statefp10', 'countyfp00','countyfp10'
   ,'tractce00','tractce10', 'blkgrpce00', 'blkgrpce10', 'blockce00', 'blockce10'
      , 'cousubfp00', 'submcdfp00', 'conctyfp00', 'placefp00', 'aiannhfp00', 'aiannhce00', 
       'comptyp00', 'trsubfp00', 'trsubce00', 'anrcfp00', 'elsdlea00', 'scsdlea00', 
       'unsdlea00', 'uace00', 'cd108fp', 'sldust00', 'sldlst00', 'vtdst00', 'zcta5ce00', 
       'tazce00', 'ugace00', 'puma5ce00','vtdst10','tazce10','uace10','puma5ce10','tazce', 'uace', 'vtdst', 'zcta5ce', 'zcta5ce10', 'puma5ce', 'ugace10','pumace10', 'estatefp', 'ugace']) FROM loader_lookuptables WHERE $2 LIKE '%' || lookup_name))
$$
language 'sql' VOLATILE;
--$Id: census_loader.sql 10179 2012-08-13 21:45:39Z robe $
--
-- PostGIS - Spatial Types for PostgreSQL
-- http://www.postgis.org
--
-- Copyright (C) 2010, 2011 Regina Obe and Leo Hsu 
-- Paragon Corporation
--
-- This is free software; you can redistribute and/or modify it under
-- the terms of the GNU General Public Licence. See the COPYING file.
--
-- Author: Regina Obe and Leo Hsu <lr@pcorp.us>
--  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--SET search_path TO tiger,public;
SELECT tiger.SetSearchPathForInstall('tiger');
CREATE OR REPLACE FUNCTION create_census_base_tables() 
	RETURNS text AS
$$
DECLARE var_temp text; 
BEGIN
var_temp := tiger.SetSearchPathForInstall('tiger');
IF NOT EXISTS(SELECT table_name FROM information_schema.columns WHERE table_schema = 'tiger' AND column_name = 'tract_id' AND table_name = 'tract')  THEN
	-- census block group/tracts parent tables not created yet or an older version -- drop old if not in use, create new structure
	DROP TABLE IF EXISTS tiger.tract;
	CREATE TABLE tract
	(
	  gid serial NOT NULL,
	  statefp varchar(2),
	  countyfp varchar(3),
	  tractce varchar(6),
	  tract_id varchar(11) PRIMARY KEY,
	  name varchar(7),
	  namelsad varchar(20),
	  mtfcc varchar(5),
	  funcstat varchar(1),
	  aland double precision,
	  awater double precision,
	  intptlat varchar(11),
	  intptlon varchar(12),
	  the_geom geometry,
	  CONSTRAINT enforce_dims_geom CHECK (st_ndims(the_geom) = 2),
	  CONSTRAINT enforce_geotype_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL),
	  CONSTRAINT enforce_srid_geom CHECK (st_srid(the_geom) = 4269)
	);
	COMMENT ON TABLE tiger.tract IS 'census tracts - $Id: census_loader.sql 10179 2012-08-13 21:45:39Z robe $';
	
	DROP TABLE IF EXISTS tiger.tabblock;
	CREATE TABLE tabblock
	(
	  gid serial NOT NULL,
	  statefp varchar(2),
	  countyfp varchar(3),
	  tractce varchar(6),
	  blockce varchar(4),
	  tabblock_id varchar(16) PRIMARY KEY,
	  name varchar(20),
	  mtfcc varchar(5),
	  ur varchar(1),
	  uace varchar(5),
	  funcstat varchar(1),
	  aland double precision,
	  awater double precision,
	  intptlat varchar(11),
	  intptlon varchar(12),
	  the_geom geometry,
	  CONSTRAINT enforce_dims_geom CHECK (st_ndims(the_geom) = 2),
	  CONSTRAINT enforce_geotype_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL),
	  CONSTRAINT enforce_srid_geom CHECK (st_srid(the_geom) = 4269)
	);
	COMMENT ON TABLE tiger.tabblock IS 'census blocks - $Id: census_loader.sql 10179 2012-08-13 21:45:39Z robe $';

	DROP TABLE IF EXISTS tiger.bg;
	CREATE TABLE bg
	(
	  gid serial NOT NULL,
	  statefp varchar(2),
	  countyfp varchar(3),
	  tractce varchar(6),
	  blkgrpce varchar(1),
	  bg_id varchar(12) PRIMARY KEY,
	  namelsad varchar(13),
	  mtfcc varchar(5),
	  funcstat varchar(1),
	  aland double precision,
	  awater double precision,
	  intptlat varchar(11),
	  intptlon varchar(12),
	  the_geom geometry,
	  CONSTRAINT enforce_dims_geom CHECK (st_ndims(the_geom) = 2),
	  CONSTRAINT enforce_geotype_geom CHECK (geometrytype(the_geom) = 'MULTIPOLYGON'::text OR the_geom IS NULL),
	  CONSTRAINT enforce_srid_geom CHECK (st_srid(the_geom) = 4269)
	);
	COMMENT ON TABLE tiger.bg IS 'block groups';
	RETURN 'Done creating census tract base tables - $Id: census_loader.sql 10179 2012-08-13 21:45:39Z robe $';
END IF;

IF EXISTS(SELECT * FROM information_schema.columns WHERE table_schema = 'tiger' AND column_name = 'tabblock_id' AND table_name = 'tabblock' AND character_maximum_length < 16)  THEN -- size of name and tabblock_id fields need to be increased
    ALTER TABLE tiger.tabblock ALTER COLUMN name TYPE varchar(20);
    ALTER TABLE tiger.tabblock ALTER COLUMN tabblock_id TYPE varchar(16);
    RAISE NOTICE 'Size of tabblock_id and name are being incrreased';
END IF;
RETURN 'Tables already present';
END
$$
language 'plpgsql';

DROP FUNCTION IF EXISTS loader_generate_census(text[], text);
CREATE OR REPLACE FUNCTION loader_generate_census_script(param_states text[], os text)
  RETURNS SETOF text AS
$$
SELECT create_census_base_tables();
SELECT 
	loader_macro_replace(
		replace(
			loader_macro_replace(declare_sect
				, ARRAY['staging_fold', 'state_fold','website_root', 'psql', 'state_abbrev', 'data_schema', 'staging_schema', 'state_fips'], 
				ARRAY[variables.staging_fold, s.state_fold, variables.website_root, platform.psql, s.state_abbrev, variables.data_schema, variables.staging_schema, s.state_fips::text]
			), '/', platform.path_sep) || '
' ||
	-- State level files - if an override website is specified we use that instead of variable one
	array_to_string( ARRAY(SELECT 'cd ' || replace(variables.staging_fold,'/', platform.path_sep) || '
' || platform.wget || ' ' || COALESCE(lu.website_root_override,variables.website_root || '/' || upper(table_name)  ) || '/*_' || s.state_fips || '* --no-parent --relative --recursive --level=2 --accept=zip --mirror --reject=html 
'
|| 'cd ' ||  replace(variables.staging_fold,'/', platform.path_sep) || '/' || replace(replace(COALESCE(lu.website_root_override,variables.website_root || '/' || upper(table_name) ), 'http://', ''),'ftp://','')    || '
' || replace(platform.unzip_command, '*.zip', 'tl_*_' || s.state_fips || '*_' || table_name || '.zip ') || '
' ||loader_macro_replace(COALESCE(lu.pre_load_process || E'\n', '') || platform.loader || ' -' ||  lu.insert_mode || ' -s 4269 -g the_geom ' 
		|| CASE WHEN lu.single_geom_mode THEN ' -S ' ELSE ' ' END::text || ' -W "latin1" tl_' || variables.tiger_year || '_' || s.state_fips 
	|| '_' || lu.table_name || '.dbf tiger_staging.' || lower(s.state_abbrev) || '_' || lu.table_name || ' | '::text || platform.psql 
		|| COALESCE(E'\n' || 
			lu.post_load_process , '') , ARRAY['loader','table_name', 'lookup_name'], ARRAY[platform.loader, lu.table_name, lu.lookup_name ])
				FROM loader_lookuptables AS lu
				WHERE level_state = true AND load = true AND lookup_name IN('tract','bg','tabblock')
				ORDER BY process_order, lookup_name), E'\n') ::text 
	-- County Level files
	|| E'\n' ||
		array_to_string( ARRAY(SELECT 'cd ' || replace(variables.staging_fold,'/', platform.path_sep) || '
' || platform.wget || ' ' || COALESCE(lu.website_root_override,variables.website_root || '/' || upper(table_name)  ) || '/*_' || s.state_fips || '* --no-parent --relative --recursive --level=2 --accept=zip --mirror --reject=html 
'
|| 'cd ' ||  replace(variables.staging_fold,'/', platform.path_sep) || '/' || replace(replace(COALESCE(lu.website_root_override,variables.website_root || '/' || upper(table_name)  || '/'), 'http://', ''),'ftp://','')  || '
' || replace(platform.unzip_command, '*.zip', 'tl_*_' || s.state_fips || '*_' || table_name || '.zip ') || '
' || loader_macro_replace(COALESCE(lu.pre_load_process || E'\n', '') || COALESCE(county_process_command || E'\n','')
				|| COALESCE(E'\n' ||lu.post_load_process , '') , ARRAY['loader','table_name','lookup_name'], ARRAY[platform.loader  || CASE WHEN lu.single_geom_mode THEN ' -S' ELSE ' ' END::text, lu.table_name, lu.lookup_name ]) 
				FROM loader_lookuptables AS lu
				WHERE level_county = true AND load = true AND lookup_name IN('tract','bg','tabblock')
				ORDER BY process_order, lookup_name), E'\n') ::text 
	, ARRAY['psql', 'data_schema','staging_schema', 'staging_fold', 'state_fold', 'website_root', 'state_abbrev','state_fips'], 
	ARRAY[platform.psql,  variables.data_schema, variables.staging_schema, variables.staging_fold, s.state_fold,variables.website_root, s.state_abbrev, s.state_fips::text])
			AS shell_code
FROM loader_variables As variables
		CROSS JOIN (SELECT name As state, abbrev As state_abbrev, lpad(st_code::text,2,'0') As state_fips, 
			 lpad(st_code::text,2,'0') || '_' 
	|| replace(name, ' ', '_') As state_fold
FROM state_lookup) As s CROSS JOIN loader_platform As platform
WHERE $1 @> ARRAY[state_abbrev::text]      -- If state is contained in list of states input generate script for it
AND platform.os = $2  -- generate script for selected platform
;
$$
  LANGUAGE sql VOLATILE;
  
--update with census tract loading logic
DELETE FROM loader_lookuptables WHERE lookup_name IN('tract','tabblock','bg');           
INSERT INTO loader_lookuptables(process_order, lookup_name, table_name, load, level_county, level_state, single_geom_mode, insert_mode, pre_load_process, post_load_process, columns_exclude )
VALUES(10, 'tract', 'tract', true, false, true,false, 'c', 
'${psql} -c "CREATE TABLE ${data_schema}.${state_abbrev}_${lookup_name}(CONSTRAINT pk_${state_abbrev}_${lookup_name} PRIMARY KEY (tract_id) ) INHERITS(tiger.${lookup_name}); " ',
	'${psql} -c "ALTER TABLE ${staging_schema}.${state_abbrev}_${table_name} RENAME geoid TO tract_id;  SELECT loader_load_staged_data(lower(''${state_abbrev}_${table_name}''), lower(''${state_abbrev}_${lookup_name}'')); "
	${psql} -c "CREATE INDEX ${data_schema}_${state_abbrev}_${lookup_name}_the_geom_gist ON ${data_schema}.${state_abbrev}_${lookup_name} USING gist(the_geom);"
	${psql} -c "VACUUM ANALYZE ${data_schema}.${state_abbrev}_${lookup_name};"
	${psql} -c "ALTER TABLE ${data_schema}.${state_abbrev}_${lookup_name} ADD CONSTRAINT chk_statefp CHECK (statefp = ''${state_fips}'');"', ARRAY['gid']);

INSERT INTO loader_lookuptables(process_order, lookup_name, table_name, load, level_county, level_state, single_geom_mode, insert_mode, pre_load_process, post_load_process, columns_exclude )
VALUES(11, 'tabblock', 'tabblock', true, false, true,false, 'c', 
'${psql} -c "CREATE TABLE ${data_schema}.${state_abbrev}_${lookup_name}(CONSTRAINT pk_${state_abbrev}_${lookup_name} PRIMARY KEY (tabblock_id)) INHERITS(tiger.${lookup_name});" ',
'${psql} -c "ALTER TABLE ${staging_schema}.${state_abbrev}_${table_name} RENAME geoid TO tabblock_id;  SELECT loader_load_staged_data(lower(''${state_abbrev}_${table_name}''), lower(''${state_abbrev}_${lookup_name}''), ''{gid, statefp10, countyfp10, tractce10, blockce10,suffix1ce,blockce,tractce}''::text[]); "
${psql} -c "ALTER TABLE ${data_schema}.${state_abbrev}_${lookup_name} ADD CONSTRAINT chk_statefp CHECK (statefp = ''${state_fips}'');"
${psql} -c "CREATE INDEX ${data_schema}_${state_abbrev}_${lookup_name}_the_geom_gist ON ${data_schema}.${state_abbrev}_${lookup_name} USING gist(the_geom);"
${psql} -c "vacuum analyze ${data_schema}.${state_abbrev}_${lookup_name};"', ARRAY['gid']);

INSERT INTO loader_lookuptables(process_order, lookup_name, table_name, load, level_county, level_state, single_geom_mode, insert_mode, pre_load_process, post_load_process, columns_exclude )
VALUES(12, 'bg', 'bg', true,false, true,false, 'c', 
'${psql} -c "CREATE TABLE ${data_schema}.${state_abbrev}_${lookup_name}(CONSTRAINT pk_${state_abbrev}_${lookup_name} PRIMARY KEY (bg_id)) INHERITS(tiger.${lookup_name});" ',
'${psql} -c "ALTER TABLE ${staging_schema}.${state_abbrev}_${table_name} RENAME geoid TO bg_id;  SELECT loader_load_staged_data(lower(''${state_abbrev}_${table_name}''), lower(''${state_abbrev}_${lookup_name}'')); "
${psql} -c "ALTER TABLE ${data_schema}.${state_abbrev}_${lookup_name} ADD CONSTRAINT chk_statefp CHECK (statefp = ''${state_fips}'');"
${psql} -c "CREATE INDEX ${data_schema}_${state_abbrev}_${lookup_name}_the_geom_gist ON ${data_schema}.${state_abbrev}_${lookup_name} USING gist(the_geom);"
${psql} -c "vacuum analyze ${data_schema}.${state_abbrev}_${lookup_name};"', ARRAY['gid']);
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
/*******************************************************************
 * $Id: tiger_topology_loader.sql 9324 2012-02-27 22:08:12Z pramsey $
 *
 * PostGIS - Spatial Types for PostgreSQL
 * Copyright 2011 Leo Hsu and Regina Obe <lr@pcorp.us> 
 * Paragon Corporation
 * This is free software; you can redistribute and/or modify it under
 * the terms of the GNU General Public Licence. See the COPYING file.
 *
 * This file contains helper functions for loading tiger data
 * into postgis topology structure
 **********************************************************************/

 /** topology_load_tiger: Will load all edges, faces, nodes into 
 *  topology named toponame
 *	that intersect the specified region
 *  region_type: 'place', 'county'
 *  region_id: the respective fully qualified geoid
 *	 place - plcidfp
 *	 county - cntyidfp 
 * USE CASE: 
 *  The following will create a topology called topo_boston 
 *   in Mass State Plane feet and load Boston, MA tiger data
 *  with tolerance of 1 foot
 * SELECT topology.DropTopology('topo_boston');
 * SELECT topology.CreateTopology('topo_boston', 2249,0.25);
 * SELECT tiger.topology_load_tiger('topo_boston', 'place', '2507000'); 
 * SELECT topology.TopologySummary('topo_boston');
 * SELECT topology.ValidateTopology('topo_boston');  
 ****/
CREATE OR REPLACE FUNCTION tiger.topology_load_tiger(IN toponame varchar,  
	region_type varchar, region_id varchar)
  RETURNS text AS
$$
DECLARE
 	var_sql text;
 	var_rgeom geometry;
 	var_statefp text;
 	var_rcnt bigint;
 	var_result text := '';
 	var_srid int := 4269;
 	var_precision double precision := 0;
BEGIN
	--$Id: tiger_topology_loader.sql 9324 2012-02-27 22:08:12Z pramsey $
	CASE region_type
		WHEN 'place' THEN
			SELECT the_geom , statefp FROM place INTO var_rgeom, var_statefp WHERE plcidfp = region_id;
		WHEN 'county' THEN
			SELECT the_geom, statefp FROM county INTO var_rgeom, var_statefp WHERE cntyidfp = region_id;
		ELSE
			RAISE EXCEPTION 'Region type % IS NOT SUPPORTED', region_type;
	END CASE;
	SELECT srid, precision FROM topology.topology into var_srid, var_precision
                WHERE name = toponame;
	var_sql := '
	CREATE TEMPORARY TABLE tmp_edge
   				AS 
	WITH te AS 
   			(SELECT tlid,  ST_GeometryN(ST_SnapToGrid(ST_Transform(ST_LineMerge(the_geom),$3),$4),1) As geom, tnidf, tnidt, tfidl, tfidr , the_geom As orig_geom
									FROM tiger.edges 
									WHERE statefp = $1 AND ST_Covers($2, the_geom)
										)
					SELECT DISTINCT ON (t.tlid) t.tlid As edge_id,t.geom 
                        , t.tnidf As start_node, t.tnidt As end_node, COALESCE(t.tfidl,0) As left_face
                        , COALESCE(t.tfidr,0) As right_face, COALESCE(tl.tlid, t.tlid) AS next_left_edge,  COALESCE(tr.tlid, t.tlid) As next_right_edge, t.orig_geom
						FROM 
							te AS t LEFT JOIN te As tl ON (t.tnidf = tl.tnidt AND t.tfidl = tl.tfidl)
							 LEFT JOIN te As tr ON (t.tnidt = tr.tnidf AND t.tfidr = tr.tfidr)				
						';
	EXECUTE var_sql USING var_statefp, var_rgeom, var_srid, var_precision;
	GET DIAGNOSTICS var_rcnt = ROW_COUNT;
	var_result := var_rcnt::text || ' edges holding in temporary. ';
	var_sql := 'ALTER TABLE tmp_edge ADD CONSTRAINT pk_tmp_edge PRIMARY KEY(edge_id );';
	EXECUTE var_sql;
	-- CREATE node indexes on temporary edges
	var_sql := 'CREATE INDEX idx_tmp_edge_start_node ON tmp_edge USING btree (start_node ); CREATE INDEX idx_tmp_edge_end_node ON tmp_edge USING btree (end_node );';

	EXECUTE var_sql;

	-- CREATE face indexes on temporary edges
	var_sql := 'CREATE INDEX idx_tmp_edge_left_face ON tmp_edge USING btree (left_face ); CREATE INDEX idx_tmp_edge_right_face ON tmp_edge USING btree (right_face );';

	EXECUTE var_sql;

	-- CREATE edge indexes on temporary edges
	var_sql := 'CREATE INDEX idx_tmp_edge_next_left_edge ON tmp_edge USING btree (next_left_edge ); CREATE INDEX idx_tmp_edge_next_right_edge ON tmp_edge USING btree (next_right_edge);';

	EXECUTE var_sql;
	
	-- start load in faces
	var_sql := 'INSERT INTO ' || quote_ident(toponame) || '.face(face_id, mbr) 
						SELECT f.tfid, ST_Envelope(ST_Transform(f.the_geom,$3)) As mbr 
							FROM tiger.faces AS f
								WHERE statefp = $1 AND 
								(  tfid IN(SELECT left_face FROM tmp_edge)
									OR tfid IN(SELECT right_face FROM tmp_edge) OR ST_Covers($2, the_geom) )
							AND tfid NOT IN(SELECT face_id FROM ' || quote_ident(toponame) || '.face) ';
	EXECUTE var_sql USING var_statefp, var_rgeom, var_srid;
	GET DIAGNOSTICS var_rcnt = ROW_COUNT;
	var_result := var_result || var_rcnt::text || ' faces added. ';
   -- end load in faces
   
   -- add remaining missing edges of present faces --
   var_sql := 'INSERT INTO tmp_edge(edge_id, geom, start_node, end_node, left_face, right_face, next_left_edge, next_right_edge, orig_geom)	
   			WITH te AS 
   			(SELECT tlid,  ST_GeometryN(ST_SnapToGrid(ST_Transform(ST_LineMerge(the_geom),$2),$3),1) As geom, tnidf, tnidt, tfidl, tfidr, the_geom As orig_geom 
									FROM tiger.edges 
									WHERE statefp = $1 AND
									 (tfidl IN(SELECT face_id FROM ' || quote_ident(toponame) || '.face)
				OR tfidr IN(SELECT face_id FROM ' || quote_ident(toponame) || '.face) )
				AND tlid NOT IN(SELECT edge_id FROM tmp_edge)
				 )
				
			SELECT DISTINCT ON (t.tlid) t.tlid As edge_id,t.geom 
                        , t.tnidf As start_node, t.tnidt As end_node, t.tfidl As left_face
                        , t.tfidr As right_face, tl.tlid AS next_left_edge,  tr.tlid As next_right_edge, t.orig_geom
				FROM 
						te AS t LEFT JOIN te As tl 
								ON (t.tnidf = tl.tnidt AND t.tfidl = tl.tfidl)
			LEFT JOIN te As tr ON (t.tnidt = tr.tnidf AND t.tfidr = tr.tfidr)
			';
	EXECUTE var_sql USING var_statefp, var_srid, var_precision;
	GET DIAGNOSTICS var_rcnt = ROW_COUNT;
	var_result := var_result || var_rcnt::text || ' edges of faces added. ';
   	-- start load in nodes
	var_sql := 'INSERT INTO ' || quote_ident(toponame) || '.node(node_id, geom)
					SELECT DISTINCT ON(tnid) tnid, geom
						FROM 
						( 
							SELECT start_node AS tnid, ST_StartPoint(e.geom) As geom 
								FROM tmp_edge As e LEFT JOIN ' || quote_ident(toponame) || '.node AS n ON e.start_node = n.node_id
						UNION ALL 
							SELECT end_node AS tnid, ST_EndPoint(e.geom) As geom 
							FROM tmp_edge As e LEFT JOIN ' || quote_ident(toponame) || '.node AS n ON e.end_node = n.node_id 
							WHERE n.node_id IS NULL) As f 
							WHERE tnid NOT IN(SELECT node_id FROM  ' || quote_ident(toponame) || '.node)
					 ';
	EXECUTE var_sql USING var_statefp, var_rgeom;
	GET DIAGNOSTICS var_rcnt = ROW_COUNT;
	var_result := var_result || ' ' || var_rcnt::text || ' nodes added. ';

   -- end load in nodes
   -- start Mark which nodes are contained in faces
   	var_sql := 'UPDATE ' || quote_ident(toponame) || '.node AS n
					SET containing_face = f.tfid
						FROM (SELECT tfid, the_geom
							FROM tiger.faces WHERE statefp = $1 
							AND tfid IN(SELECT face_id FROM ' || quote_ident(toponame) || '.face) 
							) As f
						WHERE ST_ContainsProperly(f.the_geom, ST_Transform(n.geom,4269)) ';
	EXECUTE var_sql USING var_statefp, var_rgeom;
	GET DIAGNOSTICS var_rcnt = ROW_COUNT;
	var_result := var_result || ' ' || var_rcnt::text || ' nodes contained in a face. ';
   -- end Mark nodes contained in faces

   -- Set orphan left right to itself and set edges with missing faces to world face
   var_sql := 'UPDATE tmp_edge SET next_left_edge = -1*edge_id WHERE next_left_edge IS NULL OR next_left_edge NOT IN(SELECT edge_id FROM tmp_edge);
        UPDATE tmp_edge SET next_right_edge = -1*edge_id WHERE next_right_edge IS NULL OR next_right_edge NOT IN(SELECT edge_id FROM tmp_edge);
        UPDATE tmp_edge SET left_face = 0 WHERE left_face NOT IN(SELECT face_id FROM ' || quote_ident(toponame) || '.face);
        UPDATE tmp_edge SET right_face = 0 WHERE right_face NOT IN(SELECT face_id FROM ' || quote_ident(toponame) || '.face);';
   EXECUTE var_sql;

   -- force edges start and end points to match the start and end nodes --
   var_sql := 'UPDATE tmp_edge SET geom = ST_SetPoint(ST_SetPoint(tmp_edge.geom, 0, s.geom), ST_NPoints(tmp_edge.geom) - 1,e.geom)  
                FROM ' || quote_ident(toponame) || '.node AS s, ' || quote_ident(toponame) || '.node As e
                WHERE s.node_id = tmp_edge.start_node AND e.node_id = tmp_edge.end_node AND 
                    ( NOT ST_Equals(s.geom, ST_StartPoint(tmp_edge.geom) ) OR NOT ST_Equals(e.geom, ST_EndPoint(tmp_edge.geom) ) ) '  ;   
    EXECUTE var_sql;
    GET DIAGNOSTICS var_rcnt = ROW_COUNT;
    var_result := var_result || ' ' || var_rcnt::text || ' edge start end corrected. ';
   -- TODO: Load in edges --
   var_sql := '
   	INSERT INTO ' || quote_ident(toponame) || '.edge(edge_id, geom, start_node, end_node, left_face, right_face, next_left_edge, next_right_edge)
					SELECT t.edge_id, t.geom, t.start_node, t.end_node, COALESCE(t.left_face,0) As left_face, COALESCE(t.right_face,0) As right_face, t.next_left_edge, t.next_right_edge
						FROM 
							tmp_edge AS t
							WHERE t.edge_id NOT IN(SELECT edge_id FROM ' || quote_ident(toponame) || '.edge) 				
						';
	EXECUTE var_sql USING var_statefp, var_rgeom;
	GET DIAGNOSTICS var_rcnt = ROW_COUNT;
	var_result := var_result || ' ' || var_rcnt::text || ' edges added. ';
	var_sql = 'DROP TABLE tmp_edge;';
	EXECUTE var_sql;
	RETURN var_result;
END
$$
  LANGUAGE plpgsql VOLATILE
  COST 1000;-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 
-- $Id: postgis_extension_helper.sql 10934 2012-12-26 13:44:51Z robe $
----
-- PostGIS - Spatial Types for PostgreSQL
-- http://www.postgis.org
--
-- Copyright (C) 2011 Regina Obe <lr@pcorp.us>
-- Copyright (C) 2005 Refractions Research Inc.
--
-- This is free software; you can redistribute and/or modify it under
-- the terms of the GNU General Public Licence. See the COPYING file.
--
-- Author: Regina Obe <lr@pcorp.us>
--  
-- This is a suite of SQL helper functions for use during a PostGIS extension install/upgrade
-- The functions get uninstalled after the extention install/upgrade process
---------------------------
-- postgis_extension_remove_objects: This function removes objects of a particular class from an extension
-- this is needed because there is no ALTER EXTENSION DROP FUNCTION/AGGREGATE command
-- and we can't CREATE OR REPALCe functions whose signatures have changed and we can drop them if they are part of an extention
-- So we use this to remove it from extension first before we drop
CREATE OR REPLACE FUNCTION postgis_extension_remove_objects(param_extension text, param_type text)
  RETURNS boolean AS
$$
DECLARE 
	var_sql text := '';
	var_r record;
	var_result boolean := false;
	var_class text := '';
	var_is_aggregate boolean := false;
	var_sql_list text := '';
BEGIN
		var_class := CASE WHEN lower(param_type) = 'function' OR lower(param_type) = 'aggregate' THEN 'pg_proc' ELSE '' END; 
		var_is_aggregate := CASE WHEN lower(param_type) = 'aggregate' THEN true ELSE false END;
		var_sql_list := 'SELECT ''ALTER EXTENSION '' || e.extname || '' DROP '' || $3 || '' '' || COALESCE(proc.proname || ''('' || oidvectortypes(proc.proargtypes) || '')'',typ.typname, cd.relname, op.oprname, 
				cs.typname || '' AS '' || ct.typname || '') '', opcname, opfname) || '';'' AS remove_command
		FROM pg_depend As d INNER JOIN pg_extension As e
			ON d.refobjid = e.oid INNER JOIN pg_class As c ON
				c.oid = d.classid
				LEFT JOIN pg_proc AS proc ON proc.oid = d.objid
				LEFT JOIN pg_type AS typ ON typ.oid = d.objid
				LEFT JOIN pg_class As cd ON cd.oid = d.objid
				LEFT JOIN pg_operator As op ON op.oid = d.objid
				LEFT JOIN pg_cast AS ca ON ca.oid = d.objid
				LEFT JOIN pg_type AS cs ON ca.castsource = cs.oid
				LEFT JOIN pg_type AS ct ON ca.casttarget = ct.oid
				LEFT JOIN pg_opclass As oc ON oc.oid = d.objid
				LEFT JOIN pg_opfamily As ofa ON ofa.oid = d.objid
		WHERE d.deptype = ''e'' and e.extname = $1 and c.relname = $2 AND COALESCE(proc.proisagg, false) = $4;';
		FOR var_r IN EXECUTE var_sql_list  USING param_extension, var_class, param_type, var_is_aggregate
        LOOP
            var_sql := var_sql || var_r.remove_command || ';';
        END LOOP;
        IF var_sql > '' THEN
            EXECUTE var_sql;
            var_result := true;
        END IF;
        RETURN var_result;
END;
$$
LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION postgis_extension_drop_if_exists(param_extension text, param_statement text)
  RETURNS boolean AS
$$
DECLARE 
	var_sql_ext text := 'ALTER EXTENSION ' || quote_ident(param_extension) || ' ' || replace(param_statement, 'IF EXISTS', '');
	var_result boolean := false;
BEGIN
	BEGIN
		EXECUTE var_sql_ext;
		var_result := true;
	EXCEPTION
		WHEN OTHERS THEN
			--this is to allow ignoring if the object does not exist in extension
			var_result := false;
	END;
	RETURN var_result;
END;
$$
LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION postgis_extension_AddToSearchPath(a_schema_name varchar)
RETURNS text
AS
$$
DECLARE
	var_result text;
	var_cur_search_path text;
BEGIN
	SELECT reset_val INTO var_cur_search_path FROM pg_settings WHERE name = 'search_path';
	IF var_cur_search_path LIKE '%' || quote_ident(a_schema_name) || '%' THEN
		var_result := a_schema_name || ' already in database search_path';
	ELSE
		EXECUTE 'ALTER DATABASE ' || quote_ident(current_database()) || ' SET search_path = ' || var_cur_search_path || ', ' || quote_ident(a_schema_name); 
		var_result := a_schema_name || ' has been added to end of database search_path ';
	END IF;
  
  RETURN var_result;
END
$$
LANGUAGE 'plpgsql' VOLATILE STRICT;
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 
-- $Id: add_search_path.sql.in 10934 2012-12-26 13:44:51Z robe $
----
-- PostGIS - Spatial Types for PostgreSQL
-- http://postgis.net
--
-- Copyright (C) 2012 Regina Obe <lr@pcorp.us>
--
-- This is free software; you can redistribute and/or modify it under
-- the terms of the GNU General Public Licence. See the COPYING file.
--
-- Author: Regina Obe <lr@pcorp.us>
--  
-- This adds the tiger schema to search path
-- Functions in tiger are not schema qualified 
-- so this is needed for them to work

SELECT postgis_extension_AddToSearchPath('tiger');
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- 
-- $Id: postgis_extension_helper_uninstall.sql 10934 2012-12-26 13:44:51Z robe $
----
-- PostGIS - Spatial Types for PostgreSQL
-- http://www.postgis.org
--
-- Copyright (C) 2011 Regina Obe <lr@pcorp.us>
--
-- This is free software; you can redistribute and/or modify it under
-- the terms of the GNU General Public Licence. See the COPYING file.
--
-- Author: Regina Obe <lr@pcorp.us>
--  
-- This drops extension helper functions
-- and should be called at the end of the extension upgrade file
DROP FUNCTION postgis_extension_remove_objects(text, text);
DROP FUNCTION postgis_extension_drop_if_exists(text, text);
DROP FUNCTION postgis_extension_AddToSearchPath(varchar);
SELECT pg_catalog.pg_extension_config_dump('geocode_settings', '');

COMMENT ON FUNCTION Drop_Indexes_Generate_Script(text ) IS 'args: param_schema=tiger_data - Generates a script that drops all non-primary key and non-unique indexes on tiger schema and user specified schema. Defaults schema to tiger_data if no schema is specified.';
			
COMMENT ON FUNCTION Drop_State_Tables_Generate_Script(text , text ) IS 'args: param_state, param_schema=tiger_data - Generates a script that drops all tables in the specified schema that start with county_all, state_all or stae code followed by county or state.';
			
COMMENT ON FUNCTION Drop_State_Tables_Generate_Script(text , text ) IS 'args: param_state, param_schema=tiger_data - Generates a script that drops all tables in the specified schema that are prefixed with the state abbreviation. Defaults schema to tiger_data if no schema is specified.';
			
COMMENT ON FUNCTION geocode(varchar , integer , geometry ) IS 'args: address, max_results=10, restrict_region=NULL, OUT addy, OUT geomout, OUT rating - Takes in an address as a string (or other normalized address) and outputs a set of possible locations which include a point geometry in NAD 83 long lat, a normalized address for each, and the rating. The lower the rating the more likely the match. Results are sorted by lowest rating first. Can optionally pass in maximum results, defaults to 10, and restrict_region (defaults to NULL)';
			
COMMENT ON FUNCTION geocode(norm_addy , integer , geometry ) IS 'args: in_addy, max_results=10, restrict_region=NULL, OUT addy, OUT geomout, OUT rating - Takes in an address as a string (or other normalized address) and outputs a set of possible locations which include a point geometry in NAD 83 long lat, a normalized address for each, and the rating. The lower the rating the more likely the match. Results are sorted by lowest rating first. Can optionally pass in maximum results, defaults to 10, and restrict_region (defaults to NULL)';
			
COMMENT ON FUNCTION geocode_intersection(text , text , text , text , text , integer ) IS 'args:  roadway1,  roadway2,  in_state,  in_city,  in_zip, max_results=10, OUT addy, OUT geomout, OUT rating - Takes in 2 streets that intersect and a state, city, zip, and outputs a set of possible locations on the first cross street that is at the intersection, also includes a point geometry in NAD 83 long lat, a normalized address for each location, and the rating. The lower the rating the more likely the match. Results are sorted by lowest rating first. Can optionally pass in maximum results, defaults to 10';
			
COMMENT ON FUNCTION Get_Geocode_Setting(text ) IS 'args:  setting_name - Returns value of specific setting stored in tiger.geocode_settings table.';
			
COMMENT ON FUNCTION get_tract(geometry , text ) IS 'args:  loc_geom,  output_field=name - Returns census tract or field from tract table of where the geometry is located. Default to returning short name of tract.';
			
COMMENT ON FUNCTION Install_Missing_Indexes() IS 'Finds all tables with key columns used in geocoder joins and filter conditions that are missing used indexes on those columns and will add them.';
			
COMMENT ON FUNCTION loader_generate_census_script(text[], text) IS 'args: param_states, os - Generates a shell script for the specified platform for the specified states that will download Tiger census state tract, bg, and tabblocks data tables, stage and load into tiger_data schema. Each state script is returned as a separate record.';
			
COMMENT ON FUNCTION loader_generate_script(text[], text) IS 'args: param_states, os - Generates a shell script for the specified platform for the specified states that will download Tiger data, stage and load into tiger_data schema. Each state script is returned as a separate record. Latest version supports Tiger 2010 structural changes and also loads census tract, block groups, and blocks tables.';
			
COMMENT ON FUNCTION loader_generate_nation_script(text) IS 'args: os - Generates a shell script for the specified platform that loads in the county and state lookup tables.';
			
COMMENT ON FUNCTION Missing_Indexes_Generate_Script() IS 'Finds all tables with key columns used in geocoder joins that are missing indexes on those columns and will output the SQL DDL to define the index for those tables.';
			
COMMENT ON FUNCTION normalize_address(varchar ) IS 'args: in_address - Given a textual street address, returns a composite norm_addy type that has road suffix, prefix and type standardized, street, streetname etc. broken into separate fields. This function will work with just the lookup data packaged with the tiger_geocoder (no need for tiger census data).';
			
COMMENT ON FUNCTION pprint_addy(norm_addy ) IS 'args: in_addy - Given a norm_addy composite type object, returns a pretty print representation of it. Usually used in conjunction with normalize_address.';
			
COMMENT ON FUNCTION Reverse_Geocode(geometry , boolean ) IS 'args: pt, include_strnum_range=false, OUT intpt, OUT addy, OUT street - Takes a geometry point in a known spatial ref sys and returns a record containing an array of theoretically possible addresses and an array of cross streets. If include_strnum_range = true, includes the street range in the cross streets.';
			
COMMENT ON FUNCTION Topology_Load_Tiger(varchar , varchar , varchar ) IS 'args: topo_name, region_type, region_id - Loads a defined region of tiger data into a PostGIS Topology and transforming the tiger data to spatial reference of the topology and snapping to the precision tolerance of the topology.';
			
COMMENT ON FUNCTION Set_Geocode_Setting(text , text ) IS 'args:  setting_name,  setting_value - Sets a setting that affects behavior of geocoder functions.';
			