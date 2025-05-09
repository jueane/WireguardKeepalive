#!/usr/bin/python

from pythonping import ping
import subprocess
import time
import logging
import os
import platform

import wireguard_file_parser
from WGConfig import WgConfig

# 获取当前脚本的路径
current_path = os.path.dirname(os.path.realpath(__file__))

print(current_path)

log_file = os.path.join(current_path, 'logfile.log')

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
)

# 创建日志记录器
log = logging.getLogger('demo')

# 添加 FileHandler，指定输出到文件的路径
file_handler = logging.FileHandler(log_file)
log.addHandler(file_handler)

file_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
file_handler.setFormatter(file_formatter)

log.setLevel(logging.INFO)
log.info("Wireguard Keepalive Running")


def check_network(ip):
    try:
        response_list = ping(ip, count=1, timeout=1)
        return response_list.success()
    except Exception as e:
        log.info(f"Ping error: {e}")
        return False


def restart_wireguard_linux(wg_name):
    subprocess.run(["systemctl", "restart", f"wg-quick@{wg_name}"], check=True, stdout=subprocess.DEVNULL,
                   stderr=subprocess.DEVNULL)
    log.info("WireGuard reconnected.")


def restart_wireguard_windows(wg_name):
    subprocess.run(["wireguard", "/uninstalltunnelservice", wg_name], check=False,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    time.sleep(3)

    subprocess.run(
        ["wireguard", "/installtunnelservice", rf"C:\Program Files\WireGuard\Data\Configurations\{wg_name}.conf.dpapi"],
        check=False,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    log.info("WireGuard reconnected.")


def restart_wireguard(wg_name):
    if platform.system() == 'Linux':
        restart_wireguard_linux(wg_name)
    elif platform.system() == 'Windows':
        restart_wireguard_windows(wg_name)
    else:
        log.error("Unsupported operating system.")


def process_one(wg_inst):
    if check_network(wg_inst.ip):
        wg_inst.down_count = 0

        if wg_inst.is_last_up:
            pass
        else:
            log.info(f"Network {wg_inst.wg_name} is up.")

        wg_inst.is_last_up = True
    else:
        wg_inst.down_count += 1
        if wg_inst.down_count == 1:
            log.info(f"Network {wg_inst.wg_name} is down.")
        else:
            pass

        log.info(f"Network {wg_inst.wg_name} Waiting {wg_inst.down_count}")

        if wg_inst.down_count > WgConfig.allow_max_error_count:
            log.info(f"Network {wg_inst.wg_name} Ping failed {wg_inst.down_count} times. Reconnecting WireGuard...")
            restart_wireguard(wg_inst.wg_name)

        wg_inst.is_last_up = False


wg_config_list = wireguard_file_parser.get_all_ips()

while True:
    for wg in wg_config_list:
        process_one(wg)

    # 每隔一段时间检测一次网络状态（秒）
    time.sleep(5)
