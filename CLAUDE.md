# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

WireguardWatchGo 是一个 Go 语言编写的 WireGuard 连接监控工具，通过定期 ping 目标 IP 来检测 VPN 连接状态，当连接失败超过阈值时自动重启 WireGuard 服务。

**核心特性：**
- 跨平台支持（Windows 和 Linux）
- 自动故障恢复机制
- 低资源占用（约 5-10 MB）
- 详细日志记录

## 构建和运行

### 本地构建
```bash
# Windows
go build -o wireguard-watchdog.exe

# Linux
go build -o wireguard-watchdog

# 交叉编译 Linux 版本（在 Windows 上）
GOOS=linux GOARCH=amd64 go build -o wireguard-watchdog
```

### 运行
```bash
# Windows（需要管理员权限）
wireguard-watchdog.exe h4=10.4.4.1 n7=10.7.7.1

# Linux（需要 root 权限）
sudo ./wireguard-watchdog
```

### 依赖管理
```bash
go mod download    # 下载依赖
go mod tidy        # 清理依赖
go mod verify      # 验证依赖
```

## 代码架构

### 包结构
```
wireguardwatchgo/
├── main.go              # 主入口，监控循环
├── config/              # 配置解析
│   └── parser.go        # 平台特定的配置加载逻辑
├── network/             # 网络检测
│   └── ping.go          # 跨平台 ping 实现
├── service/             # 服务管理
│   └── wireguard.go     # WireGuard 重启逻辑
├── logger/              # 日志系统
│   └── logger.go        # 双输出日志（控制台+文件）
└── types/               # 类型定义
    └── types.go         # 核心数据结构和常量
```

### 核心工作流程

1. **配置加载** (`config.GetConfigs()`)
   - **Windows**: 从命令行参数解析（格式：`name=ip`）
   - **Linux**: 扫描 `/etc/wireguard/*.conf`，从 `[Interface].Address` 推导网关 IP

2. **监控循环** (`main.mainLoop()`)
   - 每 5 秒检测一次所有配置的目标 IP
   - 使用 `network.Ping()` 执行平台特定的 ping 命令
   - 维护每个配置的失败计数器 (`DownCount`)

3. **故障恢复** (`service.RestartWireguard()`)
   - 当连续失败次数 > 3 次时触发
   - **Windows**: 卸载隧道服务 → 等待 3 秒 → 重新安装
   - **Linux**: 执行 `systemctl restart wg-quick@{name}`

### 关键设计决策

- **平台差异处理**: 所有平台特定逻辑都通过 `runtime.GOOS` 判断，集中在各自的包中
- **状态管理**: `WgConfig` 结构体维护每个接口的状态（`DownCount`, `IsLastUp`）
- **日志策略**: 同时输出到控制台和文件（`logfile.log`），便于调试和生产环境使用
- **信号处理**: 捕获 `SIGINT` 和 `SIGTERM` 以优雅退出

### 配置常量（`types/types.go`）
- `AllowMaxErrorCount = 3`: 触发重启前允许的连续失败次数
- `CheckInterval = 5s`: 检测间隔
- `LogFile = "logfile.log"`: 日志文件路径

## CI/CD

项目使用 GitHub Actions 进行自动化构建和发布：

### CI 工作流（`.github/workflows/ci.yml`）
- 触发：推送到 main 分支或 Pull Request
- 任务：代码质量检查（`go fmt`, `go vet`, `go mod verify`）+ 多平台构建验证

### Release 工作流（`.github/workflows/release.yml`）
- 触发：推送 `v*` 格式的 tag（如 `v1.0.0`）
- 输出：自动构建并发布多平台二进制文件到 GitHub Releases
  - `wireguard-watchdog-linux-amd64`
  - `wireguard-watchdog-linux-arm64`
  - `wireguard-watchdog-windows-amd64.exe`
  - 每个文件附带 SHA256 校验和

### 发布新版本
```bash
git tag v1.0.0
git push origin v1.0.0
# GitHub Actions 自动构建并创建 Release
```

详细说明见 `GITHUB_ACTIONS.md`。

## 平台特定注意事项

### Windows
- 需要管理员权限运行
- 依赖 WireGuard 官方客户端的 `wireguard.exe` CLI 工具
- 配置文件路径：`C:\Program Files\WireGuard\Data\Configurations\{name}.conf.dpapi`
- 命令行参数格式：`接口名=目标IP`（如 `h4=10.4.4.1`）

### Linux
- 需要 root 权限（`sudo`）
- 依赖 `systemctl` 和 `wg-quick` 服务
- 配置文件路径：`/etc/wireguard/*.conf`
- 自动从配置文件的 `Address` 字段推导网关 IP（将最后一段改为 `.1`）

## 常见修改场景

### 调整检测间隔
修改 `types/types.go` 中的 `CheckInterval` 常量。

### 调整失败阈值
修改 `types/types.go` 中的 `AllowMaxErrorCount` 常量。

### 添加新的平台支持
1. 在 `config/parser.go` 中添加新的 `get{Platform}Configs()` 函数
2. 在 `network/ping.go` 中添加平台特定的 ping 命令
3. 在 `service/wireguard.go` 中添加平台特定的重启逻辑
4. 在 `config.GetConfigs()` 中添加新的 `runtime.GOOS` 分支

### 修改日志格式
修改 `logger/logger.go` 中的 `formatMessage()` 函数。
