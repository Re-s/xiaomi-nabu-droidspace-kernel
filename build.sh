#!/bin/bash
# DroidSpaces Kernel Build Script for Xiaomi Pad 5 (nabu)
# This script automates the entire kernel build process

set -e  # Exit on any error

# ============================================
# Configuration
# ============================================
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

# ============================================
# Color Output
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================
# Helper Functions
# ============================================

# Print with color
print_status() {
  local status="$1"
  local message="$2"
  
  case $status in
    "info")
      echo -e "${BLUE}[*]${NC} $message"
      ;;
    "success")
      echo -e "${GREEN}[+]${NC} $message"
      ;;
    "warning")
      echo -e "${YELLOW}[!]${NC} $message"
      ;;
    "error")
      echo -e "${RED}[ERROR]${NC} $message"
      ;;
    "step")
      echo -e "${CYAN}[STEP]${NC} $message"
      ;;
  esac
}

# Log function
log() {
  local message="$1"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "[$timestamp] $message" >> "${LOG_DIR}/build.log"
}

# Check if command exists
check_command() {
  command -v "$1" >/dev/null 2>&1
}

# Check if running as root
check_root() {
  if [ "$EUID" -ne 0 ]; then
    print_status "warning" "Not running as root. Some operations may fail."
  fi
}

# ============================================
# Setup Functions
# ============================================

