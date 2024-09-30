@echo off

chcp 65001

REM 检查是否安装了 python3-venv
python -m venv --help >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo "请确保已安装 Python 3 和 venv 模块。"
    exit /b
)

REM 创建虚拟环境
echo "创建虚拟环境"
python -m venv venv

echo "激活虚拟环境..."
call venv\Scripts\activate

REM 安装依赖
IF EXIST requirements.txt (
    echo "安装依赖..."
    pip install -r requirements.txt
) ELSE (
    echo requirements.txt 文件未找到。
)

REM "退出虚拟环境"
echo 退出虚拟环境...
deactivate

echo 完成！
