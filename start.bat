@echo off
setlocal enabledelayedexpansion

set VENV_NAME=venv_win
set MAIN_SCRIPT=main.py


chcp 65001 > nul
cd /d "%~dp0"


:: 检查是否已经存在虚拟环境
if not exist "%VENV_NAME%" (
    echo Creating virtual environment...
    python -m venv "%VENV_NAME%" --upgrade-deps
)

:: 激活虚拟环境
echo Activating virtual environment...
call "%VENV_NAME%\Scripts\activate.bat"

:: 检查 pip 是否存在，如果不存在则手动安装
python -m pip --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Pip not found. Installing pip...
    curl -s https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python get-pip.py
    del get-pip.py
)

:: 升级 pip（可选）
echo Upgrading pip...
python -m pip install --upgrade pip

:: 检查 requirements.txt 是否存在
if not exist "requirements.txt" (
    echo Error: requirements.txt not found!
    exit /b 1
)

:: 安装依赖
echo Installing dependencies from requirements.txt...
pip install -r requirements.txt

:: 检查主脚本是否存在
if not exist "%MAIN_SCRIPT%" (
    echo Error: %MAIN_SCRIPT% not found!
    exit /b 1
)

:: 运行主脚本
echo Running main script...
python "%MAIN_SCRIPT%"  %*

:: 停用虚拟环境
call "%VENV_NAME%\Scripts\deactivate.bat"
echo Done.