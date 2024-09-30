#!/bin/bash

# 检查操作系统
if [[ -f /etc/debian_version ]]; then
    # Debian/Ubuntu 系统
    echo "检测到 Debian/Ubuntu 系统，安装 python3-venv..."
    sudo apt-get update
    sudo apt-get install python3-venv -y
elif [[ -f /etc/arch-release ]]; then
    # Arch Linux 系统
    echo "检测到 Arch Linux 系统，安装 python3-venv..."
    sudo pacman -Sy python-virtualenv --noconfirm
else
    echo "不支持的操作系统，请手动安装 python3-venv。"
    exit 1
fi

# 创建虚拟环境
echo "创建虚拟环境..."
python3 -m venv venv

# 激活虚拟环境
echo "激活虚拟环境..."
source venv/bin/activate

# 安装依赖
if [ -f requirements.txt ]; then
    echo "安装依赖..."
    pip install -r requirements.txt
else
    echo "requirements.txt 文件未找到。"
fi

# 退出虚拟环境
echo "退出虚拟环境..."
deactivate

echo "完成！"
