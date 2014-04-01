-- raster gets installed as part of the makepostgisdb.bat install --
-- to verify it --
SELECT postgis_raster_lib_build_date(), postgis_raster_lib_version();

-- Should give -- or a date later
 postgis_raster_lib_build_date | postgis_raster_lib_version
-------------------------------+----------------------------
 2011-12-26 08:40:40           | 2.0.0SVN
  
6) Run this quick example for creating a raster with code
CREATE TABLE rt_test (
    id numeric,
    name text,
    rast raster
);

INSERT INTO rt_test 
VALUES ( 0, '10x20, ip:0.5,0.5 scale:2,3 skew:0,0 srid:10 width:10 height:20',
(
'01' -- little endian (uint8 ndr)
|| 
'0000' -- version (uint16 0)
||
'0000' -- nBands (uint16 0)
||
'0000000000000040' -- scaleX (float64 2)
||
'0000000000000840' -- scaleY (float64 3)
||
'000000000000E03F' -- ipX (float64 0.5)
||
'000000000000E03F' -- ipY (float64 0.5)
||
'0000000000000000' -- skewX (float64 0)
||
'0000000000000000' -- skewY (float64 0)
||
'0A000000' -- SRID (int32 10)
||
'0A00' -- width (uint16 10)
||
'1400' -- height (uint16 20)
)::raster
);

SELECT name, ST_Width(rast), ST_Height(rast), ST_SRID(rast), ST_NumBands(rast)
FROM rt_test;

SELECT ST_Extent(rast)
FROM rt_test;

---------------------

Loading Raster data
The simplest way to load raster data is using the new bin\raster2pgsql.exe packaged with this install.
To get more help on it just run it without any arguments.

This will allow you to load any files supported by the libgdal packaged with this install.  You can 
get more information about drivers with the command -G command:
raster2pgsql -G

To use the raster2pgsql.exe for example you would do this:
raster2pgsql.exe -s 4326 -I -C -t 130x79 US.tif  samples.usdem > usdem.sql
psql -U postgres -d postgis20_sampler -h localhost -p 5432 -f usdem.sql

If you have multiple files, you can use the * wildcard.
Example:
raster2pgsql.exe -I -C -s 26986 -t 100x100 bostonaerials2008/*.jpg  aerials.boston > boston.sql

For more details on how to use the loader, refer to the PostGIS Official manual:
http://www.postgis.org/documentation/manual-svn/using_raster.xml.html#RT_Loading_Rasters

If you need to load raster types not supported by the packaged raster2pgsql
you can convert them to a support format using gdal_translate (using FWTools or some other GDAL distribution)
and then use raster2pgsql. 

--- REST OF THE STUFF BELOW IS A BIT OBSOLETE ---
If you need to load data types not packaged with libgdal
To use the raster2pgsql.py, you'll need python 2.5, python 2.6, or python 2.7
You need to install Python first which you can get from below and install in 5 minutes or 
less:


-- The Old Python approach is now deprecated, but may be needed
-- if you want to load files not distributed with this gdal driver
-- or you want to do raster overviews.
Pre-compiled binaries are available here:
http://www.python.org/download/releases/

There is an unofficial set of windows binaries set http://www.lfd.uci.edu/~gohlke/pythonlibs/
for Python 2.6 and 2.7 which has newer gdal and setup installers.  
use the: GDAL-1.7.3.win32-py2.6.exe or GDAL-1.7.3.win32-py2.7.exe (listed in GDAL section)
as well as the accompanying Numpy  numpy-1.5.1.win32-py2.6.exe,  numpy-1.5.1.win32-py2.7.exe
for more up to date binaries.  

c:\python27\python raster2pgsql.py --help 
-- online help
http://www.postgis.org/documentation/manual-svn/RT_reference.html#RT_Loading_Rasters

c:\python27\python raster2pgsql.py -r someimagefile -t sometablename -o somefile.sql
psql -U postgres -d postgisdb -h localhost -f somefile.sql

Details -
Tutorials
http://gis4free.wordpress.com/category/postgis-raster/
http://trac.osgeo.org/postgis/wiki/WKTRasterTutorial01


--Real world use case example
http://fuzzytolerance.info/code/postgis-raster-ftw/

FAQ on exporting, loading, displaying in mapserver
http://www.postgis.org/documentation/manual-svn/RT_FAQ.html


on how to load raster data with the loader are found here:
http://trac.osgeo.org/postgis/wiki/WKTRaster/SpecificationWorking01

and here - this one is a bit dated:
http://mateusz.loskot.net/2009/03/30/crunching-wkt-rasters/