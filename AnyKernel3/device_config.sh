#!/bin/bash
# Device Configuration for Xiaomi Pad 5 (nabu)
# DroidSpaces Kernel Configuration

# ============================================
# Device Information
# ============================================
DEVICE_NAME="Xiaomi Pad 5"
DEVICE_CODENAME="nabu"
DEVICE_MODEL="21051182C"
DEVICE_BRAND="Xiaomi"
DEVICE_MANUFACTURER="Xiaomi"
DEVICE_PLATFORM="Qualcomm SM8150"

# ============================================
# Partition Information
# ============================================
BOOT_PARTITION="/dev/block/bootdevice/by-name/boot"
DTBO_PARTITION="/dev/block/bootdevice/by-name/dtbo"
RECOVERY_PARTITION="/dev/block/bootdevice/by-name/recovery"
SYSTEM_PARTITION="/dev/block/bootdevice/by-name/system"
VENDOR_PARTITION="/dev/block/bootdevice/by-name/vendor"

# ============================================
# Kernel Configuration
# ============================================
KERNEL_VERSION="6.1.10"
KERNEL_NAME="DroidSpaces Kernel"
KERNEL_STRING="DroidSpaces Kernel for Xiaomi Pad 5 (nabu)"
KERNEL_CONFIG="xiaomi_nabu_droidspace_defconfig"
KERNEL_IMAGE="Image"
KERNEL_DTB="sm8150-xiaomi-nabu.dtb"

# ============================================
# Build Configuration
# ============================================
ARCH="arm64"
SUBARCH="arm64"
CROSS_COMPILE="aarch64-linux-gnu-"
BUILD_DIR="out"
BUILD_THREADS=$(nproc)

# ============================================
# AnyKernel3 Configuration
# ============================================
ANYKERNEL3_DIR="AnyKernel3"
ANYKERNEL3_SCRIPT="anykernel.sh"
ANYKERNEL3_TOOLS="tools"

# ============================================
# Module Configuration
# ============================================
MODULES_DIR="modules"
SYSTEM_MODULES_DIR="/system/lib/modules"
VENDOR_MODULES_DIR="/vendor/lib/modules"

# ============================================
# Boot Image Configuration
# ============================================
BOOT_IMAGE_BASE="0x0"
BOOT_IMAGE_PAGESIZE="4096"
BOOT_IMAGE_OS_VERSION="12"
BOOT_IMAGE_OS_PATCH_LEVEL="2022-08"

# ============================================
# Command Line Parameters
# ============================================
BOOT_CMDLINE="console=ttyMSM0,115200n8 androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.console=ttyMSM0,115200n8 msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 service_locator.enable=1 androidboot.bootdevice=7884000.ufshc androidboot.boot_devices=7884000.ufshc androidboot.boot_devices=7884000.ufshc"

# ============================================
# DroidSpaces Specific Configuration
# ============================================
DROIDSPACES_ENABLE="true"
DROIDSPACES_NAMESPACES="yes"
DROIDSPACES_CGROUPS="yes"
DROIDSPACES_OVERLAYFS="yes"
DROIDSPACES_NETWORKING="yes"
DROIDSPACES_SECURITY="yes"

# ============================================
# Build Options
# ============================================
BUILD_CLEAN="true"
BUILD_MODULES="true"
BUILD_DTB="true"
BUILD_DROIDSPACES="true"

# ============================================
# Output Configuration
# ============================================
OUTPUT_DIR="out"
RELEASE_DIR="release"
LOG_DIR="logs"

# ============================================
# Helper Functions
# ============================================

# Print device information
print_device_info() {
  echo "==========================================";
  echo "  Device Configuration";
  echo "==========================================";
  echo "Device Name: $DEVICE_NAME";
  echo "Device Codename: $DEVICE_CODENAME";
  echo "Device Model: $DEVICE_MODEL";
  echo "Device Brand: $DEVICE_BRAND";
  echo "Device Manufacturer: $DEVICE_MANUFACTURER";
  echo "Device Platform: $DEVICE_PLATFORM";
  echo "";
  echo "Kernel Version: $KERNEL_VERSION";
  echo "Kernel Name: $KERNEL_NAME";
  echo "Kernel Config: $KERNEL_CONFIG";
  echo "";
  echo "Boot Partition: $BOOT_PARTITION";
  echo "DTBO Partition: $DTBO_PARTITION";
  echo "System Partition: $SYSTEM_PARTITION";
  echo "Vendor Partition: $VENDOR_PARTITION";
  echo "";
  echo "Architecture: $ARCH";
  echo "Cross Compiler: $CROSS_COMPILE";
  echo "Build Threads: $BUILD_THREADS";
  echo "";
  echo "DroidSpaces Support: $DROIDSPACES_ENABLE";
  echo "Namespaces Support: $DROIDSPACES_NAMESPACES";
  echo "Cgroups Support: $DROIDSPACES_CGROUPS";
  echo "OverlayFS Support: $DROIDSPACES_OVERLAYFS";
  echo "Networking Support: $DROIDSPACES_NETWORKING";
  echo "Security Support: $DROIDSPACES_SECURITY";
  echo "==========================================";
}

