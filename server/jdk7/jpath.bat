@ECHO OFF
set JAVA_HOME=%cd%
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
