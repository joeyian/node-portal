REM Place on root of pgsql folder

@ECHO ON
REM The script sets environment variables helpful for PostgreSQL
@SET PATH="%~dp0\bin";%PATH%
@SET PGDATA=%~dp0\data
@SET PGDATABASE=postgres
@SET PGUSER=postgres
@SET PGPORT=5439
@SET PGLOCALEDIR=%~dp0\share\locale
REM "%~dp0\bin\initdb" -U postgres -A trust
"%~dp0\bin\pg_ctl" -D "%~dp0/data" -l logfile start
REM @ECHO "Press ENTER to stop"
REM @pause
REM "%~dp0\bin\pg_ctl" -D "%~dp0/data" stop