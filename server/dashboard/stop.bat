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


 
echo.
echo [========== Shutting down GEOSERVER ==========]
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
goto shutdown


:shutdown
  set RUN_JAVA=%JAVA_HOME%\bin\java
  cd %GEOSERVER_HOME%
  "%RUN_JAVA%" -DSTOP.PORT=8079 -DSTOP.KEY=geoserver -jar start.jar --stop
goto end

:end
  if %error% == 1 echo Shutting down GeoServer was unsuccessful. 
  echo.
  

REM skip POSTGIS
REM goto skipPostgis
  
  
REM 5 second delay
ping 127.0.0.1 -n 6 > nul
  
echo.
echo [=========== Shutting down POSTGIS ===========]
echo.

..\pgsql\bin\pg_ctl -D "../pgsql/data" stop

:skipPostgis


echo.
echo [=========== It's now OK to CLOSE Launcher ===========]
echo.