#!/bin/bash
# ============================================================================
# DroidSpaces Kernel Build Script for Xiaomi Pad 5 (nabu)
# Enhanced Production-Grade Kernel Compilation & Boot Image Generation
# 
# Target Device: Xiaomi Pad 5 (nabu)
# Processor: Qualcomm Snapdragon 860 (SM8150)
# Target System: HyperOS 1.0.3.0TKXCNXM
# Kernel Version: 6.1.10
# 
# Usage: ./build_kernel.sh [OPTIONS]
# ============================================================================

set -e  # Exit on any error
set -o pipefail  # Pipe failure detection

# ============================================================================
# Configuration
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="${SCRIPT_DIR}/kernel"
OUTPUT_DIR="${SCRIPT_DIR}/out"
RELEASE_DIR="${SCRIPT_DIR}/release"
LOG_DIR="${SCRIPT_DIR}/logs"
ANYKERNEL_DIR="${SCRIPT_DIR}/AnyKernel3"

# Device configuration
DEVICE="nabu"
DEVICE_NAME="Xiaomi Pad 5"
CODENAME="nabu"
HYPEROS_VERSION="1.0.3.0TKXCNXM"

# Kernel configuration
KERNEL_VERSION="6.1.10"
DEFCONFIG="xiaomi_nabu_droidspace_defconfig"
ARCH="arm64"
CROSS_COMPILE="aarch64-linux-gnu-"

# Build options
BUILD_THREADS=$(nproc)
BUILD_DTB=true
BUILD_MODULES=true
BUILD_DROIDSPACES=true
CLEAN_BUILD=true

# ============================================================================
# Boot Image Parameters (Qualcomm SM8150)
# ============================================================================
# These parameters are critical for proper boot on Xiaomi Pad 5
BOOT_IMAGE_BASE="0x0"
BOOT_IMAGE_PAGESIZE="4096"
BOOT_IMAGE_KERNEL_OFFSET="0x00008000"
BOOT_IMAGE_RAMDISK_OFFSET="0x01f88000"
BOOT_IMAGE_TAGS_OFFSET="0x00000100"
BOOT_IMAGE_HEADER_VERSION="2"

# Command line for boot image
BOOT_CMDLINE="console=ttyMSM0,115200n8 androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1"

# ============================================================================
# Color Output
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

# Print with color and status
print_status() {
    local status="$1"
    local message="$2"
    local timestamp=$(date +"%H:%M:%S")
    
    case $status in
        "info")
            echo -e "${BLUE}[${timestamp}][*]${NC} $message"
            ;;
        "success")
            echo -e "${GREEN}[${timestamp}][✓]${NC} $message"
            ;;
        "warning")
            echo -e "${YELLOW}[${timestamp}][!]${NC} $message"
            ;;
        "error")
            echo -e "${RED}[${timestamp}][✗]${NC} $message"
            ;;
        "step")
            echo -e "${CYAN}[${timestamp}][STEP]${NC} $message"
            ;;
        "debug")
            echo -e "${MAGENTA}[${timestamp}][DEBUG]${NC} $message"
            ;;
    esac
}

# Log function with timestamp
log() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    mkdir -p "$LOG_DIR"
    echo "[$timestamp] $message" >> "${LOG_DIR}/build.log"
}

# Check if command exists
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_status "warning" "Running as root. Consider running as normal user."
    fi
}

# Setup build environment
setup_environment() {
    print_status "step" "Setting up build environment..."
    
    # Create directories
    mkdir -p "$OUTPUT_DIR" "$RELEASE_DIR" "$LOG_DIR"
    
    # Check and install dependencies
    install_dependencies
    
    # Verify cross-compiler
    if ! check_command "${CROSS_COMPILE}gcc"; then
        print_status "error" "Cross-compiler not found: ${CROSS_COMPILE}gcc"
        print_status "info" "Please install gcc-aarch64-linux-gnu"
        exit 1
    fi
    
    # Verify other essential tools
    local essential_tools=("git" "make" "flex" "bison" "bc" "python3" "cpio" "zip" "unzip")
    local missing_tools=()
    
    for tool in "${essential_tools[@]}"; do
        if ! check_command "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_status "error" "Missing essential tools: ${missing_tools[*]}"
        print_status "info" "Please install these tools manually"
        exit 1
    fi
    
    print_status "success" "Build environment ready"
    log "Build environment setup completed"
}

# ============================================================================
# Dependency Management
# ============================================================================

