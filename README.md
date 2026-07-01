# WireguardWatchGo

WireGuard 连接监控工具：定期 ping 检查隧道连通性，连续失败后自动重启对应的 WireGuard 服务。

Linux 下会自动扫描 `/etc/wireguard/*.conf`；Windows 下通过命令行参数指定接口和检查 IP。

## 功能特性

- 自动检测 WireGuard 连通性，连续失败后重启对应隧道。
- Linux 自动扫描 `/etc/wireguard/*.conf`，从 `Address` 推导检查 IP。
- Windows 支持通过命令行参数指定多个接口和检查 IP。
- 支持 systemd 服务运行、开机自启和 journal 日志查看。
- 日志会记录接口名、检查 IP、失败次数和重启动作。

## Linux

### 前置要求

- 已安装 WireGuard / `wg-quick`
- WireGuard 配置文件位于 `/etc/wireguard/*.conf`
- 系统有 `curl`、`tar`、`sha256sum`
- 安装和服务管理需要 `sudo` 或 root 权限

### 安装

一键下载最新 release，并安装到 `/opt/wireguard-watchdog`：

```bash
curl -fsSL https://raw.githubusercontent.com/jueane/WireguardKeepalive/main/install-latest.sh | bash
```

安装 systemd 服务并立即启动：

```bash
cd /opt/wireguard-watchdog
sudo ./installService.sh
```

脚本会自动识别 `amd64` / `arm64`，下载对应的 Linux 包，校验 SHA256，然后复制到 `/opt/wireguard-watchdog`。

### 监控地址规则

Linux 版本不会额外读取配置文件里的目标地址，而是从 `[Interface]` 的 `Address` 推导网关 IP：

```ini
[Interface]
Address = 10.1.1.2/24
```

上面的配置会检查：

```text
10.1.1.1
```

规则就是把本机 VPN 地址最后一段改为 `.1`。

修改 `/etc/wireguard/*.conf` 后，需要重启 `wireguard-watchdog`，程序才会重新读取检查地址。

### 服务命令

```bash
sudo systemctl status wireguard-watchdog
sudo systemctl restart wireguard-watchdog
sudo systemctl stop wireguard-watchdog
sudo systemctl enable wireguard-watchdog
```

查看日志：

```bash
sudo journalctl -u wireguard-watchdog -f
```

卸载服务：

```bash
cd /opt/wireguard-watchdog
sudo ./uninstallService.sh
```

### 更新

重新执行下载脚本后重启服务：

```bash
curl -fsSL https://raw.githubusercontent.com/jueane/WireguardKeepalive/main/install-latest.sh | bash
sudo systemctl restart wireguard-watchdog
```

## Windows

前置要求：

已安装 [WireGuard for Windows](https://www.wireguard.com/install/)
管理员权限
运行：

```bash
# 格式：wireguard-watchdog.exe 接口名1=目标IP1 接口名2=目标IP2 ...
wireguard-watchdog.exe h4=10.4.4.1 n7=10.7.7.1
```

参数说明：

`h4=10.4.4.1` - 监控名为 `h4` 的 WireGuard 接口，ping 目标为 `10.4.4.1`
可以同时监控多个接口，用空格分隔
开机启动：在TaskScheduler中添加启动项

## 行为说明

- 每 5 秒检查一次。
- 连续失败超过 3 次后触发重启。
- Linux 重启命令：`systemctl restart wg-quick@接口名`
- 日志输出到 systemd journal，同时写入程序目录下的 `logfile.log`。

## License

MIT License
