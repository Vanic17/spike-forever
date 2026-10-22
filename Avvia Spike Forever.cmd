@echo off
cd /d "%~dp0"
set "APPDATA=%~dp0.runtime\roaming"
set "LOCALAPPDATA=%~dp0.runtime\local"
start "Spike Forever" "tools\godot\Godot_v4.5.1-stable_win64.exe" --path "%~dp0."
