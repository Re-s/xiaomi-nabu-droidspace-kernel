# 小米平板5（nabu）澎湃OS（HyperOS）内核特性详细分析报告

## 设备概览

| 项目 | 详情 |
|------|------|
| 设备名称 | 小米平板5 |
| 设备代号 | nabu |
| 型号 | 21051182C |
| 处理器 | 高通骁龙860 (SM8150-AC，即 Snapdragon 855+ 变体) |
| 原始系统 | MIUI 12.5/13（基于 Android 11/12） |
| 新系统 | 澎湃OS (HyperOS 1.0，基于 Android 13) |
| 架构 | ARM64 (AArch64) |

---

## 1. 澎湃OS的内核版本和特性

### 1.1 内核版本

**小米平板5（nabu）的 HyperOS 内核版本为 Linux 4.14.190**（perf 标记），这是一个非 GKI（Generic Kernel Image）内核。

这与小米官方开源的 `nabu-r-oss` 分支（内核版本 4.14.180，基于 Android R/11）非常接近，HyperOS 版本在此基础上进行了小幅升级（从 4.14.180 到 4.14.190）。

| 内核来源 | 版本 | 基于 |
|----------|------|------|
| MiCode 官方 `nabu-r-oss` | 4.14.180 | Android R (11)，高通 LA.UM.9.1.r1-07000-SMxxx0.0 |
| HyperOS 1.0 (stock) | 4.14.190-perf | Android T (13)，基于相同高通 BSP |
| Mahiro 社区内核 (hyperos branch) | 4.14.190 | 社区维护版本，支持 RT 抢占 |
| 社区主线移植 (sm8150-mainline) | 5.19 → 6.11 | 完全独立的主线内核，非小米官方 |

### 1.2 澎湃OS 架构说明

澎湃OS（Xiaomi HyperOS）是小米在 2023 年 10 月发布的操作系统，定位为"人车家全生态"操作系统。其架构具有以下特点：

- **手机/平板端**：底层仍然是基于 AOSP（Android Open Source Project）的 Linux 内核，与 MIUI 本质相同
- **IoT/穿戴端**：小米自研的 Vela 系统（基于 NuttX RTOS 微内核），用于智能手表、音箱等资源受限设备
- **跨端互联**：HyperOS 的核心创新在框架层和互联层，而非替换底层 Linux 内核

**关键结论：对于 Xiaomi Pad 5（nabu）而言，HyperOS 的内核仍然是标准的 Android Linux 内核（4.14.x），不存在微内核架构切换。**

### 1.3 HyperOS 版本支持情况

- **HyperOS 1.0**（Android 13，T）：已适配 Xiaomi Pad 5
- **HyperOS 2.0**（Android 14，U）：Xiaomi Pad 5 **不在官方支持列表中**，可能未获得更新
- **HyperOS 3.0/4.0**：更无支持计划

原因分析：Xiaomi Pad 5 使用的 SM8150 平台在高通的 BSP 维护周期已接近尾声，且内核版本 4.14 距离 Android 14+ 的 GKI 要求（5.10+）差距过大。

---

## 2. 小米平板5的内核源码可用性

### 2.1 官方开源源码