# Detect system type
detect_system() {
    if [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "redhat"
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    elif [ -f /etc/SuSE-release ]; then
        echo "suse"
    else
        echo "unknown"
    fi
}

# Install dependencies based on system type
install_dependencies() {
    print_status "step" "Checking and installing dependencies..."
    
    local system_type=$(detect_system)
    print_status "info" "Detected system type: $system_type"
    
    # List of required packages
    local debian_packages=(
        "git" "make" "gcc" "flex" "bison" "bc" "libssl-dev" "libelf-dev"
        "python3" "cpio" "zip" "unzip" "libncurses-dev" "lsb-release"
        "wget" "curl" "build-essential" "device-tree-compiler"
        "libfl-dev" "libgmp-dev" "libmpc-dev" "libmpfr-dev"
    )
    
    local redhat_packages=(
        "git" "make" "gcc" "flex" "bison" "bc" "openssl-devel" "elfutils-libelf-devel"
        "python3" "cpio" "zip" "unzip" "ncurses-devel" "redhat-lsb-core"
        "wget" "curl" "gcc-c++" "dtc"
    )
    
    local arch_packages=(
        "git" "make" "gcc" "flex" "bison" "bc" "openssl" "libelf"
        "python" "cpio" "zip" "unzip" "ncurses" "base-devel"
        "wget" "curl" "dtc"
    )
    
    local packages_to_install=()
    
    case $system_type in
        "debian")
            packages_to_install=("${debian_packages[@]}")
            ;;
        "redhat")
            packages_to_install=("${redhat_packages[@]}")
            ;;
        "arch")
            packages_to_install=("${arch_packages[@]}")
            ;;
        *)
            print_status "warning" "Unknown system type. Attempting to install packages."
            packages_to_install=("${debian_packages[@]}")
            ;;
    esac
    
    # Check for missing packages
    local missing_packages=()
    for package in "${packages_to_install[@]}"; do
        if ! dpkg -l "$package" >/dev/null 2>&1 && ! rpm -q "$package" >/dev/null 2>&1 && ! pacman -Qi "$package" >/dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        print_status "info" "Missing packages: ${missing_packages[*]}"
        
        # Check if we can use sudo
        if sudo -n true 2>/dev/null; then
            print_status "info" "Installing missing packages..."
            case $system_type in
                "debian")
                    sudo apt-get update
                    sudo apt-get install -y "${missing_packages[@]}"
                    ;;
                "redhat")
                    sudo yum install -y "${missing_packages[@]}"
                    ;;
                "arch")
                    sudo pacman -S --noconfirm "${missing_packages[@]}"
                    ;;
            esac
        else
            print_status "warning" "Cannot install packages automatically (no sudo access)"
            print_status "info" "Please install these packages manually:"
            print_status "info" "  Ubuntu/Debian: sudo apt-get install ${missing_packages[*]}"
            print_status "info" "  Fedora/RHEL: sudo yum install ${missing_packages[*]}"
            print_status "info" "  Arch: sudo pacman -S ${missing_packages[*]}"
        fi
    fi
    
    # Check cross-compiler
    if ! check_command "${CROSS_COMPILE}gcc"; then
        print_status "warning" "Cross-compiler not found: ${CROSS_COMPILE}gcc"
        
        if sudo -n true 2>/dev/null; then
            print_status "info" "Installing cross-compiler..."
            case $system_type in
                "debian")
                    sudo apt-get install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
                    ;;
                "redhat")
                    sudo yum install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
                    ;;
                "arch")
                    sudo pacman -S --noconfirm aarch64-linux-gnu-gcc aarch64-linux-gnu-binutils
                    ;;
            esac
        else
            print_status "warning" "Cannot install cross-compiler automatically (no sudo access)"
            print_status "info" "Please install manually:"
            print_status "info" "  Ubuntu/Debian: sudo apt-get install gcc-aarch64-linux-gnu"
            print_status "info" "  Fedora/RHEL: sudo yum install gcc-aarch64-linux-gnu"
            print_status "info" "  Arch: sudo pacman -S aarch64-linux-gnu-gcc"
        fi
    fi
    
    # Install mkbootimg if not present
    if ! check_command "mkbootimg"; then
        print_status "warning" "mkbootimg not found"
        
        if sudo -n true 2>/dev/null; then
            print_status "info" "Installing mkbootimg..."
            case $system_type in
                "debian")
                    sudo apt-get install -y mkbootimg 2>/dev/null || {
                        print_status "warning" "mkbootimg not available in package manager"
                        print_status "info" "Please install mkbootimg manually or use AnyKernel3 method"
                    }
                    ;;
                *)
                    print_status "warning" "mkbootimg installation not automated for this system"
                    ;;
            esac
        else
            print_status "warning" "Cannot install mkbootimg automatically (no sudo access)"
            print_status "info" "Please install manually or use AnyKernel3 method"
        fi
    fi
    
    # Verify all required tools
    print_status "info" "Verifying required tools..."
    local required_commands=("git" "make" "gcc" "flex" "bison" "bc" "python3" "cpio" "zip" "unzip")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! check_command "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        print_status "error" "Missing required commands: ${missing_commands[*]}"
        print_status "info" "Please install these manually before proceeding"
        exit 1
    fi
    
    print_status "success" "All dependencies satisfied"
    log "Dependencies installed successfully"
}

# ============================================================================
# Kernel Source Management
# ============================================================================

# Clone or update kernel source
manage_kernel_source() {
    print_status "step" "Managing kernel source..."
    
    local update_mode=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --update)
                update_mode=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    if [ -d "$KERNEL_DIR" ]; then
        print_status "info" "Kernel directory exists at $KERNEL_DIR"
        
        if [ "$update_mode" = true ]; then
            print_status "info" "Updating kernel source..."
            cd "$KERNEL_DIR"
            
            # Check if it's a git repository
            if [ -d .git ]; then
                git fetch origin
                git pull --rebase origin main || {
                    print_status "warning" "Failed to pull from origin. Trying to reset..."
                    git reset --hard origin/main
                }
                cd "$SCRIPT_DIR"
                print_status "success" "Kernel source updated"
                log "Kernel source updated"
            else
                print_status "warning" "Not a git repository. Cloning fresh..."
                cd "$SCRIPT_DIR"
                rm -rf "$KERNEL_DIR"
                clone_kernel_source
            fi
        else
            print_status "info" "Using existing kernel source"
        fi
    else
        clone_kernel_source
    fi
    
    # Verify kernel version
    verify_kernel_version
}

