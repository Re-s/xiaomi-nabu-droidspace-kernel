#!/bin/bash
# ============================================
# DroidSpaces Kernel Compatibility Checker
# 小米平板5 (nabu) 内核验证脚本
# ============================================
# 版本: 1.0.0
# 基于 DroidSpaces-OSS 内核要求
# https://github.com/ravindu644/Droidspaces-OSS
# ============================================

set -euo pipefail

# ============================================
# 颜色定义
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# 图标
CHECKMARK="${GREEN}✓${NC}"
CROSSMARK="${RED}✗${NC}"
WARNING="${YELLOW}⚠${NC}"
INFO="${BLUE}ℹ${NC}"

# ============================================
# 默认配置
# ============================================
CONFIG_FILE=""
CHECK_SINGLE=""
JSON_OUTPUT=false
VERBOSE=false
DEVICE_EXPECTED="nabu"
DEVICE_NAME_EXPECTED="Xiaomi Pad 5"
MIN_KERNEL_MAJOR=3
MIN_KERNEL_MINOR=18
RECOMMENDED_KERNEL_MAJOR=5
RECOMMENDED_KERNEL_MINOR=4

# 统计
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# JSON 数据存储
declare -A JSON_RESULTS=()

# ============================================
# 帮助信息
# ============================================
usage() {
    cat << EOF
DroidSpaces Kernel Compatibility Checker
=========================================
检查内核是否满足 DroidSpaces 容器运行要求

用法: $0 [选项]

选项:
  -c, --config FILE     从本地配置文件读取（不是 /proc/config.gz）
  -s, --single CONFIG   检查单个配置项（如 CONFIG_NAMESPACES）
  -j, --json            输出 JSON 格式报告
  -v, --verbose         详细输出模式
  -h, --help            显示此帮助信息

示例:
  $0                          # 从 /proc/config.gz 检查
  $0 -c kernel.config         # 从本地文件检查
  $0 -s CONFIG_NAMESPACES     # 检查单个配置
  $0 -j                       # 输出 JSON 报告
  $0 -v                       # 详细输出

兼容性级别:
  ✅ PASS    - 配置已启用
  ⚠️  WARN    - 可选配置未启用
  ❌ FAIL    - 必需配置未启用
  ℹ️  INFO    - 信息提示
EOF
    exit 0
}

# ============================================
# 日志函数
# ============================================
log_pass() {
    local msg="$1"
    local detail="${2:-}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -e "  ${CHECKMARK} ${GREEN}PASS${NC}: ${msg}"
    if [[ -n "$detail" && "$VERBOSE" == true ]]; then
        echo -e "       ${detail}"
    fi
    JSON_RESULTS["$msg"]="PASS"
}

log_fail() {
    local msg="$1"
    local detail="${2:-}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -e "  ${CROSSMARK} ${RED}FAIL${NC}: ${msg}"
    if [[ -n "$detail" ]]; then
        echo -e "       ${CYAN}${detail}${NC}"
    fi
    JSON_RESULTS["$msg"]="FAIL"
}

log_warn() {
    local msg="$1"
    local detail="${2:-}"
    WARNING_CHECKS=$((WARNING_CHECKS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    echo -e "  ${WARNING} ${YELLOW}WARN${NC}: ${msg}"
    if [[ -n "$detail" && "$VERBOSE" == true ]]; then
        echo -e "       ${detail}"
    fi
    JSON_RESULTS["$msg"]="WARN"
}

log_info() {
    local msg="$1"
    echo -e "  ${INFO} ${BLUE}INFO${NC}: ${msg}"
}

log_section() {
    echo ""
    echo -e "${BOLD}${MAGENTA}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${WHITE}  $1${NC}"
    echo -e "${BOLD}${MAGENTA}════════════════════════════════════════════════════════════${NC}"
}

# ============================================
# 解析参数
# ============================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -s|--single)
                CHECK_SINGLE="$2"
                shift 2
                ;;
            -j|--json)
                JSON_OUTPUT=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo "未知选项: $1"
                usage
                ;;
        esac
    done
}

