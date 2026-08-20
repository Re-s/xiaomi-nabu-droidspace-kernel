# 故障排除

本文档提供常见问题的解决方案和故障排除指南。

## 🔍 常见问题诊断

### 1. 设备无法连接 ADB

**症状**：
```bash
$ adb devices
List of devices attached
(no devices)
```

**解决方案**：

```bash
# 1. 检查 USB 连接
lsusb | grep -i xiaomi

# 2. 重启 ADB 服务
adb kill-server
adb start-server

# 3. 检查 USB 调试是否开启
# 设置 > 开发者选项 > USB 调试

# 4. 检查 USB 驱动（Windows）
# 下载并安装小米 USB 驱动

# 5. 尝试不同的 USB 端口或线缆
```

### 2. 内核刷入失败

**症状**：
```
E: Error executing updater binary in zip
```

**解决方案**：

```bash
# 1. 验证内核文件完整性
md5sum DroidSpacesKernel-nabu-*.zip
# 对比官方发布的 MD5 值

# 2. 重新下载内核文件
wget https://github.com/Re-s/xiaomi-nabu-droidspace-kernel/releases/download/v1.0/DroidSpacesKernel-nabu-YYYYMMDD.zip

# 3. 检查设备型号
adb shell getprop ro.product.model
# 应该显示：Xiaomi Pad 5

# 4. 检查 Android 版本
adb shell getprop ro.build.version.release
# 应该显示：11 或更高
```

### 3. 设备无限重启（Bootloop）

**症状**：
- 设备在开机画面反复重启
- 无法进入系统或 Recovery

**解决方案**：

```bash
# 方法一：进入 Recovery 模式
# 1. 关机
# 2. 同时按住 电源键 + 音量上键
# 3. 进入 TWRP Recovery
# 4. 刷入原厂内核或恢复备份

# 方法二：使用 Fastboot 刷入原厂内核
adb reboot bootloader
fastboot flash boot boot_stock.img
fastboot reboot

# 方法三：使用小米线刷工具
# 1. 下载小米线刷包
# 2. 进入 fastboot 模式
# 3. 使用小米线刷工具刷机
```

### 4. 容器功能无法使用

**症状**：
```bash
$ docker run hello-world
docker: Error response from daemon: linux spec namespace: namespaces: unable to start container process: exec: "hello-world": executable file not found in $PATH
```

**解决方案**：

```bash
# 1. 检查命名空间支持
adb shell ls /proc/sys/kernel/namespaces
# 应该显示：cgroup  ipc  mnt  net  pid  user  uts

# 2. 检查 cgroup 支持
adb shell ls /sys/fs/cgroup/
# 应该有多个 cgroup 目录

# 3. 检查 overlayfs 支持
adb shell lsmod | grep overlay
# 应该显示：overlay

# 4. 手动加载模块（如果需要）
adb shell su -c "modprobe overlay"
adb shell su -c "modprobe br_netfilter"
```

### 5. 性能问题

**症状**：
- 系统运行缓慢
- 应用卡顿
- 电池消耗快

**解决方案**：

```bash
# 1. 检查 CPU 频率
adb shell cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq

# 2. 检查内存使用
adb shell cat /proc/meminfo

# 3. 关闭不必要的内核功能
make menuconfig
# 关闭不需要的驱动和功能

# 4. 调整内核参数
adb shell su -c "echo 1 > /sys/devices/system/cpu/cpufreq/powersave"
```

## 📱 设备特定问题

### 小米平板5 特定问题

#### 1. 触摸屏不灵敏

```bash
# 检查触摸屏驱动
adb shell ls /dev/input/
adb shell getevent -l

# 重新校准触摸屏
# 通常在设备设置中完成
```

#### 2. WiFi 连接问题

```bash
# 检查 WiFi 模块
adb shell lsmod | grep wlan

# 重新加载 WiFi 模块
adb shell su -c "rmmod wlan"
adb shell su -c "modprobe wlan"
```

#### 3. 蓝牙问题

```bash
# 检查蓝牙模块
adb shell lsmod | grep bt

# 重启蓝牙服务
adb shell su -c "service call bluetooth_manager 8"
```

## 📊 日志分析

### 1. 获取内核日志

```bash
# 实时查看内核日志
adb shell dmesg -w

# 保存内核日志到文件
adb shell dmesg > kernel_log.txt

# 查看最后 100 行日志
adb shell dmesg | tail -100
```

### 2. 查找错误信息

```bash
# 查找内核错误
adb shell dmesg | grep -i error

# 查找内核警告
adb shell dmesg | grep -i warning

# 查找 panic 信息
adb shell dmesg | grep -i panic
```

### 3. 系统日志