# Clone kernel source
clone_kernel_source() {
    print_status "step" "Cloning kernel source..."
    
    local kernel_repo="https://github.com/maverickjb/linux-6.1.10.git"
    local clone_method="direct"
    
    # Try proxychains first if available
    if check_command "proxychains4" || check_command "proxychains"; then
        print_status "info" "Trying to clone with proxychains..."
        local proxy_cmd=""
        if check_command "proxychains4"; then
            proxy_cmd="proxychains4"
        else
            proxy_cmd="proxychains"
        fi
        
        $proxy_cmd git clone --depth=1 "$kernel_repo" "$KERNEL_DIR" 2>/dev/null && {
            print_status "success" "Kernel source cloned with proxychains"
            return 0
        } || {
            print_status "warning" "Proxychains clone failed, falling back to direct clone"
            rm -rf "$KERNEL_DIR" 2>/dev/null || true
        }
    fi
    
    # Direct clone
    print_status "info" "Cloning kernel source directly..."
    git clone --depth=1 "$kernel_repo" "$KERNEL_DIR" || {
        print_status "error" "Failed to clone kernel source"
        print_status "info" "Please check your network connection and try again"
        exit 1
    }
    
    print_status "success" "Kernel source cloned successfully"
    log "Kernel source cloned from $kernel_repo"
}

# Verify kernel version
verify_kernel_version() {
    print_status "step" "Verifying kernel version..."
    
    if [ ! -f "$KERNEL_DIR/Makefile" ]; then
        print_status "error" "Kernel Makefile not found"
        exit 1
    fi
    
    local actual_version=$(grep -m1 "VERSION" "$KERNEL_DIR/Makefile" | cut -d'=' -f2 | tr -d ' ')
    local patch_level=$(grep -m1 "PATCHLEVEL" "$KERNEL_DIR/Makefile" | cut -d'=' -f2 | tr -d ' ')
    local sub_level=$(grep -m1 "SUBLEVEL" "$KERNEL_DIR/Makefile" | cut -d'=' -f2 | tr -d ' ')
    local full_version="${actual_version}.${patch_level}.${sub_level}"
    
    if [ "$full_version" != "$KERNEL_VERSION" ]; then
        print_status "warning" "Kernel version mismatch: Expected $KERNEL_VERSION, Found $full_version"
        print_status "info" "Continuing with available version..."
    else
        print_status "success" "Kernel version verified: $full_version"
    fi
    
    log "Kernel version: $full_version"
}

# ============================================================================
# Configuration Management
# ============================================================================

# Apply kernel configuration
apply_config() {
    print_status "step" "Applying kernel configuration..."
    
    cd "$KERNEL_DIR"
    
    # Copy defconfig if not present
    if [ ! -f "arch/arm64/configs/$DEFCONFIG" ]; then
        print_status "info" "Copying defconfig to kernel source..."
        if [ -f "${SCRIPT_DIR}/arch/arm64/configs/$DEFCONFIG" ]; then
            cp "${SCRIPT_DIR}/arch/arm64/configs/$DEFCONFIG" "arch/arm64/configs/$DEFCONFIG"
        else
            print_status "error" "Defconfig not found: $DEFCONFIG"
            exit 1
        fi
    fi
    
    # Apply defconfig
    print_status "info" "Running make defconfig..."
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE $DEFCONFIG
    
    # Run olddefconfig to resolve any new options
    print_status "info" "Running make olddefconfig..."
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE olddefconfig
    
    # Verify DroidSpaces critical options
    verify_droidspaces_config
    
    cd "$SCRIPT_DIR"
    print_status "success" "Kernel configuration applied"
    log "Kernel configuration applied: $DEFCONFIG"
}

