@echo off
title Sakani Live Server & Cloudflare Tunnel
echo ==================================================
echo [1/2] Starting Sakani Backend (.NET 8)...
echo ==================================================
start "Sakani Backend (Port 5093)" cmd /k "cd /d C:\Users\pC\Downloads\sakani_app\SakaniBackend && C:\Users\pC\.dotnet\dotnet.exe bin\Debug\net8.0\SakaniBackend.dll --urls http://0.0.0.0:5093"

timeout /t 3 /nobreak >nul

echo ==================================================
echo [2/2] Starting Cloudflare Tunnel...
echo ==================================================
start "Sakani Cloudflare Tunnel" cmd /k "cd /d C:\Users\pC\Downloads\sakani_app\SakaniBackend && .\cloudflared.exe tunnel --url http://localhost:5093"
echo.
echo ==================================================
echo Both Backend and Tunnel have been launched!
echo Check the Cloudflare window for your trycloudflare.com URL.
echo ==================================================
pause
