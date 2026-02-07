package types

import "time"

// WgConfig WireGuard 配置
type WgConfig struct {
	Name      string // 接口名（如 "wg0"）
	FilePath  string // Linux: 配置文件路径, Windows: ""
	TargetIP  string // 要 ping 的目标 IP
	DownCount int    // 连续失败次数
	IsLastUp  bool   // 上次检测状态
}

// 常量配置
const (
	AllowMaxErrorCount = 3               // 允许失败次数
	CheckInterval      = 5 * time.Second // 检测间隔
	LogFile            = "logfile.log"   // 日志文件
)