# Setup build environment
setup_environment() {
  print_status "step" "Setting up build environment..."
  
  # Create directories
  mkdir -p "$OUTPUT_DIR"
  mkdir -p "$RELEASE_DIR"
  mkdir -p "$LOG_DIR"
  
  # Check required tools
  local required_tools=("git" "make" "gcc" "flex" "bison" "bc" "libssl-dev" "libelf-dev")
  local missing_tools=()
  
  for tool in "${required_tools[@]}"; do
    if ! check_command "$tool"; then
      missing_tools+=("$tool")
    fi
  done
  
  if [ ${#missing_tools[@]} -gt 0 ]; then
    print_status "error" "Missing required tools: ${missing_tools[*]}"
    print_status "info" "Install them with: sudo apt-get install ${missing_tools[*]}"
    exit 1
  fi
  
  # Check cross-compiler
  if ! check_command "${CROSS_COMPILE}gcc"; then
    print_status "error" "Cross-compiler not found: ${CROSS_COMPILE}gcc"
    print_status "info" "Install with: sudo apt-get install gcc-aarch64-linux-gnu"
    exit 1
  fi
  
  print_status "success" "Build environment ready"
  log "Build environment setup completed"
}

# Clone kernel source
clone_kernel() {
  print_status "step" "Cloning kernel source..."
  
  if [ -d "$KERNEL_DIR" ]; then
    print_status "info" "Kernel directory already exists"
    read -p "Do you want to update it? (y/N): " update_kernel
    if [[ $update_kernel =~ ^[Yy]$ ]]; then
      cd "$KERNEL_DIR"
      git pull
      cd "$SCRIPT_DIR"
    fi
  else
    print_status "info" "Cloning kernel source for $DEVICE_NAME ($CODENAME)..."
    git clone --depth=1 https://github.com/maverickjb/linux-6.1.10.git "$KERNEL_DIR"
  fi
  
  print_status "success" "Kernel source ready"
  log "Kernel source cloned"
}

# Apply DroidSpaces configuration
apply_config() {
  print_status "step" "Applying DroidSpaces configuration..."
  
  cd "$KERNEL_DIR"
  
  # Check if defconfig exists
  if [ ! -f "arch/arm64/configs/$DEFCONFIG" ]; then
    print_status "error" "Defconfig not found: $DEFCONFIG"
    exit 1
  fi
  
  # Apply configuration
  make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE $DEFCONFIG
  
  # Verify critical options
  print_status "info" "Verifying DroidSpaces support..."
  
  local required_options=(
    "CONFIG_NAMESPACES=y"
    "CONFIG_CGROUPS=y"
    "CONFIG_OVERLAY_FS=y"
    "CONFIG_USER_NS=y"
    "CONFIG_PID_NS=y"
    "CONFIG_NET_NS=y"
  )
  
  for option in "${required_options[@]}"; do
    if grep -q "$option" .config; then
      print_status "success" "✓ $option"
    else
      print_status "warning" "✗ $option not set"
    fi
  done
  
  cd "$SCRIPT_DIR"
  print_status "success" "Configuration applied"
  log "DroidSpaces configuration applied"
}

# Compile kernel
compile_kernel() {
  print_status "step" "Compiling kernel..."
  
  cd "$KERNEL_DIR"
  
  # Clean if requested
  if [ "$CLEAN_BUILD" = true ]; then
    print_status "info" "Cleaning build directory..."
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE clean
  fi
  
  # Compile kernel
  print_status "info" "Starting kernel compilation with $BUILD_THREADS threads..."
  make -j$BUILD_THREADS \
    ARCH=$ARCH \
    CROSS_COMPILE=$CROSS_COMPILE \
    Image \
    modules \
    dtbs 2>&1 | tee "${LOG_DIR}/kernel_compile.log"
  
  # Check if compilation succeeded
  if [ $? -eq 0 ]; then
    print_status "success" "Kernel compilation successful"
    log "Kernel compiled successfully"
  else
    print_status "error" "Kernel compilation failed"
    print_status "info" "Check log: ${LOG_DIR}/kernel_compile.log"
    exit 1
  fi
  
  cd "$SCRIPT_DIR"
}

# Package kernel
package_kernel() {
  print_status "step" "Packaging kernel..."
  
  cd "$KERNEL_DIR"
  
  # Create output directory
  mkdir -p "$OUTPUT_DIR"
  
  # Copy kernel image
  cp arch/arm64/boot/Image "$OUTPUT_DIR/Image"
  print_status "info" "Copied kernel image"
  
  # Copy DTB files
  if [ "$BUILD_DTB" = true ]; then
    find arch/arm64/boot/dts -name "*nabu*.dtb" -exec cp {} "$OUTPUT_DIR/" \; 2>/dev/null || true
    find arch/arm64/boot/dts -name "*sm8150*.dtb" -exec cp {} "$OUTPUT_DIR/" \; 2>/dev/null || true
    print_status "info" "Copied DTB files"
  fi
  
  # Install modules
  if [ "$BUILD_MODULES" = true ]; then
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE \
      INSTALL_MOD_PATH="$OUTPUT_DIR/modules" \
      modules_install
    print_status "info" "Installed kernel modules"
  fi
  
  cd "$SCRIPT_DIR"
  print_status "success" "Kernel packaged"
  log "Kernel packaged"
}

# Create AnyKernel3 package
create_anykernel_package() {
  print_status "step" "Creating AnyKernel3 package..."
  
  # Create release directory
  local timestamp=$(date +"%Y%m%d_%H%M%S")
  local package_dir="${RELEASE_DIR}/DroidSpaces_${DEVICE}_${timestamp}"
  mkdir -p "$package_dir"
  
  # Copy AnyKernel3 files
  cp -r "$ANYKERNEL_DIR"/* "$package_dir/"
  
  # Copy kernel files
  cp "$OUTPUT_DIR/Image" "$package_dir/"
  if [ -d "$OUTPUT_DIR/modules" ]; then
    mkdir -p "$package_dir/modules"
    cp -r "$OUTPUT_DIR/modules/lib/modules/"* "$package_dir/modules/" 2>/dev/null || true
  fi
  
  # Copy DTB files
  for dtb in "$OUTPUT_DIR"/*.dtb; do
    if [ -f "$dtb" ]; then
      cp "$dtb" "$package_dir/"
    fi
  done
  
  # Create zip package
  cd "$package_dir"
  zip -r "${RELEASE_DIR}/DroidSpaces_${DEVICE}_${timestamp}.zip" .
  cd "$SCRIPT_DIR"
  
  # Cleanup temporary directory
  rm -rf "$package_dir"
  
  print_status "success" "AnyKernel3 package created: DroidSpaces_${DEVICE}_${timestamp}.zip"
  log "AnyKernel3 package created"
}

# Clean build
clean_build() {
  print_status "step" "Cleaning build..."
  
  if [ -d "$KERNEL_DIR" ]; then
    cd "$KERNEL_DIR"
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE clean
    cd "$SCRIPT_DIR"
  fi
  
  rm -rf "$OUTPUT_DIR"
  rm -rf "$RELEASE_DIR"
  rm -rf "$LOG_DIR"
  
  print_status "success" "Build cleaned"
  log "Build cleaned"
}

# ============================================
# Main Functions
# ============================================

# Show usage
show_usage() {
  echo "DroidSpaces Kernel Build Script for $DEVICE_NAME ($DEVICE)"
  echo ""
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -h, --help          Show this help message"
  echo "  -c, --clean         Clean build directory"
  echo "  -n, --no-clean      Don't clean before building"
  echo "  -t, --threads N     Set number of build threads (default: $(nproc))"
  echo "  -d, --no-dtb        Don't build DTB"
  echo "  -m, --no-modules    Don't build modules"
  echo "  -s, --setup-only    Only setup environment"
  echo "  -b, --build-only    Only build kernel"
  echo "  -p, --package-only  Only create package"
  echo ""
  echo "Examples:"
  echo "  $0                  # Full build with clean"
  echo "  $0 -n               # Build without cleaning"
  echo "  $0 -c               # Clean build"
  echo "  $0 -t 8             # Build with 8 threads"
  echo ""
}

# Parse command line arguments
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
      -d|--no-dtb)
        BUILD_DTB=false
        shift
        ;;
      -m|--no-modules)
        BUILD_MODULES=false
        shift
        ;;
      -s|--setup-only)
        setup_environment
        exit 0
        ;;
      -b|--build-only)
        compile_kernel
        package_kernel
        exit 0
        ;;
      -p|--package-only)
        create_anykernel_package
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done
}

# Main build process
main_build() {
  print_status "info" "Starting DroidSpaces kernel build for $DEVICE_NAME ($DEVICE)"
  print_status "info" "Build threads: $BUILD_THREADS"
  print_status "info" "Clean build: $CLEAN_BUILD"
  print_status "info" "Build DTB: $BUILD_DTB"
  print_status "info" "Build modules: $BUILD_MODULES"
  echo ""
  
  # Initialize log
  mkdir -p "$LOG_DIR"
  log "Build started"
  
  # Run build steps
  setup_environment
  clone_kernel
  apply_config
  compile_kernel
  package_kernel
  create_anykernel_package
  
  echo ""
  print_status "success" "Build completed successfully!"
  print_status "info" "Release package: $(ls -1 ${RELEASE_DIR}/*.zip 2>/dev/null | tail -1)"
  print_status "info" "Build logs: ${LOG_DIR}/"
  echo ""
  print_status "info" "To install on your device:"
  print_status "info" "1. Copy the zip file to your device"
  print_status "info" "2. Boot into custom recovery (TWRP/OrangeFox)"
  print_status "info" "3. Flash the zip file"
  print_status "info" "4. Reboot"
  echo ""
}

# ============================================
# Script Entry Point
# ============================================

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # Parse arguments
  parse_arguments "$@"
  
  # Run main build
  main_build
fi