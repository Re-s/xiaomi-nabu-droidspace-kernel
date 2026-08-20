# Xiaomi Nabu DroidSpaces Kernel

为小米平板5（代号：nabu）编译的 DroidSpaces 内核，支持在 Android 设备上运行 Linux 容器。

## ⚠️ 重要警告

**澎湃OS（HyperOS 1.0）原厂内核不支持容器运行！**

经详细调研发现，澎湃OS内核**明确禁用**了以下关键配置：
- `CONFIG_PID_NS` — PID命名空间被禁用
- `CONFIG_USER_NS` — 用户命名空间被禁用  
- `CONFIG_VETH` — 虚拟以太网被禁用
- `CONFIG_MEMCG` — 内存cgroup被禁用
- `CONFIG_CGROUP_DEVICE` — 设备cgroup被禁用

**解决方案**：本项目提供完整的内核配置和构建方案，需刷入自定义内核才能使用DroidSpaces。

[![Build Kernel](https://github.com/your-username/xiaomi-nabu-droidspace-kernel/actions/workflows/build-kernel.yml/badge.svg)](https://github.com/your-username/xiaomi-nabu-droidspace-kernel/actions/workflows/build-kernel.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](./LICENSE)
[![DroidSpaces Compatible](https://img.shields.io/badge/DroidSpaces-Compatible-green.svg)](https://github.com/ravindu644/Droidspaces-OSS)

## 📱 项目特性

- ✅ **完整的容器支持**：启用命名空间（namespace）、cgroup、overlayfs 等容器核心功能
- ✅ **DroidSpaces 兼容**：完全匹配 [DroidSpaces-OSS](https://github.com/ravindu644/Droidspaces-OSS) 官方内核要求
- ✅ **自动化构建**：使用 GitHub Actions 实现自动编译和发布（支持环境缓存复用）
- ✅ **AnyKernel3 集成**：使用 AnyKernel3 工具进行安全刷入
- ✅ **GKI kABI 支持**：包含 kABI 修复补丁，避免启动循环
- ✅ **模块化设计**：支持按需加载内核模块

## 🔧 设备兼容性

| 设备 | 代号 | 处理器 | 内核版本 | 状态 |
|------|------|--------|----------|------|
| 小米平板5 | nabu | 骁龙860 (SM8150) | 5.4.x / 6.1.x | ✅ 完全支持 |

**注意**：此内核仅适用于小米平板5（nabu），请勿在其他设备上使用。

## 📋 DroidSpaces 内核要求

根据 [DroidSpaces-OSS 官方文档](https://github.com/ravindu644/Droidspaces-OSS#android-kernel-requirements)，本内核已启用以下关键配置：

| 类别 | 配置项 | 状态 |
|------|--------|------|
| **命名空间** | NAMESPACES, PID_NS, UTS_NS, IPC_NS, USER_NS, NET_NS | ✅ |
| **Cgroup** | CGROUPS, CGROUP_DEVICE, CGROUP_PIDS, MEMCG, CGROUP_SCHED | ✅ |
| **文件系统** | OVERLAY_FS, DEVTMPFS | ✅ |
| **网络** | VETH, BRIDGE, NETFILTER, NF_NAT | ✅ |
| **安全** | SECCOMP, SECCOMP_FILTER | ✅ |
| **GKI兼容** | SYSVIPC, POSIX_MQUEUE | ✅ |

## 🚀 快速开始

### 1. 下载内核

从 [Releases](https://github.com/your-username/xiaomi-nabu-droidspace-kernel/releases) 页面下载最新的内核压缩包。

### 2. 刷入内核

```bash
# 将内核文件传输到设备
adb push DroidSpacesKernel-nabu-*.zip /sdcard/

# 重启到 recovery 模式
adb reboot recovery

# 在 recovery 中刷入内核 zip 文件
# 或使用 TWRP 的安装功能
```

### 3. 验证安装

```bash
# 重启后检查内核版本
adb shell uname -r

# 检查容器支持
adb shell ls /proc/sys/kernel/namespaces
```

## 📖 文档

详细文档请查看 `docs/` 目录：

### 核心文档
| 文档 | 说明 |
|------|------|
| [快速开始](docs/QUICKSTART.md) | 5分钟快速上手指南 |
| [安装指南](docs/INSTALLATION.md) | 详细的刷机步骤 |
| [构建指南](docs/BUILDING.md) | 如何从源码编译内核 |
| [故障排除](docs/TROUBLESHOOTING.md) | 常见问题和解决方案 |

### DroidSpaces 相关
| 文档 | 说明 |
|------|------|
| [DroidSpaces 使用教程](docs/USAGE.md) | 完整的容器使用指南 |
| [DroidSpaces 内核要求](docs/DROIDSPACES_REQUIREMENTS.md) | 官方内核配置要求 |
| [兼容性分析](docs/COMPATIBILITY.md) | 澎湃OS内核兼容性报告 |

### 开发文档
| 文档 | 说明 |
|------|------|
| [贡献指南](docs/CONTRIBUTING.md) | 如何参与项目开发 |
| [项目结构](PROJECT_STRUCTURE.md) | 项目文件结构说明 |
| [项目总结](SUMMARY.md) | 开发进度总结 |

## 🏗️ 构建说明

### 使用 GitHub Actions（推荐）

1. Fork 本仓库
2. 在 Actions 标签页启用 workflows
3. 代码推送后会自动构建

### 本地构建

```bash
# 克隆仓库
git clone --recursive https://github.com/your-username/xiaomi-nabu-droidspace-kernel.git
cd xiaomi-nabu-droidspace-kernel

# 安装依赖
sudo apt-get install git-core build-essential gcc-aarch64-linux-gnu bc bison flex libssl-dev make libncurses-dev

# 下载预编译的交叉编译工具链
wget https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/heads/android12-release.tar.gz
mkdir -p toolchain
tar -xf android12-release.tar.gz -C toolchain

# 设置环境变量
export CROSS_COMPILE=$(pwd)/toolchain/bin/aarch64-linux-android-
export ARCH=arm64

# 构建内核
./build.sh
```

更多构建选项请查看 [构建指南](docs/BUILDING.md)。

## 🛠️ 工具脚本

本项目包含以下自动化工具：

| 脚本 | 说明 | 使用方法 |
|------|------|---------|
| `build.sh` | 主构建脚本 | `./build.sh` |
| `verify_kernel.sh` | 内核配置验证 | `./verify_kernel.sh` |
| `apply_gki_patches.sh` | GKI kABI补丁应用 | `./apply_gki_patches.sh` |
| `Makefile` | 简化构建命令 | `make help` |

### 常用命令

```bash
# 查看所有可用命令
make help

# 完整构建
make build

# 创建刷机包
make package

# 验证内核配置
./verify_kernel.sh

# 应用GKI补丁（GKI内核必需）
./apply_gki_patches.sh
```

## ⚠️ 注意事项

1. **备份重要数据**：刷机前务必备份设备上的重要数据
2. **解锁 Bootloader**：需要先解锁设备的 Bootloader
3. **安装 Recovery**：建议安装 TWRP Recovery
4. **风险自负**：修改内核有风险，请确保了解相关操作

## 🐛 问题反馈

如果遇到问题，请通过以下方式反馈：

1. 查看 [故障排除](docs/TROUBLESHOOTING.md) 文档
2. 在 [Issues](https://github.com/your-username/xiaomi-nabu-droidspace-kernel/issues) 页面提交问题
3. 提供详细的错误信息和设备日志

## 📜 许可证

本项目基于 GPL-2.0 许可证开源。

## 🙏 致谢

- [AnyKernel3](https://github.com/osm0sis/AnyKernel3) - 内核刷入工具
- [DroidSpaces](https://github.com/nickcano/droidspaces) - Android 容器运行时
- [LineageOS](https://lineageos.org/) - Android 开源项目

---

**免责声明**：使用本内核可能使您的设备保修失效。请谨慎操作，作者不对任何设备损坏负责。