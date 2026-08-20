# DroidSpaces Kernel for Xiaomi Pad 5 (nabu)

[![Build Kernel](https://github.com/Re-s/xiaomi-nabu-droidspace-kernel/actions/workflows/build-kernel.yml/badge.svg)](https://github.com/Re-s/xiaomi-nabu-droidspace-kernel/actions/workflows/build-kernel.yml)
[![License: GPL v2](https://img.shields.io/badge/License-GPL_v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
[![DroidSpaces Compatible](https://img.shields.io/badge/DroidSpaces-Compatible-green.svg)](https://github.com/ravindu644/Droidspaces-OSS)

这是为小米平板5（代号：nabu）定制的 Linux 内核，专门优化以支持 DroidSpaces 容器运行时所需的所有内核特性。本内核兼容 HyperOS 1.0.3.0TKXCNXM，提供完整的容器支持。

## 📱 设备信息

| 参数 | 值 |
|------|-----|
| **设备** | 小米平板5 |
| **代号** | nabu |
| **型号** | 21051182C (中国版) |
| **SoC** | 高通骁龙860 (SM8150) |
| **内核版本** | 6.1.10 |
| **架构** | arm64 |
| **兼容系统** | HyperOS 1.0.3.0TKXCNXM |

## 🎯 特性支持

本内核已启用 DroidSpaces 容器运行所需的所有关键特性：

| 类别 | 特性 | 状态 | 说明 |
|------|------|------|------|
| **Linux Namespaces** | UTS, IPC, PID, NET, USER, CGROUP | ✅ | 完整的命名空间支持 |
| **Cgroups** | device, pids, memory, freezer, etc. | ✅ | 资源隔离与限制 |
| **OverlayFS** | overlay, metacopy | ✅ | 联合文件系统支持 |
| **Seccomp filtering** | seccomp, seccomp_filter | ✅ | 系统调用过滤 |
| **网络** | veth, bridge, NAT, iptables | ✅ | 完整的网络隔离 |
| **FUSE filesystem** | fuse | ✅ | 用户空间文件系统 |
| **Checkpoint/Restore** | cgroup, freezer | ✅ | 容器状态保存与恢复 |
| **设备映射器** | device-mapper | ✅ | 块设备虚拟化 |

### 核心配置详情

**命名空间支持**：
- `CONFIG_NAMESPACES=y` - 命名空间基础支持
- `CONFIG_PID_NS=y` - 进程ID命名空间
- `CONFIG_UTS_NS=y` - 主机名命名空间
- `CONFIG_IPC_NS=y` - 进程间通信命名空间
- `CONFIG_USER_NS=y` - 用户命名空间
- `CONFIG_NET_NS=y` - 网络命名空间
- `CONFIG_CGROUP_NS=y` - 控制组命名空间

**控制组支持**：
- `CONFIG_CGROUPS=y` - 控制组基础支持
- `CONFIG_CGROUP_DEVICE=y` - 设备控制组
- `CONFIG_CGROUP_PIDS=y` - PID控制组
- `CONFIG_MEMCG=y` - 内存控制组
- `CONFIG_CGROUP_FREEZER=y` - 冻结器控制组
- `CONFIG_CGROUP_SCHED=y` - 调度控制组

**文件系统支持**：
- `CONFIG_OVERLAY_FS=y` - OverlayFS支持
- `CONFIG_DEVTMPFS=y` - 设备文件系统
- `CONFIG_FUSE_FS=FUSE` - FUSE文件系统

**网络安全**：
- `CONFIG_VETH=y` - 虚拟以太网设备
- `CONFIG_BRIDGE=y` - 网桥支持
- `CONFIG_NETFILTER=y` - 网络过滤器
- `CONFIG_NF_NAT=y` - 网络地址转换
- `CONFIG_IP_NF_IPTABLES=y` - iptables支持

## 🚀 快速开始

### 方式一：GitHub Actions 自动构建（推荐）

1. **Fork 本仓库**
   - 访问 [GitHub 仓库](https://github.com/Re-s/xiaomi-nabu-droidspace-kernel)
   - 点击右上角的 "Fork" 按钮

2. **启用 Actions**
   - 进入你 Fork 的仓库
   - 点击 "Actions" 标签页
   - 点击 "I understand my workflows, go ahead and enable them"

3. **自动构建**
   - 推送代码到 `main` 分支会自动触发构建
   - 或手动在 Actions 页面点击 "Run workflow"
   - 构建完成后在 Releases 页面下载内核包

4. **下载内核**
   - 进入 "Actions" 标签页
   - 点击最近的构建任务
   - 在 "Artifacts" 部分下载 AnyKernel3 ZIP 文件

### 方式二：本地编译（推荐）

#### 使用增强版构建脚本 (推荐)

**推荐使用 `build_kernel.sh` 脚本，它提供了完整的自动化构建流程。**

```bash
# 1. 克隆仓库
git clone --recursive https://github.com/Re-s/xiaomi-nabu-droidspace-kernel.git
cd xiaomi-nabu-droidspace-kernel

# 2. 赋予执行权限
chmod +x build_kernel.sh

# 3. 完整构建（推荐）
./build_kernel.sh

# 4. 或者使用其他选项
./build_kernel.sh -n          # 不清理直接构建
./build_kernel.sh -t 8        # 使用8个线程编译
./build_kernel.sh --use-anykernel  # 只生成AnyKernel3包
./build_kernel.sh --use-mkbootimg  # 使用mkbootimg生成boot.img
```

**脚本会自动：**
- 检测并安装缺失的依赖
- 克隆或更新内核源码
- 应用DroidSpaces配置
- 编译内核、模块和DTB
- 生成boot.img和AnyKernel3包
- 创建完整的发布包

#### 系统要求

- **操作系统**：Ubuntu 20.04+ / Debian 11+ / Fedora 34+
- **磁盘空间**：至少 50GB 可用空间
- **内存**：建议 16GB+（编译时需要大量内存）
- **CPU**：建议 4核以上（加快编译速度）

#### 安装依赖

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y git-core build-essential gcc-aarch64-linux-gnu \
  bc bison flex libssl-dev make libncurses-dev u-boot-tools \
  device-tree-compiler python3 python3-pip

# Fedora
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y gcc-aarch64-linux-gnu bc bison flex openssl-devel \
  elfutils-libelf-devel ncurses-devel u-boot-tools dtc python3
```

#### 编译步骤

```bash
# 1. 克隆仓库
git clone --recursive https://github.com/Re-s/xiaomi-nabu-droidspace-kernel.git
cd xiaomi-nabu-droidspace-kernel

# 2. 下载交叉编译工具链（可选，也可使用系统工具链）
# 如果使用系统工具链，确保 aarch64-linux-gnu-gcc 可用
which aarch64-linux-gnu-gcc || echo "请安装 gcc-aarch64-linux-gnu"

# 3. 设置环境变量
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

# 4. 清理之前的构建（首次编译可跳过）
make clean
make mrproper

# 5. 应用内核配置
make xiaomi_nabu_droidspace_defconfig

# 6. 编译内核
# 使用所有CPU核心编译
make -j$(nproc)

# 7. 编译内核模块
make modules -j$(nproc)

# 8. 创建 AnyKernel3 刷机包
make package
```

#### 输出文件说明

编译完成后，会在以下位置生成文件：

| 文件 | 位置 | 说明 |
|------|------|------|
| `boot.img` | `arch/arm64/boot/boot.img` | 内核镜像文件 |
| `Image` | `arch/arm64/boot/Image` | 压缩的内核镜像 |
| `modules.zip` | `AnyKernel3/DroidSpacesKernel-nabu-*.zip` | AnyKernel3 刷机包 |
| `.config` | `arch/arm64/configs/xiaomi_nabu_droidspace_defconfig` | 内核配置文件 |

### 方式三：使用预编译内核

1. 访问 [Releases 页面](https://github.com/Re-s/xiaomi-nabu-droidspace-kernel/releases)
2. 下载最新的 `DroidSpacesKernel-nabu-*.zip` 文件
3. 按照刷入指南进行安装

## 🔧 本地编译详细指南

### 高级编译选项

```bash
# 使用指定工具链（推荐）
export CROSS_COMPILE=/path/to/toolchain/bin/aarch64-linux-android-
export ARCH=arm64

# 使用 ccache 加速重复编译
export USE_CCACHE=1
export CCACHE_DIR=~/.ccache
ccache -M 50G  # 设置缓存大小为50GB

# 编译时显示详细信息
make -j$(nproc) V=1

# 仅编译内核（不编译模块）
make -j$(nproc) Image

# 编译并安装模块到指定目录
make modules_install INSTALL_PATH=/path/to/modules
```

### 内核配置定制

```bash
# 查看当前配置
make menuconfig

# 或者使用 nconfig（更现代的界面）
make nconfig

# 搜索配置选项
make configmenu  # 在 menuconfig 中搜索

# 查看配置依赖
make configcheck

# 验证配置完整性
make/listnewconfig
```

### 清理构建

```bash
# 清理生成的文件
make clean

# 清理所有非源码文件
make mrproper

# 清理所有文件（包括 .config）
make distclean
```

## 📲 刷入指南

### 前置条件

1. **解锁 Bootloader**
   - 使用小米官方解锁工具
   - 申请解锁权限（可能需要等待）
   - 具体步骤参考 [小米官方解锁教程](https://www.mi.com/service/unlock)

2. **安装自定义 Recovery**
   - 推荐 TWRP 或 OrangeFox Recovery
   - 下载地址：[TWRP for nabu](https://twrp.me/xiaomi/xiaomipad5.html)

3. **获取 Root 权限（可选）**
   - 推荐 KernelSU 或 Magisk
   - Root 权限可以提供更好的控制

### 方式一：使用 AnyKernel3 ZIP（推荐）

#### 通过 TWRP Recovery 刷入

1. **下载内核包**
   - 从 Releases 页面下载 `DroidSpacesKernel-nabu-*.zip`

2. **传输到设备**
   ```bash
   # 使用 ADB 传输
   adb push DroidSpacesKernel-nabu-*.zip /sdcard/

   # 或者通过 MTP 传输
   # 将文件复制到设备存储的根目录
   ```

3. **进入 Recovery 模式**
   ```bash
   # 方法一：使用 ADB
   adb reboot recovery

   # 方法二：关机状态下同时按住 电源键 + 音量上键
   ```

4. **刷入内核**
   - 在 TWRP 主界面选择 "Install"
   - 找到并选择 `DroidSpacesKernel-nabu-*.zip`
   - 滑动确认刷入
   - 等待刷入完成

5. **重启设备**
   - 返回主界面
   - 选择 "Reboot" → "System"

#### 通过 OrangeFox Recovery 刷入

1. 进入 OrangeFox Recovery
2. 选择 "Files" → 导航到内核 ZIP 文件
3. 点击文件并滑动确认刷入
4. 重启系统

### 方式二：使用 Fastboot 刷入

1. **准备文件**
   ```bash
   # 确保有 boot.img 文件
   ls arch/arm64/boot/boot.img
   ```

2. **进入 Fastboot 模式**
   ```bash
   # 方法一：使用 ADB
   adb reboot bootloader

   # 方法二：关机状态下同时按住 电源键 + 音量下键
   ```

3. **验证 Fastboot 连接**
   ```bash
   fastboot devices
   # 应该显示设备序列号
   ```

4. **刷入内核**
   ```bash
   # 刷入 boot.img
   fastboot flash boot boot.img

   # 或者同时刷入多个分区（如果需要）
   fastboot flash boot boot.img
   fastboot flash dtbo dtbo.img
   ```

5. **重启设备**
   ```bash
   fastboot reboot
   ```

### 注意事项和备份建议

#### ⚠️ 重要注意事项

1. **备份原始内核**
   ```bash
   # 在刷入前备份原始 boot.img
   adb shell su -c "dd if=/dev/block/by-name/boot of=/sdcard/boot_backup.img"
   adb pull /sdcard/boot_backup.img ./boot_backup.img
   ```

2. **备份重要数据**
   - 使用小米云服务备份
   - 使用第三方备份工具（如 Titanium Backup）
   - 手动备份重要文件到电脑

3. **保持电量充足**
   - 确保设备电量在 50% 以上
   - 避免在刷入过程中断电

4. **使用原装数据线**
   - 确保 USB 连接稳定
   - 避免使用 USB Hub

#### 🔧 恢复原始内核

如果遇到问题需要恢复原始内核：

```bash
# 方法一：使用之前备份的 boot.img
adb reboot bootloader
fastboot flash boot boot_backup.img
fastboot reboot

# 方法二：从小米官方固件中提取 boot.img
# 下载对应版本的 HyperOS 固件
# 解压得到 boot.img
# 使用 fastboot 刷入
```

## 📁 项目结构

```
xiaomi-nabu-droidspace-kernel/
├── .github/
│   ├── workflows/
│   │   └── build-kernel.yml          # GitHub Actions 构建工作流
│   └── ISSUE_TEMPLATE/               # Issue 模板
├── AnyKernel3/
│   ├── anykernel.sh                  # AnyKernel3 主脚本
│   ├── device_config.sh              # 设备配置文件
│   └── tools/
│       └── anykernel1.sh             # AnyKernel3 工具函数
├── arch/
│   └── arm64/
│       └── configs/
│           └── xiaomi_nabu_droidspace_defconfig  # 内核配置文件
├── docs/
│   ├── QUICKSTART.md                 # 快速开始指南
│   ├── INSTALLATION.md               # 详细安装指南
│   ├── BUILDING.md                   # 构建指南
│   ├── TROUBLESHOOTING.md            # 故障排除
│   ├── USAGE.md                      # DroidSpaces 使用教程
│   ├── DROIDSPACES_REQUIREMENTS.md   # 内核要求文档
│   ├── COMPATIBILITY.md              # 兼容性分析
│   └── CONTRIBUTING.md               # 贡献指南
├── .gitignore                        # Git 忽略文件
├── LICENSE                           # GPL v2 许可证
├── Makefile                          # 构建简化脚本
├── build_kernel.sh                   # 增强版构建脚本（推荐）
├── build.sh                          # 基础构建脚本
├── build_boot_img.sh                 # boot.img 生成脚本
├── verify_kernel.sh                  # 内核配置验证脚本
├── apply_gki_patches.sh              # GKI kABI 补丁脚本
├── PROJECT_STRUCTURE.md              # 项目结构说明
├── SUMMARY.md                        # 项目进度总结
└── README.md                         # 本文件
```

### 关键文件说明

| 文件 | 说明 |
|------|------|
| `build_kernel.sh` | **增强版构建脚本** - 生产级内核编译与 boot.img 生成（推荐） |
| `build.sh` | 基础构建脚本 - 简化的内核编译流程 |
| `build_boot_img.sh` | boot.img 生成脚本 - 专注于 boot.img 创建 |
| `verify_kernel.sh` | 验证内核配置是否符合 DroidSpaces 要求 |
| `apply_gki_patches.sh` | 应用 GKI kABI 兼容性补丁 |
| `xiaomi_nabu_droidspace_defconfig` | DroidSpaces 优化的内核配置 |
| `AnyKernel3/` | AnyKernel3 刷机包模板 |

## 🔧 工具脚本

### 增强版构建脚本 (build_kernel.sh)

这是推荐的生产级构建脚本，提供完整的内核编译和 boot.img 生成功能。

#### 主要特性

1. **自动依赖管理**
   - 检测系统类型（Ubuntu/Debian/CentOS/Fedora/Arch）
   - 自动安装缺失的依赖包
   - 验证交叉编译器

2. **内核源码管理**
   - 支持 git clone（自动检测代理）
   - 支持更新内核源码
   - 验证内核版本

3. **智能配置**
   - 自动复制 defconfig
   - 运行 olddefconfig
   - 验证 DroidSpaces 关键配置项

4. **并行编译**
   - 自动检测 CPU 核心数
   - 支持自定义线程数
   - 记录编译时间

5. **多种打包方式**
   - AnyKernel3 ZIP（用于 Recovery 刷入）
   - mkbootimg 生成 boot.img（用于 fastboot 刷入）
   - 完整的发布包

6. **错误处理**
   - 完整的错误捕获和日志记录
   - 编译失败时显示详细信息
   - 自动清理临时文件

#### 常用命令

```bash
# 查看所有可用命令
./build_kernel.sh -h

# 完整构建（推荐）
./build_kernel.sh

# 不清理直接构建（增量编译）
./build_kernel.sh -n

# 指定编译线程数
./build_kernel.sh -t 8

# 清理构建
./build_kernel.sh -c
```

### 基础构建脚本

```bash
# 查看所有可用命令
make help

# 完整构建（推荐）
make build

# 创建刷机包
make package

# 验证内核配置
./verify_kernel.sh

# 应用 GKI 补丁（GKI 内核必需）
./apply_gki_patches.sh

# 清理构建
make clean
```

### 构建脚本选项

#### 增强版构建脚本 (build_kernel.sh) - 推荐使用

```bash
# 查看构建脚本帮助
./build_kernel.sh -h

# 完整构建（推荐）
./build_kernel.sh

# 不清理直接构建（增量编译）
./build_kernel.sh -n

# 指定编译线程数
./build_kernel.sh -t 8

# 仅编译内核（不编译模块）
./build_kernel.sh -m

# 仅设置环境
./build_kernel.sh -s

# 仅编译内核
./build_kernel.sh -k

# 仅打包（需要先编译内核）
./build_kernel.sh -p

# 使用 AnyKernel3 打包
./build_kernel.sh --use-anykernel

# 使用 mkbootimg 生成 boot.img
./build_kernel.sh --use-mkbootimg

# 更新内核源码并编译
./build_kernel.sh --update

# 清理构建
./build_kernel.sh -c
```

#### 基础构建脚本 (build.sh)

```bash
# 查看构建脚本帮助
./build.sh -h

# 不清理直接构建（增量编译）
./build.sh -n

# 指定编译线程数
./build.sh -t 8

# 仅编译内核（不编译模块）
./build.sh --no-modules
```

## ❓ 故障排除

### 常见编译错误

#### 1. 工具链错误
**错误**：`aarch64-linux-gnu-gcc: command not found`
**解决**：
```bash
# 安装工具链
sudo apt-get install gcc-aarch64-linux-gnu

# 或者使用完整路径
export CROSS_COMPILE=/usr/bin/aarch64-linux-gnu-

# 检查工具链版本
aarch64-linux-gnu-gcc --version
```

#### 2. 内存不足
**错误**：`virtual memory exhausted: Cannot allocate memory`
**解决**：
```bash
# 增加交换空间
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 减少并行编译任务数
make -j2  # 使用2个核心编译
```

#### 3. 依赖缺失
**错误**：`Makefile:xxx: *** missing separator. Stop.`
**解决**：
```bash
# 安装所有依赖
sudo apt-get install -y build-essential bc bison flex libssl-dev make libncurses-dev

# 对于 Ubuntu 22.04+
sudo apt-get install -y libssl-dev
```

#### 4. 配置错误
**错误**：`make: *** No rule to make target 'xiaomi_nabu_droidspace_defconfig'`
**解决**：
```bash
# 检查配置文件是否存在
ls arch/arm64/configs/

# 使用默认配置
make defconfig

# 或者从原始配置开始
make menuconfig
```

### 刷入失败处理

#### 1. 无法进入 Recovery
**症状**：按键组合无法进入 TWRP
**解决**：
```bash
# 使用 ADB 强制进入
adb reboot recovery

# 如果 ADB 也无法连接
# 尝试按键组合：关机后按住 电源键 + 音量上键
# 持续按住直到出现 Recovery 界面
```

#### 2. 刷入时出错
**错误**：`Update binary missing` 或 `Error 7`
**解决**：
```bash
# 检查 ZIP 文件是否完整
md5sum DroidSpacesKernel-nabu-*.zip

# 重新下载内核包

# 尝试使用不同的 Recovery 版本

# 检查设备存储空间
df -h
```

#### 3. 刷入后无法启动
**症状**：卡在小米 Logo 或重启循环
**解决**：
```bash
# 1. 进入 Fastboot 模式
# 按住 电源键 + 音量下键

# 2. 刷入备份的 boot.img
fastboot flash boot boot_backup.img

# 3. 或者从小米官方固件刷入原始内核
fastboot flash boot stock_boot.img

# 4. 重启设备
fastboot reboot
```

#### 4. 网络问题
**症状**：容器内无法联网
**解决**：
```bash
# 检查网络命名空间
ls -la /proc/self/ns/net

# 检查 veth 设备
ip link show

# 配置网络桥接
ip link add br0 type bridge
ip link set br0 up

# 配置 iptables
iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -o wlan0 -j MASQUERADE
```

#### 5. 容器启动失败
**症状**：DroidSpaces 无法启动容器
**解决**：
```bash
# 检查内核版本
uname -r

# 验证内核配置
./verify_kernel.sh

# 检查命名空间支持
ls -la /proc/self/ns/

# 检查 cgroup 支持
mount | grep cgroup
```

### 性能优化建议

1. **内存管理**
   - 确保设备有足够内存（建议 6GB+）
   - 关闭不必要的后台应用
   - 使用 zRAM 压缩内存

2. **存储优化**
   - 使用 UFS 3.1 存储（小米平板5 支持）
   - 确保有足够的剩余空间（建议 10GB+）
   - 定期清理缓存

3. **CPU 调度**
   - 使用性能模式
   - 避免在编译时进行其他 CPU 密集型任务

## 🤝 贡献指南

### 贡献方式

1. **报告问题**
   - 在 [Issues](https://github.com/Re-s/xiaomi-nabu-droidspace-kernel/issues) 页面提交问题
   - 提供详细的错误信息和设备日志
   - 包含内核版本和设备型号

2. **提交代码**
   - Fork 本仓库
   - 创建功能分支：`git checkout -b feature/your-feature`
   - 提交更改：`git commit -m 'Add some feature'`
   - 推送到分支：`git push origin feature/your-feature`
   - 创建 Pull Request

3. **改进文档**
   - 修复错误或补充内容
   - 添加使用教程
   - 翻译文档

### 开发环境设置

```bash
# 1. Fork 并克隆仓库
git clone https://github.com/your-username/xiaomi-nabu-droidspace-kernel.git
cd xiaomi-nabu-droidspace-kernel

# 2. 添加上游仓库
git remote add upstream https://github.com/Re-s/xiaomi-nabu-droidspace-kernel.git

# 3. 安装开发依赖
sudo apt-get install -y git build-essential gcc-aarch64-linux-gnu

# 4. 验证内核配置
./verify_kernel.sh
```

### 代码规范

- 遵循 Linux 内核代码风格
- 使用 4 空格缩进
- 添加必要的注释
- 确保编译无警告

### 测试要求

1. **编译测试**
   - 确保代码能在本地编译通过
   - 使用 `make check` 验证代码

2. **功能测试**
   - 在小米平板5上测试
   - 验证 DroidSpaces 容器功能
   - 检查系统稳定性

## 📜 许可证

本项目基于 GNU General Public License v2.0 许可证开源。

详细信息请查看 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- [MiCode/Xiaomi_Kernel_OpenSource](https://github.com/MiCode/Xiaomi_Kernel_OpenSource) - 小米官方内核源码
- [maverickjb/linux-6.1.10](https://github.com/maverickjb/linux-6.1.10) - 基础内核版本
- [AnyKernel3](https://github.com/osm0sis/AnyKernel3) - 内核刷入工具
- [DroidSpaces](https://github.com/ravindu644/Droidspaces-OSS) - Android 容器运行时
- [LineageOS](https://lineageos.org/) - Android 开源项目
- [TWRP](https://twrp.me/) - 自定义 Recovery
- 所有贡献者和测试人员

## 📞 联系方式

- **项目主页**：[GitHub](https://github.com/Re-s/xiaomi-nabu-droidspace-kernel)
- **问题反馈**：[Issues](https://github.com/Re-s/xiaomi-nabu-droidspace-kernel/issues)
- **讨论交流**：[Discussions](https://github.com/Re-s/xiaomi-nabu-droidspace-kernel/discussions)

---

**免责声明**：使用本内核可能使您的设备保修失效。请谨慎操作，作者不对任何设备损坏负责。在刷入前请确保已备份重要数据。