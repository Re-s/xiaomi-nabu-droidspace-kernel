# DroidSpaces 内核贡献指南

感谢您对小米平板5（nabu）DroidSpaces 内核项目的关注！本指南将帮助您了解如何参与项目开发、提交代码和贡献文档。

## 📚 目录

1. [项目架构](#项目架构)
2. [开发环境](#开发环境)
3. [贡献流程](#贡献流程)
4. [内核开发指南](#内核开发指南)
5. [文档贡献](#文档贡献)
6. [问题反馈](#问题反馈)

---

## 项目架构

### 目录结构说明

```
xiaomi-nabu-droidspace-kernel/
├── .github/workflows/          # GitHub Actions 自动构建配置
├── AnyKernel3/                 # AnyKernel3 刷机包模板
│   ├── anykernel.sh            # 主刷机脚本
│   └── device_config.sh        # 设备配置文件
├── arch/arm64/configs/         # 内核配置文件
│   └── xiaomi_nabu_droidspace_defconfig  # DroidSpaces 内核配置
├── docs/                       # 项目文档
├── build.sh                    # 主构建脚本
├── Makefile                    # 构建简化接口
└── PROJECT_STRUCTURE.md        # 项目结构详细说明
```

### 核心文件介绍

| 文件 | 作用 | 重要程度 |
|------|------|----------|
| `arch/arm64/configs/xiaomi_nabu_droidspace_defconfig` | DroidSpaces 内核配置，定义了所有必需的内核功能 | ⭐⭐⭐⭐⭐ |
| `build.sh` | 自动化构建脚本，封装了完整的编译流程 | ⭐⭐⭐⭐ |
| `.github/workflows/build-kernel.yml` | GitHub Actions 工作流，实现自动构建和发布 | ⭐⭐⭐⭐ |
| `AnyKernel3/anykernel.sh` | 内核刷入脚本，确保安全安装 | ⭐⭐⭐ |
| `Makefile` | 提供简化的构建命令接口 | ⭐⭐⭐ |

### 构建流程图

```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  代码修改   │───▶│  配置验证    │───▶│  内核编译    │───▶│  刷机包生成  │
└─────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
       │                  │                  │                  │
       ▼                  ▼                  ▼                  ▼
  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │ 提交代码    │    │ 检查必需配置 │    │ 生成 Image   │    │ AnyKernel3   │
  │ 创建 PR     │    │ 验证兼容性   │    │ 生成模块     │    │ 刷机 ZIP     │
  └─────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

**详细构建流程：**
1. **环境准备**：安装交叉编译工具链和依赖
2. **配置阶段**：应用 `xiaomi_nabu_droidspace_defconfig`
3. **编译阶段**：使用 `make -j$(nproc)` 编译内核和模块
4. **打包阶段**：创建 AnyKernel3 刷机包
5. **验证阶段**：使用 `verify_kernel.sh` 检查内核配置

---

## 开发环境

### 必需工具

#### 1. 编译工具链
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
  build-essential \
  bc \
  bison \
  flex \
  libssl-dev \
  libelf-dev \
  gcc-aarch64-linux-gnu \
  binutils-aarch64-linux-gnu \
  git \
  cpio \
  zip \
  unzip \
  python3
```

#### 2. Android 交叉编译工具链
```bash
# 下载 Google 官方工具链
wget https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/heads/android12-release.tar.gz
mkdir -p toolchain
tar -xf android12-release.tar.gz -C toolchain

# 设置环境变量
export CROSS_COMPILE=$(pwd)/toolchain/bin/aarch64-linux-android-
export ARCH=arm64
```

#### 3. 设备调试工具
- **ADB/Fastboot**：Android 调试桥
- **TWRP Recovery**：自定义 Recovery
- **KernelSU**：Root 权限管理（推荐）

### 推荐 IDE 配置

#### VS Code 推荐配置
```json
{
  "recommendations": [
    "ms-vscode.cpptools",
    "twxs.cmake",
    "dotjosh104.gradle-for-java",
    "github.vscode-pull-request-github"
  ]
}
```

**推荐插件：**
- **C/C++**：代码高亮和智能提示
- **Makefile Tools**：Makefile 支持
- **GitLens**：Git 增强功能
- **Error Lens**：内联错误显示

#### JetBrains CLion
- 适用于内核代码深度分析
- 支持 CMake 和 Makefile 项目
- 内置调试器支持

### 调试工具

#### 1. 内核日志分析
```bash
# 实时查看内核日志
adb shell dmesg -w

# 查看完整日志
adb shell dmesg > kernel_log.txt

# 过滤特定模块日志
adb shell dmesg | grep -i "droidspaces"
```

#### 2. 内核配置验证
```bash
# 使用项目提供的验证脚本
./verify_kernel.sh

# 手动检查配置
adb shell cat /proc/config.gz | gunzip | grep -i "NAMESPACE"
```

#### 3. 性能分析工具
- **simpleperf**：CPU 性能分析
- **systrace**：系统级跟踪
- **perfetto**：现代追踪工具

#### 4. 内核调试技巧
```bash
# 启用调试选项
# 在 defconfig 中添加：
# CONFIG_DEBUG_INFO=y
# CONFIG_GDB_SCRIPTS=y
# CONFIG_FRAME_POINTER=y

# 使用 gdb 调试内核
gdb vmlinux
(gdb) target remote :1234
(gdb) break start_kernel
(gdb) continue
```

---

## 贡献流程

### Fork & Pull Request 工作流

#### 1. Fork 项目
```bash
# 在 GitHub 上 Fork 项目
# 然后克隆您的 Fork
git clone https://github.com/YOUR_USERNAME/xiaomi-nabu-droidspace-kernel.git
cd xiaomi-nabu-droidspace-kernel

# 添加上游仓库
git remote add upstream https://github.com/ORIGINAL_OWNER/xiaomi-nabu-droidspace-kernel.git
```

#### 2. 创建功能分支
```bash
# 同步最新代码
git fetch upstream
git checkout main
git merge upstream/main

# 创建功能分支
git checkout -b feature/your-feature-name
# 或修复分支
git checkout -b fix/your-bug-fix
```

#### 3. 提交更改
```bash
# 添加更改
git add .

# 提交（遵循 Commit 规范）
git commit -m "feat: 添加新的容器支持功能"

# 推送到您的 Fork
git push origin feature/your-feature-name
```

#### 4. 创建 Pull Request
1. 访问您的 Fork 页面
2. 点击 "Compare & pull request"
3. 填写 PR 描述模板
4. 等待代码审查

### Commit 规范

我们使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

#### 格式
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

#### 类型说明
- **feat**: 新功能
- **fix**: Bug 修复
- **docs**: 文档更新
- **style**: 代码格式（不影响功能）
- **refactor**: 代码重构
- **perf**: 性能优化
- **test**: 测试相关
- **build**: 构建系统
- **ci**: CI 配置
- **chore**: 其他杂项

#### 示例
```bash
# 新功能
git commit -m "feat(container): 添加 OverlayFS 支持"

# Bug 修复
git commit -m "fix(build): 修复工具链路径检测问题"

# 文档更新
git commit -m "docs: 更新安装指南中的 Recovery 版本要求"

# 重大更改
git commit -m "feat(kernel)!: 更改默认内核配置

BREAKING CHANGE: 移除了对旧版 Android 的支持"
```

### 代码审查要求

#### 审查清单
- [ ] **功能完整性**：更改是否完整实现了预期功能？
- [ ] **代码质量**：代码是否清晰、可读、符合项目风格？
- [ ] **文档更新**：是否更新了相关文档？
- [ ] **测试覆盖**：是否添加了必要的测试？
- [ ] **兼容性**：更改是否影响其他功能？
- [ ] **性能影响**：更改是否对性能有负面影响？
- [ ] **安全考虑**：是否存在安全问题？

#### 审查流程
1. **自动检查**：CI 会自动运行构建和测试
2. **人工审查**：至少需要一位维护者批准
3. **反馈处理**：及时回应审查意见
4. **最终合并**：审查通过后合并到主分支

---

## 内核开发指南

### 如何修改内核配置

#### 1. 配置文件位置
```
arch/arm64/configs/xiaomi_nabu_droidspace_defconfig
```

#### 2. 修改配置的方法
```bash
# 方法一：直接编辑配置文件
vim arch/arm64/configs/xiaomi_nabu_droidspace_defconfig

# 方法二：使用 menuconfig（推荐）
make ARCH=arm64 menuconfig
# 保存后会更新 defconfig

# 方法三：使用 savedefconfig 保存最小配置
make ARCH=arm64 savedefconfig
# 生成的 defconfig 只包含非默认配置
```

#### 3. DroidSpaces 必需配置
**必须启用的配置项：**
```makefile
# 命名空间支持（致命级）
CONFIG_NAMESPACES=y
CONFIG_PID_NS=y
CONFIG_UTS_NS=y
CONFIG_IPC_NS=y
CONFIG_USER_NS=y
CONFIG_NET_NS=y

# Cgroup 支持（致命级）
CONFIG_CGROUPS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CPUSETS=y
CONFIG_MEMCG=y
CONFIG_CGROUP_SCHED=y

# 文件系统支持（致命级）
CONFIG_DEVTMPFS=y
CONFIG_OVERLAY_FS=y
CONFIG_TMPFS=y

# 网络支持
CONFIG_VETH=y
CONFIG_BRIDGE=y
CONFIG_MACVLAN=y

# 安全特性
CONFIG_SECCOMP=y
CONFIG_SECCOMP_FILTER=y
```

#### 4. 配置验证
```bash
# 检查配置是否完整
./verify_kernel.sh

# 手动检查特定配置
grep -E "^CONFIG_(NAMESPACE|CGROUPS|OVERLAY_FS)" arch/arm64/configs/xiaomi_nabu_droidspace_defconfig
```

### 如何测试内核变更

#### 1. 本地测试环境搭建
```bash
# 安装 QEMU 用于初步测试
sudo apt-get install qemu-system-arm

# 下载 Android 镜像（可选）
# 注意：完整 Android 测试需要真实设备
```

#### 2. 基础功能测试
```bash
# 编译测试
./build.sh -n  # 不清理构建

# 配置验证
./verify_kernel.sh

# 代码静态分析
make ARCH=arm64 C=1 -j$(nproc)  # 使用 sparse 检查
```

#### 3. 真实设备测试
```bash
# 刷入测试内核
adb push DroidSpacesKernel-nabu-*.zip /sdcard/
adb reboot recovery
# 在 Recovery 中刷入

# 验证内核版本
adb shell uname -r

# 测试容器支持
adb shell ls /proc/sys/kernel/namespaces
adb shell cat /proc/self/cgroup

# 运行 DroidSpaces 测试
adb shell su -c "droidspaces check"
```

#### 4. 测试清单
- [ ] **启动测试**：设备正常启动，无循环重启
- [ ] **基础功能**：触摸、显示、声音正常
- [ ] **容器功能**：命名空间、cgroup、overlayfs 正常
- [ ] **网络功能**：Wi-Fi、蓝牙、移动网络正常
- [ ] **电源管理**：休眠、唤醒正常
- [ ] **性能测试**：基准测试无显著下降

### 如何提交新功能

#### 1. 功能提案
在提交代码前，建议先创建 Issue 讨论新功能：
```markdown
## 功能提案

### 描述
简要描述新功能

### 动机
为什么需要这个功能

### 实现方案
预计的实现方法

### 测试计划
如何测试这个功能
```

#### 2. 实现步骤
1. **创建功能分支**：`git checkout -b feature/new-feature`
2. **实现功能**：编写代码和测试
3. **更新文档**：添加或更新相关文档
4. **本地测试**：确保功能正常工作
5. **提交 PR**：创建 Pull Request 并填写描述

#### 3. PR 描述模板
```markdown
## 更改描述
简要描述您的更改

## 更改类型
- [ ] 新功能
- [ ] Bug 修复
- [ ] 文档更新
- [ ] 重构
- [ ] 其他

## 测试情况
- [ ] 本地编译通过
- [ ] 配置验证通过
- [ ] 真实设备测试
- [ ] 添加了单元测试

## 相关文档
- [ ] 更新了 README
- [ ] 更新了 BUILDING.md
- [ ] 更新了其他文档

## 截图/日志
（如果适用）
```

---

## 文档贡献

### 文档编写规范

#### 1. 文档结构
```markdown
# 标题

简要介绍

## 目录
（可选）

## 主体内容
### 第一部分
### 第二部分

## 常见问题

## 相关链接

## 贡献者
```

#### 2. Markdown 规范
- 使用中文标点符号
- 代码块指定语言（如 `bash`, `cpp`）
- 使用表格展示结构化数据
- 添加适当的 Emoji 提升可读性

#### 3. 文档位置
- **项目文档**：`docs/` 目录
- **API 文档**：代码内注释
- **示例代码**：`examples/` 目录

### 翻译贡献

#### 1. 翻译流程
1. **选择文档**：选择需要翻译的文档
2. **创建分支**：`git checkout -b docs/translate-document-name`
3. **翻译内容**：保持技术术语准确
4. **提交 PR**：创建翻译 PR

#### 2. 翻译规范
- 保持专业术语一致
- 技术名词保留英文（如 Docker、Kubernetes）
- 代码示例不翻译
- 添加语言标识（如 `[CN]`, `[EN]`）

#### 3. 需要翻译的文档
- [ ] `README.md` → 多语言版本
- [ ] `docs/INSTALLATION.md` → 英文版
- [ ] `docs/BUILDING.md` → 英文版
- [ ] `docs/TROUBLESHOOTING.md` → 英文版

### 示例代码

#### 1. 示例代码规范
```c
/**
 * 示例代码文件
 * 
 * 功能：演示如何使用 DroidSpaces API
 * 作者：Your Name
 * 日期：2025-01-01
 */

#include <stdio.h>
#include <droidspaces.h>

int main() {
    // 示例代码
    printf("DroidSpaces 示例\n");
    return 0;
}
```

#### 2. 示例代码位置
```
examples/
├── basic/           # 基础示例
├── advanced/        # 高级示例
├── containers/      # 容器相关示例
└── networking/      # 网络相关示例
```

---

## 问题反馈

### Bug 报告模板

```markdown
## Bug 报告

### 设备信息
- 设备型号：小米平板5 (nabu)
- Android 版本：
- 内核版本：（uname -a 输出）
- DroidSpaces 版本：

### 问题描述
清晰简洁地描述问题

### 复现步骤
1. 步骤一
2. 步骤二
3. 步骤三

### 期望行为
描述您期望发生什么

### 实际行为
描述实际发生了什么

### 日志信息
```
在此粘贴相关日志
```

### 截图/录屏
（如果适用）

### 其他信息
任何其他有助于诊断问题的信息
```

### 功能请求模板

```markdown
## 功能请求

### 功能描述
清晰简洁地描述您希望的功能

### 动机
为什么需要这个功能？解决什么问题？

### 实现建议
您认为应该如何实现这个功能？

### 替代方案
是否有其他方式可以达到相同目的？

### 附加信息
任何其他相关信息、截图或示例
```

### 社区支持渠道

#### 1. GitHub Issues
- **主要沟通渠道**：[Issues 页面](https://github.com/ORIGINAL_OWNER/xiaomi-nabu-droidspace-kernel/issues)
- **适用场景**：Bug 报告、功能请求、技术问题

#### 2. Telegram 群组
- **DroidSpaces 官方群组**：[t.me/Droidspaces](https://t.me/Droidspaces)
- **实时讨论**：快速问答、经验分享

#### 3. 开发者交流
- **代码审查**：Pull Request 讨论
- **技术讨论**：Issue 中的深度讨论
- **会议记录**：定期开发者会议（如有）

#### 4. 文档反馈
- **文档问题**：在对应文档的 Issue 中反馈
- **改进建议**：直接提交 PR 修复

---

## 🎯 贡献者行为准则

1. **尊重他人**：保持友好和专业的态度
2. **建设性反馈**：提供有帮助的批评和建议
3. **专注质量**：追求代码和文档的高质量
4. **社区优先**：考虑整个社区的利益
5. **持续学习**：不断学习和改进

## 📞 联系我们

- **项目负责人**：请通过 GitHub Issues 联系
- **GitHub**：[@ORIGINAL_OWNER](https://github.com/ORIGINAL_OWNER)
- **Telegram 群组**：[t.me/Droidspaces](https://t.me/Droidspaces)

---

**最后更新**：2025年1月
**版本**：v1.0

感谢您的贡献！🎉