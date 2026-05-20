@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-MpLogTail.ps1" %*
