#!/bin/bash

# 获取脚本所在目录的绝对路径
script_dir="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# 切换工作目录到脚本所在目录
cd "$script_dir"
pwd

VENV_NAME="venv"
MAIN_SCRIPT="main.py"


# 检查是否已经存在虚拟环境
if [ ! -d "$VENV_NAME" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_NAME" --upgrade-deps  # 确保安装 pip 和 setuptools
fi

# 激活虚拟环境
echo "Activating virtual environment..."
source "$VENV_NAME/bin/activate"

# 检查 pip 是否存在，如果不存在则手动安装
if ! python -m pip --version &> /dev/null; then
    echo "Pip not found. Installing pip..."
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python get-pip.py
    rm get-pip.py
fi

# 升级 pip（可选）
echo "Upgrading pip..."
python -m pip install --upgrade pip

# 检查 requirements.txt 是否存在
if [ ! -f "requirements.txt" ]; then
    echo "Error: requirements.txt not found!"
    exit 1
fi

# 安装依赖
echo "Installing dependencies from requirements.txt..."
pip install -r requirements.txt

# 检查主脚本是否存在
if [ ! -f "$MAIN_SCRIPT" ]; then
    echo "Error: $MAIN_SCRIPT not found!"
    exit 1
fi

# 运行主脚本
echo "Running main script..."
python "$MAIN_SCRIPT" "$@"

# 停用虚拟环境
echo "deactivate..."
deactivate
echo "Done."