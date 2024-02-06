chcp 65001 > nul

setlocal

rem 获取脚本所在目录的绝对路径
set "script_dir=%~dp0"

rem 切换工作目录到脚本所在目录
cd /d "%script_dir%"

python wireguard_keepalive.py