# ============================================
# 获取内核配置源路径
# ============================================
get_config_source() {
    if [[ -n "$CONFIG_FILE" ]]; then
        if [[ -f "$CONFIG_FILE" ]]; then
            echo "$CONFIG_FILE"
        else
            echo -e "${RED}错误: 配置文件不存在: $CONFIG_FILE${NC}" >&2
            exit 1
        fi
    elif [[ -f "/proc/config.gz" ]]; then
        echo "/proc/config.gz"
    else
        echo -e "${RED}错误: 无法获取内核配置${NC}" >&2
        echo "请使用 -c 选项指定配置文件，或在设备上运行此脚本" >&2
        exit 1
    fi
}

# 检查配置项
check_config() {
    local config_name="$1"
    local config_source
    config_source=$(get_config_source)

    if [[ "$config_source" == "/proc/config.gz" ]]; then
        zcat /proc/config.gz | grep -qE "^${config_name}=[ym]"
    else
        grep -qE "^${config_name}=[ym]" "$config_source"
    fi
}

# 获取配置值
get_config_value() {
    local config_name="$1"
    local config_source
    config_source=$(get_config_source)

    if [[ "$config_source" == "/proc/config.gz" ]]; then
        local value
        value=$(zcat /proc/config.gz | grep -E "^${config_name}=" | head -1 | cut -d'=' -f2)
        if [[ -n "$value" ]]; then
            echo "$value"
        else
            echo "NOT_FOUND"
        fi
    else
        local value
        value=$(grep -E "^${config_name}=" "$config_source" | head -1 | cut -d'=' -f2)
        if [[ -n "$value" ]]; then
            echo "$value"
        else
            echo "NOT_FOUND"
        fi
    fi
}

# ============================================
# 检查 1: 设备信息
# ============================================
check_device() {
    log_section "1. 设备信息检查"

    # 尝试多种方式获取设备信息
    local device_code=""
    local device_model=""
    local board_name=""

    # 检查 /sys/class/android_board/android_usb/vendor
    if [[ -f /sys/class/android_board/android_usb/vendor ]]; then
        local vendor_id
        vendor_id=$(cat /sys/class/android_board/android_usb/vendor 2>/dev/null || echo "")
        if [[ "$vendor_id" == "0x2717" ]]; then
            log_info "检测到小米设备 (vendor: $vendor_id)"
        fi
    fi

    # 检查 ro.product.board
    if command -v getprop &>/dev/null; then
        device_code=$(getprop ro.product.board 2>/dev/null || echo "")
        device_model=$(getprop ro.product.model 2>/dev/null || echo "")
        board_name=$(getprop ro.board.platform 2>/dev/null || echo "")
    fi

    # 尝试 /proc/device-tree
    if [[ -f /proc/device-tree/model ]]; then
        device_model=$(cat /proc/device-tree/model 2>/dev/null || echo "")
    fi

    # 检查是否为 nabu 设备
    if [[ "$device_code" == *"nabu"* ]] || \
       [[ "$device_model" == *"21051182C"* ]] || \
       [[ "$device_model" == *"21081111RG"* ]] || \
       [[ "$device_model" == *"Xiaomi Pad 5"* ]]; then
        log_pass "设备型号匹配: ${device_model:-$device_code}"
        log_pass "设备代号匹配: nabu (小米平板5)"
    elif [[ -z "$device_code" && -z "$device_model" ]]; then
        log_warn "无法获取设备信息" "可能不在设备上运行，跳过设备检查"
    else
        log_fail "设备不匹配" "当前设备: ${device_code:-$device_model}, 期望: $DEVICE_EXPECTED"
    fi

    # 显示平台信息
    if [[ -n "$board_name" ]]; then
        log_info "平台: $board_name"
    fi
}

