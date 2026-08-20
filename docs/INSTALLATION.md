# 安装指南

本文档提供详细的内核刷机步骤，适用于小米平板5（nabu）设备。

## 📋 前置条件

在开始之前，请确保满足以下条件：

### 1. 解锁 Bootloader

小米设备需要先解锁 Bootloader 才能刷入自定义内核：

```bash
# 1. 申请小米解锁权限
# 访问 https://www.miui.com/unlock/index.html 申请解锁

# 2. 安装小米解锁工具
# 下载地址：https://www.miui.com/unlock/download.html

# 3. 连接设备到电脑
adb devices

# 4. 进入 fastboot 模式
adb reboot bootloader

# 5. 使用小米解锁工具解锁
# 注意：需要等待小米官方审批（通常需要几天时间）
```

### 2. 安装自定义 Recovery

推荐使用 TWRP Recovery：

```bash
# 下载适用于 nabu 的 TWRP
# 官网：https://twrp.me/xiaomi/xiaomipad5.html

# 刷入 TWRP
fastboot flash recovery twrp-3.x.x-x-nabu.img

# 重启到 recovery
fastboot reboot recovery
```

### 3. 安装 ADB 和 Fastboot

确保电脑已安装 Android SDK Platform Tools：

```bash
# Ubuntu/Debian
sudo apt-get install android-tools-adb android-tools-fastboot

# Windows
# 下载地址：https://developer.android.com/tools/releases/platform-tools

# macOS
brew install android-platform-tools
```

### 4. 设备连接检查

```bash
# 检查设备连接
adb devices

# 应该显示类似：
# List of devices attached
# XXXXXXXX    device

# 如果显示 unauthorized，请在设备上授权 USB 调试
```

## 📥 下载内核

### 从 GitHub Releases 下载

1. 访问 [Releases](https://github.com/Re-s/xiaomi-nabu-droidspace-kernel/releases) 页面
2. 下载最新版本的 `DroidSpacesKernel-nabu-*.zip` 文件
3. 验证文件完整性（可选）

### 验证下载文件

```bash
# 检查文件大小（应该大于 10MB）
ls -lh DroidSpacesKernel-nabu-*.zip

# 验证 MD5（如果有提供）
md5sum DroidSpacesKernel-nabu-*.zip
```

## 🔧 刷机步骤

### 方法一：使用 TWRP Recovery（推荐）

#### 步骤 1：传输内核文件到设备

```bash
# 连接设备到电脑
adb devices

# 传输内核文件到设备存储
adb push DroidSpacesKernel-nabu-*.zip /sdcard/

# 确认文件传输成功
adb shell ls -lh /sdcard/DroidSpacesKernel-nabu-*.zip
```

#### 步骤 2：重启到 Recovery 模式

```bash
# 重启到 recovery 模式
adb reboot recovery

# 或者使用组合键：
# 关机状态下，同时按住 电源键 + 音量上键
```

#### 步骤 3：刷入内核

1. 在 TWRP 主界面，点击 **"安装"**
2. 导航到 `/sdcard/` 目录
3. 选择 `DroidSpacesKernel-nabu-*.zip` 文件
4. 滑动确认刷入
5. 等待刷入完成（通常需要 1-3 分钟）

#### 步骤 4：重启设备

```bash
# 刷入完成后，重启设备
# 在 TWRP 中点击"重启系统"
# 或者执行：
adb reboot
```

### 方法二：使用 Fastboot 刷入

如果你无法进入 Recovery 模式，可以使用 Fastboot：

```bash
# 1. 解压内核包
unzip DroidSpacesKernel-nabu-*.zip

# 2. 进入 fastboot 模式
adb reboot bootloader

# 3. 刷入内核镜像（如果有 boot.img）
fastboot flash boot boot.img

# 4. 重启设备
fastboot reboot
```

### 方法三：使用 ADB Sideload

```bash
# 1. 进入 Recovery 模式
adb reboot recovery

# 2. 在 TWRP 中选择"高级" -> "ADB Sideload"

# 3. 在电脑上执行
adb sideload DroidSpacesKernel-nabu-*.zip

# 4. 等待传输和刷入完成
```

## ✅ 刷入后配置

### 1. 验证内核版本

```bash
# 重启后检查内核版本
adb shell uname -r

# 应该显示类似：
# 5.10.xx-droidspaces-nabu
```

### 2. 检查容器支持功能

```bash
# 检查命名空间支持
adb shell ls /proc/sys/kernel/namespaces

# 检查 cgroup 支持
adb shell ls /sys/fs/cgroup/

# 检查 overlayfs 支持
adb shell lsmod | grep overlay
```

### 3. 安装 DroidSpaces

```bash
# 克隆 DroidSpaces 仓库
git clone https://github.com/nickcano/droidspaces.git
cd droidspaces

# 按照 DroidSpaces 文档进行安装
# 通常需要：
# 1. 安装 root 权限管理器（如 Magisk）
# 2. 启用必要的内核模块
# 3. 配置容器运行时
```

### 4. 启用必要的内核模块

```bash
# 检查可用模块
adb shell ls /vendor/lib/modules/

# 加载必要模块（如果需要）
adb shell su -c "modprobe <模块名>"
```

## 🔄 系统优化

### 1. 清除缓存

```bash
# 在 Recovery 中执行
# 1. 进入 TWRP
# 2. 选择"清除"
# 3. 执行"滑动恢复出厂设置"（可选）
# 4. 执行"高级清除" -> 勾选"Dalvik/ART Cache"和"Cache"
```

### 2. 调整内核参数

```bash
# 查看当前内核参数
adb shell cat /proc/cmdline

# 临时调整参数（重启后失效）
adb shell su -c "echo '参数' > /proc/sys/kernel/参数名"

# 永久调整需要修改 init.rc 或使用工具如 Kernel Adiutor
```

## 📱 设备特定设置

### 小米平板5 特定优化

1. **性能模式**：在设置中启用高性能模式
2. **电池优化**：将 DroidSpaces 相关应用加入电池优化白名单
3. **存储空间**：确保至少有 2GB 可用空间用于容器运行

## ⚠️ 注意事项

1. **首次启动可能较慢**：内核更新后首次启动可能需要更长时间
2. **数据安全**：刷机过程不会丢失用户数据，但建议备份
3. **保修问题**：刷入自定义内核可能影响设备保修
4. **恢复原厂**：如需恢复，请参考 [故障排除](TROUBLESHOOTING.md) 中的恢复原厂内核部分

## 🔗 相关链接

- [AnyKernel3 刷入工具](https://github.com/osm0sis/AnyKernel3)
- [TWRP Recovery](https://twrp.me/)
- [Magisk Root](https://github.com/topjohnwu/Magisk)
- [DroidSpaces 项目](https://github.com/nickcano/droidspaces)

---

如果遇到问题，请查看 [故障排除](TROUBLESHOOTING.md) 文档或在 [Issues](https://github.com/Re-s/xiaomi-nabu-droidspace-kernel/issues) 页面提交问题。