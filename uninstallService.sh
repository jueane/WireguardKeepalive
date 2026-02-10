#!/bin/bash

echo "Uninstalling Wireguard Watchdog Service..."

# 停止服务
echo "Stopping service..."
systemctl stop wireguard-watchdog.service

# 禁用服务（取消开机自启）
echo "Disabling service..."
systemctl disable wireguard-watchdog.service

# 删除可执行文件符号链接
echo "Removing executable symlink..."
rm -f /usr/local/bin/wireguard-watchdog

# 删除服务文件
echo "Removing service file..."
rm -f /etc/systemd/system/wireguard-watchdog.service

# 重新加载 systemd
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Uninstallation complete!"
