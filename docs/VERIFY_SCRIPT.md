# DroidSpaces 内核验证脚本使用指南

## 概述

`verify_kernel.sh` 是一个内核兼容性检查工具，用于验证小米平板5（nabu）的内核是否满足 DroidSpaces 容器运行要求。

## 功能特性

✅ **全面检查** - 检查 30+ 项内核配置
✅ **彩色输出** - 直观的彩色状态显示  
✅ **JSON 报告** - 支持生成机器可读的 JSON 报告
✅ **单项检查** - 支持检查单个配置项
✅ **本地文件** - 支持从本地配置文件读取
✅ **详细模式** - 提供详细的检查说明

## 快速开始

### 1. 在设备上直接运行

```bash
# 推送到设备
adb push verify_kernel.sh /data/local/tmp/
adb shell chmod +x /data/local/tmp/verify_kernel.sh

# 运行检查
adb shell su -c /data/local/tmp/verify_kernel.sh
```

### 2. 使用本地配置文件

```bash
# 首先导出设备的内核配置
adb shell zcat /proc/config.gz > kernel.config

# 然后在本地运行检查
./verify_kernel.sh -c kernel.config
```

## 命令行选项

| 选项 | 说明 | 示例 |
|------|------|------|
| `-c, --config FILE` | 从本地配置文件读取 | `./verify_kernel.sh -c kernel.config` |
| `-s, --single CONFIG` | 检查单个配置项 | `./verify_kernel.sh -s CONFIG_NAMESPACES` |
| `-j, --json` | 输出 JSON 格式报告 | `./verify_kernel.sh -j` |
| `-v, --verbose` | 详细输出模式 | `./verify_kernel.sh -v` |
| `-h, --help` | 显示帮助信息 | `./verify_kernel.sh --help` |

## 检查项目

### 1. 设备信息检查
- 验证设备是否为小米平板5（nabu）

### 2. 内核版本检查
- 最低要求：Linux 3.18
- 推荐版本：Linux 5.4+

### 3. 命名空间支持
**必需配置（致命级）：**
- `CONFIG_NAMESPACES` - 命名空间核心支持
- `CONFIG_PID_NS` - PID 命名空间
- `CONFIG_UTS_NS` - UTS 命名空间
- `CONFIG_IPC_NS` - IPC 命名空间

**可选配置：**
- `CONFIG_NET_NS` - 网络命名空间（NAT 模式必需）
- `CONFIG_USER_NS` - 用户命名空间（Docker 兼容）

### 4. Cgroup 支持
**必需配置（致命级）：**
- `CONFIG_CGROUPS` - Cgroup 核心支持
- `CONFIG_CGROUP_DEVICE` - 设备 Cgroup

**推荐配置：**
- `CONFIG_CGROUP_PIDS` - PID Cgroup
- `CONFIG_MEMCG` - 内存 Cgroup
- `CONFIG_CGROUP_SCHED` - CPU 调度 Cgroup
- `CONFIG_CGROUP_FREEZER` - 冻结器 Cgroup

### 5. 文件系统支持
**必需配置（致命级）：**
- `CONFIG_DEVTMPFS` - 设备临时文件系统

**推荐配置：**
- `CONFIG_OVERLAY_FS` - OverlayFS
- `CONFIG_TMPFS_POSIX_ACL` - Tmpfs POSIX ACL
- `CONFIG_TMPFS_XATTR` - Tmpfs 扩展属性

### 6. 安全支持
- `CONFIG_SECCOMP` - 系统调用过滤
- `CONFIG_SECCOMP_FILTER` - Seccomp BPF 过滤器

### 7. 网络支持（NAT 模式）
- `CONFIG_VETH` - 虚拟以太网设备
- `CONFIG_BRIDGE` - 网桥支持
- `CONFIG_NETFILTER` - 网络过滤器
- `CONFIG_NF_NAT` - NAT 支持
- `CONFIG_NF_TABLES` - nftables

## 输出结果说明

### 状态图标
- ✅ `PASS` - 配置已启用
- ⚠️ `WARN` - 可选配置未启用
- ❌ `FAIL` - 必需配置未启用
- ℹ️ `INFO` - 信息提示

### 兼容性等级
- **完全兼容** - 所有必需配置已启用，可选配置基本完整
- **基本兼容** - 所有必需配置已启用，缺少部分可选配置
- **部分兼容** - 缺少少量必需配置，需要修改内核
- **不兼容** - 缺少多个必需配置，无法正常运行

## JSON 报告格式

```json
{
  "metadata": {
    "tool": "DroidSpaces Kernel Compatibility Checker",
    "version": "1.0.0",
    "timestamp": "2026-08-20T14:33:22Z"
  },
  "device": {
    "expected": "nabu",
    "name": "Xiaomi Pad 5"
  },
  "kernel": {
    "version": "5.4.0",
    "minimum_required": "3.18",
    "recommended": "5.4"
  },
  "compatibility": {
    "level": "fully_compatible",
    "passed": 30,
    "failed": 0,
    "warnings": 2,
    "total": 32
  },
  "checks": {
    "CONFIG_NAMESPACES": "pass",
    "CONFIG_PID_NS": "pass",
    ...
  }
}
```

## 常见用法示例

### 示例 1：完整检查
```bash
./verify_kernel.sh
```

### 示例 2：详细模式
```bash
./verify_kernel.sh -v
```

### 示例 3：生成 JSON 报告
```bash
./verify_kernel.sh -j > report.json
```

### 示例 4：检查单个配置
```bash
./verify_kernel.sh -s CONFIG_OVERLAY_FS
# 输出：CONFIG_OVERLAY_FS=y
```

### 示例 5：使用本地配置文件
```bash
./verify_kernel.sh -c /path/to/kernel.config
```

## 故障排除

### 问题：无法获取内核配置
**解决方案：**
1. 确保在 Android 设备上运行
2. 或使用 `-c` 选项指定本地配置文件
3. 检查 `/proc/config.gz` 是否存在

### 问题：权限不足
**解决方案：**
```bash
adb shell su -c "zcat /proc/config.gz" > kernel.config
./verify_kernel.sh -c kernel.config
```

### 问题：脚本无法执行
**解决方案：**
```bash
chmod +x verify_kernel.sh
```

## 相关资源

- [DroidSpaces-OSS 官方文档](https://github.com/ravindu644/Droidspaces-OSS)
- [DroidSpaces 内核配置指南](https://github.com/ravindu644/Droidspaces-OSS/blob/main/Documentation/Kernel-Configuration.md)
- [小米平板5内核源码](https://github.com/maverickjb/linux-6.1.10.git)

## 许可证

本脚本基于 GPL-2.0 许可证开源。