```bash
# 查看 logcat
adb logcat > logcat.txt

# 查看特定标签的日志
adb logcat -s Kernel:V

# 查看崩溃日志
adb logcat -b crash
```

### 4. 常见错误代码

| 错误代码 | 含义 | 解决方案 |
|----------|------|----------|
| `errno 22` | 无效参数 | 检查命令参数 |
| `errno 13` | 权限被拒绝 | 使用 root 权限 |
| `errno 19` | 没有设备 | 检查设备连接 |
| `errno 28` | 设备空间不足 | 清理存储空间 |

## 🔄 恢复原厂内核

### 方法一：使用官方固件

```bash
# 1. 下载官方固件
# 访问 https://www.miui.com/download.html

# 2. 解压固件
unzip xiaomi_pad5_global_*.zip

# 3. 进入 fastboot 模式
adb reboot bootloader

# 4. 刷入原厂内核
fastboot flash boot boot.img

# 5. 重启设备
fastboot reboot
```

### 方法二：使用 TWRP 恢复

```bash
# 1. 进入 TWRP Recovery
adb reboot recovery

# 2. 选择"恢复"
# 3. 选择之前的备份
# 4. 滑动确认恢复
```

### 方法三：使用小米线刷工具

```bash
# 1. 下载小米线刷工具
# 官网：https://www.miui.com/shuaji.html

# 2. 进入 fastboot 模式
adb reboot bootloader

# 3. 使用线刷工具刷机
# 选择对应的固件包
# 点击"刷机"
```

## 🛠️ 高级调试

### 1. 启用内核调试

```bash
# 重新编译内核，启用调试选项
make menuconfig

# 启用以下选项：
# Kernel hacking
#   → Kernel debugging
#   → Debug filesystem
#   → Debug memory initialisation
#   → Debug linked list manipulation
#   → Debug SRCU (Sleepable RCU) notifications
```

### 2. 使用 GDB 调试内核

```bash
# 1. 编译内核时启用调试信息
make DEBUG_INFO=y

# 2. 启动 QEMU 进行调试
qemu-system-x86_64 -kernel bzImage -append "nokaslr"

# 3. 连接 GDB
gdb vmlinux
(gdb) target remote :1234
```

### 3. 使用 ftrace 跟踪

```bash
# 1. 启用 ftrace
adb shell su -c "echo 1 > /sys/kernel/debug/tracing/tracing_on"

# 2. 设置跟踪事件
adb shell su -c "echo sched_switch > /sys/kernel/debug/tracing/set_event"

# 3. 查看跟踪输出
adb shell cat /sys/kernel/debug/tracing/trace
```

## 📞 获取帮助

### 1. 提交 Issue

在提交 Issue 时，请提供以下信息：

1. **设备型号**：小米平板5 (nabu)
2. **Android 版本**：例如 Android 11
3. **内核版本**：`uname -r` 的输出
4. **错误描述**：详细描述问题
5. **日志信息**：相关的内核日志或 logcat

### 2. 社区支持

- **GitHub Discussions**：在仓库的 Discussions 页面提问
- **XDA Developers**：访问 [XDA 小米平板5 论坛](https://xdadevelopers.com/)
- **Telegram 群组**：加入相关的 Telegram 群组

### 3. 调试信息收集

使用以下命令收集调试信息：

```bash
#!/bin/bash
# debug_info.sh

echo "=== 设备信息 ===" > debug_info.txt
echo "设备型号：$(adb shell getprop ro.product.model)" >> debug_info.txt
echo "Android 版本：$(adb shell getprop ro.build.version.release)" >> debug_info.txt
echo "内核版本：$(adb shell uname -r)" >> debug_info.txt

echo "" >> debug_info.txt
echo "=== 内核日志 ===" >> debug_info.txt
adb shell dmesg >> debug_info.txt

echo "" >> debug_info.txt
echo "=== 系统日志 ===" >> debug_info.txt
adb logcat -d >> debug_info.txt

echo "" >> debug_info.txt
echo "=== 内存信息 ===" >> debug_info.txt
adb shell cat /proc/meminfo >> debug_info.txt

echo "" >> debug_info.txt
echo "=== 网络信息 ===" >> debug_info.txt
adb shell ifconfig >> debug_info.txt

echo "调试信息已保存到 debug_info.txt"
```

## 🔗 相关资源

- [Android 调试文档](https://developer.android.com/studio/debug)
- [内核调试文档](https://www.kernel.org/doc/html/latest/dev-tools/)
- [TWRP 文档](https://twrp.me/faq/faq.html)
- [Magisk 文档](https://topjohnwu.github.io/Magisk/)

---

如果以上方法都无法解决问题，请在 [Issues](https://github.com/Re-s/xiaomi-nabu-droidspace-kernel/issues) 页面提交详细的问题报告。