# ============================================
# 检查 2: 内核版本
# ============================================
check_kernel_version() {
    log_section "2. 内核版本检查"

    local kernel_version
    kernel_version=$(uname -r)

    log_info "当前内核版本: $kernel_version"

    # 解析主版本号和次版本号
    local major minor patch
    major=$(echo "$kernel_version" | cut -d'.' -f1)
    minor=$(echo "$kernel_version" | cut -d'.' -f2)
    patch=$(echo "$kernel_version" | cut -d'.' -f3 | cut -d'-' -f1)

    # 检查最低要求 3.18
    if [[ "$major" -lt "$MIN_KERNEL_MAJOR" ]] || \
       ([[ "$major" -eq "$MIN_KERNEL_MAJOR" && "$minor" -lt "$MIN_KERNEL_MINOR" ]]); then
        log_fail "内核版本过低: $kernel_version" \
                 "最低要求: ${MIN_KERNEL_MAJOR}.${MIN_KERNEL_MINOR}"
    else
        log_pass "内核版本满足最低要求: $kernel_version >= ${MIN_KERNEL_MAJOR}.${MIN_KERNEL_MINOR}"
    fi

    # 检查推荐版本 5.4+
    if [[ "$major" -gt "$RECOMMENDED_KERNEL_MAJOR" ]] || \
       ([[ "$major" -eq "$RECOMMENDED_KERNEL_MAJOR" && "$minor" -ge "$RECOMMENDED_KERNEL_MINOR" ]]); then
        log_pass "内核版本达到推荐级别: $kernel_version >= ${RECOMMENDED_KERNEL_MAJOR}.${RECOMMENDED_KERNEL_MINOR}"
        log_info "支持完整功能，包括嵌套容器和 Cgroup v2"
    elif [[ "$major" -ge 4 ]]; then
        log_warn "内核版本未达推荐级别" \
                 "推荐: ${RECOMMENDED_KERNEL_MAJOR}.${RECOMMENDED_KERNEL_MINOR}+ 以获得最佳兼容性"
    else
        log_warn "内核版本较旧" \
                 "部分功能可能受限，建议升级到 ${RECOMMENDED_KERNEL_MAJOR}.${RECOMMENDED_KERNEL_MINOR}+"
    fi

    # 显示详细版本信息
    if [[ "$VERBOSE" == true ]]; then
        echo -e "       ${CYAN}版本分解: major=$major, minor=$minor, patch=$patch${NC}"
    fi
}

# ============================================
# 检查 3: 命名空间支持
# ============================================
check_namespaces() {
    log_section "3. 命名空间 (Namespace) 支持检查"

    log_info "命名空间是容器化的基础，缺少任一必需项将导致容器无法启动"
    echo ""

    # 核心命名空间（致命级）
    echo -e "${BOLD}  核心命名空间 (必需):${NC}"

    # CONFIG_NAMESPACES
    if check_config "CONFIG_NAMESPACES"; then
        log_pass "CONFIG_NAMESPACES" "命名空间核心支持已启用"
    else
        log_fail "CONFIG_NAMESPACES" "致命: 命名空间核心支持缺失，容器无法启动"
    fi

    # CONFIG_PID_NS
    if check_config "CONFIG_PID_NS"; then
        log_pass "CONFIG_PID_NS" "PID 命名空间已启用"
    else
        log_fail "CONFIG_PID_NS" "致命: PID 命名空间缺失，容器无法隔离进程"
    fi

    # CONFIG_UTS_NS
    if check_config "CONFIG_UTS_NS"; then
        log_pass "CONFIG_UTS_NS" "UTS 命名空间已启用"
    else
        log_fail "CONFIG_UTS_NS" "致命: UTS 命名空间缺失，无法设置独立主机名"
    fi

    # CONFIG_IPC_NS
    if check_config "CONFIG_IPC_NS"; then
        log_pass "CONFIG_IPC_NS" "IPC 命名空间已启用"
    else
        log_fail "CONFIG_IPC_NS" "致命: IPC 命名空间缺失，容器间通信隔离失败"
    fi

    echo ""
    echo -e "${BOLD}  网络命名空间 (NAT模式必需):${NC}"

    # CONFIG_NET_NS
    if check_config "CONFIG_NET_NS"; then
        log_pass "CONFIG_NET_NS" "网络命名空间已启用"
    else
        log_warn "CONFIG_NET_NS" "NAT 和 None 网络模式不可用，仅支持 Host 模式"
    fi

    # CONFIG_USER_NS (Docker 兼容)
    if check_config "CONFIG_USER_NS"; then
        log_pass "CONFIG_USER_NS" "用户命名空间已启用 (Docker 兼容)"
    else
        log_warn "CONFIG_USER_NS" "Docker procfs 可能出错，建议启用"
    fi
}

