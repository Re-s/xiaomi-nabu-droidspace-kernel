# DroidSpaces 内核构建快速参考指南

## 🚀 快速开始

### 一键构建（推荐）
```bash
cd xiaomi-nabu-droidspace-kernel
chmod +x build_kernel.sh
./build_kernel.sh
```

### 系统要求
- **操作系统**: Ubuntu 20.04+ / Debian 11+ / Fedora 34+ / Arch Linux
- **磁盘空间**: 至少 50GB 可用空间
- **内存**: 建议 16GB+（编译时需要大量内存）
- **CPU**: 建议 4核以上（加快编译速度）

## 📦 依赖安装

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y git-core build-essential gcc-aarch64-linux-gnu \
  bc bison flex libssl-dev make libncurses-dev u-boot-tools \
  device-tree-compiler python3 python3-pip libelf-dev libfl-dev \
  libgmp-dev libmpc-dev libmpfr-dev cpio zip unzip wget curl
```

### Fedora/RHEL
```bash
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y gcc-aarch64-linux-gnu bc bison flex openssl-devel \
  elfutils-libelf-devel ncurses-devel u-boot-tools dtc python3 \
  cpio zip unzip wget curl
```

### Arch Linux
```bash
sudo pacman -S base-devel aarch64-linux-gnu-gcc aarch64-linux-gnu-binutils \
  bc bison flex openssl libelf ncurses dtc python cpio zip unzip wget curl
```

## 🔧 构建脚本选项

### 基本用法
```bash
./build_kernel.sh                    # 完整构建
./build_kernel.sh -n                 # 不清理直接构建
./build_kernel.sh -c                 # 清理构建
./build_kernel.sh -t 8               # 使用8个线程编译
```

### 高级选项
```bash
./build_kernel.sh -s                 # 仅设置环境
./build_kernel.sh -k                 # 仅编译内核
./build_kernel.sh -p                 # 仅打包
./build_kernel.sh -m                 # 不编译模块
./build_kernel.sh --use-anykernel    # 仅使用AnyKernel3打包
./build_kernel.sh --use-mkbootimg    # 使用mkbootimg生成boot.img
./build_kernel.sh --update           # 更新内核源码
```

## 📁 输出文件

构建完成后，输出文件位于：

| 文件 | 位置 | 说明 |
|------|------|------|
| `boot.img` | `out/boot.img` | 启动镜像（用于fastboot） |
| `Image` | `out/Image` | 内核镜像 |
| `DroidSpaces_*.zip` | `release/` | AnyKernel3刷机包 |
| `*.tar.gz` | `release/` | 完整发布包 |

## 📱 刷入方法

### 方法1：Fastboot（推荐）
```bash
# 重启到bootloader
adb reboot bootloader

# 刷入boot.img
fastboot flash boot out/boot.img

# 重启
fastboot reboot
```

### 方法2：AnyKernel3 ZIP
1. 将ZIP文件复制到设备存储
2. 重启到Recovery（TWRP/OrangeFox）
3. 安装ZIP文件
4. 重启系统

### 方法3：使用刷机脚本
```bash
# 在发布包目录中
chmod +x flash.sh
./flash.sh boot
```

## 🔍 验证内核

```bash
# 检查内核版本
adb shell uname -r

# 检查DroidSpaces支持
adb shell ls /proc/self/ns/
adb shell cat /proc/version
```

## 🛠️ 故障排除

### 编译失败
```bash
# 查看编译日志
cat logs/build.log
cat logs/kernel_compile.log

# 清理重新编译
./build_kernel.sh -c
```

### 依赖缺失
```bash
# 检查缺失的依赖
./build_kernel.sh --setup-only

# 手动安装缺失的包
sudo apt-get install <package-name>
```

### boot.img生成失败
```bash
# 使用AnyKernel3方法
./build_kernel.sh --use-anykernel

# 或手动安装mkbootimg
sudo apt-get install mkbootimg
```

## 📊 构建时间参考

| CPU核心数 | 首次编译 | 增量编译 |
|-----------|----------|----------|
| 4核 | ~45分钟 | ~10分钟 |
| 8核 | ~25分钟 | ~5分钟 |
| 16核 | ~15分钟 | ~3分钟 |

## 🔧 环境变量

可以设置以下环境变量自定义构建：

```bash
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export BUILD_THREADS=$(nproc)
```

## 📝 注意事项

1. **首次编译**需要较长时间，后续增量编译会快很多
2. **确保足够的磁盘空间**（至少50GB）
3. **建议使用SSD**加快编译速度
4. **编译时关闭不必要的程序**以释放内存
5. **备份原始boot.img**以防刷机失败

## 🆘 获取帮助

```bash
# 查看帮助
./build_kernel.sh -h

# 查看构建日志
cat logs/build.log

# 验证内核配置
./verify_kernel.sh
```