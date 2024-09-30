chcp 65001 > nul

setlocal

set "script_dir=%~dp0"

cd /d "%script_dir%"

python wireguard_keepalive.py %*
