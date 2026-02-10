#!/bin/bash

# 获取脚本所在目录的绝对路径
script_dir="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# 检查可执行文件是否存在
if [ ! -f "$script_dir/wireguard-watchdog" ]; then
    echo "Executable not found. Building..."
    cd "$script_dir"
    ./build.sh
    if [ $? -ne 0 ]; then
        echo "Build failed!"
        exit 1
    fi
else
    echo "Executable already exists, skipping build."
fi

echo "Installing Wireguard Watchdog from: $script_dir"

# 安装 systemd 服务文件
echo "Installing systemd service..."
ln -sf "$script_dir/wireguard-watchdog.service" /etc/systemd/system/

# 安装可执行文件
echo "Installing executable..."
ln -sf "$script_dir/wireguard-watchdog" /usr/local/bin/wireguard-watchdog

# 重新加载 systemd
echo "Reloading systemd daemon..."
systemctl daemon-reload

# 启用服务（开机自启）
echo "Enabling service..."
systemctl enable wireguard-watchdog.service

# 启动服务
echo "Starting service..."
systemctl start wireguard-watchdog.service

echo "Installation complete!"
echo "Service status: systemctl status wireguard-watchdog"
