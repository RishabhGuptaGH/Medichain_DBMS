@echo off
setlocal
echo ============================================================
echo  MediChain - Cloud Database Setup
echo ============================================================
echo.
echo This initialises a REMOTE MySQL (Aiven / Clever Cloud / Railway /
echo FreeSQLDatabase / db4free / any MySQL 8 host) with MediChain's
echo schema, triggers, procedures and seed data.
echo.
echo Credentials are read from a local .env file. Copy .env.example to
echo .env first, then fill in the values from your provider.
echo.

if not exist ".env" (
    echo ERROR: .env not found. Copy .env.example to .env and fill it in.
    pause
    exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%A in (".env") do (
    if not "%%A"=="" if not "%%A:~0,1%"=="#" set "%%A=%%B"
)

if "%DB_HOST%"=="" (
    echo ERROR: DB_HOST missing in .env
    pause & exit /b 1
)
if "%DB_PORT%"=="" set DB_PORT=3306
if "%DB_NAME%"=="" (
    echo ERROR: DB_NAME missing in .env
    pause & exit /b 1
)
if "%DB_USERNAME%"=="" (
    echo ERROR: DB_USERNAME missing in .env
    pause & exit /b 1
)
if "%DB_PASSWORD%"=="" (
    echo ERROR: DB_PASSWORD missing in .env
    pause & exit /b 1
)

echo Target: %DB_USERNAME%@%DB_HOST%:%DB_PORT%/%DB_NAME%
echo.

set MYSQL_ARGS=-h %DB_HOST% -P %DB_PORT% -u %DB_USERNAME% -p%DB_PASSWORD% --protocol=TCP --ssl-mode=REQUIRED %DB_NAME%

rem triggers.sql / procedures.sql / seed_data.sql start with `USE medichain;`
rem which is wrong for cloud (DB is named by the provider, e.g. defaultdb).
rem findstr /V strips that line before piping to mysql.

echo Running schema_cloud.sql...
mysql %MYSQL_ARGS% < database\schema_cloud.sql
if %ERRORLEVEL% NEQ 0 ( echo schema failed & pause & exit /b 1 )

echo Running triggers.sql...
findstr /V /B /C:"USE medichain;" database\triggers.sql | mysql %MYSQL_ARGS%
if %ERRORLEVEL% NEQ 0 ( echo triggers failed & pause & exit /b 1 )

echo Running procedures.sql...
findstr /V /B /C:"USE medichain;" database\procedures.sql | mysql %MYSQL_ARGS%
if %ERRORLEVEL% NEQ 0 ( echo procedures failed & pause & exit /b 1 )

echo Running seed_data.sql...
findstr /V /B /C:"USE medichain;" database\seed_data.sql | mysql %MYSQL_ARGS%
if %ERRORLEVEL% NEQ 0 ( echo seed_data failed & pause & exit /b 1 )

echo.
echo ============================================================
echo  Cloud database ready. Start the app with: run-cloud.bat
echo ============================================================
pause
