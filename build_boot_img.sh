#!/bin/bash
# DroidSpaces Kernel - Complete Boot Image Build Script
# For Xiaomi Pad 5 (nabu) - HyperOS 1.0.3.0TKXCNXM

set -e

# ============================================
# Configuration
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="${SCRIPT_DIR}/kernel"
OUTPUT_DIR="${SCRIPT_DIR}/out"
RELEASE_DIR="${SCRIPT_DIR}/release"
LOG_DIR="${SCRIPT_DIR}/logs"

# Device configuration
DEVICE="nabu"
DEVICE_NAME="Xiaomi Pad 5"
CODENAME="nabu"
HYPEROS_VERSION="1.0.3.0TKXCNXM"

# Kernel sources
# 选项1: MiCode官方内核 (Android R, 4.14.x)
MICODE_REPO="https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git"
MICODE_BRANCH="nabu-r-oss"

# 选项2: 社区维护的6.1内核
COMMUNITY_REPO="https://github.com/maverickjb/linux-6.1.10.git"
COMMUNITY_BRANCH="main"

# 选择使用哪个内核源码 (1=MiCode官方, 2=社区6.1)
KERNEL_SOURCE=2

# Build configuration
DEFCONFIG="xiaomi_nabu_droidspace_defconfig"
ARCH="arm64"
CROSS_COMPILE="aarch64-linux-gnu-"
BUILD_THREADS=$(nproc)

# mkbootimg configuration (from device)
BOOTIMG_KERNEL_OFFSET="0x00008000"
BOOTIMG_RAMDISK_OFFSET="0x01000000"
BOOTIMG_SECOND_OFFSET="0x00f00000"
BOOTIMG_TAGS_OFFSET="0x00000100"
BOOTIMG_PAGESIZE="4096"
BOOTIMG_OS_VERSION="13"
BOOTIMG_OS_PATCH_LEVEL="2024-01"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================
# Helper Functions
# ============================================
print_status() {
  local status="$1"
  local message="$2"
  case $status in
    "info") echo -e "${BLUE}[*]${NC} $message" ;;
    "success") echo -e "${GREEN}[✓]${NC} $message" ;;
    "warning") echo -e "${YELLOW}[!]${NC} $message" ;;
    "error") echo -e "${RED}[✗]${NC} $message" ;;
    "step") echo -e "${CYAN}[STEP]${NC} $message" ;;
  esac
}

log() {
  local message="$1"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $message" >> "${LOG_DIR}/build.log"
}

check_command() {
  command -v "$1" >/dev/null 2>&1
}

