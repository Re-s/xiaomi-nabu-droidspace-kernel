# 小米平板5 DroidSpaces 内核快速开始指南

本指南帮助你快速编译和刷入 DroidSpaces 内核，让你的小米平板5（nabu）能够运行 Linux 容器。

## 🚀 一键构建（GitHub Actions）

**最快的方式，无需本地编译环境**

### 步骤 1：Fork 仓库
1. 访问 [xiaomi-nabu-droidspace-kernel](https://github.com/your-username/xiaomi-nabu-droidspace-kernel)
2. 点击右上角 **Fork** 按钮
3. 等待 Fork 完成

### 步骤 2：触发构建
1. 进入你 Fork 的仓库
2. 点击 **Actions** 标签页
3. 选择 **Build Kernel** 工作流
4. 点击 **Run workflow**
5. 选择分支（通常选 `main`），点击绿色按钮触发

### 步骤 3：下载刷机包
1. 等待构建完成（约 10-15 分钟）
2. 点击完成的构建任务
3. 在 **Artifacts** 部分下载 `DroidSpacesKernel-nabu.zip`
4. 解压得到可刷入的内核包

## 💻 本地构建（5分钟快速上手）

### 步骤 1：环境准备
```bash
# 1. 安装构建依赖
sudo apt-get update
sudo apt-get install -y git-core build-essential gcc-aarch64-linux-gnu \
    bc bison flex libssl-dev make libncurses-dev zip unzip python3

# 2. 克隆仓库
git clone --recursive https://github.com/your-username/xiaomi-nabu-droidspace-kernel.git
cd xiaomi-nabu-droidspace-kernel

# 3. 下载工具链
wget https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/heads/android12-release.tar.gz
mkdir -p toolchain
tar -xf android12-release.tar.gz -C toolchain
chmod +x toolchain/bin/*
```

### 步骤 2：构建内核
```bash
# 1. 设置环境变量
export CROSS_COMPILE=$(pwd)/toolchain/bin/aarch64-linux-android-
export ARCH=arm64

# 2. 配置内核
make droidspaces_nabu_defconfig

# 3. 编译（使用所有 CPU 核心）
make -j$(nproc)

# 4. 打包刷机包
./build.sh
```

**构建完成后**，刷机包位于：
```
./AnyKernel3/DroidSpacesKernel-nabu-*.zip
```

## 📱 刷机步骤

### 前置条件检查
1. **解锁 Bootloader**
   - 访问 [小米解锁官网](https://www.miui.com/unlock/index.html) 申请解锁
   - 下载小米解锁工具
   - 连接设备，执行 `adb reboot bootloader`
   - 使用解锁工具解锁（需等待审批）

2. **安装 TWRP Recovery**
   ```bash
   # 下载适用于 nabu 的 TWRP
   # 访问 https://twrp.me/xiaomi/xiaomipad5.html
   
   # 刷入 TWRP
   fastboot flash recovery twrp-3.x.x-x-nabu.img
   fastboot reboot recovery
   ```

3. **安装 ADB/Fastboot**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install android-tools-adb android-tools-fastboot
   
   # 检查设备连接
   adb devices
   ```

### Recovery 刷入
```bash
# 1. 传输内核到设备
adb push DroidSpacesKernel-nabu-*.zip /sdcard/

# 2. 重启到 Recovery
adb reboot recovery

# 3. 在 TWRP 中：
#    - 点击"安装"
#    - 选择 /sdcard/DroidSpacesKernel-nabu-*.zip
#    - 滑动确认刷入

# 4. 重启设备
adb reboot
```

### 验证安装
```bash
# 检查内核版本
adb shell uname -r
# 应显示：5.10.xx-droidspaces-nabu

# 检查容器支持
adb shell ls /proc/sys/kernel/namespaces
adb shell ls /sys/fs/cgroup/
```

## 🐧 首次使用 DroidSpaces

### 安装 DroidSpaces App
1. 从 [GitHub Releases](https://github.com/nickcano/droidspaces/releases) 下载最新版本
2. 安装 APK 文件
3. 授予 Root 权限（需要 Magisk）

### 创建第一个容器
1. 打开 DroidSpaces App
2. 点击 **创建新容器**
3. 选择 Linux 发行版（如 Ubuntu 22.04）
4. 设置容器名称和资源限制
5. 点击 **创建** 并等待下载完成

### 常用命令
```bash
# 列出所有容器
droidspaces list

# 启动容器
droidspaces start <容器名>

# 进入容器
droidspaces exec <容器名> bash

# 停止容器
droidspaces stop <容器名>

# 删除容器
droidspaces rm <容器名>

# 查看容器状态
droidspaces status
```

### 基本使用示例
```bash
# 启动 Ubuntu 容器
droidspaces start ubuntu

# 进入容器安装软件
droidspaces exec ubuntu bash
apt update
apt install -y vim git curl

# 在容器中运行程序
droidspaces exec ubuntu python3 --version
```

## ❓ 常见问题

### 构建失败
- 检查依赖是否完整：`sudo apt-get install -y build-essential gcc-aarch64-linux-gnu`
- 减少并行编译数：`make -j2`
- 增加 swap 空间

### 刷机失败
- 确保 Bootloader 已解锁
- 尝试使用 Fastboot 模式：`adb reboot bootloader`
- 检查 TWRP 版本是否兼容

### DroidSpaces 无法启动
- 确认内核版本正确：`uname -r`
- 检查 Root 权限是否正常
- 查看 Logcat 日志：`adb logcat | grep droidspaces`

## 📚 详细文档

- [完整构建指南](BUILDING.md)
- [详细安装步骤](INSTALLATION.md)
- [内核配置要求](DROIDSPACES_REQUIREMENTS.md)
- [故障排除](TROUBLESHOOTING.md)
- [兼容性说明](COMPATIBILITY.md)

## 🔗 有用链接

- [DroidSpaces 官方仓库](https://github.com/nickcano/droidspaces)
- [AnyKernel3 刷入工具](https://github.com/osm0sis/AnyKernel3)
- [TWRP Recovery](https://twrp.me/)
- [Magisk Root](https://github.com/topjohnwu/Magisk)
- [小米解锁官网](https://www.miui.com/unlock/index.html)

---

**提示**：首次启动可能需要较长时间，这是正常现象。如果遇到问题，请查看[故障排除](TROUBLESHOOTING.md)文档。