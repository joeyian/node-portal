This package includes the extension files needed to 
use the new CREATE EXTENSION/ALTER EXTENSION syntax for PostGIS installation.

It's still experimental.
Currently doesn't have feature to install from unpackaged. 
This will come before release.

To use the new extension approach for installing PostGIS.
Edit the makepostgisdb_using_extensions.bat 
changing PGINSTALL to path of your PostgreSQL 9.1 install
and THEDB to the name of new database you want to create.

This will create a new postgis database.

If you want to spatially enable a different one:
If you use PgAdmin, you should see 2 new extensions:
postgis  (this has geometry/geography/raster support)
postgis_topology

which you can install with PgAdmin by selecting from the extensions drop down.

Alternatively you can use the new SQL syntax to install in your database

CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;

-- Upgrading extension --
To upgrade an extension, it's just as easy. If you are using PgAdmin,
go to the extensions section and the postgis / postgis_topology.
Select the version drop down and bump what you have currently to the latest.

-- What to do if you get an error that there is no migration path
-- from your current to new --
If you get an error message about not able to migrate from your current version to new, 
because no migration path, you can create a migration path file, you need to do a HARD UPGRADE.

Hard upgrade is pretty simple if your backup was using extensions:
1) Backup your database
2) CREATE a new database and run:
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;

3) Restore your old database backup onto the new one.
Since the postgis extension is installed, you might get a restore failure notice about postgis and postgis_topology
extensions not restored because they are already present.  You can safely ignore those notices.