# ============================================
# 检查 4: Cgroup 支持
# ============================================
check_cgroups() {
    log_section "4. Cgroup 控制组支持检查"

    log_info "Cgroup 用于资源限制和隔离"
    echo ""

    # CONFIG_CGROUPS
    if check_config "CONFIG_CGROUPS"; then
        log_pass "CONFIG_CGROUPS" "Cgroup 核心支持已启用"
    else
        log_fail "CONFIG_CGROUPS" "致命: Cgroup 核心支持缺失，容器资源管理失败"
    fi

    # CONFIG_CGROUP_DEVICE
    if check_config "CONFIG_CGROUP_DEVICE"; then
        log_pass "CONFIG_CGROUP_DEVICE" "设备 Cgroup 已启用"
    else
        log_fail "CONFIG_CGROUP_DEVICE" "致命: 设备 Cgroup 缺失，无法控制设备访问"
    fi

    echo ""

    # 其他推荐的 cgroup 配置
    echo -e "${BOLD}  推荐的 Cgroup 配置:${NC}"

    # CONFIG_CGROUP_PIDS
    if check_config "CONFIG_CGROUP_PIDS"; then
        log_pass "CONFIG_CGROUP_PIDS" "PID Cgroup 已启用"
    else
        log_warn "CONFIG_CGROUP_PIDS" "PID 限制功能不可用"
    fi

    # CONFIG_MEMCG
    if check_config "CONFIG_MEMCG"; then
        log_pass "CONFIG_MEMCG" "内存 Cgroup 已启用"
    else
        log_warn "CONFIG_MEMCG" "内存限制功能不可用"
    fi

    # CONFIG_CGROUP_SCHED
    if check_config "CONFIG_CGROUP_SCHED"; then
        log_pass "CONFIG_CGROUP_SCHED" "CPU 调度 Cgroup 已启用"
    else
        log_warn "CONFIG_CGROUP_SCHED" "CPU 调度控制不可用"
    fi

    # CONFIG_CGROUP_FREEZER
    if check_config "CONFIG_CGROUP_FREEZER"; then
        log_pass "CONFIG_CGROUP_FREEZER" "冻结器 Cgroup 已启用"
    else
        log_warn "CONFIG_CGROUP_FREEZER" "容器冻结/解冻功能不可用"
    fi

    # CONFIG_FAIR_GROUP_SCHED
    if check_config "CONFIG_FAIR_GROUP_SCHED"; then
        log_pass "CONFIG_FAIR_GROUP_SCHED" "公平调度已启用"
    else
        log_warn "CONFIG_FAIR_GROUP_SCHED" "公平调度不可用"
    fi
}

