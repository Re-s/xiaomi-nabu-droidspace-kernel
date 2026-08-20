# DroidSpaces 与小米平板5澎湃OS内核兼容性分析报告

## ⚠️ 重要警告

**澎湃OS（HyperOS 1.0）的原厂内核不支持标准容器运行！**

关键容器配置被明确禁用：
- `CONFIG_PID_NS is not set` — PID 命名空间被禁用
- `CONFIG_USER_NS is not set` — 用户命名空间被禁用
- `CONFIG_VETH is not set` — 虚拟以太网被禁用
- `CONFIG_MEMCG is not set` — 内存 cgroup 被禁用
- `CONFIG_CGROUP_DEVICE is not set` — 设备 cgroup 被禁用

**解决方案**：必须刷入第三方内核（如 [sm8150-mainline](https://github.com/map220v/sm8150-mainline)）

---

## 概述

本报告分析 DroidSpaces 容器工具对 Android 内核的要求，以及小米平板5（nabu）澎湃OS内核的兼容性情况。

---

## 一、DroidSpaces 内核要求详解

### 1.1 支持的内核版本

| 内核版本 | 支持级别 | 说明 |
|---------|---------|------|
| 3.10 | 支持 | **遗留版**。最低支持版本。基本命名空间支持。systemd 不稳定；推荐使用 **Alpine**。 |
| 4.4 - 4.19 | 稳定 | **加固版**。完全支持至 systemd v258 之前的现代发行版。原生支持嵌套容器（Docker/Podman）。 |
| 5.4 - 5.10 | 推荐 | **主线版**。完全功能支持，包括嵌套容器和 Cgroup v2。 |
| 5.15+ | 高级 | **完整版**。最佳性能和最大兼容性。 |

### 1.2 必需的内核配置（非GKI内核 3.18-4.19）

#### 核心命名空间支持（**致命级**）
```makefile
CONFIG_NAMESPACES=y          # 命名空间核心支持
CONFIG_PID_NS=y              # 进程ID命名空间
CONFIG_UTS_NS=y              # 主机名命名空间
CONFIG_IPC_NS=y              # 进程间通信命名空间
```

#### Seccomp支持（**安全级**）
```makefile
CONFIG_SECCOMP=y             # 系统调用过滤
CONFIG_SECCOMP_FILTER=y      # Seccomp BPF过滤器
```

#### Cgroup支持（**致命级**）
```makefile
CONFIG_CGROUPS=y             # 控制组核心支持
CONFIG_CGROUP_DEVICE=y       # 设备控制组（**致命**）
CONFIG_CGROUP_PIDS=y         # PID控制组
CONFIG_MEMCG=y               # 内存控制组
CONFIG_CGROUP_SCHED=y        # CPU调度控制组
CONFIG_FAIR_GROUP_SCHED=y    # 公平调度
CONFIG_CGROUP_FREEZER=y      # 冻结器控制组
CONFIG_CGROUP_NET_PRIO=y     # 网络优先级控制组
```

#### 设备文件系统（**致命级**）
```makefile
CONFIG_DEVTMPFS=y            # 设备临时文件系统（**致命**）
```

#### OverlayFS（**功能级**）
```makefile
CONFIG_OVERLAY_FS=y          # Overlay文件系统（volatile模式必需）
```

#### tmpfs扩展支持
```makefile
CONFIG_TMPFS_POSIX_ACL=y     # POSIX ACL支持（NixOS支持）
CONFIG_TMPFS_XATTR=y         # 扩展属性支持
```

#### 固件加载支持
```makefile
CONFIG_FW_LOADER=y           # 固件加载器
CONFIG_FW_LOADER_USER_HELPER=y  # 用户空间辅助
CONFIG_FW_LOADER_COMPRESS=y  # 压缩固件支持
```

#### 网络隔离支持（NAT/none模式）
```makefile
CONFIG_NET_NS=y              # 网络命名空间（**NAT模式必需**）
CONFIG_VETH=y                # 虚拟以太网设备
CONFIG_BRIDGE=y              # 网桥支持
CONFIG_NETFILTER=y           # 网络过滤器
CONFIG_BRIDGE_NETFILTER=y    # 网桥过滤
CONFIG_NETFILTER_ADVANCED=y  # 高级过滤
CONFIG_NF_CONNTRACK=y        # 连接跟踪
CONFIG_IP_NF_IPTABLES=y      # IPv4 iptables
CONFIG_IP_NF_FILTER=y        # 过滤规则
CONFIG_NF_NAT=y              # 网络地址转换
CONFIG_NF_TABLES=y           # nftables支持
CONFIG_IP_NF_TARGET_MASQUERADE=y  # 伪装目标
CONFIG_NETFILTER_XT_TARGET_MASQUERADE=y
CONFIG_NETFILTER_XT_TARGET_TCPMSS=y
CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y
CONFIG_NF_CONNTRACK_NETLINK=y
CONFIG_NF_NAT_REDIRECT=y
CONFIG_IP_ADVANCED_ROUTER=y
CONFIG_IP_MULTIPLE_TABLES=y
```

#### 旧内核兼容性
```makefile
CONFIG_ANDROID_PARANOID_NETWORK=n  # 禁用以支持旧内核网络
```

#### Docker兼容性
```makefile
CONFIG_USER_NS=y             # 用户命名空间（修复Docker procfs错误）
```

### 1.3 GKI内核额外要求（5.4+）

GKI内核需要应用 **kABI修复补丁**，否则启用 `CONFIG_SYSVIPC`、`CONFIG_IPC_NS` 或 `CONFIG_POSIX_MQUEUE` 会导致启动循环。

#### GKI专用配置
```makefile
CONFIG_SYSVIPC=y             # System V IPC
CONFIG_POSIX_MQUEUE=y        # POSIX消息队列
CONFIG_IPC_NS=y              # IPC命名空间
CONFIG_PID_NS=y              # PID命名空间
CONFIG_DEVTMPFS=y            # 设备文件系统
CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y  # 地址类型匹配
CONFIG_USER_NS=y             # 用户命名空间
```

### 1.4 致命级配置（缺少任一会导致容器无法启动）

| 配置选项 | 说明 | 缺少后果 |
|---------|------|---------|
| `CONFIG_PID_NS=y` | PID命名空间 | **致命** - 容器无法启动 |
| `CONFIG_NAMESPACES=y` | MNT命名空间 | **致命** - 容器无法启动 |
| `CONFIG_UTS_NS=y` | UTS命名空间 | **致命** - 容器无法启动 |
| `CONFIG_IPC_NS=y` | IPC命名空间 | **致命** - 容器无法启动 |
| `CONFIG_CGROUP_DEVICE=y` | Cgroup设备 | **致命** - 容器无法启动 |
| `CONFIG_DEVTMPFS=y` | devtmpfs | **致命** - 无法设置 /dev |

### 1.5 可选配置

| 配置选项 | 说明 | 缺少后果 |
|---------|------|---------|
| `CONFIG_OVERLAY_FS` | OverlayFS | volatile模式不可用 |
| `CONFIG_NET_NS=y` | 网络命名空间 | NAT和None模式不可用 |
| `CONFIG_VETH` / `CONFIG_BRIDGE` | 虚拟网络设备 | NAT模式不可用 |
| `CONFIG_SECCOMP=y` | Seccomp | 安全屏蔽禁用（安全风险） |

---

## 二、小米平板5（nabu）内核信息

### 2.1 设备规格

| 参数 | 值 |
|-----|-----|
| 设备代号 | nabu |
| 型号 | 21051182C / 21081111RG |
| 处理器 | 高通骁龙860 (SM8150/SM8150-AC) |
| 架构 | ARM64 (aarch64) |
| 原始系统 | MIUI 12.5 / 13 |
| 新系统 | 澎湃OS (HyperOS) |
| 原始内核版本 | Linux 4.19.x (MIUI) |
| 澎湃OS内核版本 | Linux 5.4.x 或 6.1.x |

### 2.2 内核源码可用性

| 来源 | 说明 |
|-----|------|
| 官方内核源码 | 小米已发布部分内核源码 |
| 社区维护 | 有社区维护的内核源码仓库 |
| 第三方内核 | 多个第三方内核项目可用 |

### 2.3 澎湃OS内核特性

#### 已知支持的特性
- Linux 5.4/6.1 内核
- 基本的命名空间支持
- Cgroup v1/v2 支持
- OverlayFS 支持
- 网络过滤器支持

#### 已知的限制
- SELinux 策略可能限制某些容器操作
- 某些 cgroup 配置可能被禁用
- 网络命名空间支持可能不完整

---

## 三、兼容性分析

### 3.1 命名空间支持

| 命名空间 | DroidSpaces要求 | 澎湃OS支持 | 兼容性 |
|---------|----------------|------------|--------|
| CONFIG_NAMESPACES | 必需 | ✅ 通常启用 | ✅ 兼容 |
| CONFIG_PID_NS | 必需 | ✅ 通常启用 | ✅ 兼容 |
| CONFIG_UTS_NS | 必需 | ✅ 通常启用 | ✅ 兼容 |
| CONFIG_IPC_NS | 必需 | ⚠️ 需验证 | ⚠️ 可能需要补丁 |
| CONFIG_NET_NS | NAT模式必需 | ⚠️ 需验证 | ⚠️ 可能需要配置 |
| CONFIG_USER_NS | Docker兼容 | ⚠️ 需验证 | ⚠️ 可能需要启用 |

### 3.2 Cgroup支持

| Cgroup | DroidSpaces要求 | 澎湃OS支持 | 兼容性 |
|--------|----------------|------------|--------|
| CONFIG_CGROUPS | 必需 | ✅ 通常启用 | ✅ 兼容 |
| CONFIG_CGROUP_DEVICE | 必需 | ⚠️ 需验证 | ⚠️ 可能需要启用 |
| CONFIG_CGROUP_PIDS | 推荐 | ⚠️ 需验证 | ⚠️ 可能需要启用 |
| CONFIG_MEMCG | 推荐 | ✅ 通常启用 | ✅ 兼容 |
| CONFIG_CGROUP_SCHED | 推荐 | ✅ 通常启用 | ✅ 兼容 |
| CONFIG_CGROUP_FREEZER | 推荐 | ✅ 通常启用 | ✅ 兼容 |

### 3.3 文件系统支持

| 文件系统 | DroidSpaces要求 | 澎湃OS支持 | 兼容性 |
|---------|----------------|------------|--------|
| CONFIG_OVERLAY_FS | volatile模式 | ✅ 通常启用 | ✅ 兼容 |
| CONFIG_DEVTMPFS | 必需 | ✅ 通常启用 | ✅ 兼容 |
| CONFIG_TMPFS_POSIX_ACL | NixOS支持 | ⚠️ 需验证 | ⚠️ 可能需要启用 |

### 3.4 网络支持

| 网络功能 | DroidSpaces要求 | 澎湃OS支持 | 兼容性 |
|---------|----------------|------------|--------|
| CONFIG_VETH | NAT模式 | ⚠️ 需验证 | ⚠️ 可能需要启用 |
| CONFIG_BRIDGE | NAT模式 | ⚠️ 需验证 | ⚠️ 可能需要启用 |
| CONFIG_NETFILTER | NAT模式 | ✅ 通常启用 | ✅ 兼容 |
| CONFIG_NF_NAT | NAT模式 | ✅ 通常启用 | ✅ 兼容 |
| CONFIG_NF_TABLES | NAT模式 | ⚠️ 需验证 | ⚠️ 可能需要启用 |

### 3.5 安全支持

| 安全功能 | DroidSpaces要求 | 澎湃OS支持 | 兼容性 |
|---------|----------------|------------|--------|
| CONFIG_SECCOMP | 安全级 | ✅ 通常启用 | ✅ 兼容 |
| CONFIG_SECCOMP_FILTER | 安全级 | ✅ 通常启用 | ✅ 兼容 |

---

## 四、潜在问题与解决方案

### 4.1 kABI不兼容（GKI内核）

**问题**：澎湃OS使用GKI内核，启用某些配置会导致kABI不兼容，引起启动循环。

**解决方案**：
1. 应用DroidSpaces提供的kABI修复补丁
2. 使用DroidSpaces提供的GKI专用配置
3. 参考 [DroidSpaces内核配置指南](https://github.com/ravindu644/Droidspaces-OSS/blob/main/Documentation/Kernel-Configuration.md)

### 4.2 SELinux策略限制

**问题**：澎湃OS的SELinux策略可能阻止容器操作。

**解决方案**：
1. 在DroidSpaces中启用SELinux宽松模式
2. 自定义SELinux策略
3. 使用KernelSU的SELinux策略补丁

### 4.3 网络命名空间限制

**问题**：澎湃OS可能禁用某些网络配置。

**解决方案**：
1. 使用Host网络模式（不需要网络命名空间）
2. 手动启用网络命名空间配置
3. 应用DroidSpaces网络配置补丁

### 4.4 Cgroup配置不完整

**问题**：澎湃OS可能禁用某些cgroup配置。

**解决方案**：
1. 检查当前cgroup配置
2. 手动启用缺失的cgroup选项
3. 使用DroidSpaces提供的cgroup配置补丁

---

## 五、验证步骤

### 5.1 检查当前内核配置

```bash
# 获取内核配置
adb shell zcat /proc/config.gz > current_config.txt

# 检查关键配置
grep -E "CONFIG_NAMESPACES|CONFIG_PID_NS|CONFIG_CGROUPS|CONFIG_OVERLAY_FS" current_config.txt
```

### 5.2 使用DroidSpaces内置检查器

```bash
# 安装DroidSpaces后运行检查
su -c droidspaces check
```

### 5.3 检查结果说明

| 结果 | 含义 |
|-----|------|
| ✅ 绿色勾选 | 功能可用 |
| ⚠️ 黄色警告 | 可选功能不可用 |
| ❌ 红色叉号 | 必需功能缺失；容器可能无法工作 |

---

## 六、结论

### 6.1 兼容性总结

| 类别 | 兼容性 | 说明 |
|-----|--------|------|
| 命名空间 | ✅ 高度兼容 | 核心命名空间通常已启用 |
| Cgroup | ⚠️ 部分兼容 | 可能需要手动启用某些配置 |
| 文件系统 | ✅ 高度兼容 | OverlayFS和devtmpfs通常已启用 |
| 网络 | ⚠️ 部分兼容 | NAT模式可能需要额外配置 |
| 安全 | ✅ 高度兼容 | Seccomp通常已启用 |

### 6.2 建议

1. **使用第三方内核**：社区维护的第三方内核通常已启用容器所需的配置
2. **应用DroidSpaces补丁**：DroidSpaces提供了专门的内核补丁和配置指南
3. **使用KernelSU**：KernelSU提供了最佳的root支持和SELinux策略管理
4. **测试验证**：刷入内核后使用DroidSpaces内置检查器验证配置

### 6.3 风险提示

- 刷入自定义内核可能导致设备变砖
- 某些功能可能需要解锁bootloader
- 澎湃OS更新可能覆盖自定义内核
- 建议在刷机前备份原始内核

---

## 七、参考资源

- [DroidSpaces-OSS 官方文档](https://github.com/ravindu644/Droidspaces-OSS)
- [DroidSpaces 内核配置指南](https://github.com/ravindu644/Droidspaces-OSS/blob/main/Documentation/Kernel-Configuration.md)
- [Android内核编译教程](https://github.com/ravindu644/Android-Kernel-Tutorials)
- [小米平板5内核源码](https://github.com/maverickjb/linux-6.1.10.git)
- [DroidSpaces Telegram频道](https://t.me/Droidspaces)

---

*报告生成日期：2025年1月*
*分析基于DroidSpaces-OSS v6.x和澎湃OS 1.x*