小米通过 [MiCode/Xiaomi_Kernel_OpenSource](https://github.com/MiCode/Xiaomi_Kernel_OpenSource) 仓库开源了 Xiaomi Pad 5 的内核源码：

| 分支 | 设备 | Android 版本 | 高通基线标签 |
|------|------|-------------|-------------|
| `nabu-r-oss` | Xiaomi Pad 5 | Android R (11) | LA.UM.9.1.r1-07000-SMxxx0.0 |

**注意事项：**
- 这是小米为 nabu 开源的**唯一**内核分支
- 仅覆盖到 Android R（11），**HyperOS 对应的 Android T（13）版本内核未被开源**
- 使用的 defconfig 文件名为 `nabu_user_defconfig`

### 2.2 社区维护内核

| 项目 | 地址 | 说明 |
|------|------|------|
| Mahiro 内核 | [utziacre/android_kernel_xiaomi_nabu](https://github.com/utziacre/android_kernel_xiaomi_nabu) | 基于 4.14.190，支持 KernelSU，含 RT 抢占补丁 |
| HyperOS KSU 内核 | [DurkaEbanaya/nabu-hyperos-ksu-kernel](https://github.com/DurkaEbanaya/nabu-hyperos-ksu-kernel) | HyperOS 1.0 stock 基础上的 KernelSU-Next 内核 |
| 主线内核移植 | [map220v/sm8150-mainline](https://github.com/map220v/sm8150-mainline) | WIP 状态，已推进到 Linux 6.11，支持 nabu |
| Linux on Xiaomi Pad 5 | [TheMojoMan/xiaomi-nabu](https://github.com/TheMojoMan/xiaomi-nabu) | Linux 发行版磁盘镜像和构建脚本 |
| linux-on-xiaomi-pad-5 | [srikantpatnaik/linux-on-xiaomi-pad-5](https://github.com/srikantpatnaik/linux-on-xiaomi-pad-5) | 移植 GNU/Linux 到 Xiaomi Pad 5 的信息集合 |
| postmarketOS | [sm8150-mainline](https://github.com/sm8150-mainline/linux) | SM8150/855/855+/860 的主线内核 fork |

---

## 3. 澎湃OS对容器支持的情况

### 3.1 Stock HyperOS 内核的容器相关配置

基于对 DurkaEbanaya 的 `kernel.config`（HyperOS 1.0 stock 配置）和 MiCode 官方 `nabu_user_defconfig` 的逐项分析：

#### 命名空间（Namespaces）

| 配置项 | Stock HyperOS 1.0 | 官方 nabu-r-oss | 说明 |
|--------|-------------------|-----------------|------|
| `CONFIG_NAMESPACES=y` | ✅ | ✅ | 通用命名空间支持 |
| `CONFIG_UTS_NS=y` | ✅ | (默认启用) | UTS 命名空间（主机名隔离） |
| `CONFIG_NET_NS=y` | ✅ | (默认启用) | 网络命名空间 |
| `CONFIG_PID_NS is not set` | ❌ **禁用** | ❌ **禁用** | PID 命名空间 **被明确禁用** |
| `CONFIG_USER_NS is not set` | ❌ **禁用** | (未列出) | 用户命名空间 **被明确禁用** |
| `CONFIG_IPC_NS` | (未列出) | (未列出) | IPC 命名空间（4.14 内核默认跟随 NAMESPACES） |
| `CONFIG_CGROUPS=y` | ✅ | ✅ | Cgroups 基础支持 |

**⚠️ 关键发现：PID 命名空间和用户命名空间均被明确禁用。这是容器支持的最大障碍。**

#### Cgroup 控制器

| 配置项 | Stock HyperOS 1.0 | 说明 |
|--------|-------------------|------|
| `CONFIG_CGROUPS=y` | ✅ | Cgroups v1 基础支持 |
| `CONFIG_CGROUP_SCHED=y` | ✅ | CPU 调度控制器 |
| `CONFIG_CGROUP_CPUACCT=y` | ✅ | CPU 记账 |
| `CONFIG_CPUSETS=y` | ✅ | CPU 集（已配置小米自定义分组） |
| `CONFIG_CGROUP_FREEZER=y` | ✅ | 冻结控制器 |
| `CONFIG_CGROUP_BPF=y` | ✅ | BPF cgroup 支持 |
| `CONFIG_BLK_CGROUP=y` | ✅ | 块 I/O 控制器 |
| `CONFIG_MEMCG is not set` | ❌ **禁用** | 内存 cgroup **被禁用** |
| `CONFIG_CGROUP_DEVICE is not set` | ❌ **禁用** | 设备 cgroup **被禁用** |
| `CONFIG_CGROUP_PIDS is not set` | ❌ **禁用** | PID cgroup **被禁用** |
| `CONFIG_CGROUP_PERF is not set` | ❌ **禁用** | 性能监控 cgroup 被禁用 |
| `CONFIG_CGROUP_HUGETLB` | (未列出) | 大页 cgroup 未配置 |

#### 网络与存储

| 配置项 | Stock HyperOS 1.0 | 说明 |
|--------|-------------------|------|
| `CONFIG_VETH is not set` | ❌ **禁用** | 虚拟以太网设备 **被禁用**（Docker/容器必需） |
| `CONFIG_BRIDGE=y` | ✅ | 网桥支持 |
| `CONFIG_BRIDGE_NETFILTER=y` | ✅ | 网桥 netfilter |
| `CONFIG_OVERLAY_FS=y` | ✅ | OverlayFS（容器分层文件系统） |
| `CONFIG_NETFILTER=y` | ✅ | Netfilter/iptables |

### 3.2 与官方 nabu-r-oss (Android R) 的对比

| 配置项 | nabu-r-oss (Android R) | HyperOS 1.0 (stock) | 变化 |
|--------|----------------------|---------------------|------|
| `CONFIG_VETH=y` | ✅ 启用 | ❌ 禁用 | **退化** |
| `CONFIG_MEMCG=y` | ✅ 启用 | ❌ 禁用 | **退化** |
| `CONFIG_MEMCG_SWAP=y` | ✅ 启用 | ❌ 禁用 | **退化** |
| `CONFIG_PID_NS` | ❌ 禁用 | ❌ 禁用 | 保持不变 |
| `CONFIG_OVERLAY_FS=y` | ✅ 启用 | ✅ 启用 | 保持不变 |

**结论：HyperOS 版本相比原始 Android R 版本，在容器相关配置上不进反退。**

---

## 4. 澎湃OS的安全特性

### 4.1 SELinux

| 配置项 | 状态 | 说明 |
|--------|------|------|
| `CONFIG_SECURITY_SELINUX=y` | ✅ 启用 | SELinux 强制启用 |
| `CONFIG_DEFAULT_SECURITY_SELINUX=y` | ✅ | SELinux 为默认安全模块 |
| `CONFIG_SECURITY_SELINUX_DEVELOP=y` | ✅ | 开发模式（可在运行时切换 permissive） |
| `CONFIG_SECURITY_SELINUX_CHECKREQPROT_VALUE=0` | - | 不检查请求保护 |
| `CONFIG_SECURITY_SELINUX_DISABLE` | ❌ 禁用 | 不允许运行时禁用 SELinux |

Xiaomi 在 SELinux 策略上进行了定制化处理：
- 已知 Android 应用需要 `u:object_r:sdcard_external:s0` 等自定义标签
- KernelSU-Next 项目通过补丁实现了 SELinux 策略的"欺骗"（spoofing），使 root 管理器能在 SELinux enforcing 模式下工作

### 4.2 Seccomp

| 配置项 | 状态 | 说明 |
|--------|------|------|
| `CONFIG_SECCOMP=y` | ✅ 启用 | Seccomp 系统调用过滤 |
| `CONFIG_SECCOMP_FILTER=y` | ✅ 启用 | Seccomp BPF 过滤器 |
| `CONFIG_HAVE_ARCH_SECCOMP_FILTER=y` | ✅ | 架构支持 seccomp 过滤器 |

Seccomp 对容器安全至关重要，Docker/Podman 等运行时使用 seccomp 限制容器内的系统调用。该内核完整支持 seccomp。

### 4.3 其他安全特性

- **Android Verified Boot (AVB)**：A/B 分区方案，bootloader 解锁后可刷入自定义内核
- **KASLR**：内核地址空间布局随机化
- **SELinux for KernelSU**：KernelSU-Next 在 4.14 内核上通过手动补丁实现了完整的 SELinux 交互

---

## 5. 命名空间和 Cgroup 支持情况详细分析

### 5.1 PID 命名空间缺失的影响

`CONFIG_PID_NS is not set` 是最严重的容器支持障碍：

1. **Docker/Podman**：需要 PID 命名空间来隔离进程。没有 PID NS，容器内可以看到宿主机的全部进程。
2. **LXC/LXD**：同样依赖 PID 命名空间实现完整的进程隔离。
3. **Android 容器**（如 Docker-Android）：完全无法工作。

### 5.2 用户命名空间缺失的影响

`CONFIG_USER_NS is not set` 意味着：
1. 无法实现非特权容器（rootless containers）
2. 容器内的 root 映射到宿主机的 root，安全性大幅降低
3. Podman rootless 模式完全不可用

### 5.3 VETH 缺失的影响

`CONFIG_VETH is not set` 意味着：
1. Docker 的默认 bridge 网络模式无法创建虚拟以太网对
2. 容器网络隔离无法正常实现
3. 即使禁用 PID NS 的"共享 PID"模式下，网络隔离也是个问题

### 5.4 Cgroup v1 vs v2

Xiaomi Pad 5 的内核使用 **cgroup v1**（基于 `CONFIG_CGROUPS=y` 和各级控制器），不支持 cgroup v2。Docker 较新版本偏好 cgroup v2，但 v1 仍然兼容。

---

## 6. 已知的兼容性问题

### 6.1 容器运行时兼容性

| 运行时 | 是否可运行 | 障碍 |
|--------|-----------|------|
| Docker (root) | ❌ 不行 | 缺少 PID_NS、VETH、MEMCG、CGROUP_DEVICE |
| Docker (rootless) | ❌ 不行 | 缺少 USER_NS、PID_NS、VETH |
| Podman (root) | ❌ 不行 | 缺少 PID_NS、VETH |
| Podman (rootless) | ❌ 不行 | 缺少 USER_NS |
| LXC/LXD | ❌ 不行 | 缺少 PID_NS |
| chroot/proot | ⚠️ 有限 | 可工作但无隔离 |
| termux-proot-distro | ⚠️ 有限 | proot 可模拟，但性能差、功能受限 |

### 6.2 内核版本限制

Linux 4.14 内核相比现代内核（5.10+）缺少：
- cgroup v2 完整支持
- 某些容器所需的系统调用
- eBPF 功能受限（虽然有 `CONFIG_CGROUP_BPF=y`）
- 某些 OverlayFS 特性

### 6.3 存储相关问题

- `CONFIG_SDCARD_FS=y`（in-kernel sdcardfs）与 Android 14+ 的 FUSE 方案冲突
- 这也是为什么该设备难以刷入 Android 14+ 的自定义 ROM 的原因
- stock HyperOS 使用 sdcardfs 避免了 vold 死锁问题

### 6.4 安全启动与解锁

- 需要解锁 bootloader 才能刷入自定义内核
- 小米官方解锁流程需要等待期（通常 7-30 天）
- 解锁后 AVB 验证链断裂，需注意 SafetyNet/Play Integrity 检测

---

## 7. 社区相关的讨论和解决方案

### 7.1 社区项目与解决方案

#### 方案一：使用主线内核运行完整 Linux（推荐用于容器场景）

**sm8150-mainline 项目**已将主线 Linux 内核移植到 Xiaomi Pad 5：

| 分支 | 内核版本 | 状态 |
|------|---------|------|
| nabu-5.19 | Linux 5.19 | 早期移植 |
| nabu-6.0-rc1 | Linux 6.0-rc1 | 开发中 |
| nabu-6.4 | Linux 6.4 | 开发中 |
| nabu-6.6 | Linux 6.6 | 开发中 |
| nabu-6.7 | Linux 6.7 | 开发中 |
| nabu-6.11 | Linux 6.11 | **最新稳定** |

在主线内核下，**所有容器特性均可用**：
- ✅ PID_NS、USER_NS、NET_NS、UTS_NS、IPC_NS 全部启用
- ✅ VETH、MEMCG、CGROUP_DEVICE 全部启用
- ✅ cgroup v2 支持
- ✅ 完整的 Docker/Podman 支持

**参考项目：**
- [TheMojoMan/xiaomi-nabu](https://github.com/TheMojoMan/xiaomi-nabu) — 提供 Ubuntu 等 Linux 发行版的磁盘镜像
- [srikantpatnaik/linux-on-xiaomi-pad-5](https://github.com/srikantpatnaik/linux-on-xiaomi-pad-5) — 移植信息集合
- [ArKT-7/nabu-uefi-autopatcher](https://github.com/ArKT-7/nabu-uefi-autopatcher) — UEFI 引导自动补丁工具（17 stars）
- [timoxa0/LoN-Deployer](https://github.com/timoxa0/LoN-Deployer) — Linux on Nabu 部署器

#### 方案二：在 stock HyperOS 内核上使用 proot

如果不想刷机，可以在 HyperOS 上通过 **proot**（userspace chroot）运行 Linux 容器：

- proot 不需要内核命名空间支持
- 性能较差（ptrace 代理），但不需要解锁 bootloader
- Termux 的 `proot-distro` 提供了一键安装体验
- 适合轻量级开发和测试，不适合生产负载

#### 方案三：在 stock HyperOS 内核上重新编译启用缺失配置

理论上可以通过修改 defconfig 启用容器相关配置：

需要启用的关键配置：
```
CONFIG_PID_NS=y
CONFIG_USER_NS=y
CONFIG_VETH=y
CONFIG_MEMCG=y
CONFIG_MEMCG_SWAP=y
CONFIG_MEMCG_SWAP_ENABLED=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_PIDS=y
```

**风险与限制：**
- 需要解锁 bootloader
- 修改命名空间配置可能影响 Android 系统稳定性（Android 依赖某些特定的 cgroup/namespace 行为）
- 某些配置需要内核代码层面的兼容性检查
- 缺乏社区验证，稳定性未知

### 7.2 社区讨论热点

1. **Arch Linux on Xiaomi Pad 5**：已有完整的教程和视频，使用 ALOHA UEFI 固件启动
2. **KernelSU 支持**：Mahiro 内核和 HyperOS KSU 内核提供了 root 方案
3. **双系统方案**：HyperOS + Arch Linux 双启动已被验证
4. **Windows 模拟**：通过 Box86/Box64 + Wine 在 Linux 下运行 Windows 程序

---

## 8. 综合结论

### 8.1 澎湃OS内核是否支持容器运行？

**直接回答：不支持。**

Stock HyperOS 1.0 的内核（4.14.190-perf）**不具备运行标准容器（Docker/Podman/LXC）的条件**，主要原因：

1. **PID 命名空间被禁用**（`CONFIG_PID_NS is not set`）—— 这是最关键的阻塞项
2. **用户命名空间被禁用**（`CONFIG_USER_NS is not set`）—— 阻止 rootless 容器
3. **VETH 被禁用**（`CONFIG_VETH is not set`）—— 容器网络隔离不可用
4. **MEMCG 被禁用**（`CONFIG_MEMCG is not set`）—— 内存限制不可用
5. **CGROUP_DEVICE 被禁用** —— 设备访问控制不可用

### 8.2 替代方案推荐

| 场景 | 推荐方案 | 复杂度 | 容器支持 |
|------|---------|--------|---------|
| 轻量级 Linux 使用 | proot-distro（无需刷机） | ⭐ 低 | ⚠️ 有限 |
| 完整 Linux 环境 | 刷入主线内核 + Arch Linux | ⭐⭐⭐ 高 | ✅ 完整 |
| root 管理 | KernelSU-Next（stock 内核） | ⭐⭐ 中 | ❌ 无容器 |
| 开发测试 | proot 或 chroot in Termux | ⭐ 低 | ⚠️ 有限 |

### 8.3 如果目标是容器支持

**最佳路径：使用 sm8150-mainline 主线内核（6.11）**

1. UEFI 启动 → 安装 Arch Linux ARM 或 Ubuntu ARM64
2. 主线内核已验证支持所有容器特性
3. Docker/Podman 可正常工作
4. 社区有完整的安装文档和脚本

---

## 附录：关键资源链接

### 官方源码
- [MiCode/Xiaomi_Kernel_OpenSource](https://github.com/MiCode/Xiaomi_Kernel_OpenSource) — nabu-r-oss 分支

### 社区内核
- [map220v/sm8150-mainline](https://github.com/map220v/sm8150-mainline) — 主线内核移植（推荐）
- [utziacre/android_kernel_xiaomi_nabu](https://github.com/utziacre/android_kernel_xiaomi_nabu) — Mahiro 内核
- [DurkaEbanaya/nabu-hyperos-ksu-kernel](https://github.com/DurkaEbanaya/nabu-hyperos-ksu-kernel) — HyperOS + KernelSU

### Linux on Nabu
- [TheMojoMan/xiaomi-nabu](https://github.com/TheMojoMan/xiaomi-nabu) — Linux 磁盘镜像
- [srikantpatnaik/linux-on-xiaomi-pad-5](https://github.com/srikantpatnaik/linux-on-xiaomi-pad-5) — 移植信息
- [ArKT-7/nabu-uefi-autopatcher](https://github.com/ArKT-7/nabu-uefi-autopatcher) — UEFI 补丁工具

### 其他参考
- [postmarketOS SM8150 Wiki](https://wiki.postmarketos.org/wiki/Qualcomm_Snapdragon_855_(SM8150))
- [Linux on Nabu Gitbook](https://linux-on-nabu.gitbook.io/linux-for-mi-pad-5/)
- [Qualcomm SM8150/855/855+/860 Mainline](https://github.com/sm8150-mainline/)

---

*报告生成时间：2026年8月19日*
*数据来源：MiCode 官方仓库、GitHub 社区项目、postmarketOS Wiki、内核配置文件分析*