# ============================================
# 检查 5: 文件系统支持
# ============================================
check_filesystems() {
    log_section "5. 文件系统支持检查"

    # CONFIG_DEVTMPFS
    if check_config "CONFIG_DEVTMPFS"; then
        log_pass "CONFIG_DEVTMPFS" "设备临时文件系统已启用"
    else
        log_fail "CONFIG_DEVTMPFS" "致命: devtmpfs 缺失，无法设置 /dev"
    fi

    # CONFIG_OVERLAY_FS
    if check_config "CONFIG_OVERLAY_FS"; then
        log_pass "CONFIG_OVERLAY_FS" "OverlayFS 已启用"
    else
        log_warn "CONFIG_OVERLAY_FS" "volatile 模式不可用"
    fi

    echo ""

    echo -e "${BOLD}  Tmpfs 扩展支持:${NC}"

    # CONFIG_TMPFS_POSIX_ACL
    if check_config "CONFIG_TMPFS_POSIX_ACL"; then
        log_pass "CONFIG_TMPFS_POSIX_ACL" "Tmpfs POSIX ACL 支持已启用"
    else
        log_warn "CONFIG_TMPFS_POSIX_ACL" "NixOS 等系统可能受限"
    fi

    # CONFIG_TMPFS_XATTR
    if check_config "CONFIG_TMPFS_XATTR"; then
        log_pass "CONFIG_TMPFS_XATTR" "Tmpfs 扩展属性支持已启用"
    else
        log_warn "CONFIG_TMPFS_XATTR" "扩展属性功能受限"
    fi

    echo ""

    echo -e "${BOLD}  固件加载支持:${NC}"

    # CONFIG_FW_LOADER
    if check_config "CONFIG_FW_LOADER"; then
        log_pass "CONFIG_FW_LOADER" "固件加载器已启用"
    else
        log_warn "CONFIG_FW_LOADER" "固件加载可能受限"
    fi

    # CONFIG_FW_LOADER_USER_HELPER
    if check_config "CONFIG_FW_LOADER_USER_HELPER"; then
        log_pass "CONFIG_FW_LOADER_USER_HELPER" "固件加载器用户辅助已启用"
    else
        log_warn "CONFIG_FW_LOADER_USER_HELPER" "用户空间固件辅助不可用"
    fi
}

# ============================================
# 检查 6: 安全支持
# ============================================
check_security() {
    log_section "6. 安全支持检查"

    # CONFIG_SECCOMP
    if check_config "CONFIG_SECCOMP"; then
        log_pass "CONFIG_SECCOMP" "Seccomp 系统调用过滤已启用"
    else
        log_warn "CONFIG_SECCOMP" "安全屏蔽禁用（安全风险）"
    fi

    # CONFIG_SECCOMP_FILTER
    if check_config "CONFIG_SECCOMP_FILTER"; then
        log_pass "CONFIG_SECCOMP_FILTER" "Seccomp BPF 过滤器已启用"
    else
        log_warn "CONFIG_SECCOMP_FILTER" "Seccomp BPF 不可用"
    fi
}

# ============================================
# 检查 7: 网络支持
# ============================================
check_networking() {
    log_section "7. 网络支持检查 (NAT 模式)"

    log_info "以下配置对于 NAT 和 None 网络模式是必需的"
    echo ""

    # CONFIG_VETH
    if check_config "CONFIG_VETH"; then
        log_pass "CONFIG_VETH" "虚拟以太网设备已启用"
    else
        log_warn "CONFIG_VETH" "虚拟网络设备不可用"
    fi

    # CONFIG_BRIDGE
    if check_config "CONFIG_BRIDGE"; then
        log_pass "CONFIG_BRIDGE" "网桥支持已启用"
    else
        log_warn "CONFIG_BRIDGE" "网桥功能不可用"
    fi

    echo ""

    echo -e "${BOLD}  Netfilter 支持:${NC}"

    # CONFIG_NETFILTER
    if check_config "CONFIG_NETFILTER"; then
        log_pass "CONFIG_NETFILTER" "网络过滤器已启用"
    else
        log_warn "CONFIG_NETFILTER" "网络过滤功能不可用"
    fi

    # CONFIG_NF_NAT
    if check_config "CONFIG_NF_NAT"; then
        log_pass "CONFIG_NF_NAT" "NAT 支持已启用"
    else
        log_warn "CONFIG_NF_NAT" "NAT 功能不可用"
    fi

    # CONFIG_NF_TABLES
    if check_config "CONFIG_NF_TABLES"; then
        log_pass "CONFIG_NF_TABLES" "nftables 已启用"
    else
        log_warn "CONFIG_NF_TABLES" "nftables 不可用"
    fi

    # CONFIG_BRIDGE_NETFILTER
    if check_config "CONFIG_BRIDGE_NETFILTER"; then
        log_pass "CONFIG_BRIDGE_NETFILTER" "网桥过滤已启用"
    else
        log_warn "CONFIG_BRIDGE_NETFILTER" "网桥过滤功能不可用"
    fi

    # CONFIG_NF_CONNTRACK
    if check_config "CONFIG_NF_CONNTRACK"; then
        log_pass "CONFIG_NF_CONNTRACK" "连接跟踪已启用"
    else
        log_warn "CONFIG_NF_CONNTRACK" "连接跟踪功能不可用"
    fi
}

