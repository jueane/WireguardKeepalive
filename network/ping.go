package network

import (
	"os/exec"
	"runtime"
)

// Ping 检测 IP 是否可达
func Ping(ip string) bool {
	var cmd *exec.Cmd

	if runtime.GOOS == "windows" {
		// Windows: ping -n 1 -w 1000 {ip}
		cmd = exec.Command("ping", "-n", "1", "-w", "1000", ip)
	} else {
		// Linux: ping -c 1 -W 1 {ip}
		cmd = exec.Command("ping", "-c", "1", "-W", "1", ip)
	}

	// 忽略输出，只关心退出码
	err := cmd.Run()
	return err == nil
}
