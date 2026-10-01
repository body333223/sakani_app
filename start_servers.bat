@echo off
chcp 65001 >nul
title Sakani Live Server & Auto-Sync
cd /d "%~dp0"
python run_sakani_online.py
pause
