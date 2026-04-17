@echo off
setlocal enabledelayedexpansion
echo ============================================================
echo  MediChain - Starting Application (Cloud DB)
echo ============================================================
echo.

if not exist ".env" (
    echo ERROR: .env not found. Copy .env.example to .env and fill it in
    echo with the connection details from your free MySQL provider.
    pause
    exit /b 1
)

rem Load DB_HOST / DB_PORT / DB_NAME / DB_USERNAME / DB_PASSWORD from .env
for /f "usebackq tokens=1,* delims==" %%A in (".env") do (
    set "key=%%A"
    if not "!key!"=="" if not "!key:~0,1!"=="#" set "!key!=%%B"
)

if "%DB_PORT%"=="" set DB_PORT=3306

rem Compose JDBC URL for Spring. SSL required — every free MySQL host
rem (Aiven, Clever Cloud, Railway) mandates it; harmless if the host ignores it.
set "DB_URL=jdbc:mysql://%DB_HOST%:%DB_PORT%/%DB_NAME%?useSSL=true&requireSSL=true&serverTimezone=UTC&allowPublicKeyRetrieval=true"

echo Connecting to: %DB_USERNAME%@%DB_HOST%:%DB_PORT%/%DB_NAME%
echo Starting Spring Boot backend on http://localhost:8080
echo.

cd backend
call mvnw.cmd spring-boot:run
pause