# Validate device configuration
validate_device_config() {
  echo "Validating device configuration...";

  # Check if running on correct device
  local device_name=$(getprop ro.product.device 2>/dev/null);
  if [ "$device_name" != "$DEVICE_CODENAME" ]; then
    echo "Warning: This configuration is for $DEVICE_NAME ($DEVICE_CODENAME)";
    echo "Detected device: $device_name";
    echo "Continuing anyway...";
  fi

  # Check partitions
  if [ ! -b "$BOOT_PARTITION" ]; then
    echo "Error: Boot partition not found: $BOOT_PARTITION";
    return 1;
  fi

  if [ ! -b "$DTBO_PARTITION" ]; then
    echo "Warning: DTBO partition not found: $DTBO_PARTITION";
    echo "DTB flashing will be skipped.";
  fi

  echo "Device configuration validated.";
  return 0;
}

# Get device properties
get_device_properties() {
  echo "Device Properties:";
  echo "  Model: $(getprop ro.product.model)";
  echo "  Device: $(getprop ro.product.device)";
  echo "  Brand: $(getprop ro.product.brand)";
  echo "  Manufacturer: $(getprop ro.product.manufacturer)";
  echo "  Android Version: $(getprop ro.build.version.release)";
  echo "  SDK Version: $(getprop ro.build.version.sdk)";
  echo "  Build ID: $(getprop ro.build.display.id)";
  echo "  Build Type: $(getprop ro.build.type)";
}

# Check device compatibility
check_device_compatibility() {
  echo "Checking device compatibility...";

  local device_name=$(getprop ro.product.device 2>/dev/null);
  local android_version=$(getprop ro.build.version.release 2>/dev/null);

  # Check device
  if [ "$device_name" != "$DEVICE_CODENAME" ]; then
    echo "Incompatible device: $device_name (expected $DEVICE_CODENAME)";
    return 1;
  fi

  # Check Android version (minimum Android 10)
  if [ -n "$android_version" ]; then
    local major_version=$(echo $android_version | cut -d. -f1);
    if [ $major_version -lt 10 ]; then
      echo "Warning: Android version $android_version may not be fully supported";
      echo "Recommended: Android 10 or higher";
    fi
  fi

  echo "Device compatibility check passed.";
  return 0;
}

# ============================================
# Export functions
# ============================================

# Export all variables and functions
export DEVICE_NAME DEVICE_CODENAME DEVICE_MODEL DEVICE_BRAND DEVICE_MANUFACTURER DEVICE_PLATFORM
export BOOT_PARTITION DTBO_PARTITION RECOVERY_PARTITION SYSTEM_PARTITION VENDOR_PARTITION
export KERNEL_VERSION KERNEL_NAME KERNEL_STRING KERNEL_CONFIG KERNEL_IMAGE KERNEL_DTB
export ARCH SUBARCH CROSS_COMPILE BUILD_DIR BUILD_THREADS
export ANYKERNEL3_DIR ANYKERNEL3_SCRIPT ANYKERNEL3_TOOLS
export MODULES_DIR SYSTEM_MODULES_DIR VENDOR_MODULES_DIR
export BOOT_IMAGE_BASE BOOT_IMAGE_PAGESIZE BOOT_IMAGE_OS_VERSION BOOT_IMAGE_OS_PATCH_LEVEL
export BOOT_CMDLINE
export DROIDSPACES_ENABLE DROIDSPACES_NAMESPACES DROIDSPACES_CGROUPS DROIDSPACES_OVERLAYFS DROIDSPACES_NETWORKING DROIDSPACES_SECURITY
export BUILD_CLEAN BUILD_MODULES BUILD_DTB BUILD_DROIDSPACES
export OUTPUT_DIR RELEASE_DIR LOG_DIR

# Export functions
export -f print_device_info validate_device_config get_device_properties check_device_compatibility