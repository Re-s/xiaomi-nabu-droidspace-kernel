#!/bin/bash
# ============================================
# GKI kABI Patch Application Script for DroidSpaces
# ============================================
# This script applies necessary kABI fix patches for GKI kernels
# to enable CONFIG_SYSVIPC, CONFIG_IPC_NS, CONFIG_POSIX_MQUEUE
# without causing boot loops.
#
# Reference: https://github.com/ravindu644/Droidspaces-OSS/tree/main/Documentation/resources/kernel-patches/GKI
#
# Usage: ./apply_gki_patches.sh [OPTIONS]
# Run with --help for detailed usage information.
# ============================================

set -euo pipefail

# ============================================
# Configuration
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="${SCRIPT_DIR}/kernel"
LOG_DIR="${SCRIPT_DIR}/logs"
PATCH_DIR="${SCRIPT_DIR}/patches/gki"
BACKUP_DIR="${SCRIPT_DIR}/patches/backup"
GITHUB_BASE_URL="https://github.com/ravindu644/Droidspaces-OSS/raw/main/Documentation/resources/kernel-patches/GKI"

# Patch file names (base names)
PATCH_SYSVIPC="sysv_ipc_kabi_fix.patch"
PATCH_POSIX_MQUEUE="posix_mqueue_kabi_fix.patch"
PATCH_SYSVIPC_NEW="sysv_ipc_kabi_fix_new.patch"  # For 6.12+

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================
# Helper Functions
# ============================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_debug() {
    if [[ "${DEBUG:-0}" -eq 1 ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $*"
    fi
}

# Create required directories
create_directories() {
    mkdir -p "${LOG_DIR}" "${PATCH_DIR}" "${BACKUP_DIR}"
}

# Generate timestamp for log files
get_timestamp() {
    date +"%Y%m%d_%H%M%S"
}

# Log to file
log_to_file() {
    local log_file="${LOG_DIR}/apply_patches_$(get_timestamp).log"
    echo "$*" >> "${log_file}"
    echo "${log_file}"
}

# ============================================
# Version Detection
# ============================================
detect_kernel_version() {
    local version=""
    local major=0
    local minor=0
    local patch=0
    
    # Try to detect from kernel directory Makefile
    if [[ -f "${KERNEL_DIR}/Makefile" ]]; then
        version=$(grep -E "^VERSION\s*=" "${KERNEL_DIR}/Makefile" | head -1 | awk '{print $3}')
        patchlevel=$(grep -E "^PATCHLEVEL\s*=" "${KERNEL_DIR}/Makefile" | head -1 | awk '{print $3}')
        sublevel=$(grep -E "^SUBLEVEL\s*=" "${KERNEL_DIR}/Makefile" | head -1 | awk '{print $3}')
        
        if [[ -n "${version}" && -n "${patchlevel}" && -n "${sublevel}" ]]; then
            major="${version}"
            minor="${patchlevel}"
            patch="${sublevel}"
        fi
    fi
    
    # Fallback: try to detect from main Makefile in script directory
    if [[ "${major}" -eq 0 ]]; then
        if [[ -f "${SCRIPT_DIR}/Makefile" ]]; then
            local ver_line
            ver_line=$(grep -E "KERNEL_VERSION\s*:=" "${SCRIPT_DIR}/Makefile" | head -1)
            if [[ -n "${ver_line}" ]]; then
                version=$(echo "${ver_line}" | sed 's/.*:=\s*//' | tr -d '[:space:]')
                if [[ "${version}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
                    major="${BASH_REMATCH[1]}"
                    minor="${BASH_REMATCH[2]}"
                    patch="${BASH_REMATCH[3]}"
                fi
            fi
        fi
    fi
    
    # If still no version, try uname -r (running kernel)
    if [[ "${major}" -eq 0 ]]; then
        local running_ver
        running_ver=$(uname -r 2>/dev/null || true)
        if [[ "${running_ver}" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
            major="${BASH_REMATCH[1]}"
            minor="${BASH_REMATCH[2]}"
            patch="${BASH_REMATCH[3]}"
            log_warning "Using running kernel version: ${running_ver}"
        fi
    fi
    
    if [[ "${major}" -eq 0 ]]; then
        log_error "Could not detect kernel version. Please ensure kernel source is present."
        return 1
    fi
    
    echo "${major}.${minor}.${patch}"
    return 0
}

# Compare version strings: returns 0 if $1 >= $2
version_gte() {
    local v1="$1"
    local v2="$2"
    
    # Convert to comparable integers
    local IFS='.'
    read -r -a v1_parts <<< "${v1}"
    read -r -a v2_parts <<< "${v2}"
    
    # Pad with zeros if needed
    while [[ ${#v1_parts[@]} -lt 3 ]]; do v1_parts+=(0); done
    while [[ ${#v2_parts[@]} -lt 3 ]]; do v2_parts+=(0); done
    
    for i in 0 1 2; do
        local p1=${v1_parts[$i]:-0}
        local p2=${v2_parts[$i]:-0}
        if (( p1 > p2 )); then return 0; fi
        if (( p1 < p2 )); then return 1; fi
    done
    return 0  # Equal
}

# Check if version is in range [low, high]
version_in_range() {
    local ver="$1"
    local low="$2"
    local high="$3"
    
    if version_gte "${ver}" "${low}" && version_gte "${high}" "${ver}"; then
        return 0
    fi
    return 1
}

# ============================================
# Patch Management
# ============================================
# Download patch from GitHub
download_patch() {
    local patch_name="$1"
    local target_file="${PATCH_DIR}/${patch_name}"
    
    # Check if patch already exists locally
    if [[ -f "${target_file}" ]]; then
        log_info "Using existing local patch: ${patch_name}"
        return 0
    fi
    
    log_info "Downloading patch: ${patch_name}"
    local url="${GITHUB_BASE_URL}/${patch_name}"
    
    if command -v curl &> /dev/null; then
        if curl -fsSL "${url}" -o "${target_file}" 2>/dev/null; then
            log_success "Downloaded: ${patch_name}"
            return 0
        fi
    elif command -v wget &> /dev/null; then
        if wget -q "${url}" -O "${target_file}" 2>/dev/null; then
            log_success "Downloaded: ${patch_name}"
            return 0
        fi
    fi
    
    log_warning "Could not download ${patch_name}. Creating template patch."
    create_template_patch "${patch_name}" "${target_file}"
    return 0
}

# Create a template patch file
create_template_patch() {
    local patch_name="$1"
    local output_file="$2"
    
    cat > "${output_file}" << 'PATCH_TEMPLATE'
From: DroidSpaces Kernel Team <kernel@droidspaces.org>
Subject: [PATCH] GKI kABI fix patch template

This is a template patch file. You need to:
1. Find the actual kABI-breaking changes in your kernel source
2. Fill in the correct context lines (marked with ?)
3. Ensure the patch applies cleanly with 'patch --dry-run'

---
 ipc/Makefile          |  2 +-
 ipc/sysv.c            | 10 +++++++++-
 ipc/util.c            |  8 +++++++-
 include/linux/ipc.h   |  5 +++++
 include/linux/msg.h   |  3 +++
 include/linux/sem.h   |  3 +++
 include/linux/shm.h   |  3 +++
 7 files changed, 32 insertions(+), 3 deletions(-)

diff --git a/ipc/Makefile b/ipc/Makefile
index ????..???? 100644
--- a/ipc/Makefile
+++ b/ipc/Makefile
@@ -? +? @@ 
-obj-y += util.o
+obj-y += util.o kabi_fix.o
diff --git a/ipc/sysv.c b/ipc/sysv.c
index ????..???? 100644
--- a/ipc/sysv.c
+++ b/ipc/sysv.c
@@ -? +? @@ 
+/* DroidSpaces kABI fix: Add backward compatibility shims */
+#ifdef CONFIG_SYSVIPC
+static struct ipc_ids sysv_ipc_ids;
+#endif
diff --git a/ipc/util.c b/ipc/util.c
index ????..???? 100644
--- a/ipc/util.c
+++ b/ipc/util.c
@@ -? +? @@ 
+/* DroidSpaces kABI fix: Export hidden symbols for kABI compatibility */
+EXPORT_SYMBOL_GPL(ipc_lock);
+EXPORT_SYMBOL_GPL(ipc_unlock);
diff --git a/include/linux/ipc.h b/include/linux/ipc.h
index ????..???? 100644
--- a/include/linux/ipc.h
+++ b/include/linux/ipc.h
@@ -? +? @@ 
+/* DroidSpaces kABI fix: Add missing struct members for kABI compatibility */
+
diff --git a/include/linux/msg.h b/include/linux/msg.h
index ????..???? 100644
--- a/include/linux/msg.h
+++ b/include/linux/msg.h
@@ -? +? @@ 
+/* DroidSpaces kABI fix: Message queue compatibility */
+
diff --git a/include/linux/sem.h b/include/linux/sem.h
index ????..???? 100644
--- a/include/linux/sem.h
+++ b/include/linux/sem.h
@@ -? +? @@ 
+/* DroidSpaces kABI fix: Semaphore compatibility */
+
diff --git a/include/linux/shm.h b/include/linux/shm.h
index ????..???? 100644
--- a/include/linux/shm.h
+++ b/include/linux/shm.h
@@ -? +? @@ 
+/* DroidSpaces kABI fix: Shared memory compatibility */
+
-- 
PATCH_TEMPLATE
    
    log_info "Template patch created: ${output_file}"
    log_info "Please edit this file with actual patch content before applying."
}

# Backup original files
backup_files() {
    local patch_file="$1"
    local timestamp
    timestamp=$(get_timestamp)
    local backup_subdir="${BACKUP_DIR}/backup_${timestamp}"
    mkdir -p "${backup_subdir}"
    
    log_info "Creating backup in: ${backup_subdir}"
    
    # Extract file paths from patch
    local files
    files=$(grep -E "^diff --git a/" "${patch_file}" | sed 's|^diff --git a/||' | sed 's| b/.*||')
    
    for file in ${files}; do
        local src_path="${KERNEL_DIR}/${file}"
        if [[ -f "${src_path}" ]]; then
            local dest_path="${backup_subdir}/${file}"
            mkdir -p "$(dirname "${dest_path}")"
            cp -a "${src_path}" "${dest_path}"
            log_debug "Backed up: ${file}"
        fi
    done
    
    # Also backup the patch itself
    cp "${patch_file}" "${backup_subdir}/applied_$(basename "${patch_file}")"
    
    echo "${backup_subdir}"
}

# Apply a patch
apply_patch() {
    local patch_file="$1"
    local dry_run="${2:-0}"
    local reverse="${3:-0}"
    
    if [[ ! -f "${patch_file}" ]]; then
        log_error "Patch file not found: ${patch_file}"
        return 1
    fi
    
    log_info "Applying patch: $(basename "${patch_file}")"
    log_info "Target directory: ${KERNEL_DIR}"
    
    # Verify kernel directory exists
    if [[ ! -d "${KERNEL_DIR}" ]]; then
        log_error "Kernel directory not found: ${KERNEL_DIR}"
        log_error "Please ensure kernel source is available."
        return 1
    fi
    
    local patch_args=()
    patch_args+=(--directory="${KERNEL_DIR}")
    patch_args+=(--strip=1)
    patch_args+=(--verbose)
    
    if [[ "${dry_run}" -eq 1 ]]; then
        patch_args+=(--dry-run)
        log_info "DRY RUN mode: No files will be modified"
    fi
    
    if [[ "${reverse}" -eq 1 ]]; then
        patch_args+=(--reverse)
        log_info "REVERSE mode: Reversing previously applied patch"
    fi
    
    # Apply patch
    local output
    if output=$(patch "${patch_args[@]}" < "${patch_file}" 2>&1); then
        log_success "Patch applied successfully"
        echo "${output}"
        return 0
    else
        log_error "Failed to apply patch"
        echo "${output}" >&2
        return 1
    fi
}

# Verify patch was applied correctly
verify_patch() {
    local patch_file="$1"
    log_info "Verifying patch application..."
    
    # Try reverse dry-run to verify
    local output
    if output=$(patch --directory="${KERNEL_DIR}" --strip=1 --reverse --dry-run < "${patch_file}" 2>&1); then
        log_success "Patch verification passed"
        return 0
    else
        log_warning "Patch verification failed - patch may not have been applied cleanly"
        return 1
    fi
}

# Record applied patches
record_applied_patch() {
    local patch_name="$1"
    local backup_dir="$2"
    local record_file="${PATCH_DIR}/applied_patches.log"
    
    echo "$(get_timestamp) | ${patch_name} | ${backup_dir}" >> "${record_file}"
    log_info "Patch application recorded in ${record_file}"
}

# ============================================
# Main Logic
# ============================================
show_help() {
    cat << 'HELP'
GKI kABI Patch Application Script for DroidSpaces
==================================================

This script applies necessary kABI fix patches for GKI kernels to enable
CONFIG_SYSVIPC, CONFIG_IPC_NS, CONFIG_POSIX_MQUEUE without boot loops.

Reference: https://github.com/ravindu644/Droidspaces-OSS/tree/main/Documentation/resources/kernel-patches/GKI

Usage:
    ./apply_gki_patches.sh [OPTIONS]

Options:
    -h, --help          Show this help message
    -v, --version       Show script version
    -d, --dry-run       Dry run mode (no changes made)
    -b, --backup-only   Only backup files, don't apply patches
    -r, --reverse       Reverse (undo) previously applied patches
    -f, --force         Force apply even if patches already applied
    -l, --list          List available and applied patches
    -t, --template      Create template patch files
    -c, --check         Check kernel version and required patches
    -V, --verbose       Enable verbose output
    -D, --debug         Enable debug output
    -k, --kernel-dir    Specify kernel directory (default: ./kernel)
    -o, --output-dir    Specify output directory (default: ./patches)

Environment Variables:
    DEBUG=1             Enable debug output

Examples:
    ./apply_gki_patches.sh --dry-run              # Preview changes
    ./apply_gki_patches.sh                        # Apply patches
    ./apply_gki_patches.sh --reverse              # Undo patches
    ./apply_gki_patches.sh --template             # Create template patches
    ./apply_gki_patches.sh --check                # Check requirements
    ./apply_gki_patches.sh --kernel-dir /path/to/kernel

Patch Logic:
    For kernels 5.4 - 6.11:
        - Apply SYSVIPC kABI fix patch
        - If kernel <= 5.10: Also apply POSIX_MQUEUE kABI fix patch
    
    For kernels 6.12+:
        - Apply new SYSVIPC kABI fix patch

Notes:
    - Patches are downloaded from GitHub when not available locally
    - Template patches are created if download fails
    - All operations are logged in the logs/ directory
    - Backups are stored in patches/backup/

HELP
}

show_version() {
    echo "apply_gki_patches.sh - GKI kABI Patch Application Tool"
    echo "Version: 1.0.0"
    echo "Date: $(date +%Y-%m-%d)"
    echo "For DroidSpaces Kernel Development"
}

list_patches() {
    log_info "Available patches in ${PATCH_DIR}:"
    if [[ -d "${PATCH_DIR}" ]]; then
        ls -la "${PATCH_DIR}/"*.patch 2>/dev/null || echo "  No patches found"
    else
        echo "  Patch directory not found"
    fi
    
    echo ""
    log_info "Applied patches record:"
    local record_file="${PATCH_DIR}/applied_patches.log"
    if [[ -f "${record_file}" ]]; then
        cat "${record_file}"
    else
        echo "  No patches applied yet"
    fi
}

check_kernel_requirements() {
    log_info "Checking kernel requirements..."
    
    # Detect version
    local kernel_version
    if ! kernel_version=$(detect_kernel_version); then
        log_error "Cannot determine kernel version"
        return 1
    fi
    
    log_info "Detected kernel version: ${kernel_version}"
    
    # Determine required patches
    local requires_sysvipc=0
    local requires_posix_mqueue=0
    local uses_new_sysvipc=0
    
    if version_in_range "${kernel_version}" "5.4" "6.11.99"; then
        requires_sysvipc=1
        log_info "Kernel 5.4-6.11: SYSVIPC patch required"
        
        if version_gte "5.10.99" "${kernel_version}"; then
            requires_posix_mqueue=1
            log_info "Kernel ≤5.10: POSIX_MQUEUE patch also required"
        fi
    elif version_gte "${kernel_version}" "6.12"; then
        uses_new_sysvipc=1
        log_info "Kernel ≥6.12: New SYSVIPC patch required"
    else
        log_warning "Kernel version ${kernel_version} may not need these patches"
    fi
    
    # Check if patches are available
    echo ""
    log_info "Patch availability:"
    
    if [[ "${requires_sysvipc}" -eq 1 || "${uses_new_sysvipc}" -eq 1 ]]; then
        local sysvipc_patch="${PATCH_SYSVIPC}"
        if [[ "${uses_new_sysvipc}" -eq 1 ]]; then
            sysvipc_patch="${PATCH_SYSVIPC_NEW}"
        fi
        
        if [[ -f "${PATCH_DIR}/${sysvipc_patch}" ]]; then
            echo -e "  ${GREEN}✓${NC} ${sysvipc_patch} available locally"
        else
            echo -e "  ${YELLOW}○${NC} ${sysvipc_patch} will be downloaded"
        fi
    fi
    
    if [[ "${requires_posix_mqueue}" -eq 1 ]]; then
        if [[ -f "${PATCH_DIR}/${PATCH_POSIX_MQUEUE}" ]]; then
            echo -e "  ${GREEN}✓${NC} ${PATCH_POSIX_MQUEUE} available locally"
        else
            echo -e "  ${YELLOW}○${NC} ${PATCH_POSIX_MQUEUE} will be downloaded"
        fi
    fi
    
    # Check kernel directory
    echo ""
    if [[ -d "${KERNEL_DIR}" ]]; then
        log_success "Kernel directory found: ${KERNEL_DIR}"
    else
        log_warning "Kernel directory not found: ${KERNEL_DIR}"
        log_info "Patches will be prepared but cannot be applied"
    fi
    
    return 0
}

# ============================================
# Main Script
# ============================================
main() {
    # Defaults
    local dry_run=0
    local backup_only=0
    local reverse=0
    local force=0
    local list_only=0
    local template_only=0
    local check_only=0
    local verbose=0
    local kernel_dir=""
    local output_dir=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -d|--dry-run)
                dry_run=1
                shift
                ;;
            -b|--backup-only)
                backup_only=1
                shift
                ;;
            -r|--reverse)
                reverse=1
                shift
                ;;
            -f|--force)
                force=1
                shift
                ;;
            -l|--list)
                list_only=1
                shift
                ;;
            -t|--template)
                template_only=1
                shift
                ;;
            -c|--check)
                check_only=1
                shift
                ;;
            -V|--verbose)
                verbose=1
                shift
                ;;
            -D|--debug)
                export DEBUG=1
                shift
                ;;
            -k|--kernel-dir)
                kernel_dir="$2"
                shift 2
                ;;
            -o|--output-dir)
                output_dir="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Run with --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Apply custom directories
    if [[ -n "${kernel_dir}" ]]; then
        KERNEL_DIR="${kernel_dir}"
    fi
    if [[ -n "${output_dir}" ]]; then
        PATCH_DIR="${output_dir}/gki"
        BACKUP_DIR="${output_dir}/backup"
    fi
    
    # Set verbose mode
    if [[ "${verbose}" -eq 1 ]]; then
        log_info "Verbose mode enabled"
    fi
    
    # Create required directories
    create_directories
    
    # Start logging
    local log_file="${LOG_DIR}/apply_patches_$(get_timestamp).log"
    exec > >(tee -a "${log_file}") 2>&1
    log_info "Logging to: ${log_file}"
    log_info "Script started at $(date)"
    
    # Handle simple commands first
    if [[ "${list_only}" -eq 1 ]]; then
        list_patches
        exit 0
    fi
    
    if [[ "${template_only}" -eq 1 ]]; then
        log_info "Creating template patches..."
        create_template_patch "${PATCH_SYSVIPC}" "${PATCH_DIR}/${PATCH_SYSVIPC}"
        create_template_patch "${PATCH_POSIX_MQUEUE}" "${PATCH_DIR}/${PATCH_POSIX_MQUEUE}"
        create_template_patch "${PATCH_SYSVIPC_NEW}" "${PATCH_DIR}/${PATCH_SYSVIPC_NEW}"
        log_success "Template patches created in ${PATCH_DIR}"
        exit 0
    fi
    
    if [[ "${check_only}" -eq 1 ]]; then
        check_kernel_requirements
        exit $?
    fi
    
    # Detect kernel version
    local kernel_version
    if ! kernel_version=$(detect_kernel_version); then
        log_error "Failed to detect kernel version"
        exit 1
    fi
    
    log_info "Detected kernel version: ${kernel_version}"
    
    # Determine which patches to apply
    local patches_to_apply=()
    
    if version_in_range "${kernel_version}" "5.4" "6.11.99"; then
        log_info "Kernel 5.4-6.11: SYSVIPC patch required"
        patches_to_apply+=("${PATCH_SYSVIPC}")
        
        if version_gte "5.10.99" "${kernel_version}"; then
            log_info "Kernel ≤5.10: POSIX_MQUEUE patch also required"
            patches_to_apply+=("${PATCH_POSIX_MQUEUE}")
        fi
    elif version_gte "${kernel_version}" "6.12"; then
        log_info "Kernel ≥6.12: New SYSVIPC patch required"
        patches_to_apply+=("${PATCH_SYSVIPC_NEW}")
    else
        log_warning "Kernel version ${kernel_version} may not need these patches"
        log_warning "Proceeding anyway..."
    fi
    
    if [[ ${#patches_to_apply[@]} -eq 0 ]]; then
        log_error "No patches determined for this kernel version"
        exit 1
    fi
    
    log_info "Patches to apply: ${patches_to_apply[*]}"
    
    # Download or create patches
    for patch in "${patches_to_apply[@]}"; do
        download_patch "${patch}"
    done
    
    # Check if patches are already applied (unless forced or reversing)
    if [[ "${force}" -eq 0 && "${reverse}" -eq 0 ]]; then
        local already_applied=0
        for patch in "${patches_to_apply[@]}"; do
            local patch_file="${PATCH_DIR}/${patch}"
            if [[ -f "${patch_file}" ]]; then
                # Try to apply in reverse dry-run to check
                if patch --directory="${KERNEL_DIR}" --strip=1 --reverse --dry-run < "${patch_file}" &>/dev/null; then
                    log_info "Patch ${patch} appears to be already applied"
                    ((already_applied++))
                fi
            fi
        done
        
        if [[ ${already_applied} -eq ${#patches_to_apply[@]} ]]; then
            log_warning "All patches already applied. Use --force to reapply or --reverse to undo."
            exit 0
        fi
    fi
    
    # Backup files before applying
    local backup_dirs=()
    for patch in "${patches_to_apply[@]}"; do
        local patch_file="${PATCH_DIR}/${patch}"
        if [[ -f "${patch_file}" ]]; then
            local backup_dir
            backup_dir=$(backup_files "${patch_file}")
            backup_dirs+=("${backup_dir}")
        fi
    done
    
    if [[ "${backup_only}" -eq 1 ]]; then
        log_success "Backup completed. Files saved in: ${backup_dirs[*]}"
        exit 0
    fi
    
    # Apply patches (or reverse them)
    local success_count=0
    local total_count=${#patches_to_apply[@]}
    
    for i in "${!patches_to_apply[@]}"; do
        local patch="${patches_to_apply[$i]}"
        local patch_file="${PATCH_DIR}/${patch}"
        local backup_dir="${backup_dirs[$i]:-}"
        
        echo ""
        log_info "Processing patch $((i+1))/${total_count}: ${patch}"
        
        if [[ "${reverse}" -eq 1 ]]; then
            if apply_patch "${patch_file}" "${dry_run}" 1; then
                ((success_count++))
                if [[ "${dry_run}" -eq 0 ]]; then
                    log_success "Reversed: ${patch}"
                fi
            fi
        else
            if apply_patch "${patch_file}" "${dry_run}" 0; then
                ((success_count++))
                if [[ "${dry_run}" -eq 0 ]]; then
                    # Verify
                    if verify_patch "${patch_file}"; then
                        record_applied_patch "${patch}" "${backup_dir}"
                    fi
                fi
            fi
        fi
    done
    
    # Summary
    echo ""
    echo "=========================================="
    if [[ "${dry_run}" -eq 1 ]]; then
        log_info "DRY RUN COMPLETE - No changes were made"
        log_info "Patches that would be applied: ${patches_to_apply[*]}"
    elif [[ "${reverse}" -eq 1 ]]; then
        if [[ ${success_count} -eq ${total_count} ]]; then
            log_success "All patches reversed successfully (${success_count}/${total_count})"
        else
            log_warning "Some patches failed to reverse (${success_count}/${total_count})"
        fi
    else
        if [[ ${success_count} -eq ${total_count} ]]; then
            log_success "All patches applied successfully (${success_count}/${total_count})"
            log_info "Backups stored in: ${BACKUP_DIR}"
            log_info "Application log: ${log_file}"
            echo ""
            log_info "Next steps:"
            log_info "1. Enable required config options in your defconfig:"
            log_info "   CONFIG_SYSVIPC=y"
            log_info "   CONFIG_IPC_NS=y"
            log_info "   CONFIG_POSIX_MQUEUE=y"
            log_info "2. Build the kernel normally"
            log_info "3. Test on device - boot loops should be resolved"
        else
            log_error "Some patches failed (${success_count}/${total_count})"
            log_info "Check the log file for details: ${log_file}"
            log_info "You may need to restore from backup"
        fi
    fi
    echo "=========================================="
    
    # Return appropriate exit code
    if [[ ${success_count} -eq ${total_count} ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"