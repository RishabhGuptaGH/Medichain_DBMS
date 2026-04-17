@echo off
echo ============================================================
echo  MediChain - Database Setup Script
echo ============================================================
echo.

echo Step 1: Setting up MySQL database...
echo   This will DROP and recreate the 'medichain' database.
echo.
set /p MYSQL_PASS="Enter MySQL root password (default: password): "
if "%MYSQL_PASS%"=="" set MYSQL_PASS=password

echo.
echo Running schema.sql...
mysql -u root -p%MYSQL_PASS% < database/schema.sql
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to run schema.sql
    pause
    exit /b 1
)

echo Running triggers.sql...
mysql -u root -p%MYSQL_PASS% < database/triggers.sql
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to run triggers.sql
    pause
    exit /b 1
)

echo Running procedures.sql...
mysql -u root -p%MYSQL_PASS% < database/procedures.sql
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to run procedures.sql
    pause
    exit /b 1
)

echo Running seed_data.sql...
mysql -u root -p%MYSQL_PASS% < database/seed_data.sql
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to run seed_data.sql
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  Database setup complete!
echo ============================================================
echo.
echo Step 2: Starting Spring Boot backend...
echo.
cd backend
call mvnw.cmd spring-boot:run
pause
