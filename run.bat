@echo off
echo ============================================================
echo  MediChain - Starting Application
echo ============================================================
echo.
echo Starting Spring Boot backend on http://localhost:8080
echo.
cd backend
call mvnw.cmd spring-boot:run
pause