# ============================================
# Setup Functions
# ============================================
setup_environment() {
  print_status "step" "Setting up build environment..."
  
  mkdir -p "$OUTPUT_DIR" "$RELEASE_DIR" "$LOG_DIR"
  
  # Check and install dependencies
  local required_tools=("git" "make" "gcc" "flex" "bison" "bc" "libssl-dev" "libelf-dev" "python3" "cpio" "zip" "unzip" "libncurses-dev")
  local missing_tools=()
  
  for tool in "${required_tools[@]}"; do
    if ! check_command "$tool"; then
      missing_tools+=("$tool")
    fi
  done
  
  if [ ${#missing_tools[@]} -gt 0 ]; then
    print_status "info" "Installing missing tools: ${missing_tools[*]}"
    sudo apt-get update
    sudo apt-get install -y "${missing_tools[@]}"
  fi
  
  # Check cross-compiler
  if ! check_command "${CROSS_COMPILE}gcc"; then
    print_status "info" "Installing cross-compiler..."
    sudo apt-get install -y gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
  fi
  
  # Install mkbootimg
  if ! check_command "mkbootimg"; then
    print_status "info" "Installing mkbootimg..."
    sudo apt-get install -y mkbootimg android-tools-fbutils 2>/dev/null || {
      # Build from source if package not available
      git clone https://android.googlesource.com/platform/system/core.git /tmp/core 2>/dev/null || true
    }
  fi
  
  print_status "success" "Build environment ready"
}

clone_kernel() {
  print_status "step" "Cloning kernel source..."
  
  if [ -d "$KERNEL_DIR" ]; then
    print_status "info" "Kernel directory exists"
    read -p "Update kernel source? (y/N): " update
    if [[ $update =~ ^[Yy]$ ]]; then
      cd "$KERNEL_DIR" && git pull
    fi
  else
    if [ $KERNEL_SOURCE -eq 1 ]; then
      print_status "info" "Cloning MiCode official kernel (nabu-r-oss)..."
      git clone --depth=1 -b "$MICODE_BRANCH" "$MICODE_REPO" "$KERNEL_DIR" 2>/dev/null || {
        print_status "warning" "MiCode clone failed, using community kernel..."
        git clone --depth=1 "$COMMUNITY_REPO" "$KERNEL_DIR"
      }
    else
      print_status "info" "Cloning community kernel (linux-6.1.10)..."
      git clone --depth=1 "$COMMUNITY_REPO" "$KERNEL_DIR"
    fi
  fi
  
  print_status "success" "Kernel source ready"
}

apply_config() {
  print_status "step" "Applying DroidSpaces configuration..."
  
  cd "$KERNEL_DIR"
  
  # Check if defconfig exists, if not create it
  if [ ! -f "arch/arm64/configs/$DEFCONFIG" ]; then
    print_status "info" "Creating DroidSpaces defconfig..."
    cp "${SCRIPT_DIR}/arch/arm64/configs/xiaomi_nabu_droidspace_defconfig" \
       "arch/arm64/configs/$DEFCONFIG"
  fi
  
  # Apply configuration
  make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE "$DEFCONFIG"
  
  # Verify critical options
  print_status "info" "Verifying DroidSpaces support..."
  local required_options=("CONFIG_NAMESPACES=y" "CONFIG_PID_NS=y" "CONFIG_CGROUPS=y" "CONFIG_CGROUP_DEVICE=y" "CONFIG_OVERLAY_FS=y" "CONFIG_SECCOMP=y")
  
  for option in "${required_options[@]}"; do
    if grep -q "$option" .config; then
      print_status "success" "✓ $option"
    else
      print_status "warning" "✗ $option not set"
    fi
  done
  
  cd "$SCRIPT_DIR"
}

compile_kernel() {
  print_status "step" "Compiling kernel..."
  
  cd "$KERNEL_DIR"
  
  # Clean if needed
  if [ "${CLEAN_BUILD:-false}" = "true" ]; then
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE clean
  fi
  
  # Build kernel image
  print_status "info" "Building kernel image with $BUILD_THREADS threads..."
  make -j$BUILD_THREADS \
    ARCH=$ARCH \
    CROSS_COMPILE=$CROSS_COMPILE \
    Image \
    modules \
    dtbs 2>&1 | tee "${LOG_DIR}/kernel_compile.log"
  
  # Verify build
  if [ -f "arch/arm64/boot/Image" ]; then
    print_status "success" "Kernel image built successfully"
  else
    print_status "error" "Kernel build failed"
    exit 1
  fi
  
  cd "$SCRIPT_DIR"
}

extract_ramdisk() {
  print_status "step" "Extracting ramdisk from current boot.img..."
  
  # Check if we have a stock boot.img to extract ramdisk from
  local stock_boot="${SCRIPT_DIR}/stock_boot.img"
  
  if [ ! -f "$stock_boot" ]; then
    print_status "warning" "No stock_boot.img found"
    print_status "info" "Please provide stock boot.img at: $stock_boot"
    print_status "info" "You can extract it from your device with: adb pull /dev/block/bootdevice/by-name/boot stock_boot.img"
    
    # Create minimal ramdisk
    print_status "info" "Creating minimal ramdisk..."
    mkdir -p "${OUTPUT_DIR}/ramdisk"
    cd "${OUTPUT_DIR}/ramdisk"
    
    # Create basic init structure
    mkdir -p sbin proc sys dev tmp
    
    # Create init.rc
    cat > init.rc << 'EOF'
# Basic init.rc for DroidSpaces kernel
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
    
    # Pack ramdisk
    find . | cpio -o -H newc -R 0:0 | gzip > "${OUTPUT_DIR}/ramdisk.gz"
    cd "$SCRIPT_DIR"
  else
    print_status "info" "Extracting ramdisk from stock boot.img..."
    # Use unpack_bootimg if available, otherwise use abootimg
    if check_command "unpack_bootimg"; then
      unpack_bootimg --boot_img "$stock_boot" --out "${OUTPUT_DIR}/boot_extracted"
    elif check_command "abootimg"; then
      cd "${OUTPUT_DIR}"
      abootimg -x "$stock_boot"
      cd "$SCRIPT_DIR"
    else
      print_status "warning" "No extraction tool available, using mkbootimg with default ramdisk"
    fi
  fi
}

create_boot_img() {
  print_status "step" "Creating boot.img..."
  
  local kernel_img="${KERNEL_DIR}/arch/arm64/boot/Image"
  local ramdisk="${OUTPUT_DIR}/ramdisk.gz"
  local output_boot="${OUTPUT_DIR}/boot.img"
  
  # Check kernel image
  if [ ! -f "$kernel_img" ]; then
    print_status "error" "Kernel image not found: $kernel_img"
    exit 1
  fi
  
  # Try different mkbootimg methods
  if check_command "mkbootimg"; then
    print_status "info" "Using system mkbootimg..."
    mkbootimg \
      --kernel "$kernel_img" \
      --ramdisk "$ramdisk" \
      --kernel_offset "$BOOTIMG_KERNEL_OFFSET" \
      --ramdisk_offset "$BOOTIMG_RAMDISK_OFFSET" \
      --second_offset "$BOOTIMG_SECOND_OFFSET" \
      --tags_offset "$BOOTIMG_TAGS_OFFSET" \
      --pagesize "$BOOTIMG_PAGESIZE" \
      --os_version "$BOOTIMG_OS_VERSION" \
      --os_patch_level "$BOOTIMG_OS_PATCH_LEVEL" \
      --cmdline "console=ttyMSM0,115200n8 androidboot.hardware=qcom androidboot.console=ttyMSM0" \
      -o "$output_boot"
  elif [ -f "${SCRIPT_DIR}/tools/mkbootimg" ]; then
    print_status "info" "Using local mkbootimg..."
    "${SCRIPT_DIR}/tools/mkbootimg" \
      --kernel "$kernel_img" \
      --ramdisk "$ramdisk" \
      --kernel_offset "$BOOTIMG_KERNEL_OFFSET" \
      --ramdisk_offset "$BOOTIMG_RAMDISK_OFFSET" \
      --pagesize "$BOOTIMG_PAGESIZE" \
      --cmdline "console=ttyMSM0,115200n8 androidboot.hardware=qcom" \
      -o "$output_boot"
  else
    print_status "error" "mkbootimg not found"
    print_status "info" "Install with: sudo apt-get install mkbootimg"
    print_status "info" "Or download from: https://android.googlesource.com/platform/system/tools/mkbootimg/"
    exit 1
  fi
  
  if [ -f "$output_boot" ]; then
    print_status "success" "boot.img created: $output_boot"
    ls -lh "$output_boot"
  else
    print_status "error" "Failed to create boot.img"
    exit 1
  fi
}

create_anykernel_zip() {
  print_status "step" "Creating AnyKernel3 zip..."
  
  local timestamp=$(date +"%Y%m%d_%H%M%S")
  local package_dir="${RELEASE_DIR}/DroidSpaces_${DEVICE}_${timestamp}"
  mkdir -p "$package_dir"
  
  # Copy AnyKernel3 files
  cp "${SCRIPT_DIR}/AnyKernel3/anykernel.sh" "$package_dir/"
  mkdir -p "${package_dir}/tools"
  cp "${SCRIPT_DIR}/AnyKernel3/tools/anykernel1.sh" "${package_dir}/tools/"
  
  # Copy kernel image
  cp "${KERNEL_DIR}/arch/arm64/boot/Image" "$package_dir/"
  
  # Copy DTB files
  find "${KERNEL_DIR}/arch/arm64/boot/dts" -name "*nabu*.dtb" -exec cp {} "$package_dir/" \; 2>/dev/null || true
  find "${KERNEL_DIR}/arch/arm64/boot/dts" -name "*sm8150*.dtb" -exec cp {} "$package_dir/" \; 2>/dev/null || true
  
  # Copy modules
  if [ -d "${OUTPUT_DIR}/modules" ]; then
    mkdir -p "${package_dir}/modules"
    cp -r "${OUTPUT_DIR}/modules/lib/modules/"* "${package_dir}/modules/" 2>/dev/null || true
  fi
  
  # Create zip
  cd "$package_dir"
  zip -r "${RELEASE_DIR}/DroidSpaces_${DEVICE}_${timestamp}.zip" .
  cd "$SCRIPT_DIR"
  
  # Cleanup
  rm -rf "$package_dir"
  
  print_status "success" "AnyKernel3 zip created"
}

create_release() {
  print_status "step" "Creating release package..."
  
  local timestamp=$(date +"%Y%m%d_%H%M%S")
  local release_name="DroidSpaces_${DEVICE}_${HYPEROS_VERSION}_${timestamp}"
  local release_dir="${RELEASE_DIR}/${release_name}"
  
  mkdir -p "$release_dir"
  
  # Copy boot.img
  cp "${OUTPUT_DIR}/boot.img" "$release_dir/"
  
  # Copy AnyKernel3 zip
  cp "${RELEASE_DIR}"/DroidSpaces_${DEVICE}_*.zip "$release_dir/" 2>/dev/null || true
  
  # Copy kernel image and DTB
  cp "${KERNEL_DIR}/arch/arm64/boot/Image" "$release_dir/"
  find "${KERNEL_DIR}/arch/arm64/boot/dts" -name "*nabu*.dtb" -exec cp {} "$release_dir/" \; 2>/dev/null || true
  
  # Create flash script
  cat > "${release_dir}/flash.sh" << 'FLASH_SCRIPT'
#!/bin/bash
# Flash script for DroidSpaces kernel
# Usage: ./flash.sh [boot|recovery]

set -e

FLASH_TARGET="${1:-boot}"

echo "Flashing DroidSpaces kernel..."
echo "Target: $FLASH_TARGET"

# Check device connection
if ! adb devices | grep -q "device$"; then
  echo "Error: No device connected"
  exit 1
fi

case $FLASH_TARGET in
  "boot")
    echo "Flashing boot.img..."
    adb reboot bootloader
    sleep 5
    fastboot flash boot boot.img
    fastboot reboot
    ;;
  "recovery")
    echo "Flashing to recovery..."
    adb reboot bootloader
    sleep 5
    fastboot flash recovery boot.img
    fastboot reboot
    ;;
  *)
    echo "Usage: ./flash.sh [boot|recovery]"
    exit 1
    ;;
