#!/bin/bash
#cd "$(dirname "$0")"


# 获取脚本所在目录的绝对路径
script_dir="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# 切换工作目录到脚本所在目录
cd "$script_dir"


venv/bin/python wireguard_keepalive.py "$@"

