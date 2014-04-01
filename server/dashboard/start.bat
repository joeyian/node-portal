@echo off
set error=0



REM set JDK
echo.
echo [=========== Setting up JDK ===========]
echo.

@ECHO OFF
set JAVA_HOME=%cd%\..\jdk7
set CLASSPATH=.;%JAVA_HOME%\jre\lib\ext
PATH=%JAVA_HOME%\bin;%JAVA_HOME%\jre\bin;%PATH%
cls
echo.
set JAVA_HOME
echo.
set CLASSPATH
echo.
echo The JAVA_HOME, CLASSPATH, and PATH environment variables are now set relative to the drive and directory you just ran jpath.bat from.
echo.
java -version
echo.
javac -version




REM skip POSTGIS
REM goto skipPostgis

echo.
echo [=========== Starting up POSTGIS ===========]
echo.
@SET PGPORT=5432
..\pgsql\bin\pg_ctl -D "../pgsql/data" start

REM 5 second delay
ping 127.0.0.1 -n 6 > nul

:skipPostgis

echo.
echo [========== Starting up GEOSERVER ==========]
echo.

rem JAVA_HOME not defined
if "%JAVA_HOME%" == "" goto noJava

rem JAVA_HOME defined incorrectly
if not exist "%JAVA_HOME%\bin\java.exe" goto badJava

REM Java is OK
echo JAVA_HOME: %JAVA_HOME%
echo.

goto setHome

:noJava
  echo The JAVA_HOME environment variable is not defined.
goto JavaFail

:badJava
  echo The JAVA_HOME environment variable is not defined correctly.
goto JavaFail

:JavaFail
  echo This environment variable is needed to run this program.
  echo.
  echo Set this environment variable via the following command:
  echo    set JAVA_HOME=[path to Java]
  echo Example:
  echo    set JAVA_HOME=C:\Program Files\Java\jdk6
  echo.
  set error=1
goto end


:setHome
  REM cd.. below goes to geoserver root directory
  cd ..\geoserver
  set GEOSERVER_HOME=%CD%
  echo GEOSERVER_HOME = %GEOSERVER_HOME%
  echo.
  set GEOSERVER_DATA_DIR=%GEOSERVER_HOME%\data_dir
  echo GEOSERVER_DATA_DIR = %GEOSERVER_DATA_DIR%
  echo.
goto run


:run
  set RUN_JAVA=%JAVA_HOME%\bin\java
  cd %GEOSERVER_HOME%
  echo Please wait while loading GeoServer...
  echo.
  "%RUN_JAVA%" -DGEOSERVER_DATA_DIR="%GEOSERVER_DATA_DIR%" -XX:MaxPermSize=256m -Djava.awt.headless=true -DSTOP.PORT=8079 -DSTOP.KEY=geoserver -jar start.jar
  echo.
goto end


:end
  if %error% == 1 echo Startup of GeoServer was unsuccessful. 
  echo.