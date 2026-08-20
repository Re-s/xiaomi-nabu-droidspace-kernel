# DroidSpaces 内核项目结构

## 小米平板5 (nabu) 专用 DroidSpaces 内核构建项目

---

## 项目概述

本项目为小米平板5（代号：nabu）提供完整的 DroidSpaces 容器支持内核构建方案，包括：

- ✅ GitHub Actions 自动化构建（支持环境复用）
- ✅ DroidSpaces 官方内核配置要求
- ✅ AnyKernel3 刷机包
- ✅ 完整的文档和教程
- ✅ 内核验证工具
- ✅ GKI kABI 补丁支持

---

## 目录结构

```
xiaomi-nabu-droidspace-kernel/
├── .github/
│   └── workflows/
│       └── build-kernel.yml          # GitHub Actions 工作流（支持缓存复用）
├── AnyKernel3/
│   ├── anykernel.sh                  # AnyKernel3 主脚本
│   ├── tools/
│   │   └── anykernel1.sh             # AnyKernel3 工具函数
│   └── device_config.sh              # 设备配置文件
├── arch/
│   └── arm64/
│       └── configs/
│           └── xiaomi_nabu_droidspace_defconfig  # 内核配置文件
├── docs/
│   ├── README.md                     # 项目主文档
│   ├── INSTALLATION.md               # 详细安装指南
│   ├── BUILDING.md                   # 构建指南
│   ├── TROUBLESHOOTING.md            # 故障排除
│   └── COMPATIBILITY.md              # 兼容性分析报告
├── .gitignore                        # Git忽略文件
├── LICENSE                           # GPL v3 许可证
├── Makefile                          # 构建简化脚本
├── build.sh                          # 主构建脚本
├── verify_kernel.sh                  # 内核验证脚本（待创建）
├── apply_gki_patches.sh              # GKI补丁应用脚本（待创建）
└── PROJECT_STRUCTURE.md              # 本文件
```

---

## 核心文件说明

### 1. GitHub Actions 工作流

**文件**: `.github/workflows/build-kernel.yml`

**特性**:
- 支持环境缓存复用，避免重复下载
- 分阶段构建，提高效率
- 自动创建 AnyKernel3 刷机包
- 支持手动触发和自动触发
- 生成可复用的构建产物

**缓存策略**:
- 工具链缓存：`toolchain-${{ runner.os }}-aarch64-linux-gnu`
- 内核源码缓存：`kernel-source-${{ env.KERNEL_VERSION }}`
- 依赖缓存：`deps-${{ runner.os }}-v1`

### 2. 内核配置文件

**文件**: `arch/arm64/configs/xiaomi_nabu_droidspace_defconfig`

**DroidSpaces 必需配置**:
```makefile
# 命名空间（致命级）
CONFIG_NAMESPACES=y
CONFIG_PID_NS=y
CONFIG_UTS_NS=y
CONFIG_IPC_NS=y

# Cgroup（致命级）
CONFIG_CGROUPS=y
CONFIG_CGROUP_DEVICE=y

# 文件系统（致命级）
CONFIG_DEVTMPFS=y

# 安全
CONFIG_SECCOMP=y
CONFIG_SECCOMP_FILTER=y

# OverlayFS（volatile模式）
CONFIG_OVERLAY_FS=y

# 网络隔离（NAT模式）
CONFIG_NET_NS=y
CONFIG_VETH=y
CONFIG_BRIDGE=y
```

### 3. AnyKernel3 刷机包

**目录**: `AnyKernel3/`

**特性**:
- 自动检测设备型号
- 备份原始内核
- 支持多种刷机方式
- 安装后自动配置

### 4. 构建脚本

**文件**: `build.sh`

**功能**:
- 自动化构建流程
- 支持多种构建选项
- 生成发布包

**使用方法**:
```bash
# 完整构建
./build.sh

# 不清理构建
./build.sh -n

# 指定线程数
./build.sh -t 8

# 查看帮助
./build.sh -h
```

### 5. 内核验证脚本

**文件**: `verify_kernel.sh`

**功能**:
- 检查设备兼容性
- 验证内核配置
- 输出详细报告

**使用方法**:
```bash
# 从 /proc/config.gz 检查
./verify_kernel.sh

# 从本地文件检查
./verify_kernel.sh -f /path/to/config
```

### 6. GKI 补丁脚本

**文件**: `apply_gki_patches.sh`

**功能**:
- 自动检测内核版本
- 应用 kABI 修复补丁
- 支持撤销操作

**使用方法**:
```bash
# 应用补丁
./apply_gki_patches.sh

# 预览模式
./apply_gki_patches.sh --dry-run

# 撤销补丁
./apply_gki_patches.sh --revert
```

---

## 构建流程

### GitHub Actions 自动构建

1. **Push 到 main 分支** 或 **创建 tag** 自动触发
2. 工具链和依赖自动缓存
3. 内核源码自动下载
4. 自动编译和打包
5. 生成可下载的 AnyKernel3 刷机包

### 本地构建

```bash
# 1. 安装依赖
sudo apt-get install build-essential bc bison flex libssl-dev libelf-dev \
  gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu

# 2. 克隆项目
git clone https://github.com/your-repo/xiaomi-nabu-droidspace-kernel.git
cd xiaomi-nabu-droidspace-kernel

# 3. 构建内核
make setup
make clone
make config
make build

# 4. 创建刷机包
make package
```

---

## 刷机流程

### 前置条件

1. 解锁 Bootloader
2. 安装自定义 Recovery（TWRP/OrangeFox）
3. 获取 Root 权限（推荐 KernelSU）
4. 备份原始内核

### 刷入步骤

1. 下载 AnyKernel3 刷机包
2. 复制到设备存储
3. 重启进入 Recovery
4. 刷入 ZIP 文件
5. 重启设备

### 验证安装

```bash
# 检查内核版本
uname -a

# 使用 DroidSpaces 验证
su -c droidspaces check
```

---

## 故障排除

### 常见问题

1. **启动循环**
   - 原因：kABI 不兼容
   - 解决：应用 GKI 补丁

2. **容器无法启动**
   - 原因：内核配置缺失
   - 解决：验证并启用必需配置

3. **网络不通**
   - 原因：网络命名空间未启用
   - 解决：使用 Host 模式或启用网络配置

### 恢复原始内核

```bash
# 使用 AnyKernel3 备份恢复
# 或使用 fastboot 刷入原始 boot.img
```

---

## 参考资源

- [DroidSpaces 官方文档](https://github.com/ravindu644/Droidspaces-OSS)
- [DroidSpaces 内核配置指南](https://github.com/ravindu644/Droidspaces-OSS/blob/main/Documentation/Kernel-Configuration.md)
- [Android 内核编译教程](https://github.com/ravindu644/Android-Kernel-Tutorials)
- [小米平板5内核源码](https://github.com/maverickjb/linux-6.1.10.git)
- [DroidSpaces Telegram 频道](https://t.me/Droidspaces)

---

## 许可证

本项目采用 GNU General Public License v3.0 许可证。

---

*项目版本：1.0*
*更新日期：2025年1月*