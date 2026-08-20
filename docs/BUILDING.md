# 构建指南

本文档介绍如何从源码编译小米平板5（nabu）的 DroidSpaces 内核。

## 🏗️ 构建环境要求

### 系统要求

- **操作系统**：Ubuntu 20.04+ / Debian 11+ / 其他 Linux 发行版
- **内存**：至少 8GB RAM（推荐 16GB）
- **磁盘空间**：至少 50GB 可用空间
- **处理器**：多核处理器（推荐 4 核以上）

### 依赖软件包

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    git-core \
    build-essential \
    gcc-aarch64-linux-gnu \
    bc \
    bison \
    flex \
    libssl-dev \
    make \
    libncurses-dev \
    zip \
    unzip \
    python3 \
    python3-pip

# Fedora/RHEL
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y \
    gcc-aarch64-linux-gnu \
    bc \
    bison \
    flex \
    openssl-devel \
    ncurses-devel \
    zip \
    unzip \
    python3
```

## 📥 获取源码

### 1. 克隆仓库

```bash
# 克隆主仓库
git clone --recursive https://github.com/Re-s/xiaomi-nabu-droidspace-kernel.git
cd xiaomi-nabu-droidspace-kernel

# 或者克隆特定分支
git clone -b droidspaces https://github.com/Re-s/xiaomi-nabu-droidspace-kernel.git
```

### 2. 初始化子模块

```bash
# 如果使用 --recursive 克隆，子模块会自动初始化
# 否则需要手动初始化
git submodule update --init --recursive
```

## 🔧 交叉编译工具链

### 方法一：使用 Google 预编译工具链（推荐）

```bash
# 下载 Android 预编译 GCC 工具链
wget https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/heads/android12-release.tar.gz

# 创建工具链目录
mkdir -p toolchain

# 解压工具链
tar -xf android12-release.tar.gz -C toolchain

