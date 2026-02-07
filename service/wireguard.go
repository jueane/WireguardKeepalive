package service

import (
	"fmt"
	"os/exec"
	"runtime"
	"time"
	"wireguardwatchgo/logger"
)

// RestartWireguard 重启 WireGuard 服务
func RestartWireguard(name string) {
	if runtime.GOOS == "windows" {
		restartWindows(name)
	} else if runtime.GOOS == "linux" {
		restartLinux(name)
	} else {
		logger.Error("不支持的操作系统: " + runtime.GOOS)
	}
}

// restartWindows Windows 重启流程
func restartWindows(name string) {
	// 1. 卸载服务
	cmd := exec.Command("wireguard", "/uninstalltunnelservice", name)
	if err := cmd.Run(); err != nil {
		logger.Error("卸载隧道失败: " + err.Error())
	}

	// 2. 等待 3 秒
	time.Sleep(3 * time.Second)

	// 3. 重新安装服务
	configPath := fmt.Sprintf(`C:\Program Files\WireGuard\Data\Configurations\%s.conf.dpapi`, name)
	cmd = exec.Command("wireguard", "/installtunnelservice", configPath)
	if err := cmd.Run(); err != nil {
		logger.Error("安装隧道失败: " + err.Error())
	}

	logger.Info("WireGuard 已重新连接 (Windows)")
}

// restartLinux Linux 重启流程
func restartLinux(name string) {
	cmd := exec.Command("systemctl", "restart", "wg-quick@"+name)
	if err := cmd.Run(); err != nil {
		logger.Error("systemctl 重启失败: " + err.Error())
	}
	logger.Info("WireGuard 已重新连接 (Linux)")
}
