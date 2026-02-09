# GitHub Actions 自动构建实现方案

## 背景

WireguardWatchGo 是一个 Go 语言编写的 WireGuard 监控工具，用于自动重启失去连接的 WireGuard 服务。本文档描述了项目的 CI/CD 自动化构建方案。

### 当前状态
- Go 1.21 项目，依赖极少（仅 gopkg.in/ini.v1）
- 支持 Windows 和 Linux 跨平台
- 手动构建命令：`go build -o wireguard-watchdog[.exe]`

### 目标
- 自动化代码质量检查（格式化、静态分析）
- 自动化多平台构建验证
- 自动化发布流程（打 tag 时自动构建并发布二进制文件）

## 实现方案

### 方案概述

创建两个独立的 GitHub Actions 工作流：

1. **CI 工作流** (`ci.yml`) - 持续集成，每次推送/PR 时运行
2. **Release 工作流** (`release.yml`) - 发布构建，仅在推送 tag 时运行

这种分离设计的优势：
- PR 反馈更快（不执行不必要的发布构建）
- 职责清晰分离
- 更好的资源利用

### 文件结构

```
.github/
└── workflows/
    ├── ci.yml          # 持续集成工作流
    └── release.yml     # 发布工作流
```

## CI 工作流 (`.github/workflows/ci.yml`)

### 触发条件
- 推送到 `main` 分支
- 针对 `main` 分支的 Pull Request
- 手动触发（workflow_dispatch）

### 包含的任务

#### 任务 1：代码质量检查 (quality)
- **运行环境**：`ubuntu-latest`
- **Go 版本**：1.21
- **检查项**：
  - `go mod verify` - 依赖验证
  - `gofmt -l .` - 代码格式检查
  - `go vet ./...` - 静态分析

#### 任务 2：多平台构建验证 (build)
- **构建矩阵**：
  - 操作系统：`ubuntu-latest`, `windows-latest`
  - Go 版本：1.21
- **输出**：构建成功的二进制文件（作为 artifacts 保存 1 天）

### 优化特性
- **Go 模块缓存**：使用 `actions/setup-go@v5` 的内置缓存，加速 30-60%
- **并发控制**：新推送自动取消旧的运行，节省资源
- **快速失败**：质量检查失败则不执行构建（needs: quality）

## Release 工作流 (`.github/workflows/release.yml`)

### 触发条件
- 推送匹配 `v*` 模式的 tag（如 v1.0.0, v1.2.3）
- 手动触发（可指定版本）

### 包含的任务

#### 任务 1：创建 GitHub Release (release)
- 从 tag 提取版本号
- 自动生成 Release Notes
- 使用 `softprops/action-gh-release@v1`

#### 任务 2：构建并上传多平台二进制文件 (build)
- **构建矩阵**：
  ```
  - Linux amd64: wireguard-watchdog-linux-amd64
  - Linux arm64: wireguard-watchdog-linux-arm64
  - Windows amd64: wireguard-watchdog-windows-amd64.exe
  ```
- **构建配置**：
  - `CGO_ENABLED=0` - 静态编译，无外部依赖
  - `-ldflags="-s -w"` - 去除调试信息，减小体积
  - `-trimpath` - 移除文件系统路径，可重现构建
- **校验和**：为每个二进制生成 SHA256 校验和
- **自动上传**：所有文件自动上传到 GitHub Release

### 支持的架构
- **Linux**: amd64（主流服务器）, arm64（树莓派、ARM 服务器）
- **Windows**: amd64（主流桌面）

## 使用说明

### 日常开发

推送代码到 main 分支或创建 PR 时，CI 工作流会自动运行：

```bash
# 推送代码
git add .
git commit -m "feat: 添加新功能"
git push origin main

# 或创建 Pull Request
git checkout -b feature/new-feature
git push origin feature/new-feature
# 然后在 GitHub 上创建 PR
```

CI 会自动执行：
1. 代码质量检查
2. Windows 和 Linux 构建验证

### 发布新版本

创建并推送 tag 时，Release 工作流会自动运行：

```bash
# 1. 确保代码已提交到 main 分支
git checkout main
git pull

# 2. 创建并推送 tag
git tag v1.0.0
git push origin v1.0.0

# 3. GitHub Actions 自动执行：
#    - 创建 GitHub Release
#    - 构建所有平台的二进制文件
#    - 生成 SHA256 校验和
#    - 上传所有文件到 Release

# 4. 在 GitHub Releases 页面查看和下载二进制文件
```

### 手动触发

两个工作流都支持手动触发：

1. 访问 GitHub 仓库的 Actions 页面
2. 选择要运行的工作流（CI 或 Release）
3. 点击 "Run workflow" 按钮
4. 对于 Release 工作流，可以指定版本号

## 验证方案

### CI 工作流验证

1. 创建一个测试分支：
   ```bash
   git checkout -b test/ci-workflow
   ```

2. 修改代码（如更新 README）并推送：
   ```bash
   git add .
   git commit -m "test: 测试 CI 工作流"
   git push origin test/ci-workflow
   ```

3. 在 GitHub 上创建 PR 到 main 分支

4. 检查 GitHub Actions 页面，确认：
   - ✅ 代码质量检查通过
   - ✅ Windows 和 Linux 构建成功
   - ✅ Artifacts 已生成