# ============================================
# 检查 8: Android 特定配置
# ============================================
check_android_specific() {
    log_section "8. Android 特定配置检查"

    # CONFIG_ANDROID_PARANOID_NETWORK
    if check_config "CONFIG_ANDROID_PARANOID_NETWORK"; then
        local value
        value=$(get_config_value "CONFIG_ANDROID_PARANOID_NETWORK")
        if [[ "$value" == "n" ]]; then
            log_pass "CONFIG_ANDROID_PARANOID_NETWORK=n" "Android 网络隔离已禁用"
        else
            log_warn "CONFIG_ANDROID_PARANOID_NETWORK" "Android 网络隔离可能限制旧内核网络"
        fi
    else
        log_pass "CONFIG_ANDROID_PARANOID_NETWORK 未设置" "等同于禁用"
    fi
}

# ============================================
# 生成兼容性评估
# ============================================
generate_assessment() {
    log_section "兼容性评估"

    local kernel_version
    kernel_version=$(uname -r)

    # 计算兼容性等级
    local compat_level=""
    local compat_color=""
    local compat_desc=""

    if [[ "$FAILED_CHECKS" -eq 0 && "$WARNING_CHECKS" -le 3 ]]; then
        compat_level="完全兼容"
        compat_color="$GREEN"
        compat_desc="内核完全支持 DroidSpaces，可以正常运行所有功能"
    elif [[ "$FAILED_CHECKS" -eq 0 ]]; then
        compat_level="基本兼容"
        compat_color="$YELLOW"
        compat_desc="内核支持基本功能，但缺少某些可选功能"
    elif [[ "$FAILED_CHECKS" -le 2 ]]; then
        compat_level="部分兼容"
        compat_color="$YELLOW"
        compat_desc="内核缺少某些必需配置，需要修改内核配置"
    else
        compat_level="不兼容"
        compat_color="$RED"
        compat_desc="内核缺少多个必需配置，无法正常运行 DroidSpaces"
    fi

    echo ""
    echo -e "${BOLD}  ┌─────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}  │  兼容性等级: ${compat_color}${compat_level}${NC}${BOLD}                          │${NC}"
    echo -e "${BOLD}  └─────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${compat_desc}"
    echo ""

    # 检查结果汇总
    echo -e "${BOLD}  检查结果汇总:${NC}"
    echo -e "  ─────────────────────────────────────────────"
    echo -e "  ${GREEN}通过: ${PASSED_CHECKS}${NC}"
    echo -e "  ${RED}失败: ${FAILED_CHECKS}${NC}"
    echo -e "  ${YELLOW}警告: ${WARNING_CHECKS}${NC}"
    echo -e "  总计: ${TOTAL_CHECKS}"
    echo ""

    # 建议
    echo -e "${BOLD}  建议:${NC}"
    echo -e "  ─────────────────────────────────────────────"

    if [[ "$FAILED_CHECKS" -gt 0 ]]; then
        echo -e "  ${RED}1. 需要修改内核配置以启用缺失的必需选项${NC}"
        echo -e "     参考: DroidSpaces 内核配置指南"
    fi

    if [[ "$WARNING_CHECKS" -gt 0 ]]; then
        echo -e "  ${YELLOW}2. 可选功能未启用，可能影响部分功能${NC}"
        echo -e "     建议在内核配置中启用这些选项"
    fi

    # 版本建议
    local major minor
    major=$(echo "$kernel_version" | cut -d'.' -f1)
    minor=$(echo "$kernel_version" | cut -d'.' -f2)

    if [[ "$major" -lt 5 ]] || ([[ "$major" -eq 5 && "$minor" -lt 4 ]]); then
        echo -e "  ${YELLOW}3. 建议升级到 Linux 5.4+ 以获得最佳兼容性${NC}"
    fi

    echo -e "  ${INFO}4. 刷入内核后使用 DroidSpaces 内置检查器验证"
    echo -e "     命令: su -c droidspaces check"
    echo ""

    # 返回兼容性状态码
    if [[ "$FAILED_CHECKS" -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================
# 生成 JSON 报告
# ============================================
generate_json_report() {
    local kernel_version
    kernel_version=$(uname -r)

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    local compat_level=""
    if [[ "$FAILED_CHECKS" -eq 0 && "$WARNING_CHECKS" -le 3 ]]; then
        compat_level="fully_compatible"
    elif [[ "$FAILED_CHECKS" -eq 0 ]]; then
        compat_level="mostly_compatible"
    elif [[ "$FAILED_CHECKS" -le 2 ]]; then
        compat_level="partially_compatible"
    else
        compat_level="incompatible"
    fi

    cat << EOF
{
  "metadata": {
    "tool": "DroidSpaces Kernel Compatibility Checker",
    "version": "1.0.0",
    "timestamp": "$timestamp",
    "source": "https://github.com/ravindu644/Droidspaces-OSS"
  },
  "device": {
    "expected": "$DEVICE_EXPECTED",
    "name": "$DEVICE_NAME_EXPECTED"
  },
  "kernel": {
    "version": "$kernel_version",
    "minimum_required": "${MIN_KERNEL_MAJOR}.${MIN_KERNEL_MINOR}",
    "recommended": "${RECOMMENDED_KERNEL_MAJOR}.${RECOMMENDED_KERNEL_MINOR}"
  },
  "compatibility": {
    "level": "$compat_level",
    "passed": $PASSED_CHECKS,
    "failed": $FAILED_CHECKS,
    "warnings": $WARNING_CHECKS,
    "total": $TOTAL_CHECKS
  },
  "checks": {
EOF

    local first=true
    for key in "${!JSON_RESULTS[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            echo ","
        fi
        local value="${JSON_RESULTS[$key]}"
        local status
        case "$value" in
            PASS) status="pass" ;;
            FAIL) status="fail" ;;
            WARN) status="warn" ;;
            *) status="unknown" ;;
        esac
        echo -n "    \"$key\": \"$status\""
    done

    cat << EOF

  },
  "recommendations": [
EOF

    local rec_first=true

    if [[ "$FAILED_CHECKS" -gt 0 ]]; then
        if [[ "$rec_first" == true ]]; then
            rec_first=false
        else
            echo ","
        fi
        echo -n "    \"Enable missing required kernel configurations\""
    fi

    if [[ "$WARNING_CHECKS" -gt 0 ]]; then
        if [[ "$rec_first" == true ]]; then
            rec_first=false
        else
            echo ","
        fi
        echo -n "    \"Consider enabling optional features for better compatibility\""
    fi

    local major
    major=$(echo "$kernel_version" | cut -d'.' -f1)
    if [[ "$major" -lt 5 ]]; then
        if [[ "$rec_first" == true ]]; then
            rec_first=false
        else
            echo ","
        fi
        echo -n "    \"Upgrade to Linux 5.4+ for best compatibility\""
    fi

    cat << EOF

  ]
}
EOF
}

# ============================================
# 主函数
# ============================================
main() {
    parse_args "$@"

    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║       DroidSpaces Kernel Compatibility Checker             ║${NC}"
    echo -e "${BOLD}${CYAN}║       小米平板5 (nabu) 内核验证工具                        ║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # 检查单个配置项模式
    if [[ -n "$CHECK_SINGLE" ]]; then
        local value
        value=$(get_config_value "$CHECK_SINGLE")
        echo "$CHECK_SINGLE=$value"
        if [[ "$JSON_OUTPUT" == true ]]; then
            echo "{\"config\": \"$CHECK_SINGLE\", \"value\": \"$value\"}"
        fi
        exit 0
    fi

    # 运行所有检查
    check_device
    check_kernel_version
    check_namespaces
    check_cgroups
    check_filesystems
    check_security
    check_networking
    check_android_specific

    # 生成评估
    if [[ "$JSON_OUTPUT" == true ]]; then
        generate_json_report
    else
        generate_assessment
    fi
}

# 运行主函数
main "$@"
