#!/usr/bin/python

import subprocess
import time
import logging
from systemd.journal import JournalHandler
from systemd import journal
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


def check_network():
    try:
        subprocess.run(["ping", "-c", "1", "10.1.1.1"], check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        return True
    except subprocess.CalledProcessError as e:
        # 获取 ping 命令的输出
        output = e.output.decode('utf-8')
        if "100% packet loss" in output:
            return False
        else:
            # 其他错误，将其输出
            log.info(f"Ping error: {output}")
            raise


def restart_wireguard():
    # 重新连接 WireGuard（请替换为你的命令）
    subprocess.run(["systemctl", "restart", "wg-quick@wg0"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    log.info("WireGuard reconnected.")


# 允许ping失败的次数
allow_max_error_count = 3
down_count = 0
# 上次是在线的
is_last_up = False

while True:
    if check_network():
        down_count = 0
        if is_last_up:
            pass
        else:
            log.info("Network is up.")

        is_last_up = True
    else:
        down_count += 1
        if down_count == 1:
            log.info("Network is down.")
        else:
            pass

        log.info(f"Waiting {down_count}")

        if down_count > allow_max_error_count:
            log.info(f"Ping failed {down_count} times. Reconnecting WireGuard...")
            restart_wireguard()

        is_last_up = False

    # 每隔一段时间检测一次网络状态（秒）
    time.sleep(10)
