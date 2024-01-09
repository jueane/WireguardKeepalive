#!/usr/bin/python

import os

# 获取当前脚本的路径
current_path = os.path.dirname(os.path.abspath(__file__))

# 源文件和目标路径
source_file_py = os.path.join(current_path, "wireguard_keepalive.py")
target_link_py = "/bin/wireguard_keepalive"

source_file_service = os.path.join(current_path, "wireguard_keepalive.service")
target_link_service = "/etc/systemd/system/wireguard_keepalive.service"

# 创建软链接
try:
    # 创建Python脚本软链接
    os.symlink(source_file_py, target_link_py)
    print(f"软链接成功创建：{target_link_py}")

except FileExistsError:
    print(f"{target_link_py}软链接已存在，无需创建。")
except Exception as e:
    print(f"创建软链接时发生错误：{e}")

# 创建软链接
try:
    # 创建服务文件软链接
    os.symlink(source_file_service, target_link_service)
    print(f"软链接成功创建：{target_link_service}")

except FileExistsError:
    print(f"{target_link_service}软链接已存在，无需创建。")
except Exception as e:
    print(f"创建软链接时发生错误：{e}")
