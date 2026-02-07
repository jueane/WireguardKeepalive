package config

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"wireguardwatchgo/logger"
	"wireguardwatchgo/types"

	"gopkg.in/ini.v1"
)

// GetConfigs 获取所有 WireGuard 配置
func GetConfigs() []types.WgConfig {
	if runtime.GOOS == "windows" {
		return getWindowsConfigs()
	} else if runtime.GOOS == "linux" {
		return getLinuxConfigs()
	}
	logger.Error("不支持的平台: " + runtime.GOOS)
	return []types.WgConfig{}
}

// getWindowsConfigs Windows: 从命令行参数解析
func getWindowsConfigs() []types.WgConfig {
	var configs []types.WgConfig

	for _, arg := range os.Args[1:] {
		parts := strings.SplitN(arg, "=", 2)
		if len(parts) != 2 {
			logger.Error("参数格式错误: " + arg)
			continue
		}

		name := parts[0]
		ip := parts[1]

		logger.Info("从参数解析配置: " + name + " -> " + ip)
		configs = append(configs, types.WgConfig{
			Name:      name,
			FilePath:  "",
			TargetIP:  ip,
			DownCount: 0,
			IsLastUp:  false,
		})
	}

	return configs
}

// getLinuxConfigs Linux: 扫描 /etc/wireguard/*.conf
func getLinuxConfigs() []types.WgConfig {
	var configs []types.WgConfig
	configDir := "/etc/wireguard"

	files, err := filepath.Glob(filepath.Join(configDir, "*.conf"))
	if err != nil {
		logger.Error("扫描配置文件失败: " + err.Error())
		return configs
	}

	for _, file := range files {
		cfg, err := ini.Load(file)
		if err != nil {
			logger.Error("解析配置文件失败 " + file + ": " + err.Error())
			continue
		}

		// 读取 [Interface] 节的 Address
		address := cfg.Section("Interface").Key("Address").String()
		if address == "" {
			logger.Error("未找到 Address 字段: " + file)
			continue
		}

		// 转换为网关 IP
		targetIP := getGatewayIP(address)
		if targetIP == "" {
			logger.Error("无法提取网关 IP: " + address)
			continue
		}

		name := strings.TrimSuffix(filepath.Base(file), ".conf")
		logger.Info("找到配置: " + name + " -> " + targetIP + " (" + file + ")")

		configs = append(configs, types.WgConfig{
			Name:      name,
			FilePath:  file,
			TargetIP:  targetIP,
			DownCount: 0,
			IsLastUp:  false,
		})
	}

	return configs
}

// getGatewayIP 将 VPN 客户端地址转换为网关地址
// 例如: "10.0.0.2/24" -> "10.0.0.1"
func getGatewayIP(ipStr string) string {
	// 去除 CIDR 后缀
	ipPart := strings.Split(ipStr, "/")[0]

	// 分割为 4 段
	parts := strings.Split(ipPart, ".")
	if len(parts) != 4 {
		return ""
	}

	// 最后一段改为 "1"
	parts[3] = "1"
	return strings.Join(parts, ".")
}
