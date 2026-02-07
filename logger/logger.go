package logger

import (
	"fmt"
	"io"
	"log"
	"os"
	"time"
)

var (
	infoLogger  *log.Logger
	errorLogger *log.Logger
	logFile     *os.File
)

// Init 初始化日志系统
func Init(filename string) error {
	var err error
	logFile, err = os.OpenFile(filename, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		return err
	}

	// 同时输出到控制台和文件
	multiWriter := io.MultiWriter(os.Stdout, logFile)

	infoLogger = log.New(multiWriter, "", 0)
	errorLogger = log.New(multiWriter, "", 0)

	return nil
}

// Close 关闭日志文件
func Close() {
	if logFile != nil {
		logFile.Close()
	}
}

// formatMessage 格式化日志消息
func formatMessage(level, message string) string {
	now := time.Now().Format("2006/1/2 15:04:05")
	return fmt.Sprintf("%s - demo - %s - %s", now, level, message)
}

// Info 记录信息日志
func Info(message string) {
	infoLogger.Println(formatMessage("INFO", message))
}

// Error 记录错误日志
func Error(message string) {
	errorLogger.Println(formatMessage("ERROR", message))
}
