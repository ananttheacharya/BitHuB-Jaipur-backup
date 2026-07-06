@echo off
title BitHuB Development Service

echo ==========================================
echo Starting BitHuB Development Services...
echo ==========================================
echo.
echo [VERIFICATION] Configuration:
echo - Frontend: Localhost (Port 3000)
echo - Backend:  https://bithub-jaipur-development.onrender.com (Remote)
echo - Database: Automatically handled by remote backend
echo.
echo ==========================================
echo.

:: Ensure frontend connects to remote backend via Vite proxy
set VITE_BACKEND_URL=https://bithub-jaipur-development.onrender.com
set VITE_API_BASE_URL=

:: Start the Frontend in a new window
echo Starting React Frontend on port 3000...
start "BitHuB Frontend" cmd /k "cd ""Front-End New"" && npm.cmd run dev"

:: Wait a few seconds for the frontend to initialize
timeout /t 5 /nobreak >nul

:: Start Ngrok in the current window
echo.
echo Starting Ngrok Tunnel on port 3000...
echo ==========================================
npx.cmd ngrok http 127.0.0.1:3000
