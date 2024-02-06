#!/usr/bin/python

import os

# 获取当前脚本的路径
current_path = os.path.dirname(os.path.abspath(__file__))

# 源文件和目标路径
source_file_py = os.path.join(current_path, "startservice.sh")
target_link_py = "/bin/wireguard_keepalive"

source_file_service = os.path.join(current_path, "wireguard_keepalive.service")
target_link_service = "/etc/systemd/system/wireguard_keepalive.service"

# 创建软链接
try:
    # 创建Python脚本软链接
    if os.path.exists(target_link_py):
        os.remove(target_link_py)  # 如果软链接已存在，先删除
    os.symlink(source_file_py, target_link_py)
    print(f"软链接成功创建：{target_link_py}")

except Exception as e:
    print(f"创建软链接时发生错误：{e}")

# 创建软链接
try:
    # 创建服务文件软链接
    if os.path.exists(target_link_service):
        os.remove(target_link_service)  # 如果软链接已存在，先删除
    os.symlink(source_file_service, target_link_service)
    print(f"软链接成功创建：{target_link_service}")

except Exception as e:
    print(f"创建软链接时发生错误：{e}")