# Verify DroidSpaces configuration
verify_droidspaces_config() {
    print_status "step" "Verifying DroidSpaces support..."
    
    local required_options=(
        "CONFIG_NAMESPACES=y"
        "CONFIG_CGROUPS=y"
        "CONFIG_CGROUP_DEVICE=y"
        "CONFIG_OVERLAY_FS=y"
        "CONFIG_SECCOMP=y"
        "CONFIG_USER_NS=y"
        "CONFIG_PID_NS=y"
        "CONFIG_NET_NS=y"
        "CONFIG_UTS_NS=y"
        "CONFIG_IPC_NS=y"
    )
    
    local recommended_options=(
        "CONFIG_MEMCG=y"
        "CONFIG_MEMCG_SWAP=y"
        "CONFIG_VETH=y"
        "CONFIG_BRIDGE=y"
        "CONFIG_MACVLAN=y"
        "CONFIG_DUMMY=y"
        "CONFIG_VXLAN=m"
    )
    
    local missing_required=()
    local missing_recommended=()
    
    # Check required options
    for option in "${required_options[@]}"; do
        if grep -q "^$option" .config 2>/dev/null || grep -q "^# $option" .config 2>/dev/null; then
            print_status "success" "✓ $option"
        else
            print_status "warning" "✗ $option not set"
            missing_required+=("$option")
        fi
    done
    
    # Check recommended options
    for option in "${recommended_options[@]}"; do
        local option_name=$(echo "$option" | cut -d'=' -f1)
        if grep -q "^$option" .config 2>/dev/null || grep -q "^# $option" .config 2>/dev/null; then
            print_status "success" "✓ $option (recommended)"
        else
            print_status "info" "- $option not set (recommended)"
            missing_recommended+=("$option")
        fi
    done
    
    # Report missing options
    if [ ${#missing_required[@]} -gt 0 ]; then
        print_status "warning" "Missing required options: ${#missing_required[@]}"
        print_status "info" "DroidSpaces may not function correctly without these options"
    fi
    
    if [ ${#missing_recommended[@]} -gt 0 ]; then
        print_status "info" "Missing recommended options: ${#missing_recommended[@]}"
    fi
    
    log "DroidSpaces config verification: ${#missing_required[@]} missing required, ${#missing_recommended[@]} missing recommended"
}

# ============================================================================
# Kernel Compilation
# ============================================================================

# Compile kernel
compile_kernel() {
    print_status "step" "Compiling kernel..."
    
    cd "$KERNEL_DIR"
    
    # Clean if requested
    if [ "$CLEAN_BUILD" = true ]; then
        print_status "info" "Cleaning build directory..."
        make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE clean
        make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper
        # Re-apply config after clean
        make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE $DEFCONFIG
        make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE olddefconfig
    fi
    
    # Record start time
    local start_time=$(date +%s)
    print_status "info" "Starting kernel compilation with $BUILD_THREADS threads..."
    
    # Compile Image
    print_status "info" "Compiling kernel image (Image)..."
    make -j$BUILD_THREADS \
        ARCH=$ARCH \
        CROSS_COMPILE=$CROSS_COMPILE \
        CC="${CROSS_COMPILE}gcc" \
        Image \
        2>&1 | tee "${LOG_DIR}/kernel_compile.log"
    
    # Verify Image was created
    if [ ! -f "arch/arm64/boot/Image" ]; then
        print_status "error" "Kernel Image not found"
        print_status "info" "Check log: ${LOG_DIR}/kernel_compile.log"
        exit 1
    fi
    
    # Compile modules if enabled
    if [ "$BUILD_MODULES" = true ]; then
        print_status "info" "Compiling kernel modules..."
        make -j$BUILD_THREADS \
            ARCH=$ARCH \
            CROSS_COMPILE=$CROSS_COMPILE \
            CC="${CROSS_COMPILE}gcc" \
            modules \
            2>&1 | tee -a "${LOG_DIR}/kernel_compile.log"
    fi
    
    # Compile DTBs if enabled
    if [ "$BUILD_DTB" = true ]; then
        print_status "info" "Compiling device tree blobs (DTBs)..."
        make -j$BUILD_THREADS \
            ARCH=$ARCH \
            CROSS_COMPILE=$CROSS_COMPILE \
            CC="${CROSS_COMPILE}gcc" \
            dtbs \
            2>&1 | tee -a "${LOG_DIR}/kernel_compile.log"
    fi
    
    # Record end time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    print_status "success" "Kernel compilation completed in ${minutes}m ${seconds}s"
    log "Kernel compilation completed in ${minutes}m ${seconds}s"
    
    cd "$SCRIPT_DIR"
}

# ============================================================================
# Module Installation
# ============================================================================

# Install kernel modules
install_modules() {
    if [ "$BUILD_MODULES" = false ]; then
        print_status "info" "Skipping module installation (modules disabled)"
        return 0
    fi
    
    print_status "step" "Installing kernel modules..."
    
    cd "$KERNEL_DIR"
    
    local modules_dir="${OUTPUT_DIR}/modules"
    mkdir -p "$modules_dir"
    
    # Install modules
    make ARCH=$ARCH \
        CROSS_COMPILE=$CROSS_COMPILE \
        INSTALL_MOD_PATH="$modules_dir" \
        modules_install
    
    # Verify modules were installed
    if [ -d "$modules_dir/lib/modules/$KERNEL_VERSION" ]; then
        local module_count=$(find "$modules_dir/lib/modules/$KERNEL_VERSION" -name "*.ko" | wc -l)
        print_status "success" "Installed $module_count kernel modules"
        log "Installed $module_count kernel modules"
    else
        print_status "warning" "No modules directory found"
    fi
    
    cd "$SCRIPT_DIR"
}

# ============================================================================
# Output Packaging
# ============================================================================

# Copy build outputs
copy_outputs() {
    print_status "step" "Copying build outputs..."
    
    mkdir -p "$OUTPUT_DIR"
    
    # Copy kernel image
    if [ -f "$KERNEL_DIR/arch/arm64/boot/Image" ]; then
        cp "$KERNEL_DIR/arch/arm64/boot/Image" "$OUTPUT_DIR/Image"
        print_status "success" "Copied kernel image"
    else
        print_status "error" "Kernel image not found"
        exit 1
    fi
    
    # Copy DTB files
    if [ "$BUILD_DTB" = true ]; then
        mkdir -p "$OUTPUT_DIR/dtbs"
        
        # Copy nabu-specific DTBs
        find "$KERNEL_DIR/arch/arm64/boot/dts" -name "*nabu*.dtb" -exec cp {} "$OUTPUT_DIR/dtbs/" \; 2>/dev/null || true
        
        # Copy SM8150-related DTBs
        find "$KERNEL_DIR/arch/arm64/boot/dts" -name "*sm8150*.dtb" -exec cp {} "$OUTPUT_DIR/dtbs/" \; 2>/dev/null || true
        
        local dtb_count=$(find "$OUTPUT_DIR/dtbs" -name "*.dtb" | wc -l)
        if [ $dtb_count -gt 0 ]; then
            print_status "success" "Copied $dtb_count DTB files"
        else
            print_status "warning" "No DTB files found for nabu/sm8150"
        fi
    fi
    
    log "Build outputs copied to $OUTPUT_DIR"
}

# ============================================================================
# Boot Image Generation
# ============================================================================

# Generate boot.img using mkbootimg
generate_bootimg_mkbootimg() {
    print_status "step" "Generating boot.img using mkbootimg..."
    
    local kernel_img="${OUTPUT_DIR}/Image"
    local output_boot="${OUTPUT_DIR}/boot.img"
    local ramdisk_dir="${OUTPUT_DIR}/ramdisk"
    
    # Check if kernel image exists
    if [ ! -f "$kernel_img" ]; then
        print_status "error" "Kernel image not found: $kernel_img"
        exit 1
    fi
    
    # Check for mkbootimg
    if ! check_command "mkbootimg"; then
        print_status "error" "mkbootimg not found"
        print_status "info" "Install with: sudo apt-get install mkbootimg"
        print_status "info" "Or use AnyKernel3 method: ./build_kernel.sh --use-anykernel"
        return 1
    fi
    
    # Extract or create ramdisk
    if [ ! -d "$ramdisk_dir" ]; then
        print_status "info" "No ramdisk found. Creating minimal ramdisk..."
        create_minimal_ramdisk "$ramdisk_dir"
    fi
    
    # Create ramdisk archive
    local ramdisk_gz="${OUTPUT_DIR}/ramdisk.gz"
    if [ ! -f "$ramdisk_gz" ]; then
        print_status "info" "Creating ramdisk archive..."
        cd "$ramdisk_dir"
        find . | cpio -o -H newc -R 0:0 2>/dev/null | gzip -9 > "$ramdisk_gz"
        cd "$SCRIPT_DIR"
    fi
    
    # Generate boot.img
    print_status "info" "Creating boot.img with mkbootimg..."
    mkbootimg \
        --kernel "$kernel_img" \
        --ramdisk "$ramdisk_gz" \
        --base "$BOOT_IMAGE_BASE" \
        --pagesize "$BOOT_IMAGE_PAGESIZE" \
        --kernel_offset "$BOOT_IMAGE_KERNEL_OFFSET" \
        --ramdisk_offset "$BOOT_IMAGE_RAMDISK_OFFSET" \
        --tags_offset "$BOOT_IMAGE_TAGS_OFFSET" \
        --header_version "$BOOT_IMAGE_HEADER_VERSION" \
        --cmdline "$BOOT_CMDLINE" \
        -o "$output_boot"
    
    if [ -f "$output_boot" ]; then
        print_status "success" "boot.img created successfully"
        print_status "info" "Output: $output_boot"
        ls -lh "$output_boot"
        log "boot.img created using mkbootimg"
    else
        print_status "error" "Failed to create boot.img"
        return 1
    fi
}

# Create minimal ramdisk
create_minimal_ramdisk() {
    local ramdisk_dir="$1"
    
    mkdir -p "$ramdisk_dir"
    cd "$ramdisk_dir"
    
    # Create basic directory structure
    mkdir -p sbin proc sys dev tmp etc
    
    # Create basic init.rc
    cat > init.rc << 'EOF'
# DroidSpaces minimal init.rc
on early-init
    mount rootfs rootfs / ro remount
    mount devtmpfs /dev
    mount proc /proc
    mount sysfs /sys
    mount tmpfs /tmp

on init
    export PATH /sbin:/vendor/bin:/system/bin
    export LD_LIBRARY_PATH /vendor/lib64:/system/lib64

on post-fs
    mount rootfs rootfs / ro remount bind

on property:sys.boot_completed=1
    stop
EOF
    
    cd "$SCRIPT_DIR"
}

# ============================================================================
# AnyKernel3 Packaging
# ============================================================================

# Create AnyKernel3 package
create_anykernel_package() {
    print_status "step" "Creating AnyKernel3 package..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local package_dir="${RELEASE_DIR}/DroidSpaces_${DEVICE}_${timestamp}"
    mkdir -p "$package_dir"
    
    # Verify AnyKernel3 directory exists
    if [ ! -d "$ANYKERNEL_DIR" ]; then
        print_status "error" "AnyKernel3 directory not found: $ANYKERNEL_DIR"
        exit 1
    fi
    
    # Copy AnyKernel3 files
    cp "$ANYKERNEL_DIR/anykernel.sh" "$package_dir/"
    mkdir -p "${package_dir}/tools"
    cp "$ANYKERNEL_DIR/tools/anykernel1.sh" "${package_dir}/tools/" 2>/dev/null || true
    
    # Copy kernel image
    if [ -f "$OUTPUT_DIR/Image" ]; then
        cp "$OUTPUT_DIR/Image" "$package_dir/"
    else
        print_status "error" "Kernel image not found"
        exit 1
    fi
    
    # Copy DTB files
    if [ -d "$OUTPUT_DIR/dtbs" ]; then
        cp "$OUTPUT_DIR/dtbs/"*.dtb "$package_dir/" 2>/dev/null || true
    fi
    
    # Copy modules
    if [ -d "${OUTPUT_DIR}/modules/lib/modules/$KERNEL_VERSION" ]; then
        mkdir -p "${package_dir}/modules"
        cp -r "${OUTPUT_DIR}/modules/lib/modules/$KERNEL_VERSION"/* "${package_dir}/modules/" 2>/dev/null || true
    fi
    
    # Create zip package
    cd "$package_dir"
    zip -r "${RELEASE_DIR}/DroidSpaces_${DEVICE}_${timestamp}.zip" .
    cd "$SCRIPT_DIR"
    
    # Cleanup temporary directory
    rm -rf "$package_dir"
    
    local zip_file="${RELEASE_DIR}/DroidSpaces_${DEVICE}_${timestamp}.zip"
    if [ -f "$zip_file" ]; then
        print_status "success" "AnyKernel3 package created: $zip_file"
        ls -lh "$zip_file"
        log "AnyKernel3 package created: $zip_file"
    else
        print_status "error" "Failed to create AnyKernel3 package"
        exit 1
    fi
}

# ============================================================================
# Release Package Creation
# ============================================================================

# Create complete release package
create_release_package() {
    print_status "step" "Creating release package..."
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local release_name="DroidSpaces_${DEVICE}_${HYPEROS_VERSION}_${timestamp}"
    local release_dir="${RELEASE_DIR}/${release_name}"
    
    mkdir -p "$release_dir"
    
    # Copy boot.img if it exists
    if [ -f "${OUTPUT_DIR}/boot.img" ]; then
        cp "${OUTPUT_DIR}/boot.img" "$release_dir/"
    fi
    
    # Copy AnyKernel3 zip if it exists
    local latest_zip=$(ls -1t "${RELEASE_DIR}"/DroidSpaces_${DEVICE}_*.zip 2>/dev/null | head -1)
    if [ -n "$latest_zip" ] && [ -f "$latest_zip" ]; then
        cp "$latest_zip" "$release_dir/"
    fi
    
    # Copy kernel image and DTBs
    if [ -f "${OUTPUT_DIR}/Image" ]; then
        cp "${OUTPUT_DIR}/Image" "$release_dir/"
    fi
    
    if [ -d "${OUTPUT_DIR}/dtbs" ]; then
        cp "${OUTPUT_DIR}/dtbs/"*.dtb "$release_dir/" 2>/dev/null || true
    fi
    
    # Create flash script
    cat > "${release_dir}/flash.sh" << 'FLASH_SCRIPT'
#!/bin/bash
# DroidSpaces Kernel Flash Script
# Usage: ./flash.sh [boot|recovery|fastboot]

set -e

FLASH_TARGET="${1:-boot}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "DroidSpaces Kernel Flash Script"
echo "========================================="

# Check device connection
if ! adb devices | grep -q "device$"; then
    echo "Error: No device connected via ADB"
    echo "Please ensure USB debugging is enabled"
    exit 1
fi

case $FLASH_TARGET in
    "boot")
        echo "Flashing boot.img to boot partition..."
        adb reboot bootloader
        sleep 5
        if [ -f "$SCRIPT_DIR/boot.img" ]; then
            fastboot flash boot "$SCRIPT_DIR/boot.img"
        else
            echo "Error: boot.img not found in $SCRIPT_DIR"
            exit 1
        fi
        fastboot reboot
        ;;
    "recovery")
        echo "Flashing boot.img to recovery partition..."
        adb reboot bootloader
        sleep 5
        if [ -f "$SCRIPT_DIR/boot.img" ]; then
            fastboot flash recovery "$SCRIPT_DIR/boot.img"
        else
            echo "Error: boot.img not found in $SCRIPT_DIR"
            exit 1
        fi
        fastboot reboot
        ;;
    "fastboot")
        echo "Rebooting to fastboot mode..."
        adb reboot bootloader
        ;;
    *)
        echo "Usage: ./flash.sh [boot|recovery|fastboot]"
        echo ""
        echo "Options:"
        echo "  boot      - Flash to boot partition (default)"
        echo "  recovery  - Flash to recovery partition"
        echo "  fastboot  - Just reboot to fastboot mode"
        exit 1
        ;;
esac

echo ""
echo "Flash complete! Device will reboot."
echo "After reboot, verify with: adb shell uname -r"
FLASH_SCRIPT
    chmod +x "${release_dir}/flash.sh"
    
    # Create README
    cat > "${release_dir}/README.md" << EOF
# DroidSpaces Kernel for Xiaomi Pad 5 (nabu)

## Device Information
- **Device**: Xiaomi Pad 5 (nabu)
- **Processor**: Qualcomm Snapdragon 860 (SM8150)
- **HyperOS Version**: ${HYPEROS_VERSION}
- **Kernel Version**: ${KERNEL_VERSION}
- **Build Date**: $(date)

## Files Included
- \`boot.img\` - Boot image for fastboot flashing
- \`Image\` - Kernel image
- \`*.dtb\` - Device tree blobs
- \`DroidSpaces_*.zip\` - AnyKernel3 flashable zip (for TWRP/OrangeFox)
- \`flash.sh\` - Automated flash script

## Flash Instructions

### Method 1: Using fastboot (Recommended)
\`\`\`bash
# Reboot to bootloader
adb reboot bootloader

# Flash boot.img
fastboot flash boot boot.img

# Reboot
fastboot reboot
\`\`\`

### Method 2: Using AnyKernel3 zip
1. Copy the zip file to your device storage
2. Reboot to recovery (TWRP/OrangeFox)
3. Install the zip file
4. Reboot to system

### Method 3: Using flash script
\`\`\`bash
chmod +x flash.sh
./flash.sh boot
\`\`\`

## Verification
After reboot, verify the kernel:
\`\`\`bash
adb shell uname -r
adb shell cat /proc/version
\`\`\`

## DroidSpaces Support
This kernel includes full support for DroidSpaces containers:
- **Namespaces**: PID, UTS, IPC, NET, USER
- **Cgroups**: Resource management and device access
- **OverlayFS**: Container layer support
- **Network**: Bridge, veth, macvlan support
- **Security**: Seccomp filtering

## Important Notes
- This kernel is specifically built for HyperOS ${HYPEROS_VERSION}
- **Always backup your current boot.img before flashing**
- If bootloop occurs, flash stock boot.img via fastboot
- For best performance, ensure proper thermal management

## Troubleshooting
- **Bootloop**: Flash stock boot.img or use recovery to restore
- **No network**: Ensure network namespace modules are loaded
- **Container issues**: Verify all required kernel options are enabled

## Support
For issues or questions, please refer to the project documentation.
EOF
    
    # Calculate checksums
    print_status "info" "Calculating checksums..."
    cd "$release_dir"
    
    # Create MD5 checksums
    find . -type f \( -name "*.img" -o -name "*.zip" -o -name "*.dtb" \) -exec md5sum {} \; > MD5SUMS.txt
    
    cd "$SCRIPT_DIR"
    
    # Create tarball
    cd "${RELEASE_DIR}"
    tar -czf "${release_name}.tar.gz" "$release_name"
    cd "$SCRIPT_DIR"
    
    # Generate build summary
    generate_build_summary "$release_dir" "$release_name"
    
    print_status "success" "Release package created: ${release_name}"
    ls -lh "${RELEASE_DIR}/${release_name}.tar.gz"
    log "Release package created: ${release_name}"
}

# ============================================================================
# Build Summary and Reporting
# ============================================================================

# Generate build summary
generate_build_summary() {
    local release_dir="$1"
    local release_name="$2"
    
    print_status "step" "Generating build summary..."
    
    local summary_file="${LOG_DIR}/build_summary.txt"
    
    cat > "$summary_file" << EOF
===========================================
DroidSpaces Kernel Build Summary
===========================================
Build Date: $(date)
Device: ${DEVICE_NAME} (${DEVICE})
Processor: Qualcomm Snapdragon 860 (SM8150)
Target System: HyperOS ${HYPEROS_VERSION}
Kernel Version: ${KERNEL_VERSION}
Build Threads: ${BUILD_THREADS}

===========================================
Output Files
===========================================
EOF
    
    # List output files with sizes
    if [ -f "${OUTPUT_DIR}/boot.img" ]; then
        echo "boot.img: $(ls -lh "${OUTPUT_DIR}/boot.img" | awk '{print $5}')" >> "$summary_file"
        echo "  MD5: $(md5sum "${OUTPUT_DIR}/boot.img" | awk '{print $1}')" >> "$summary_file"
    fi
    
    if [ -f "${OUTPUT_DIR}/Image" ]; then
        echo "Image: $(ls -lh "${OUTPUT_DIR}/Image" | awk '{print $5}')" >> "$summary_file"
        echo "  MD5: $(md5sum "${OUTPUT_DIR}/Image" | awk '{print $1}')" >> "$summary_file"
    fi
    
    if [ -d "${OUTPUT_DIR}/dtbs" ]; then
        local dtb_count=$(find "${OUTPUT_DIR}/dtbs" -name "*.dtb" | wc -l)
        echo "DTBs: ${dtb_count} files" >> "$summary_file"
    fi
    
    if [ -d "${OUTPUT_DIR}/modules/lib/modules/$KERNEL_VERSION" ]; then
        local module_count=$(find "${OUTPUT_DIR}/modules/lib/modules/$KERNEL_VERSION" -name "*.ko" | wc -l)
        echo "Modules: ${module_count} files" >> "$summary_file"
    fi
    
    local latest_zip=$(ls -1t "${RELEASE_DIR}"/DroidSpaces_${DEVICE}_*.zip 2>/dev/null | head -1)
    if [ -n "$latest_zip" ] && [ -f "$latest_zip" ]; then
        echo "AnyKernel3 ZIP: $(ls -lh "$latest_zip" | awk '{print $5}')" >> "$summary_file"
    fi
    
    if [ -f "${RELEASE_DIR}/${release_name}.tar.gz" ]; then
        echo "Release tarball: $(ls -lh "${RELEASE_DIR}/${release_name}.tar.gz" | awk '{print $5}')" >> "$summary_file"
    fi
    
    cat >> "$summary_file" << EOF

===========================================
DroidSpaces Configuration
===========================================
EOF
    
    # List enabled DroidSpaces features
    if [ -f "$KERNEL_DIR/.config" ]; then
        for option in NAMESPACES PID_NS NET_NS USER_NS UTS_NS IPC_NS CGROUPS OVERLAY_FS SECCOMP VETH BRIDGE; do
            if grep -q "CONFIG_${option}=y" "$KERNEL_DIR/.config" 2>/dev/null; then
                echo "✓ CONFIG_${option}" >> "$summary_file"
            fi
        done
    fi
    
    cat >> "$summary_file" << EOF

===========================================
Flash Instructions
===========================================
1. Copy boot.img to your device
2. Reboot to bootloader: adb reboot bootloader
3. Flash boot: fastboot flash boot boot.img
4. Reboot: fastboot reboot

Or use AnyKernel3 zip with TWRP/OrangeFox recovery.
===========================================
EOF
    
    print_status "success" "Build summary saved to: $summary_file"
    cat "$summary_file"
}

# ============================================================================
# Cleanup Functions
# ============================================================================

# Clean build artifacts
clean_build() {
    print_status "step" "Cleaning build artifacts..."
    
    # Clean kernel build directory
    if [ -d "$KERNEL_DIR" ]; then
        cd "$KERNEL_DIR"
        make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE clean 2>/dev/null || true
        make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper 2>/dev/null || true
        cd "$SCRIPT_DIR"
    fi
    
    # Remove output directories
    rm -rf "$OUTPUT_DIR"
    rm -rf "$RELEASE_DIR"
    
    print_status "success" "Build artifacts cleaned"
    log "Build artifacts cleaned"
}

# Cleanup on error
cleanup_on_error() {
    print_status "error" "Build failed!"
    print_status "info" "Check logs for details:"
    print_status "info" "  - Build log: ${LOG_DIR}/build.log"
    print_status "info" "  - Compile log: ${LOG_DIR}/kernel_compile.log"
    
    # Show last few lines of error
    if [ -f "${LOG_DIR}/kernel_compile.log" ]; then
        print_status "error" "Last error from compile log:"
        tail -20 "${LOG_DIR}/kernel_compile.log"
    fi
}

# ============================================================================
# Help and Usage
# ============================================================================

show_usage() {
    echo "DroidSpaces Kernel Build Script for ${DEVICE_NAME} (${DEVICE})"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -c, --clean             Clean build directory"
    echo "  -n, --no-clean          Don't clean before building"
    echo "  -t, --threads N         Set number of build threads (default: $(nproc))"
    echo "  -s, --setup-only        Only setup environment"
    echo "  -k, --kernel-only       Only compile kernel"
    echo "  -p, --package-only      Only create package"
    echo "  -m, --no-modules        Don't compile modules"
    echo "  --use-anykernel         Use AnyKernel3 packaging only"
    echo "  --use-mkbootimg         Use mkbootimg for boot.img generation"
    echo "  --update                Update kernel source before building"
    echo ""
    echo "Examples:"
    echo "  $0                      # Full build with clean"
    echo "  $0 -n                   # Build without cleaning"
    echo "  $0 -c                   # Clean build"
    echo "  $0 -t 8                 # Build with 8 threads"
    echo "  $0 --use-anykernel      # Only create AnyKernel3 zip"
    echo "  $0 --use-mkbootimg      # Generate boot.img with mkbootimg"
    echo ""
    echo "Output Files:"
    echo "  - boot.img              # Boot image for fastboot"
    echo "  - DroidSpaces_*.zip     # AnyKernel3 flashable zip"
    echo "  - Release tarball       # Complete release package"
    echo ""
}

# ============================================================================
# Command Line Argument Parsing
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -c|--clean)
                clean_build
                exit 0
                ;;
            -n|--no-clean)
                CLEAN_BUILD=false
                shift
                ;;
            -t|--threads)
                BUILD_THREADS="$2"
                shift 2
                ;;
            -s|--setup-only)
                setup_environment
                exit 0
                ;;
            -k|--kernel-only)
                compile_kernel
                copy_outputs
                exit 0
                ;;
            -p|--package-only)
                if [ -f "${OUTPUT_DIR}/Image" ]; then
                    create_anykernel_package
                else
                    print_status "error" "No kernel image found. Run full build first."
                    exit 1
                fi
                exit 0
                ;;
            -m|--no-modules)
                BUILD_MODULES=false
                shift
                ;;
            --use-anykernel)
                if [ -f "${OUTPUT_DIR}/Image" ]; then
                    create_anykernel_package
                else
                    print_status "error" "No kernel image found. Run full build first."
                    exit 1
                fi
                exit 0
                ;;
            --use-mkbootimg)
                if [ -f "${OUTPUT_DIR}/Image" ]; then
                    generate_bootimg_mkbootimg
                else
                    print_status "error" "No kernel image found. Run full build first."
                    exit 1
                fi
                exit 0
                ;;
            --update)
                manage_kernel_source --update
                shift
                ;;
            *)
                print_status "error" "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# Main Build Process
# ============================================================================

main_build() {
    print_status "info" "=========================================="
    print_status "info" "DroidSpaces Kernel Build for ${DEVICE_NAME}"
    print_status "info" "HyperOS Version: ${HYPEROS_VERSION}"
    print_status "info" "Kernel Version: ${KERNEL_VERSION}"
    print_status "info" "=========================================="
    echo ""
    
    # Initialize log
    mkdir -p "$LOG_DIR"
    log "Build started"
    
    # Set up error handling
    trap cleanup_on_error ERR
    
    # Check root
    check_root
    
    # Install dependencies
    install_dependencies
    
    # Setup environment
    setup_environment
    
    # Clone or update kernel source
    manage_kernel_source
    
    # Apply configuration
    apply_config
    
    # Compile kernel
    compile_kernel
    
    # Install modules
    install_modules
    
    # Copy outputs
    copy_outputs
    
    # Generate boot.img (try both methods)
    if [ "$BUILD_DROIDSPACES" = true ]; then
        # Try mkbootimg first
        if check_command "mkbootimg"; then
            generate_bootimg_mkbootimg
        else
            print_status "info" "mkbootimg not available, using AnyKernel3 method"
        fi
        
        # Always create AnyKernel3 package
        create_anykernel_package
    fi
    
    # Create release package
    create_release_package
    
    echo ""
    print_status "success" "=========================================="
    print_status "success" "Build completed successfully!"
    print_status "success" "=========================================="
    echo ""
    print_status "info" "Output files:"
    
    if [ -f "${OUTPUT_DIR}/boot.img" ]; then
        print_status "info" "  boot.img: ${OUTPUT_DIR}/boot.img"
    fi
    
    local latest_zip=$(ls -1t "${RELEASE_DIR}"/DroidSpaces_${DEVICE}_*.zip 2>/dev/null | head -1)
    if [ -n "$latest_zip" ] && [ -f "$latest_zip" ]; then
        print_status "info" "  AnyKernel3 ZIP: $latest_zip"
    fi
    
    local latest_tarball=$(ls -1t "${RELEASE_DIR}"/*.tar.gz 2>/dev/null | head -1)
    if [ -n "$latest_tarball" ] && [ -f "$latest_tarball" ]; then
        print_status "info" "  Release tarball: $latest_tarball"
    fi
    
    echo ""
    print_status "info" "To install on your device:"
    print_status "info" "  adb reboot bootloader"
    
    if [ -f "${OUTPUT_DIR}/boot.img" ]; then
        print_status "info" "  fastboot flash boot ${OUTPUT_DIR}/boot.img"
    else
        print_status "info" "  Copy AnyKernel3 zip to device and flash via recovery"
    fi
    
    print_status "info" "  fastboot reboot"
    echo ""
    print_status "info" "Build logs: ${LOG_DIR}/"
    echo ""
    
    # Disable error trap
    trap - ERR
}

# ============================================================================
# Script Entry Point
# ============================================================================

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Parse arguments
    parse_arguments "$@"
    
    # Run main build
    main_build
fi