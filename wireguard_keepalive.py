#!/usr/bin/python

import subprocess
import time
import logging
import os

# 获取当前脚本的路径
current_path = os.path.dirname(os.path.realpath(__file__))

print(current_path)

log_file = current_path + '/logfile.log'

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
        subprocess.run(["ping", "-c", "1", ip], check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        return True
    except subprocess.CalledProcessError as e:
        # 获取 ping 命令的输出
        output = e.output.decode('utf-8')
        if "100% packet loss" in output:
            return False
        else:
            # 其他错误，将其输出
            log.info(f"Ping error: {output}")


def restart_wireguard(wg_name):
    # 重新连接 WireGuard（请替换为你的命令）
    subprocess.run(["systemctl", "restart", f"wg-quick@{wg_name}"], check=True, stdout=subprocess.DEVNULL,
                   stderr=subprocess.DEVNULL)
    log.info("WireGuard reconnected.")


class WgConfig:
    # 允许ping失败的次数
    allow_max_error_count = 3

    def __init__(self, wg_name, ip):
        self.wg_name = wg_name
        self.ip = ip
        self.down_count = 0
        # 上次是在线的
        self.is_last_up = False


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


wg_config_list = [
    WgConfig("wg0", "10.1.1.1"),
    WgConfig("wg1", "10.4.4.1")
]

while True:
    for wg in wg_config_list:
        process_one(wg)

    # 每隔一段时间检测一次网络状态（秒）
    time.sleep(10)
