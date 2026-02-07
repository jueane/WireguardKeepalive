# AGENTS.md - WireguardWatchGo 开发指南

本文件为 AI 代理和开发者提供项目开发规范和操作指南。

## 项目概述

WireguardWatchGo 是一个 WireGuard VPN 连接监控工具，使用 Go 语言编写，支持 Windows 和 Linux 平台。当网络不通时自动重启 WireGuard 服务，具有低内存占用、详细日志记录等特点。

## 构建命令

### 依赖安装
```bash
go mod download
```

### Windows 编译
```bash
go build -o wireguard-watchdog.exe
```

### Linux 编译
```bash
GOOS=linux GOARCH=amd64 go build -o wireguard-watchdog
```

### 交叉编译示例
```bash
# Windows x64
GOOS=windows GOARCH=amd64 go build -o wwg.exe

# Linux x64
GOOS=linux GOARCH=amd64 go build -o wwg
```

### 运行程序
```bash
# Windows 使用
wireguard-watchdog.exe h4=10.4.4.1 n7=10.7.7.1

# Linux 使用
sudo ./wireguard-watchdog
```

## 代码风格规范

### 命名约定

**文件命名**：使用小写字母，单词间用下划线分隔（snake_case），例如 `wireguard.go`、`log_parser.go`。

**包名**：使用简短的小写字母，不使用下划线或混合大小写，如 `config`、`logger`、`network`、`service`。

**类型命名**：使用 PascalCase，遵循清晰简洁的原则，如 `WgConfig`、`NetworkMonitor`。

**变量命名**：使用 camelCase，避免缩写，保持语义清晰，如 `targetIP`、`downCount`、`isLastUp`。常量使用全大写加下划线，如 `AllowMaxErrorCount`。

**函数命名**：使用 PascalCase，公开函数首字母大写，私有函数首字母小写。

### 导入规范

按以下顺序分组导入：
1. Go 标准库
2. 第三方库
3. 本地内部包（相对于项目根目录的路径）

各组之间用空行分隔：
```go
import (
    "fmt"
    "os"
    "time"
    
    "gopkg.in/ini.v1"
    
    "wireguardwatchgo/config"
    "wireguardwatchgo/logger"
    "wireguardwatchgo/types"
)
```

### 格式化规则

**缩进**：使用 Go 官方标准格式（gofmt），不要手动调整缩进。

**行宽**：单行代码不宜过长，保持在合理范围内。

**空格**：二元运算符两侧加空格，函数参数之间加空格，括号内侧不加空格。

**空行**：函数之间、逻辑块之间使用空行提高可读性；单行相关代码之间不加空行。

### 错误处理

Go 语言错误处理遵循以下原则：
- 函数应返回错误类型而非忽略错误
- 立即处理错误或返回给调用者
- 使用 `if err != nil { return err }` 模式处理错误
- 自定义错误信息应包含上下文信息
- 避免在业务逻辑中使用 `panic`

```go
func processData(data []byte) error {
    cfg, err := ini.Load(file)
    if err != nil {
        return fmt.Errorf("解析配置文件失败 %s: %w", file, err)
    }
    // 继续处理
}
```

### 日志记录

使用项目中的 `logger` 包记录日志：
- `logger.Info()` 记录普通信息
- `logger.Error()` 记录错误信息

日志消息使用中文，清晰描述事件：
```go
logger.Info("网络已恢复")
logger.Error("解析配置文件失败: " + err.Error())
```

### 注释规范

**包注释**：每个包应有包级别的注释说明包的用途。

**函数注释**：导出函数必须有注释说明功能、参数和返回值。

**行内注释**：复杂逻辑或关键步骤可添加行内注释说明。

注释使用中文，与项目现有风格保持一致。

### 结构体定义

结构体字段注释清晰说明字段用途：
```go
type WgConfig struct {
    Name      string // 接口名（如 "wg0"）
    FilePath  string // Linux: 配置文件路径, Windows: ""
    TargetIP  string // 要 ping 的目标 IP
    DownCount int    // 连续失败次数
    IsLastUp  bool   // 上次检测状态
}
```

### 常量定义

相关常量分组定义并添加注释：
```go
const (
    AllowMaxErrorCount = 3               // 允许失败次数
    CheckInterval      = 5 * time.Second // 检测间隔
    LogFile            = "logfile.log"   // 日志文件
)
```

### 跨平台兼容性

项目同时支持 Windows 和 Linux，使用 `runtime.GOOS` 判断操作系统类型：
```go
if runtime.GOOS == "windows" {
    // Windows 特定逻辑
} else if runtime.GOOS == "linux" {
    // Linux 特定逻辑
} else {
    logger.Error("不支持的平台: " + runtime.GOOS)
}
```

### 项目目录结构

```
wireguardwatchgo/
├── main.go              # 程序入口
├── go.mod               # 模块定义
├── README.md            # 项目说明
├── AGENTS.md            # 开发指南
├── config/
│   └── parser.go        # 配置解析
├── logger/
│   └── logger.go        # 日志系统
├── network/
│   └── ping.go         # 网络检测
├── service/
│   └── wireguard.go     # WireGuard 服务管理
└── types/
    └── types.go         # 类型定义
```

### 测试规范

项目当前没有测试文件。新增功能应添加对应的单元测试，使用 Go 标准测试框架：
- 测试文件命名为 `xxx_test.go`
- 测试函数以 `Test` 开头
- 使用 `testing` 包

运行所有测试：
```bash
go test ./...
```

### 代码质量检查

格式化代码：
```bash
gofmt -w .
```

检查并修复代码：
```bash
go vet ./...
```

### 提交规范

提交前确保：
- 代码已格式化（gofmt）
- 没有编译错误（go build）
- 新功能添加了测试
- 遵循上述代码风格规范

提交信息使用中文，说明更改内容和原因。
