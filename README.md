# WireguardWatchGo

WireGuard 连接监控工具，通过定期 ping 检测 VPN 连接状态，网络不通时自动重启 WireGuard 服务。

## ✨ 功能特性

- 🔄 **自动故障恢复** - 检测到连接失败时自动重启 WireGuard 服务
- 🚀 **跨平台支持** - 原生支持 Windows 和 Linux
- 📊 **低资源占用** - 内存占用约 5-10 MB
- 📝 **详细日志记录** - 同时输出到控制台和文件（`logfile.log`）
- ⚡ **快速响应** - 5 秒检测间隔，连续失败 3 次后触发重启
- 🎯 **智能配置** - Windows 支持命令行参数，Linux 自动扫描配置文件

## 📦 安装

### 从 GitHub Releases 下载（推荐）

访问 [Releases 页面](https://github.com/你的用户名/WireguardWatchGo/releases) 下载预编译的二进制文件：

- **Linux amd64**: `wireguard-watchdog-linux-amd64`
- **Linux arm64**: `wireguard-watchdog-linux-arm64`（适用于树莓派等 ARM 设备）
- **Windows amd64**: `wireguard-watchdog-windows-amd64.exe`

每个文件都附带 SHA256 校验和，可用于验证完整性。

### 从源码编译

**前置要求：**
- Go 1.21 或更高版本
- Git

```bash
# 克隆仓库
git clone https://github.com/你的用户名/WireguardWatchGo.git
cd WireguardWatchGo

# 下载依赖
go mod download

# 编译
go build -o wireguard-watchdog
```

**交叉编译：**
```bash
# 编译 Linux 版本
GOOS=linux GOARCH=amd64 go build -o wireguard-watchdog-linux-amd64

# 编译 Windows 版本
GOOS=windows GOARCH=amd64 go build -o wireguard-watchdog-windows-amd64.exe
```

## 🚀 使用方法

### Windows

**前置要求：**
- 已安装 [WireGuard for Windows](https://www.wireguard.com/install/)
- 管理员权限

**运行：**
```bash
# 格式：wireguard-watchdog.exe 接口名1=目标IP1 接口名2=目标IP2 ...
wireguard-watchdog.exe h4=10.4.4.1 n7=10.7.7.1
```

**参数说明：**
- `h4=10.4.4.1` - 监控名为 `h4` 的 WireGuard 接口，ping 目标为 `10.4.4.1`
- 可以同时监控多个接口，用空格分隔

**开机启动：在TaskScheduler中添加启动项（可选）：**
```bash
# 这样可以开机自动启动
```

### Linux

**前置要求：**
- 已安装 WireGuard（`apt install wireguard` 或 `yum install wireguard-tools`）
- 配置文件位于 `/etc/wireguard/*.conf`
- Root 权限

#### 快速安装（推荐）

使用一键安装脚本自动下载最新版本：

```bash
curl -fsSL https://raw.githubusercontent.com/jueane/WireguardKeepalive/main/install-latest.sh | bash
```

或者下载脚本后执行：

```bash
wget https://raw.githubusercontent.com/jueane/WireguardKeepalive/main/install-latest.sh
chmod +x install-latest.sh
./install-latest.sh
```

脚本会自动：
- 检测系统架构（amd64/arm64）
- 下载最新版本的二进制文件
- 验证 SHA256 校验和
- 解压到 `/opt/wireguard-watchdog` 目录
- 设置执行权限

安装完成后，按照提示运行：

```bash
cd /opt/wireguard-watchdog && sudo ./installService.sh
```

#### 手动运行

**运行：**
```bash
sudo ./wireguard-watchdog
```

程序会自动扫描 `/etc/wireguard/` 目录下的所有 `.conf` 文件，并从配置文件的 `[Interface].Address` 字段推导出网关 IP（将最后一段改为 `.1`）。

**示例：**
```ini
# /etc/wireguard/wg0.conf
[Interface]
Address = 10.0.0.2/24  # 程序会自动 ping 10.0.0.1
PrivateKey = ...

[Peer]
...
```

#### 安装为 systemd 服务（推荐）
```bash
# 创建服务文件
sudo nano /etc/systemd/system/wireguard-watchdog.service
```

```ini
[Unit]
Description=WireGuard Connection Watchdog
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/wireguard-watchdog
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# 启用并启动服务
sudo systemctl daemon-reload
sudo systemctl enable wireguard-watchdog
sudo systemctl start wireguard-watchdog

# 查看状态
sudo systemctl status wireguard-watchdog

# 查看日志
sudo journalctl -u wireguard-watchdog -f
```

## ⚙️ 配置

### 调整检测参数

编辑 `types/types.go` 文件中的常量：

```go
const (
    AllowMaxErrorCount = 3               // 触发重启前允许的连续失败次数
    CheckInterval      = 5 * time.Second // 检测间隔
    LogFile            = "logfile.log"   // 日志文件路径
)
```

修改后需要重新编译。

## 📋 工作原理

1. **配置加载**
   - Windows: 从命令行参数解析接口名和目标 IP
   - Linux: 扫描 `/etc/wireguard/*.conf`，自动推导网关 IP

2. **监控循环**
   - 每 5 秒 ping 一次所有配置的目标 IP
   - 维护每个接口的失败计数器

3. **故障恢复**
   - 连续失败 3 次后触发重启
   - Windows: 卸载隧道服务 → 等待 3 秒 → 重新安装
   - Linux: 执行 `systemctl restart wg-quick@{接口名}`

4. **日志记录**
   - 同时输出到控制台和 `logfile.log` 文件
   - 记录连接状态变化和重启操作

## 🛠️ 开发

### 项目结构

```
wireguardwatchgo/
├── main.go              # 主入口，监控循环
├── config/              # 配置解析（平台特定）
├── network/             # 网络检测（跨平台 ping）
├── service/             # 服务管理（WireGuard 重启）
├── logger/              # 日志系统
└── types/               # 类型定义和常量
```

### 运行测试

```bash
go test ./...
```

### 代码质量检查

```bash
go fmt ./...      # 格式化代码
go vet ./...      # 静态分析
go mod verify     # 验证依赖
```

### CI/CD

项目使用 GitHub Actions 进行自动化构建：

- **CI 工作流**: 每次推送或 PR 时运行代码质量检查和构建验证
- **Release 工作流**: 推送 tag 时自动构建多平台二进制文件并发布到 GitHub Releases

详细说明见 [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md)。

## 📝 日志示例

```
2026/02/09 12:00:00 - demo - INFO - Wireguard Keepalive Running (Go)
2026/02/09 12:00:00 - demo - INFO - 从参数解析配置: h4 -> 10.4.4.1
2026/02/09 12:00:00 - demo - INFO - 从参数解析配置: n7 -> 10.7.7.1
2026/02/09 12:00:05 - demo - INFO - 网络 h4 已断开
2026/02/09 12:00:05 - demo - INFO - 网络 h4 等待中 1
2026/02/09 12:00:10 - demo - INFO - 网络 h4 等待中 2
2026/02/09 12:00:15 - demo - INFO - 网络 h4 等待中 3
2026/02/09 12:00:20 - demo - INFO - 网络 h4 Ping 失败 4 次，正在重新连接...
2026/02/09 12:00:23 - demo - INFO - WireGuard 已重新连接 (Windows)
2026/02/09 12:00:28 - demo - INFO - 网络 h4 已恢复
```

## 📄 许可证

MIT License

## 🔗 相关链接

- [WireGuard 官网](https://www.wireguard.com/)
- [Go 官方文档](https://go.dev/doc/)
 