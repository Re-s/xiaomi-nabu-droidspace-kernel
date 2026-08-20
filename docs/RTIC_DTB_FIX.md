# RTIC DTB 修复：第三方内核包缺失 qcom,rtic-id 节点

适用设备：小米平板 5（nabu / SM8150），HyperOS 1.0.3.0.TKXCNXM

## 问题

部分第三方 AnyKernel3 内核包重新编译 dtb 时只保留了平台 FDT，
丢失了原厂 dtb 尾部一个 173 字节的 FDT。该 FDT 内容为：

```
node ''
  qcom,rtic-id = <0x00000001>
  MP_DATA = '0000b00980ffffff0000a8010000000088050000838b7003...'
```

这是高通 RTIC（Real Time Integrity Checker，运行时完整性检查）的度量数据。

对比实例（`nabu_Hyperos1_KernelSU-Next_anykernel3.zip`，
md5 `fda41e0114dc2aaef0a5e549bfa1ce53`）：

| | FDT 数量 | 尾部 RTIC FDT | dtb 大小 |
|---|---|---|---|
| 原厂 `vendor_boot.img` 内的 dtb | 5 | 有（173 B，md5 `5050b998160bce8f6aad92683b2ad9f7`） | 1995141 |
| 第三方包内的 dtb | 4 | **缺失** | 1998328 |
| 修复后 | 5 | 已追加 | 1998501 |

## 平台背景

nabu 使用 **boot header v3** 布局，这一点决定了 dtb 的存放位置：

- `boot` 分区：v3 头**没有** `dtb_size` 字段，dtb 不在这里
- `vendor_boot` 分区：`dtb_size` 位于头部偏移 2100，dtb 段紧随
  `vendor_ramdisk` 之后（页对齐）

因此 AnyKernel3 脚本中操作 `vendor_boot` 的部分是**必需**的，
它正是用来替换 dtb 的：

```sh
block=/dev/block/bootdevice/by-name/vendor_boot;
is_slot_device=1;
reset_ak;
dump_boot;
write_boot;
```

dtb 本身是多个 FDT **顺序拼接的裸格式**（无索引表），所以修复方式
就是把缺失的 FDT 追加到尾部，不需要重新编译。

## 用法

```bash
# 1. 解包第三方 AnyKernel3 zip
mkdir work && cd work && unzip ../third_party_kernel.zip && cd ..

# 2. 从原厂线刷包取 vendor_boot.img，修复 dtb
python3 fix_rtic_dtb.py \
    /path/to/stock/images/vendor_boot.img \
    work/dtb \
    work/dtb.fixed

# 3. 替换并重新打包（zip 根目录必须直接是这些文件）
mv work/dtb.fixed work/dtb
cd work && zip -r9 -X ../fixed_kernel.zip . && cd ..
```

脚本会打印两侧 FDT 明细并在写出后复验结构，退出码：

| 退出码 | 含义 |
|---|---|
| 0 | 修复成功，结构校验通过 |
| 1 | 输入不合法（非 vendor_boot、RTIC FDT 数量异常、复验失败） |
| 2 | 参数错误或文件不存在 |
| 3 | 目标 dtb 已含 RTIC FDT，跳过（幂等） |

## 诊断方法

判断一个 dtb 是否缺 RTIC 节点，扫描拼接的 FDT 序列即可。注意要按每个
FDT 头声明的 `totalsize` 推进并校验头部字段，否则会把内核数据里偶然
出现的 `d00dfeed` 误判为 FDT 起点：

```bash
python3 fix_rtic_dtb.py stock/vendor_boot.img suspect/dtb /dev/null
```

输出中 `[待修dtb]` 一节若只有 4 个 FDT 且无 `<- RTIC` 标记，即为缺失。

读取设备上 `vendor_boot` 当前的 dtb 状态（只读，需要 root 或 recovery）：

```bash
adb shell 'dd if=/dev/block/by-name/vendor_boot_a bs=4096 count=2' | \
    od -A d -t x1 | head
# 头部偏移 2100 处的小端 u32 即 dtb_size
```

## 有效性说明

**本修复的必要性未经对照实验证实。**

已确认的事实：

- 原厂 dtb 确有该 FDT，第三方包确实缺失（可复现，见上表 md5）
- 追加后 zip 能被 AnyKernel3 正常处理，设备可正常启动

未能确认的部分：

- `MP_DATA` 中的度量值对应原厂 `4.14.180-perf` 内核，而第三方内核为
  `4.14.336`。若 RTIC 严格校验内核哈希，该度量值对新内核并不匹配；
  若 RTIC 仅要求节点存在（软失败），补回即可。目前无证据区分两者。
- 排查过程中发现的另一个故障（boot 分区 ramdisk 区被写成高熵数据，
  导致 `magiskboot` 报 `cpio: unsupported cpio format` 而
  `dump_boot` 中止）与本 dtb 问题**相互独立**。该故障通过回刷原厂
  `boot.img` 解决。因此无法归因于 RTIC 缺失。

要证明 RTIC FDT 的必要性，需要在健康的 boot 分区上分别刷未修复包与
修复包做对照。考虑到失败代价（设备落入 EDL），未进行该实验。

## 刷写前建议

```bash
# 备份两个关键分区，出问题可十分钟回滚
adb shell 'dd if=/dev/block/by-name/boot_a of=/sdcard/boot_a_backup.img'
adb shell 'dd if=/dev/block/by-name/vendor_boot_a of=/sdcard/vb_a_backup.img'

# 确认活动槽位
adb shell getprop ro.boot.slot_suffix
```

刷第三方 AnyKernel3 包前，先检查 `anykernel.sh` 里声明的 `block=`
目标；凡是操作了 zip 内并无对应镜像的分区，需要确认脚本是否依赖
`dump_boot` 从设备现有分区取内容，还是确实缺料。
