# DroidSpaces 使用教程

本教程详细介绍如何在小米平板5（nabu）上使用 DroidSpaces 运行 Linux 容器。

---

## 📑 目录

1. [DroidSpaces 简介](#1-droidspaces-简介)
2. [安装方法](#2-安装方法)
3. [容器管理](#3-容器管理)
4. [网络配置](#4-网络配置)
5. [高级功能](#5-高级功能)
6. [常用发行版](#6-常用发行版)
7. [实用场景](#7-实用场景)
8. [故障排除](#8-故障排除)

---

## 1. DroidSpaces 简介

### 1.1 什么是 DroidSpaces

DroidSpaces 是一个运行在 Android 设备上的容器运行时，允许你在 Android 系统上创建和管理 Linux 容器。通过自定义内核的支持，它能够利用 Linux 内核的命名空间（Namespace）和控制组（Cgroup）功能，实现完整的容器隔离。

### 1.2 功能特性

| 特性 | 说明 |
|------|------|
| **命名空间隔离** | 完整支持 PID、NET、MNT、UTS、IPC、USER 命名空间 |
| **OverlayFS** | 支持分层文件系统，高效管理容器镜像 |
| **网络模式** | 支持 Host、NAT、None、Gateway 四种网络模式 |
| **GPU 加速** | 可选的 GPU 直通支持 |
| **音频透传** | 支持 ALSA/PulseAudio 音频透传 |
| **硬件访问** | 支持访问 USB 设备、串口等硬件 |
| **多种发行版** | 官方支持 Ubuntu、Debian、Arch Linux、Alpine 等 |

### 1.3 与其他工具对比

| 特性 | DroidSpaces | LXC/LXD | Docker | Chroot |
|------|-------------|---------|--------|--------|
| **运行平台** | Android (原生) | Linux | Linux | Linux/Android |
| **安装难度** | ⭐⭐ 简单 | ⭐⭐⭐ 中等 | ⭐⭐ 简单 | ⭐ 简单 |
| **隔离程度** | 高（命名空间+cgroup） | 高 | 高 | 低（仅文件系统） |
| **网络支持** | 完整 | 完整 | 完整 | 无 |
| **存储效率** | OverlayFS | ZFS/Btrfs | OverlayFS | N/A |
| **需要 Root** | 是 | 是 | 是 | 是（Android） |
| **内核依赖** | 自定义内核 | 标准内核 | 标准内核 | 无 |
| **Android 兼容性** | 原生支持 | 需额外配置 | 需额外配置 | 兼容 |

**DroidSpaces 的优势**：
- 专为 Android 设计，开箱即用
- 无需复杂的内核补丁
- 官方提供 App 管理界面
- 对小米平板5等设备有良好的社区支持

---

## 2. 安装方法

### 2.1 前置条件

在安装 DroidSpaces 之前，请确保：

1. **已刷入 DroidSpaces 内核**
   ```bash
   # 验证内核版本
   adb shell uname -r
   # 应显示类似: 5.10.xx-droidspaces-nabu
   ```

2. **已获取 Root 权限**
   ```bash
   # 推荐使用 KernelSU 或 Magisk
   adb shell su -c "id"
   # 应显示: uid=0(root)
   ```

3. **已安装 ADB 工具**
   ```bash
   adb version
   ```

### 2.2 Android App 安装

#### 方法一：从 GitHub 下载

```bash
# 1. 下载最新版 DroidSpaces APK
wget https://github.com/nickcano/droidspaces/releases/latest/download/DroidSpaces.apk

# 2. 通过 ADB 安装到设备
adb install DroidSpaces.apk

# 3. 启动应用
adb shell am start -n com.droidspaces.app/.MainActivity
```

#### 方法二：从 F-Droid 安装（如已收录）

```bash
# 使用 fdroid 命令行工具（需先安装）
fdroid install com.droidspaces.app
```

#### 方法三：通过应用商店

在 Google Play 或其他应用商店搜索 "DroidSpaces" 进行安装。

### 2.3 CLI 工具安装

对于高级用户，可以使用命令行工具进行管理：

```bash
# 1. 下载 CLI 工具
wget https://github.com/nickcano/droidspaces/releases/latest/download/droidspaces-cli

# 2. 推送到设备
adb push droidspaces-cli /data/local/tmp/

# 3. 设置权限并移动到系统路径
adb shell su -c "chmod 755 /data/local/tmp/droidspaces-cli"
adb shell su -c "cp /data/local/tmp/droidspaces-cli /system/bin/droidspaces"

# 4. 验证安装
adb shell su -c "droidspaces --version"
```

### 2.4 验证安装

```bash
# 检查 DroidSpaces 状态
adb shell su -c "droidspaces status"

# 检查内核支持
adb shell su -c "droidspaces check"

# 应输出所有必要功能的状态
```

---

## 3. 容器管理

### 3.1 创建容器

#### 使用 App 创建

1. 打开 DroidSpaces 应用
2. 点击 "新建容器" 按钮
3. 选择发行版和版本
4. 配置容器名称和其他选项
5. 点击 "创建"

#### 使用 CLI 创建

```bash
# 基本语法
adb shell su -c "droidspaces create <名称> --distro <发行版> --release <版本>"

# 创建 Ubuntu 容器
adb shell su -c "droidspaces create my-ubuntu --distro ubuntu --release 22.04"

# 创建 Debian 容器
adb shell su -c "droidspaces create my-debian --distro debian --release bookworm"

# 创建 Arch Linux 容器
adb shell su -c "droidspaces create my-arch --distro arch --release latest"

# 创建 Alpine 容器
adb shell su -c "droidspaces create my-alpine --distro alpine --release 3.18"

# 创建带 rootfs 的容器
adb shell su -c "droidspaces create my-container --distro ubuntu --release 22.04 --rootfs /data/droidspaces/rootfs"
```

#### 创建选项

```bash
# 查看所有创建选项
adb shell su -c "droidspaces create --help"

# 主要选项：
#   --distro        发行版 (ubuntu|debian|arch|alpine)
#   --release       版本号
#   --rootfs        自定义 rootfs 路径
#   --memory        内存限制 (例如: 1024m, 2g)
#   --cpu           CPU 核心数限制
#   --storage       存储空间限制
#   --network       网络模式 (host|nat|none|gateway)
```

### 3.2 启动容器

```bash
# 基本启动
adb shell su -c "droidspaces start <容器名>"

# 启动并附加终端
adb shell su -c "droidspaces start <容器名> --attach"

# 后台启动
adb shell su -c "droidspaces start <容器名> --daemon"

# 启动时执行命令
adb shell su -c "droidspaces start <容器名> --exec 'uname -a'"
```

**示例**：

```bash
# 启动 Ubuntu 容器
adb shell su -c "droidspaces start my-ubuntu"

# 启动并进入 shell
adb shell su -c "droidspaces start my-ubuntu --attach"
# 进入后你会看到:
# root@my-ubuntu:/#
```

### 3.3 停止容器

```bash
# 优雅停止（发送 SIGTERM）
adb shell su -c "droidspaces stop <容器名>"

# 强制停止（发送 SIGKILL）
adb shell su -c "droidspaces stop <容器名> --force"

# 停止所有容器
adb shell su -c "droidspaces stop --all"
```

### 3.4 删除容器

```bash
# 删除容器（需先停止）
adb shell su -c "droidspaces delete <容器名>"

# 强制删除（包括运行中的容器）
adb shell su -c "droidspaces delete <容器名> --force"

# 删除并清理存储
adb shell su -c "droidspaces delete <容器名> --purge"
```

### 3.5 容器状态管理

```bash
# 列出所有容器
adb shell su -c "droidspaces list"

# 输出示例：
# NAME          STATUS    DISTRO    RELEASE    IP
# my-ubuntu     running   ubuntu    22.04      192.168.122.2
# my-debian     stopped   debian    bookworm   -
# my-arch       stopped   arch      latest     -

# 查看容器详情
adb shell su -c "droidspaces inspect <容器名>"

# 查看容器日志
adb shell su -c "droidspaces logs <容器名>"
adb shell su -c "droidspaces logs <容器名> --tail 100"
```

### 3.6 容器配置

#### 配置文件位置

容器配置文件位于：
```
/data/droidspaces/containers/<容器名>/config.json
```

#### 常用配置项

```bash
# 进入容器配置目录
adb shell su -c "cd /data/droidspaces/containers/my-ubuntu"

# 查看配置文件
adb shell su -c "cat /data/droidspaces/containers/my-ubuntu/config.json"
```

#### 修改容器资源限制

```bash
# 修改内存限制
adb shell su -c "droidspaces update <容器名> --memory 2048m"

# 修改 CPU 限制
adb shell su -c "droidspaces update <容器名> --cpu 4"

# 修改存储限制
adb shell su -c "droidspaces update <容器名> --storage 10g"
```

#### 容器内操作

```bash
# 在容器内执行命令
adb shell su -c "droidspaces exec <容器名> -- <命令>"

# 示例：在容器内更新包列表
adb shell su -c "droidspaces exec my-ubuntu -- apt update"

# 进入容器 shell
adb shell su -c "droidspaces exec <容器名> -- /bin/bash"
```

---

## 4. 网络配置

DroidSpaces 提供四种网络模式，适用于不同的使用场景。

### 4.1 Host 模式

容器直接使用宿主机的网络栈，没有网络隔离。

```bash
# 创建使用 host 网络的容器
adb shell su -c "droidspaces create my-host-net --distro ubuntu --release 22.04 --network host"

# 或修改现有容器
adb shell su -c "droidspaces update my-host-net --network host"
```

**特点**：
- ✅ 最高性能（无 NAT 开销）
- ✅ 容器可以直接访问宿主机网络服务
- ❌ 无网络隔离
- ❌ 端口冲突风险

**适用场景**：
- 需要高性能网络的应用
- 容器内运行服务需要被外部访问
- 调试网络问题

### 4.2 NAT 模式（默认）

容器使用独立的网络命名空间，通过 NAT 与外部通信。

```bash
# 创建使用 NAT 网络的容器（默认）
adb shell su -c "droidspaces create my-nat-net --distro ubuntu --release 22.04 --network nat"

# 显式指定 NAT 模式
adb shell su -c "droidspaces update my-nat-net --network nat"
```

**特点**：
- ✅ 网络隔离
- ✅ 容器有独立 IP
- ✅ 可配置端口映射
- ❌ 有一定性能开销

**端口映射**：

```bash
# 映射容器端口到宿主机
adb shell su -c "droidspaces port-forward <容器名> <宿主机端口> <容器端口>"

# 示例：将容器的 80 端口映射到宿主机的 8080 端口
adb shell su -c "droidspaces port-forward my-nat-net 8080 80"

# 查看端口映射
adb shell su -c "droidspaces port-list <容器名>"

# 删除端口映射
adb shell su -c "droidspaces port-remove <容器名> <映射ID>"
```

**网络配置示例**：

```bash
# 容器内配置网络
adb shell su -c "droidspaces exec my-nat-net -- bash"

# 在容器内
ip addr show          # 查看网络接口
ip route show         # 查看路由表
cat /etc/resolv.conf  # 查看 DNS 配置

# 从外部访问容器
ping 192.168.122.2   # 容器 IP
```

### 4.3 None 模式

容器没有网络访问能力。

```bash
# 创建无网络的容器
adb shell su -c "droidspaces create my-no-net --distro ubuntu --release 22.04 --network none"
```

**特点**：
- ✅ 完全网络隔离（最高安全性）
- ❌ 无法访问网络
- ❌ 无法下载软件包

**适用场景**：
- 运行不需要网络的隔离任务
- 安全敏感的应用
- 离线环境模拟

**注意**：使用 None 模式时，容器内无法访问外网，需要提前在镜像中准备好所有软件包。

### 4.4 Gateway 模式

容器通过指定的网关访问网络。

```bash
# 创建使用 gateway 网络的容器
adb shell su -c "droidspaces create my-gw-net --distro ubuntu --release 22.04 --network gateway"

# 指定网关地址
adb shell su -c "droidspaces update my-gw-net --network gateway --gateway 10.0.0.1"
```

**特点**：
- ✅ 可控的网络访问
- ✅ 支持自定义路由
- ✅ 适合复杂网络拓扑
- ❌ 配置相对复杂

**适用场景**：
- 需要通过代理访问网络
- 多层网络架构
- 企业内网环境

### 4.5 网络诊断

```bash
# 查看容器网络配置
adb shell su -c "droidspaces network inspect <容器名>"

# 测试网络连通性
adb shell su -c "droidspaces exec <容器名> -- ping -c 3 8.8.8.8"

# 查看 DNS 解析
adb shell su -c "droidspaces exec <容器名> -- nslookup google.com"

# 查看容器 IP 地址
adb shell su -c "droidspaces exec <容器名> -- ip addr show eth0"

# 查看网络统计
adb shell su -c "droidspaces network stats <容器名>"
```

---

## 5. 高级功能

### 5.1 GPU 加速

DroidSpaces 支持可选的 GPU 直通，用于图形渲染和机器学习加速。

#### 前置条件

```bash
# 检查 GPU 支持
adb shell su -c "droidspaces gpu check"

# 查看可用的 GPU 设备
adb shell su -c "ls -la /dev/dri/"
adb shell su -c "ls -la /dev/kgsl-3d0"
```

#### 启用 GPU 加速

```bash
# 创建带 GPU 的容器
adb shell su -c "droidspaces create my-gpu --distro ubuntu --release 22.04 --gpu"

# 为现有容器启用 GPU
adb shell su -c "droidspaces update my-gpu --gpu"
```

#### 容器内使用 GPU

```bash
# 进入容器
adb shell su -c "droidspaces start my-gpu --attach"

# 安装 GPU 驱动（以 Mesa 为例）
apt update
apt install -y mesa-utils libgl1-mesa-dri

# 测试 OpenGL
glxinfo | grep "OpenGL renderer"
glxgears  # 应看到图形窗口
```

#### OpenCL 支持（机器学习）

```bash
# 安装 OpenCL 运行时
apt install -y ocl-icd-libopencl1 pocl-opencl-icd

# 测试 OpenCL
clinfo
```

### 5.2 音频支持

支持将 Android 音频系统透传到容器内。

#### 启用音频

```bash
# 创建带音频的容器
adb shell su -c "droidspaces create my-audio --distro ubuntu --release 22.04 --audio"

# 为现有容器启用音频
adb shell su -c "droidspaces update my-audio --audio"
```

#### 容器内配置音频

```bash
# 进入容器
adb shell su -c "droidspaces start my-audio --attach"

# 安装 ALSA 工具
apt update
apt install -y alsa-utils pulseaudio

# 测试音频
speaker-test -t wav -c 2  # 测试扬声器
arecord -l                  # 查看录音设备
```

#### PulseAudio 配置

```bash
# 如果需要完整的 PulseAudio 支持
apt install -y pulseaudio

# 配置 PulseAudio 连接到宿主机
mkdir -p ~/.config/pulse
echo "default-server = unix:/run/pulse/native" > ~/.config/pulse/client.conf

# 启动 PulseAudio
pulseaudio --start
```

### 5.3 硬件访问

#### USB 设备访问

```bash
# 启用 USB 设备透传
adb shell su -c "droidspaces create my-usb --distro ubuntu --release 22.04 --devices"

# 在容器内访问 USB 设备
adb shell su -c "droidspaces exec my-usb -- lsusb"

# 安装 USB 工具
apt install -y usbutils

# 监控 USB 设备
apt install -y usbmon
```

#### 串口访问

```bash
# 启用串口设备访问
adb shell su -c "droidspaces update my-container --devices"

# 在容器内访问串口
adb shell su -c "droidspaces exec my-container -- ls -la /dev/tty*"

# 安装串口工具
apt install -y minicom picocom
```

#### 其他硬件设备

```bash
# 查看可用的硬件设备
adb shell su -c "ls -la /dev/"

# 常见设备：
# /dev/sda    - 存储设备
# /dev/tty*   - 串口设备
# /dev/video* - 摄像头设备
# /dev/input/* - 输入设备
```

### 5.4 嵌套容器（Docker in DroidSpaces）

在 DroidSpaces 容器内运行 Docker，实现容器套容器。

#### 前置条件

```bash
# 确保内核支持嵌套容器
adb shell su -c "cat /proc/sys/kernel/unprivileged_userns_clone"
# 应显示: 1

# 检查 cgroup 支持
adb shell su -c "ls /sys/fs/cgroup/"
```

#### 配置 Docker 容器

```bash
# 创建用于 Docker 的容器
adb shell su -c "droidspaces create docker-host --distro ubuntu --release 22.04 --privileged --cgroupns host"

# 进入容器
adb shell su -c "droidspaces start docker-host --attach"
```

#### 在容器内安装 Docker

```bash
# 在容器内执行

# 更新系统
apt update
apt upgrade -y

# 安装依赖
apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 添加 Docker 官方 GPG key
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 添加 Docker 仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

#### 启动 Docker 服务

```bash
# 启动 Docker 守护进程
service docker start
# 或
dockerd &

# 验证 Docker 运行
docker run hello-world
```

#### 嵌套容器示例

```bash
# 运行一个简单的容器
docker run -it ubuntu:22.04 bash

# 运行一个 Web 服务
docker run -d -p 8080:80 nginx

# 使用 Docker Compose
cat > docker-compose.yml << EOF
version: '3'
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
  db:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: example
EOF

docker-compose up -d
```

**注意**：嵌套容器需要较多资源，建议分配至少 2GB 内存和 2 个 CPU 核心。

---

## 6. 常用发行版

### 6.1 Ubuntu

Ubuntu 是最常用的发行版，软件包丰富，社区支持完善。

```bash
# 创建 Ubuntu 容器
adb shell su -c "droidspaces create my-ubuntu --distro ubuntu --release 22.04"

# 启动并进入
adb shell su -c "droidspaces start my-ubuntu --attach"

# 容器内操作
apt update && apt upgrade -y
apt install -y vim git curl wget htop
```

**推荐版本**：
- `22.04 LTS` - 长期支持版，稳定可靠
- `20.04 LTS` - 旧版 LTS，兼容性好
- `24.04 LTS` - 最新 LTS

### 6.2 Debian

Debian 以稳定著称，适合服务器场景。

```bash
# 创建 Debian 容器
adb shell su -c "droidspaces create my-debian --distro debian --release bookworm"

# 启动并进入
adb shell su -c "droidspaces start my-debian --attach"

# 容器内操作
apt update && apt upgrade -y
apt install -y build-essential python3 python3-pip
```

**推荐版本**：
- `bookworm` (12) - 当前稳定版
- `bullseye` (11) - 旧稳定版
- `trixie` (13) - 测试版

### 6.3 Arch Linux

Arch Linux 提供最新的软件包，适合喜欢折腾的用户。

```bash
# 创建 Arch Linux 容器
adb shell su -c "droidspaces create my-arch --distro arch --release latest"

# 启动并进入
adb shell su -c "droidspaces start my-arch --attach"

# 容器内操作
pacman -Syu
pacman -S base-devel git vim
```

**特点**：
- 滚动更新，软件包最新
- 使用 pacman 包管理器
- 文档完善（Arch Wiki）
- 需要手动配置较多

### 6.4 Alpine

Alpine Linux 非常轻量，适合资源受限的环境。

```bash
# 创建 Alpine 容器
adb shell su -c "droidspaces create my-alpine --distro alpine --release 3.18"

# 启动并进入
adb shell su -c "droidspaces start my-alpine --attach"

# 容器内操作
apk update
apk add bash curl git
```

**特点**：
- 镜像体积小（~5MB 基础镜像）
- 使用 musl libc
- 安全性好（默认启用 PIE）
- 适合容器化部署

### 6.5 发行版对比

| 特性 | Ubuntu | Debian | Arch | Alpine |
|------|--------|--------|------|--------|
| 包管理器 | apt | apt | pacman | apk |
| 包数量 | 丰富 | 丰富 | 极多 | 较少 |
| 更新频率 | 定期 | 定期 | 滚动 | 定期 |
| 基础镜像大小 | ~70MB | ~50MB | ~100MB | ~5MB |
| 学习曲线 | 低 | 低 | 中 | 中 |
| 适合场景 | 通用 | 服务器 | 开发 | 轻量部署 |

---

## 7. 实用场景

### 7.1 运行 Docker

在 DroidSpaces 中运行完整的 Docker 环境。

```bash
# 1. 创建 Docker 专用容器
adb shell su -c "droidspaces create docker-env --distro ubuntu --release 22.04 --privileged --memory 4g --cpu 4"

# 2. 启动容器
adb shell su -c "droidspaces start docker-env --attach"

# 3. 在容器内安装 Docker
# （参见 5.4 节）

# 4. 使用 Docker 部署服务
docker run -d --name web -p 8080:80 nginx:alpine
docker run -d --name db -e POSTGRES_PASSWORD=secret postgres:14
```

### 7.2 运行桌面环境

在容器中运行完整的 Linux 桌面环境。

```bash
# 1. 创建桌面环境容器
adb shell su -c "droidspaces create desktop --distro ubuntu --release 22.04 --gpu --memory 4g"

# 2. 启动容器
adb shell su -c "droidspaces start desktop --attach"

# 3. 安装桌面环境
apt update
apt install -y ubuntu-desktop gnome-core

# 4. 安装 VNC 服务器
apt install -y tightvncserver

# 5. 启动 VNC
vncserver :1 -geometry 1920x1080 -depth 24

# 6. 使用 VNC 客户端连接
# 连接地址: localhost:5901
```

#### 使用 X11 转发

```bash
# 在 Android 端安装 X11 服务器应用（如 XServer XSDL）

# 启动容器时启用 X11 转发
adb shell su -c "droidspaces start desktop --x11"

# 在容器内运行图形应用
DISPLAY=:0 xclock
DISPLAY=:0 firefox
```

### 7.3 开发服务器

使用容器搭建各种开发环境。

#### Web 开发环境

```bash
# 创建开发容器
adb shell su -c "droidspaces create webdev --distro ubuntu --release 22.04 --network nat"

# 启动容器
adb shell su -c "droidspaces start webdev --attach"

# 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# 安装其他工具
apt install -y git postgresql redis-server

# 创建项目
mkdir -p /root/my-project
cd /root/my-project
npm init -y
npm install express
```

#### Python 开发环境

```bash
# 创建 Python 开发容器
adb shell su -c "droidspaces create python-dev --distro ubuntu --release 22.04"

# 启动容器
adb shell su -c "droidspaces start python-dev --attach"

# 安装 Python 和工具
apt update
apt install -y python3 python3-pip python3-venv

# 创建虚拟环境
python3 -m venv /root/myenv
source /root/myenv/bin/activate

# 安装常用包
pip install flask django requests
```

#### Go 开发环境

```bash
# 创建 Go 开发容器
adb shell su -c "droidspaces create go-dev --distro ubuntu --release 22.04"

# 启动容器
adb shell su -c "droidspaces start go-dev --attach"

# 安装 Go
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz

# 配置环境变量
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# 验证安装
go version
```

### 7.4 网络工具

使用容器进行网络测试和安全研究。

#### 网络监控

```bash
# 创建网络工具容器
adb shell su -c "droidspaces create nettools --distro ubuntu --release 22.04 --network host --privileged"

# 启动容器
adb shell su -c "droidspaces start nettools --attach"

# 安装网络工具
apt update
apt install -y \
    nmap \
    tcpdump \
    wireshark-common \
    net-tools \
    iputils-ping \
    dnsutils \
    traceroute \
    curl \
    wget

# 使用示例
nmap -sn 192.168.1.0/24        # 扫描局域网
tcpdump -i eth0 port 80        # 抓取 HTTP 流量
dig google.com                  # DNS 查询
```

#### 安全测试工具

```bash
# 安装安全工具
apt install -y \
    metasploit-framework \
    nikto \
    dirb \
    sqlmap

# 使用 Nmap 进行端口扫描
nmap -sV -sC target_ip

# 使用 Nikto 扫描 Web 漏洞
nikto -h http://target_ip
```

### 7.5 其他场景

#### 数据库服务器

```bash
# 创建数据库容器
adb shell su -c "droidspaces create dbserver --distro ubuntu --release 22.04 --network nat --memory 2g"

# 安装 MySQL
apt update
apt install -y mysql-server

# 安装 PostgreSQL
apt install -y postgresql

# 安装 Redis
apt install -y redis-server
```

#### 文件服务器

```bash
# 创建文件服务器容器
adb shell su -c "droidspaces create fileserver --distro ubuntu --release 22.04 --network nat"

# 安装 Samba
apt update
apt install -y samba

# 配置共享目录
mkdir -p /srv/samba/shared
```

#### 编译环境

```bash
# 创建编译容器
adb shell su -c "droidspaces create buildenv --distro ubuntu --release 22.04 --memory 4g --cpu 4"

# 安装编译工具
apt update
apt install -y \
    build-essential \
    cmake \
    g++ \
    gcc \
    make \
    pkg-config
```

---

## 8. 故障排除

### 8.1 常见问题

#### 问题：容器无法启动

```bash
# 检查内核支持
adb shell su -c "droidspaces check"

# 检查容器日志
adb shell su -c "droidspaces logs <容器名>"

# 检查系统日志
adb shell su -c "logcat | grep droidspaces"
```

#### 问题：网络不通

```bash
# 检查网络配置
adb shell su -c "droidspaces network inspect <容器名>"

# 重启网络服务
adb shell su -c "droidspaces exec <容器名> -- systemctl restart networking"

# 检查 DNS
adb shell su -c "droidspaces exec <容器名> -- cat /etc/resolv.conf"
```

#### 问题：存储空间不足

```bash
# 检查存储使用情况
adb shell su -c "df -h"

# 清理容器存储
adb shell su -c "droidspaces system prune"

# 清理 Docker（如果使用）
adb shell su -c "droidspaces exec <容器名> -- docker system prune -a"
```

### 8.2 日志查看

```bash
# DroidSpaces 日志
adb shell su -c "cat /data/droidspaces/logs/droidspaces.log"

# 容器日志
adb shell su -c "cat /data/droidspaces/containers/<容器名>/log"

# 系统日志
adb logcat -s DroidSpaces:V
```

### 8.3 重置和恢复

```bash
# 重置容器
adb shell su -c "droidspaces delete <容器名> --purge"
adb shell su -c "droidspaces create <容器名> --distro <发行版> --release <版本>"

# 完全重置 DroidSpaces
adb shell su -c "droidspaces system reset"

# 恢复出厂设置（谨慎使用）
adb shell su -c "droidspaces system factory-reset"
```

---

## 📚 更多资源

- [DroidSpaces 官方文档](https://github.com/nickcano/droidspaces)
- [DroidSpaces Telegram 频道](https://t.me/Droidspaces)
- [DroidSpaces 内核配置指南](https://github.com/ravindu644/Droidspaces-OSS/blob/main/Documentation/Kernel-Configuration.md)
- [AnyKernel3 刷入工具](https://github.com/osm0sis/AnyKernel3)

---

## 📝 贡献

如果你发现问题或有改进建议，请在 [Issues](https://github.com/Re-s/xiaomi-nabu-droidspace-kernel/issues) 页面提交。

---

**版本**: 1.0  
**更新日期**: 2025年1月  
**许可证**: GPL-2.0
