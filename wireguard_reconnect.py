#!/usr/bin/python

import subprocess
import time


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
            print(f"Ping error: {output}")
            raise


def restart_wireguard():
    # 重新连接 WireGuard（请替换为你的命令）
    subprocess.run(["sudo", "systemctl", "restart", "wg-quick@wg0"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print("WireGuard reconnected.")


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
            print("Network is up.")

        is_last_up = True
    else:
        down_count += 1
        if down_count == 1:
            print("Network is down.")
        else:
            pass

        if down_count > allow_max_error_count:
            print("Ping failed ", down_count, " times. Reconnecting WireGuard...")
            restart_wireguard()

        is_last_up = False

    # 每隔一段时间检测一次网络状态（秒）
    time.sleep(3)
