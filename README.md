# WireguardWatchGo

WireGuard 连接监控工具的 Go 语言实现版本。

## 功能特性

- 🔄 自动监控 WireGuard VPN 连接状态
- 🚀 跨平台支持（Windows 和 Linux）
- 📊 低内存占用（约 5-10 MB）
- 📝 详细的日志记录
- ⚡ 快速响应网络故障（5秒检测间隔）

## 安装依赖

```bash
cd D:\develop\WireguardWatchGo
go mod download
```

## 编译

### Windows 版本
```bash
go build -o wireguard-watchdog.exe
```

### Linux 版本
```bash
GOOS=linux GOARCH=amd64 go build -o wireguard-watchdog
```

## 使用方法

### Windows
```bash
wireguard-watchdog.exe h4=10.4.4.1 n7=10.7.7.1
```

### Linux
```bash
sudo ./wireguard-watchdog
```
