package main

import (
	"fmt"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"
	"wireguardwatchgo/config"
	"wireguardwatchgo/logger"
	"wireguardwatchgo/network"
	"wireguardwatchgo/service"
	"wireguardwatchgo/types"
)

func main() {
	// 获取可执行文件所在目录
	exePath, err := os.Executable()
	if err != nil {
		fmt.Printf("获取程序路径失败: %v\n", err)
		os.Exit(1)
	}
	exeDir := filepath.Dir(exePath)
	logPath := filepath.Join(exeDir, types.LogFile)

	// 初始化日志
	if err := logger.Init(logPath); err != nil {
		fmt.Printf("日志初始化失败: %v\n", err)
		os.Exit(1)
	}
	defer logger.Close()

	logger.Info("Wireguard Keepalive Running (Go)")

	// 加载配置
	configs := config.GetConfigs()
	if len(configs) == 0 {
		logger.Info("未找到 WireGuard 配置，退出")
		return
	}

	// 处理 Ctrl+C 信号
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-sigChan
		logger.Info("停止 Wireguard Watchdog...")
		os.Exit(0)
	}()

	// 主循环
	mainLoop(configs)
}

// mainLoop 主监控循环
func mainLoop(configs []types.WgConfig) {
	for {
		// 处理每个配置
		for i := range configs {
			processOne(&configs[i])
		}

		// 休眠
		time.Sleep(types.CheckInterval)
	}
}

// processOne 处理单个 WireGuard 配置
func processOne(wg *types.WgConfig) {
	isOnline := network.Ping(wg.TargetIP)

	if isOnline {
		// Ping 成功
		wg.DownCount = 0
		if !wg.IsLastUp {
			logger.Info(fmt.Sprintf("网络 %s 已恢复", wg.Name))
		}
		wg.IsLastUp = true
	} else {
		// Ping 失败
		wg.DownCount++
		if wg.DownCount == 1 {
			logger.Info(fmt.Sprintf("网络 %s 已断开", wg.Name))
		}

		logger.Info(fmt.Sprintf("网络 %s 等待中 %d", wg.Name, wg.DownCount))

		if wg.DownCount > types.AllowMaxErrorCount {
			logger.Info(fmt.Sprintf("网络 %s Ping 失败 %d 次，正在重新连接...", wg.Name, wg.DownCount))
			service.RestartWireguard(wg.Name)
		}

		wg.IsLastUp = false
	}
}