5. 下载 artifacts 验证二进制文件可执行

### Release 工作流验证

1. 创建测试 tag：
   ```bash
   git tag v0.0.1-test
   git push origin v0.0.1-test
   ```

2. 检查 GitHub Actions 页面，确认 release 工作流运行

3. 验证 GitHub Releases 页面：
   - ✅ 创建了新 release
   - ✅ 包含 3 个二进制文件（Linux amd64/arm64, Windows amd64）
   - ✅ 包含 3 个 SHA256 校验和文件
   - ✅ 自动生成了 Release Notes

4. 下载并测试各平台二进制文件：
   ```bash
   # Linux
   wget https://github.com/用户名/WireguardWatchGo/releases/download/v0.0.1-test/wireguard-watchdog-linux-amd64
   chmod +x wireguard-watchdog-linux-amd64
   ./wireguard-watchdog-linux-amd64 --help

   # 验证校验和
   sha256sum -c wireguard-watchdog-linux-amd64.sha256
   ```

### 端到端测试

完整的开发-发布流程测试：

1. 修改代码（如更新 README）
2. 提交并推送到 main 分支 → 触发 CI
3. 等待 CI 通过
4. 创建新 tag（如 v1.0.0）并推送 → 触发 Release
5. 从 GitHub Releases 下载二进制文件
6. 在目标平台运行并验证功能正常

## 最佳实践

### 1. 模块缓存
使用 `actions/setup-go@v5` 的内置缓存功能（`cache: true`），显著加速构建：
- 首��构建：~2-3 分钟
- 缓存命中后：~30-60 秒

### 2. 静态编译
`CGO_ENABLED=0` 确保二进制无外部依赖，可在任何系统运行：
- 无需安装 glibc 或其他系统库
- 适合在 Docker 容器中运行
- 适合在最小化 Linux 发行版上运行

### 3. 安全性
- 最小权限原则：仅授予必要的 `contents: write` 权限
- 使用官方 Actions（`actions/*`, `softprops/action-gh-release`）
- 固定 Actions 版本（`@v4`, `@v5`）

### 4. 并发控制
自动取消旧的运行，节省资源：
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### 5. 命名规范
清晰的二进制文件命名：`{项目名}-{系统}-{架构}`
- `wireguard-watchdog-linux-amd64`
- `wireguard-watchdog-linux-arm64`
- `wireguard-watchdog-windows-amd64.exe`

## 故障排查

### CI 失败常见原因

#### 1. 代码格式问题
```
Error: The following files are not formatted:
main.go
```

**解决方案**：
```bash
go fmt ./...
git add .
git commit -m "fix: 格式化代码"
git push
```

#### 2. 静态分析错误
```
Error: go vet ./... failed
```

**解决方案**：
```bash
go vet ./...  # 查看具体错误
# 修复代码问题
git add .
git commit -m "fix: 修复静态分析错误"
git push
```

#### 3. 依赖验证失败
```
Error: go mod verify failed
```

**解决方案**：
```bash
go mod tidy
go mod verify
git add go.mod go.sum
git commit -m "fix: 更新依赖"
git push
```

### Release 失败常见原因

#### 1. 权限不足
```
Error: Resource not accessible by integration
```

**解决方案**：
- 检查仓库设置 → Actions → General → Workflow permissions
- 确保选择 "Read and write permissions"

#### 2. Tag 已存在
```
Error: Release already exists
```

**解决方案**：
```bash
# 删除本地和远程 tag
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0

# 重新创建 tag
git tag v1.0.0
git push origin v1.0.0
```

#### 3. 构建失败
```
Error: build failed for linux/arm64
```

**解决方案**：
- 检查代码是否使用了平台特定的功能
- 确保所有依赖支持目标平台
- 在本地测试交叉编译：
  ```bash
  GOOS=linux GOARCH=arm64 go build
  ```

## 未来增强

### 测试集成
当项目添加测试后，可在 CI 工作流中添加：

```yaml
- name: Run tests
  run: go test -v -race -coverprofile=coverage.out ./...

- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage.out
```

### 额外平台支持
可选的额外平台：
- macOS (darwin/amd64, darwin/arm64)
- Linux ARM (linux/arm)
- FreeBSD (freebsd/amd64)

添加方法：在 `release.yml` 的 matrix 中添加：
```yaml
- os: macos-latest
  goos: darwin
  goarch: amd64
  output: wireguard-watchdog-darwin-amd64
```

### Docker 镜像构建
可以添加 Docker 镜像构建和推送到 Docker Hub：

```yaml
- name: Build Docker image
  run: docker build -t username/wireguard-watchdog:${{ needs.release.outputs.version }} .

- name: Push to Docker Hub
  run: docker push username/wireguard-watchdog:${{ needs.release.outputs.version }}
```

### 性能基准测试
添加性能回归检测：
- name: Run benchmarks
  run: go test -bench=. -benchmem ./...
```

## 参考资料

- [GitHub Actions 官方文档](https://docs.github.com/en/actions)
- [Go 官方文档 - 交叉编译](https://go.dev/doc/install/source#environment)
- [softprops/action-gh-release](https://github.com/softprops/action-gh-release)
- [actions/setup-go](https://github.com/actions/setup-go)

## 维护记录

- 2026-02-09: 初始实现，创建 CI 和 Release 工作流
