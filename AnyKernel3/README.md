# AnyKernel3 for Xiaomi Pad 5 (nabu) - DroidSpaces Kernel

## 概述

本 AnyKernel3 配置用于将 DroidSpaces 内核刷入 **Xiaomi Pad 5 (nabu)**。DroidSpaces 内核基于 Linux 5.15，并添加了容器支持（Linux Namespaces、Cgroups、OverlayFS、FUSE 等），允许在 Android 上运行完整的 Linux 容器。

## 支持的设备

| 设备名称 | 型号 | 代号 |
|---------|------|------|
| Xiaomi Pad 5 | 21051182C | nabu |
| Xiaomi Pad 5 | 21081111RG | nabu |
| Xiaomi Pad 5 | 2201123C | nabu |
| Xiaomi Pad 5 Pro | 21091116C | nabu |

## 前置要求

1. **已解锁 Bootloader** - 使用小米官方解锁工具
2. **已刷入自定义 Recovery** - 推荐使用 [TWRP](https://twrp.me/xiaomi/xiaomipad5.html) 或 OrangeFox
3. **备份** - 刷机前务必备份原始 boot.img

## 目录结构

```
AnyKernel3/
├── anykernel.sh          # AnyKernel3 主脚本
├── device_config.sh      # 设备配置脚本
├── README.md             # 本文件
└── tools/
    ├── anykernel1.sh     # AnyKernel3 核心函数库
    └── mkbootimg_wrapper # mkbootimg 包装脚本
```

## 使用方法

### 方法一：通过 Recovery 刷入（推荐）

1. **打包 AnyKernel3 zip**：
   ```bash
   cd AnyKernel3
   # 确保目录下有 kernel 文件（Image 或 zImage）
   zip -r9 ../DroidSpaces-nabu-kernel.zip . -x "*.git*"
   ```

2. **传输到设备**：
   ```bash
   adb push DroidSpaces-nabu-kernel.zip /sdcard/
   ```

3. **进入 Recovery 刷入**：
   - 关机
   - 同时按住 **音量上 + 电源键** 进入 TWRP Recovery
   - 点击 **Install**
   - 选择 `/sdcard/DroidSpaces-nabu-kernel.zip`
   - 滑动确认刷入
   - 等待安装完成
   - 选择 **Reboot System**

### 方法二：通过 ADB 手动刷入

1. **使用 mkbootimg_wrapper 生成 boot.img**：
   ```bash
   cd AnyKernel3
   chmod +x tools/mkbootimg_wrapper
   ./tools/mkbootimg_wrapper \
     --kernel ../arch/arm64/boot/Image \
     --ramdisk ../arch/arm64/boot/ramdisk.cpio.gz \
     --output ../boot.img
   ```

2. **刷入 boot.img**：
   ```bash
   adb reboot bootloader
   fastboot flash boot ../boot.img
   fastboot reboot
   ```

## AnyKernel3 工具

### mkbootimg_wrapper

`tools/mkbootimg_wrapper` 是一个封装脚本，内置了 SM8150 平台的正确参数：

```bash
./tools/mkbootimg_wrapper --help

# 用法示例：
./tools/mkbootimg_wrapper \
  --kernel ../arch/arm64/boot/Image \
  --ramdisk ramdisk.cpio.gz \
  --dtb ../arch/arm64/boot/dtb.img \
  --dtbo ../arch/arm64/boot/dtbo.img \
  --output ../boot.img
```

内置参数（适用于 Xiaomi Pad 5 / SM8150）：
- `--base 0x0`
- `--pagesize 4096`
- `--kernel_offset 0x00008000`
- `--ramdisk_offset 0x01f88000`
- `--tags_offset 0x00000100`
- `--header_version 2`
- `--cmdline console=ttyMSM0,115200n8 androidboot.hardware=qcom ...`

## 内核安装后

刷入完成后首次启动可能需要 2-3 分钟。安装完成后的功能特性：

- **Linux Namespaces** (UTS, IPC, PID, NET, USER, CGROUP)
- **Cgroups** 资源管理
- **OverlayFS** 容器层支持
- **网络桥接与 veth** 支持
- **FUSE 文件系统** 支持
- **Seccomp** 安全过滤
- **Checkpoint/Restore** 支持
- **Device Mapper** (dm-crypt, dm-thin)

## 回滚

如需恢复原始内核：
```bash
# 使用之前备份的 boot.img
adb reboot bootloader
fastboot flash boot boot_backup.img
fastboot reboot
```

## 故障排除

### 无法进入系统（Bootloop）
1. 进入 TWRP Recovery
2. 挂载 System 和 Data
3. 删除 `/data/dalvik-cache/*`
4. 清除 Cache / Dalvik Cache
5. 如果仍然无法启动，刷入备份的 boot.img

### 触摸屏不工作
这通常与 DTB/DTBO 不匹配有关。请确保使用的内核与当前系统版本兼容。

### WiFi/蓝牙不工作
确认 WiFi/BT 固件（fwcnss*）文件存在于 `/vendor/firmware/`。

## 免责声明

- 刷入自定义内核可能使设备失去保修
- 请确保理解风险后再进行操作
- 本项目仅用于学习和研究目的
- 刷机有风险，请谨慎操作