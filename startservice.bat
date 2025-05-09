chcp 65001 > nul

setlocal

set "script_dir=%~dp0"

cd /d "%script_dir%"

venv\Scripts\python.exe main.py %*
