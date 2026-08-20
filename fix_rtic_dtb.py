#!/usr/bin/env python3
# ============================================
# RTIC DTB Fixer for Xiaomi Pad 5 (nabu)
# 小米平板5 dtb RTIC 节点修复工具
# ============================================
# 版本: 1.0.0
#
# 用途:
#   部分第三方内核包在重新编译 dtb 时只保留了平台 FDT，
#   丢失了原厂 dtb 尾部的 qcom,rtic-id / MP_DATA 节点
#   （高通 RTIC 运行时完整性检查的度量数据）。
#   本工具从原厂 vendor_boot.img 提取该 FDT，追加回目标 dtb。
#
# 背景:
#   nabu 使用 boot header v3 布局，dtb 存放在 vendor_boot 分区内，
#   而非 boot 分区。boot v3 头没有 dtb_size 字段。
#
# 用法:
#   python3 fix_rtic_dtb.py <原厂vendor_boot.img> <待修dtb> <输出dtb>
#
# 示例:
#   # 1. 解包第三方 AnyKernel3 zip
#   unzip -d work third_party_kernel.zip
#   # 2. 修复 dtb
#   python3 fix_rtic_dtb.py stock/vendor_boot.img work/dtb work/dtb.fixed
#   # 3. 替换并重新打包
#   mv work/dtb.fixed work/dtb
#   (cd work && zip -r9 ../fixed_kernel.zip .)
# ============================================

import hashlib
import os
import struct
import sys

FDT_MAGIC = b"\xd0\x0d\xfe\xed"
VENDOR_BOOT_MAGIC = b"VNDRBOOT"
RTIC_MARKER = b"qcom,rtic-id"

# vendor_boot header v3/v4 字段偏移
VB_OFF_HEADER_SIZE = 2096
VB_OFF_DTB_SIZE = 2100


def scan_fdts(buf):
    """
    严格扫描拼接的 FDT 序列。

    dtb 是多个 FDT 顺序拼接的裸格式（无索引表），因此按每个 FDT
    头声明的 totalsize 推进，并校验头部字段合法性，避免把内核数据
    里偶然出现的 d00dfeed 误判为 FDT 起点。
    """
    found = []
    i = 0
    while i < len(buf) - 40:
        if buf[i:i + 4] == FDT_MAGIC:
            totalsize, off_struct, off_strings, off_rsvmap, version, last_comp = \
                struct.unpack(">6I", buf[i + 4:i + 28])
            size_strings, size_struct = struct.unpack(">2I", buf[i + 32:i + 40])
            valid = (
                0 < totalsize <= len(buf) - i
                and version in (16, 17)
                and last_comp == 16
                and off_struct + size_struct <= totalsize
                and off_strings + size_strings <= totalsize
            )
            if valid:
                found.append({
                    "offset": i,
                    "size": totalsize,
                    "version": version,
                    "data": buf[i:i + totalsize],
                })
                i += totalsize
                continue
        i += 1
    return found


def extract_stock_dtb(vendor_boot_path):
    """从 vendor_boot.img 中提取 dtb 段。"""
    with open(vendor_boot_path, "rb") as fh:
        vb = fh.read()

    if vb[:8] != VENDOR_BOOT_MAGIC:
        raise ValueError(f"{vendor_boot_path}: 不是 vendor_boot 镜像 "
                         f"(魔数 {vb[:8]!r}，应为 {VENDOR_BOOT_MAGIC!r})")

    header_version, page_size, _kaddr, _raddr, vendor_ramdisk_size = \
        struct.unpack("<5I", vb[8:28])
    header_size, dtb_size = struct.unpack(
        "<2I", vb[VB_OFF_HEADER_SIZE:VB_OFF_HEADER_SIZE + 8])

    if header_version < 3:
        raise ValueError(f"vendor_boot header v{header_version} 不受支持（需要 v3/v4）")
    if dtb_size == 0:
        raise ValueError("vendor_boot 中 dtb_size 为 0，无 dtb 可提取")

    def page_align(n):
        return (n + page_size - 1) // page_size * page_size

    dtb_offset = page_align(page_align(header_size) + vendor_ramdisk_size)

    print(f"[原厂] {os.path.basename(vendor_boot_path)}")
    print(f"       header_version={header_version} page_size={page_size}")
    print(f"       vendor_ramdisk_size={vendor_ramdisk_size}")
    print(f"       dtb @0x{dtb_offset:x} size={dtb_size}")

    return vb[dtb_offset:dtb_offset + dtb_size]


def report(label, fdts, total_len):
    covered = sum(f["size"] for f in fdts)
    print(f"[{label}] {len(fdts)} 个 FDT，覆盖 {covered}/{total_len} 字节"
          f"{'' if covered == total_len else '  ← 有未覆盖残留'}")
    for idx, f in enumerate(fdts):
        tag = "  <- RTIC" if RTIC_MARKER in f["data"] else ""
        digest = hashlib.md5(f["data"]).hexdigest()[:16]
        print(f"       #{idx} off=0x{f['offset']:<8x} size={f['size']:<8} "
              f"md5={digest}{tag}")


def main():
    if len(sys.argv) != 4:
        print(__doc__ or "")
        print("用法: fix_rtic_dtb.py <原厂vendor_boot.img> <待修dtb> <输出dtb>")
        return 2

    vendor_boot_path, target_dtb_path, output_path = sys.argv[1:4]

    for p in (vendor_boot_path, target_dtb_path):
        if not os.path.isfile(p):
            print(f"错误: 找不到文件 {p}")
            return 2

    # 1. 从原厂 vendor_boot 取出 dtb 并定位 RTIC FDT
    try:
        stock_dtb = extract_stock_dtb(vendor_boot_path)
    except (ValueError, struct.error) as exc:
        print(f"错误: {exc}")
        return 1
    stock_fdts = scan_fdts(stock_dtb)
    report("原厂dtb", stock_fdts, len(stock_dtb))

    rtic = [f for f in stock_fdts if RTIC_MARKER in f["data"]]
    if len(rtic) != 1:
        print(f"错误: 原厂 dtb 中找到 {len(rtic)} 个 RTIC FDT，预期恰好 1 个")
        return 1
    rtic = rtic[0]
    print(f"\n[RTIC] size={rtic['size']} "
          f"md5={hashlib.md5(rtic['data']).hexdigest()}")

    # 2. 检查目标 dtb
    with open(target_dtb_path, "rb") as fh:
        target = fh.read()
    target_fdts = scan_fdts(target)
    print()
    report("待修dtb", target_fdts, len(target))

    if any(RTIC_MARKER in f["data"] for f in target_fdts):
        print("\n[跳过] 目标 dtb 已包含 RTIC FDT，无需修复")
        return 3

    # 3. 追加并复验
    fixed = target + rtic["data"]
    with open(output_path, "wb") as fh:
        fh.write(fixed)

    print(f"\n[输出] {output_path}")
    print(f"       {len(target)} + {rtic['size']} = {len(fixed)} 字节")

    with open(output_path, "rb") as fh:
        verify_fdts = scan_fdts(fh.read())
    print()
    report("复验", verify_fdts, len(fixed))

    if len(verify_fdts) != len(target_fdts) + 1:
        print("\n错误: FDT 数量未按预期增加 1")
        return 1
    if RTIC_MARKER not in verify_fdts[-1]["data"]:
        print("\n错误: 尾部 FDT 不是 RTIC")
        return 1
    if sum(f["size"] for f in verify_fdts) != len(fixed):
        print("\n错误: FDT 覆盖字节数与文件长度不符")
        return 1

    print("\n[OK] 结构校验通过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
