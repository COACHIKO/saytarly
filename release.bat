@echo off
rem SaytarlyMind — Saytarly Release Control Center (local website)
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tool\megaming.ps1"
if errorlevel 1 pause
