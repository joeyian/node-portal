PostGIS 1.3,1.4,1.5,2.0,2.1 can coexist in the same PostgreSQL server, but must be installed in separate databases.  This makes it a little easier to cross test different versions.  However -- all versions will share the same proj and geos dlls so you
may want to back these up libproj.dll, geos*.dll, shp2pgsql, pgsql2shp, libxml2-2.dll in the bin folder of your PostgreSQL install before continuing. PostGIS 2.0 has a dependency on libgdal.dll to support
raster support.

Note: PostGIS 2.0 requires geos 3.3.2 so backup your old and replace with the version in this install

If you want to use the new PostgreSQL 9.1 extensions approach for installing -- use the makepostgisdb_using_extensions.bat script instead
of makepostgisdb.bat.  Follow the upgrade instructions in README_EXTENSIONS.txt

NOTE: For raster functions such as ST_Transform, ST_Resample, ST_Clip you'll need to set the following environment variables
a) GDAL_DATA -- this should be set to path of your gdal-data folder -- you can use the packaged one "C:\Program Files\PostgreSQL\9.1\gdal-data"
b) PROJ_SO -- this may not need to be set if you are running 9.1 64-bit sinc eit uses 4.7.1 (but if things don't work add it and set it to proj-0.dll)

-- create a postgis/raster/topology enabled database --
1) Edit the batch script changing ports etc. to your settings
2) You should uncomment the dattemplate line to make it a template database if you want
3) Run the batch script

-- THE SHP2PGSQL-GUI -- 
The shp2pgsql-gui can run standalone or as a plugin under PgAdminIII. To run under a PgAdminIII install,
1) copy the postgis-gui folder to your bin directory which is identified in PgAdminIII -> Options -> General -> PG-binpath
2) In PgAdmin I.13+,copy the plugins.d folder to your PgAdmin III folder.  The script should do this for you.

----Start here --
The way to install plugins for pgAdmin III has changed in 1.13.  PgAdmin 1.13 or above is needed for PostgreSQL 9.1+ Please refer to for details:
http://www.postgresonline.com/journal/archives/180-PgAdmin-III-1.13-change-in-plugin-architecture-and-PostGIS-Plugins.html

--- End Here --

--NOTE FOR UPGRADERS --
PostGIS 1.5, 1.4,1.3,2.0,2.1  can coexist on the same PostgreSQL install but must reside in different databases, but if you wish to maintain more than one
, make sure to copy the .sql scripts into separate folders so as to not get confused


The only caveat is that there can only be one proj and one geos install, so when you copy the above, you 
will automatically upgrade your proj to 4.6.1 and your GEOS to 3.3.3dev (3.3 has some fixes for Union topological rounding issues but is in Release candidate)

Since 2.0 is still a work in progress -- you might want to just work with test databases or restore your production
into a blank postgis 2.0 db.


--If you are running PostGIS 2.0.0 alpha1 or above you can do a soft upgrade by:
1) copy the binaries
2) run the following files located in share/contrib/postgis-2.0 folder of this package
 a) postgis_upgrade_20_minor.sql
 b) run rtpostgis_upgrade_20_minor.sql
 c) run topology_upgrade_20_minor.sql
 d) If you have tiger installed you should edit and run the:
	C:\projects\postgis\trunk\extras\tiger_geocoder\tiger_2010\upgrade_geocode.s

-- for prior PostGIS versions 
If you are upgrading from 1.3 or 1.4 to 1.5 or older install (or earlier PostGIS 2.0 pre - alpha1)
you need to do a HARD UPGRADE
If you are upgrading from 1.5 or prior PostGIS, it's a bit cleaner to run the 
upgrade pg_restore.pl which requires ActivePerl or some other perl installed on your pc
--the below isntructions will work fine even though they return a lot of errors
-- HARD UPGRADE
1) Backup your existing database with PgAmin III or pg_dump (make sure not to choose drop objects before restore)
2) Create a new postgis database using the above instructions
3) Restore your backup into this new postgis db (again you can use PgAdmin III for this)
4) Run the postgis_upgrade_20_minor.sql, rtpostgis_upgrade_20_minor.sql, and topology_upgrade_20_minor.sql files.