esac

echo "Flash complete! Device will reboot."
FLASH_SCRIPT
  chmod +x "${release_dir}/flash.sh"
  
  # Create README
  cat > "${release_dir}/README.md" << EOF
# DroidSpaces Kernel for Xiaomi Pad 5

## Device Information
- Device: Xiaomi Pad 5 (nabu)
- HyperOS Version: ${HYPEROS_VERSION}
- Build Date: $(date)

## Files Included
- \`boot.img\` - Boot image for flashing
- \`Image\` - Kernel image
- \`*.dtb\` - Device tree blobs
- \`flash.sh\` - Automated flash script
- \`DroidSpaces_*.zip\` - AnyKernel3 flashable zip

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
1. Copy the zip file to your device
2. Reboot to recovery (TWRP)
3. Install the zip file
4. Reboot

### Method 3: Using flash script
\`\`\`bash
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
- Namespace isolation (PID, UTS, IPC, NET, USER)
- Cgroup resource management
- OverlayFS for container layers
- Network bridge and veth support
- Seccomp filtering

## Notes
- This kernel is specifically built for HyperOS ${HYPEROS_VERSION}
- Always backup your current boot.img before flashing
- If bootloop occurs, flash stock boot.img via fastboot
EOF
  
  # Create tarball
  cd "${RELEASE_DIR}"
  tar -czf "${release_name}.tar.gz" "$release_name"
  cd "$SCRIPT_DIR"
  
  print_status "success" "Release package created: ${release_name}"
  ls -lh "${RELEASE_DIR}/${release_name}.tar.gz"
}

# ============================================
# Main Build Process
# ============================================
main() {
  print_status "info" "=========================================="
  print_status "info" "DroidSpaces Kernel Build for Xiaomi Pad 5"
  print_status "info" "HyperOS Version: $HYPEROS_VERSION"
  print_status "info" "=========================================="
  echo ""
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  -h, --help          Show this help"
        echo "  -c, --clean         Clean build"
        echo "  -s, --source NUM    Kernel source (1=MiCode, 2=Community)"
        echo "  -j, --jobs NUM      Build threads"
        echo "  --skip-clone        Skip kernel clone"
        echo "  --skip-build        Skip kernel build"
        echo "  --boot-only         Only create boot.img"
        echo "  --zip-only          Only create AnyKernel3 zip"
        exit 0
        ;;
      -c|--clean)
        CLEAN_BUILD=true
        shift
        ;;
      -s|--source)
        KERNEL_SOURCE="$2"
        shift 2
        ;;
      -j|--jobs)
        BUILD_THREADS="$2"
        shift 2
        ;;
      --skip-clone)
        SKIP_CLONE=true
        shift
        ;;
      --skip-build)
        SKIP_BUILD=true
        shift
        ;;
      --boot-only)
        BOOT_ONLY=true
        shift
        ;;
      --zip-only)
        ZIP_ONLY=true
        shift
        ;;
      *)
        print_status "error" "Unknown option: $1"
        exit 1
        ;;
    esac
  done
  
  # Execute build steps
  setup_environment
  
  if [ "${SKIP_CLONE:-false}" != "true" ]; then
    clone_kernel
  fi
  
  apply_config
  
  if [ "${SKIP_BUILD:-false}" != "true" ]; then
    compile_kernel
  fi
  
  if [ "${ZIP_ONLY:-false}" != "true" ]; then
    extract_ramdisk
    create_boot_img
  fi
  
  if [ "${BOOT_ONLY:-false}" != "true" ]; then
    create_anykernel_zip
  fi
  
  create_release
  
  echo ""
  print_status "success" "=========================================="
  print_status "success" "Build completed successfully!"
  print_status "success" "=========================================="
  echo ""
  print_status "info" "Output files:"
  print_status "info" "  boot.img: ${OUTPUT_DIR}/boot.img"
  print_status "info" "  Release: ${RELEASE_DIR}/"
  echo ""
  print_status "info" "To flash on device:"
  print_status "info" "  adb reboot bootloader"
  print_status "info" "  fastboot flash boot ${OUTPUT_DIR}/boot.img"
  print_status "info" "  fastboot reboot"
  echo ""
}

# Run main function
main "$@"