# 设置权限
chmod +x toolchain/bin/*

# 设置环境变量
export CROSS_COMPILE=$(pwd)/toolchain/bin/aarch64-linux-android-
export ARCH=arm64

# 验证工具链
${CROSS_COMPILE}gcc --version
```

### 方法二：使用 Clang 编译器

```bash
# 下载 Clang 工具链
wget https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/android12-release/clang-r416183b1.tar.gz

# 创建 Clang 目录
mkdir -p clang

# 解压 Clang
tar -xf clang-r416183b1.tar.gz -C clang

# 设置环境变量
export PATH=$(pwd)/clang/bin:$PATH
export CC=clang
export CROSS_COMPILE=aarch64-linux-gnu-
export CLANG_TRIPLE=aarch64-linux-gnu-
export ARCH=arm64

# 验证 Clang
clang --version
```

### 方法三：使用系统 GCC

```bash
# 安装系统 GCC
sudo apt-get install gcc-aarch64-linux-gnu

# 设置环境变量
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# 验证
${CROSS_COMPILE}gcc --version
```

## ⚙️ 内核配置

### 1. 默认配置

```bash
# 使用默认的 nabu 配置
make nabu_defconfig

# 或者使用 DroidSpaces 专用配置
make droidspaces_nabu_defconfig
```

### 2. 自定义配置

```bash
# 打开内核配置菜单
make menuconfig

# 或者使用 xconfig（需要 Qt）
make xconfig

# 或者使用 nconfig
make nconfig
```

### 3. 关键配置选项

确保以下选项已启用（用于 DroidSpaces 容器支持）：

```
# 命名空间支持
CONFIG_NAMESPACES=y
CONFIG_UTS_NS=y
CONFIG_IPC_NS=y
CONFIG_USER_NS=y
CONFIG_PID_NS=y
CONFIG_NET_NS=y

# Cgroup 支持
CONFIG_CGROUPS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CPUSETS=y
CONFIG_CGROUP_CPUACCT=y
CONFIG_MEMCG=y
CONFIG_CGROUP_SCHED=y
CONFIG_FAIR_GROUP_SCHED=y
CONFIG_CGROUP_FREEZER=y

# OverlayFS 支持
CONFIG_OVERLAY_FS=y

# 其他容器相关
CONFIG_DEVPTS_MULTIPLE_INSTANCES=y
CONFIG_POSIX_MQUEUE=y
CONFIG_KEYS=y
CONFIG_PACKET=y
CONFIG_VLAN_8021Q=y
```

### 4. 验证配置

```bash
# 检查配置文件
grep -E "CONFIG_(NAMESPACES|CGROUPS|OVERLAY_FS)" .config

# 应该看到类似输出：
# CONFIG_NAMESPACES=y
# CONFIG_UTS_NS=y
# CONFIG_IPC_NS=y
# CONFIG_USER_NS=y
# CONFIG_PID_NS=y
# CONFIG_NET_NS=y
# CONFIG_CGROUPS=y
# CONFIG_OVERLAY_FS=y
```

## 🚀 编译内核

### 1. 基本编译

```bash
# 清理之前的编译文件
make clean

# 编译内核（使用所有 CPU 核心）
make -j$(nproc)

# 或者指定核心数
make -j8
```

### 2. 编译模块

```bash
# 编译所有模块
make modules

# 编译特定模块
make M=drivers/net/wireless modules
```

### 3. 打包内核

```bash
# 使用 AnyKernel3 打包
./build.sh

# 或者手动打包
make modules_install INSTALL_MOD_PATH=modules_install
```

### 4. 完整编译脚本

```bash
#!/bin/bash
# build_kernel.sh

set -e

# 设置环境变量
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

# 清理
echo "清理编译文件..."
make clean

# 配置内核
echo "配置内核..."
make droidspaces_nabu_defconfig

# 编译
echo "编译内核..."
make -j$(nproc)

# 编译模块
echo "编译模块..."
make modules

# 打包
echo "打包内核..."
./build.sh

echo "编译完成！"
```

## 📦 使用 GitHub Actions 自动构建

### 1. 启用 GitHub Actions

1. 访问你的 GitHub 仓库
2. 点击 "Actions" 标签页
3. 点击 "I understand my workflows, go ahead and enable them"

### 2. 触发自动构建

```bash
# 推送代码触发构建
git add .
git commit -m "更新内核配置"
git push origin main

# 或者创建标签触发发布构建
git tag -a v1.0.0 -m "发布版本 1.0.0"
git push origin v1.0.0
```

### 3. 查看构建状态

1. 访问仓库的 "Actions" 页面
2. 查看最新的 workflow 运行状态
3. 下载构建产物（Artifacts）

### 4. 自定义 GitHub Actions 配置

编辑 `.github/workflows/build.yml` 文件：

```yaml
name: Build Kernel

on:
  push:
    branches: [ main, develop ]
    tags: [ 'v*' ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup build environment
      run: |
        sudo apt-get update
        sudo apt-get install -y git-core build-essential gcc-aarch64-linux-gnu bc bison flex libssl-dev make libncurses-dev zip unzip python3
        
    - name: Download toolchain
      run: |
        wget https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/heads/android12-release.tar.gz
        mkdir -p toolchain
        tar -xf android12-release.tar.gz -C toolchain
        
    - name: Build kernel
      run: |
        export CROSS_COMPILE=$(pwd)/toolchain/bin/aarch64-linux-android-
        export ARCH=arm64
        make droidspaces_nabu_defconfig
        make -j$(nproc)
        make modules
        ./build.sh
        
    - name: Upload kernel
      uses: actions/upload-artifact@v3
      with:
        name: DroidSpacesKernel-nabu
        path: AnyKernel3/*.zip
```

## 🔍 编译选项

### 1. 调试编译

```bash
# 启用调试信息
make DEBUG_INFO=y

# 启用 KASAN（内核地址消毒器）
make KASAN=y

# 启用 ftrace
make FTRACE=y
```

### 2. 优化编译

```bash
# 使用 LTO（链接时优化）
make LLVM=1

# 使用 PGO（基于配置文件的优化）
make PGO=y
```

### 3. 模块编译

```bash
# 只编译特定模块
make M=net/bluetooth modules

# 编译并安装模块
make modules_install INSTALL_MOD_PATH=moduledir
```

## 📋 编译输出

编译完成后，你会在以下位置找到输出文件：

```
./AnyKernel3/
├── DroidSpacesKernel-nabu-YYYYMMDD-HHMMSS.zip  # 可刷入的内核包
├── boot.img                                      # 内核镜像
└── modules/                                      # 内核模块
    └── ...
```

## 🚨 常见编译问题

### 1. 缺少依赖

```bash
# 错误：ncurses.h: No such file or directory
sudo apt-get install libncurses-dev

# 错误：openssl/ssl.h: No such file or directory
sudo apt-get install libssl-dev
```

### 2. 工具链问题

```bash
# 错误：aarch64-linux-gnu-gcc: command not found
export CROSS_COMPILE=/path/to/toolchain/bin/aarch64-linux-gnu-

# 错误：Permission denied
chmod +x toolchain/bin/*
```

### 3. 内存不足

```bash
# 错误：virtual memory exhausted
# 减少并行编译数
make -j2
# 或者增加 swap
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 🔗 相关资源

- [内核编译文档](https://www.kernel.org/doc/html/latest/process/programming-language.html)
- [ARM64 内核编译](https://www.kernel.org/doc/Documentation/arm64/)
- [AnyKernel3 文档](https://github.com/osm0sis/AnyKernel3)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

---

如果遇到编译问题，请查看 [故障排除](TROUBLESHOOTING.md) 文档或在 [Issues](https://github.com/Re-s/xiaomi-nabu-droidspace-kernel/issues) 页面提交问题。