#!/bin/bash

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub 仓库信息
REPO_OWNER="jueane"
REPO_NAME="WireguardKeepalive"
GITHUB_API="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"

# 默认安装目录
INSTALL_DIR="/opt/wireguard-watchdog"

# 检测系统架构
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo -e "${RED}Error: Unsupported architecture: $arch${NC}" >&2
            exit 1
            ;;
    esac
}

# 检查必要的命令
check_dependencies() {
    local missing_deps=()

    for cmd in curl tar sha256sum; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required commands: ${missing_deps[*]}${NC}" >&2
        echo "Please install them first." >&2
        exit 1
    fi
}

# 获取最新 release 信息
get_latest_release() {
    echo -e "${YELLOW}Fetching latest release information...${NC}"

    local response=$(curl -s "$GITHUB_API")

    if [ -z "$response" ]; then
        echo -e "${RED}Error: Failed to fetch release information${NC}" >&2
        exit 1
    fi

    # 提取版本号
    local version=$(echo "$response" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*: *"\(.*\)".*/\1/')

    if [ -z "$version" ]; then
        echo -e "${RED}Error: Could not parse version from API response${NC}" >&2
        exit 1
    fi

    echo "$version"
}

# 下载文件
download_file() {
    local url=$1
    local output=$2

    echo -e "${YELLOW}Downloading: $url${NC}"

    if ! curl -L -f -o "$output" "$url"; then
        echo -e "${RED}Error: Failed to download $url${NC}" >&2
        return 1
    fi

    echo -e "${GREEN}Downloaded: $output${NC}"
    return 0
}

# 验证 SHA256
verify_checksum() {
    local file=$1
    local checksum_file=$2

    echo -e "${YELLOW}Verifying checksum...${NC}"

    if ! sha256sum -c "$checksum_file" &> /dev/null; then
        echo -e "${RED}Error: Checksum verification failed!${NC}" >&2
        return 1
    fi

    echo -e "${GREEN}Checksum verified successfully${NC}"
    return 0
}

# 主函数
main() {
    echo -e "${GREEN}=== WireGuard Watchdog Downloader ===${NC}"
    echo ""

    # 检查依赖
    check_dependencies

    # 检测架构
    local arch=$(detect_arch)
    echo -e "${GREEN}Detected architecture: $arch${NC}"

    # 获取最新版本
    local version=$(get_latest_release)
    echo -e "${GREEN}Latest version: $version${NC}"

    # 构建文件名
    local filename="wireguard-watchdog-linux-${arch}-${version}.tar.gz"
    local checksum_filename="${filename}.sha256"
    local download_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${version}/${filename}"
    local checksum_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${version}/${checksum_filename}"

    # 创建临时目录
    local temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    cd "$temp_dir"

    # 下载文件
    if ! download_file "$download_url" "$filename"; then
        exit 1
    fi

    if ! download_file "$checksum_url" "$checksum_filename"; then
        exit 1
    fi

    # 验证校验和
    if ! verify_checksum "$filename" "$checksum_filename"; then
        exit 1
    fi

    # 解压文件
    echo -e "${YELLOW}Extracting files...${NC}"
    tar -xzf "$filename"

    # 检查必要文件是否存在
    if [ ! -f "installService.sh" ] || [ ! -f "wireguard-watchdog" ]; then
        echo -e "${RED}Error: Required files not found in archive${NC}" >&2
        exit 1
    fi

    # 创建安装目录
    echo -e "${YELLOW}Creating installation directory: $INSTALL_DIR${NC}"
    sudo mkdir -p "$INSTALL_DIR"

    # 复制文件到安装目录
    echo -e "${YELLOW}Copying files to $INSTALL_DIR${NC}"
    sudo cp -r * "$INSTALL_DIR/"

    # 设置执行权限
    sudo chmod +x "$INSTALL_DIR"/*.sh "$INSTALL_DIR/wireguard-watchdog"

    echo ""
    echo -e "${GREEN}=== Download and Extract Complete ===${NC}"
    echo -e "${GREEN}Version: $version${NC}"
    echo -e "${GREEN}Architecture: $arch${NC}"
    echo -e "${GREEN}Installation directory: $INSTALL_DIR${NC}"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Next Steps:${NC}"
    echo ""
    echo -e "${YELLOW}1. Install and start the service:${NC}"
    echo -e "   ${GREEN}cd $INSTALL_DIR && sudo ./installService.sh${NC}"
    echo ""
    echo -e "${YELLOW}2. Or manually control the service:${NC}"
    echo -e "   ${GREEN}sudo systemctl start wireguard-watchdog${NC}    # Start service"
    echo -e "   ${GREEN}sudo systemctl stop wireguard-watchdog${NC}     # Stop service"
    echo -e "   ${GREEN}sudo systemctl status wireguard-watchdog${NC}   # Check status"
    echo -e "   ${GREEN}sudo systemctl enable wireguard-watchdog${NC}   # Enable auto-start"
    echo ""
    echo -e "${YELLOW}3. View logs:${NC}"
    echo -e "   ${GREEN}sudo journalctl -u wireguard-watchdog -f${NC}"
    echo ""
    echo -e "${YELLOW}4. Uninstall service:${NC}"
    echo -e "   ${GREEN}cd $INSTALL_DIR && sudo ./uninstallService.sh${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 运行主函数
main "$@"
