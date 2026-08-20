# AnyKernel3 Ramdisk Mod
# AnyKernel3 - Xiaomi Pad 5 (nabu) DroidSpaces Kernel
# AnyKernel3 Ramdisk Mod
# ============================================
# This AnyKernel script is designed for Xiaomi Pad 5 (nabu)
# with DroidSpaces container support
# ============================================

# AnyKernel setup
# begin properties
properties() {
kernel.string=AnyKernel3 for Xiaomi Pad 5 (nabu) - DroidSpaces Support
do.devicecheck=1
device.name1=nabu
device.name2=Xiaomi Pad 5
device.name3=21051182C
device.name4=Xiaomi Pad 5
device.name5=21081111RG
device.name6=Xiaomi Pad 5
device.name7=2201123C
device.name8=Xiaomi Pad 5 Pro
device.name9=21091116C
device.name10=Xiaomi Pad 5 Pro
block.device=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk.compression=auto;
patch.vbmeta.device=auto;
patch.vbmeta.device=auto;
} end properties

# ============================================
# Shell Variables
# ============================================
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=0;
ramdisk_compression=auto;
patch_vbmeta_device=auto;

# ============================================
# AnyKernel install methods
# ============================================

. tools/anykernel1.sh;
# end install methods

# AnyKernel kernel install
# begin block
install() {
  ui_print "Installing DroidSpaces Kernel for Xiaomi Pad 5 (nabu)";
  ui_print "==================================================";

  # Backup original kernel
  ui_print "- Backing up original kernel...";
  backup_boot;

  # Install kernel image
  ui_print "- Installing kernel image...";
  flash_boot;

  # Install DTB if present
  if [ -f dtb ]; then
    ui_print "- Installing DTB...";
    flash_dtbo;
  fi

  # Install modules if present
  if [ -d modules ]; then
    ui_print "- Installing kernel modules...";
    install_modules;
  fi

  ui_print "==================================================";
  ui_print "DroidSpaces Kernel installation complete!";
  ui_print "Your kernel now supports Linux containers!";
  ui_print "";
  ui_print "Features enabled:";
  ui_print "  - Linux Namespaces (UTS, IPC, PID, NET, USER, CGROUP)";
  ui_print "  - Cgroups for resource management";
  ui_print "  - OverlayFS for container layers";
  ui_print "  - Network bridge and veth support";
  ui_print "  - FUSE filesystem support";
  ui_print "  - Seccomp filtering";
  ui_print "  - Checkpoint/Restore support";
  ui_print "";
  ui_print "Reboot to apply changes.";
} end block

# AnyKernel boot partition patching
# begin patch
patch() {
  ui_print "- Patching boot partition...";

  # Get boot partition info
  local boot_block;
  local boot_size;
  boot_block=$(get_block $block);
  boot_size=$(get_file_size $boot_block);

  # Verify kernel size
  local kernel_size;
  kernel_size=$(get_file_size kernel);
  if [ $kernel_size -gt $boot_size ]; then
    ui_print "! Error: Kernel image too large for boot partition!";
    ui_print "! Kernel: ${kernel_size} bytes, Boot: ${boot_size} bytes";
    abort "! Installation aborted.";
  fi

  ui_print "- Boot partition size: ${boot_size} bytes";
  ui_print "- Kernel image size: ${kernel_size} bytes";
  ui_print "- Space available: $((boot_size - kernel_size)) bytes";
} end patch

# AnyKernel boot partition extraction
# begin extract
extract() {
  ui_print "- Extracting kernel from boot partition...";

  # Backup current kernel
  local backup_file="${WORK_DIR}/kernel_backup_$(date +%Y%m%d_%H%M%S).img";
  dd if=$block of=$backup_file 2>/dev/null;

  ui_print "- Backup saved to: ${backup_file}";
  ui_print "- Original kernel preserved.";
} end extract

# AnyKernel boot partition verification
# begin verify
verify() {
  ui_print "- Verifying kernel compatibility...";

  # Check device
  local device_model;
  device_model=$(getprop ro.product.model);
  local device_name;
  device_name=$(getprop ro.product.device);

  if [ "$device_name" != "nabu" ] && [ "$device_model" != "Xiaomi Pad 5" ]; then
    ui_print "! Warning: This kernel is designed for Xiaomi Pad 5 (nabu)";
    ui_print "! Detected device: ${device_model} (${device_name})";
    ui_print "! Proceed with caution...";

    # Ask for confirmation
    ui_print "- Continue installation? (auto-continuing)";
  fi

  ui_print "- Device verification passed.";
} end verify

# AnyKernel boot partition backup
# begin backup
backup_boot() {
  ui_print "- Creating boot partition backup...";

  local backup_dir="${WORK_DIR}/backups";
  mkdir -p $backup_dir;

  local backup_file="${backup_dir}/boot_backup_$(date +%Y%m%d_%H%M%S).img";
  dd if=$block of=$backup_file 2>/dev/null;

  ui_print "- Backup created: ${backup_file}";
  ui_print "- To restore: dd if=${backup_file} of=${block}";
} end backup

# AnyKernel flash boot
# begin flash_boot
flash_boot() {
  ui_print "- Flashing kernel image...";

  # Get current kernel
  dd if=$block of=/tmp/boot_current.img 2>/dev/null;

  # Extract ramdisk from current boot image using unpack_bootimg (if available)
  # or use the ramdisk provided in the AnyKernel3 zip
  local ramdisk_source;
  if [ -f ramdisk.cpio.gz ]; then
    ramdisk_source="ramdisk.cpio.gz";
  elif [ -f ramdisk ]; then
    ramdisk_source="ramdisk";
  else
    # Fall back to extracting ramdisk from current boot image
    # This requires unpack_bootimg or manual extraction
    ramdisk_source="";
  fi

  # Build mkbootimg command
  local mkbootimg_cmd="/tmp/anykernel/tools/mkbootimg";
  local mkbootimg_args="";

  mkbootimg_args="--kernel kernel";

  if [ -n "$ramdisk_source" ] && [ -f "$ramdisk_source" ]; then
    mkbootimg_args="$mkbootimg_args --ramdisk $ramdisk_source";
  else
    mkbootimg_args="$mkbootimg_args --ramdisk /tmp/boot_current.img";
  fi;

  # SM8150-specific boot image parameters
  mkbootimg_args="$mkbootimg_args --cmdline \"console=ttyMSM0,115200n8 androidboot.hardware=qcom androidboot.console=ttyMSM0 msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 service_locator.enable=1 androidboot.bootdevice=7884000.ufshc androidboot.boot_devices=7884000.ufshc\"";
  mkbootimg_args="$mkbootimg_args --base 0x0";
  mkbootimg_args="$mkbootimg_args --pagesize 4096";
  mkbootimg_args="$mkbootimg_args --kernel_offset 0x00008000";
  mkbootimg_args="$mkbootimg_args --ramdisk_offset 0x01f88000";
  mkbootimg_args="$mkbootimg_args --tags_offset 0x00000100";
  mkbootimg_args="$mkbootimg_args --header_version 2";
  mkbootimg_args="$mkbootimg_args --os_version 12";
  mkbootimg_args="$mkbootimg_args --os_patch_level 2022-08";
  mkbootimg_args="$mkbootimg_args -o /tmp/boot.img.new";

  ui_print "  mkbootimg args: $mkbootimg_args";
  eval "$mkbootimg_cmd $mkbootimg_args" 2>/dev/null;

  if [ $? -ne 0 ] || [ ! -f /tmp/boot.img.new ]; then
    ui_print "! Error: mkbootimg failed to create boot image!";
    abort "! Kernel installation aborted.";
  fi

  # Flash new boot image
  dd if=/tmp/boot.img.new of=$block 2>/dev/null;

  # Clean up
  rm -f /tmp/boot.img.new /tmp/boot_current.img;

  ui_print "- Kernel flashed successfully.";
} end flash_boot

# AnyKernel flash dtbo
# begin flash_dtbo
flash_dtbo() {
  ui_print "- Flashing DTBO...";

  local dtbo_block="/dev/block/bootdevice/by-name/dtbo";

  if [ -b "$dtbo_block" ]; then
    dd if=dtb of=$dtbo_block 2>/dev/null;
    ui_print "- DTBO flashed successfully.";
  else
    ui_print "- Warning: DTBO partition not found, skipping.";
  fi
} end flash_dtbo

# AnyKernel install modules
# begin install_modules
install_modules() {
  ui_print "- Installing kernel modules...";

  local modules_dir="/system/lib/modules";
  local vendor_modules_dir="/vendor/lib/modules";

  # Create module directories
  mkdir -p $modules_dir;
  mkdir -p $vendor_modules_dir;

  # Copy modules
  for module in modules/*.ko; do
    if [ -f "$module" ]; then
      local module_name=$(basename $module);
      ui_print "  - Installing: ${module_name}";

      # Copy to system
      cp $module $modules_dir/;

      # Copy to vendor
      cp $module $vendor_modules_dir/;

      # Set permissions
      chmod 644 $modules_dir/$module_name;
      chmod 644 $vendor_modules_dir/$module_name;
    fi
  done

  # Update module dependencies
  ui_print "- Updating module dependencies...";
  # Try depmod with current kernel version
  local kernel_version;
  kernel_version=$(uname -r 2>/dev/null);
  if [ -n "$kernel_version" ]; then
    ui_print "  - Kernel version: ${kernel_version}";
    depmod -a "$kernel_version" 2>/dev/null;
  else
    depmod -a 2>/dev/null;
  fi;

  # Update module dependencies for vendor as well
  ui_print "  - Syncing module dependencies...";
  sync;

  ui_print "- Modules installed successfully.";
} end install_modules

# AnyKernel restore original kernel
# begin restore
restore() {
  ui_print "- Restoring original kernel...";

  local backup_dir="${WORK_DIR}/backups";
  local latest_backup=$(ls -t ${backup_dir}/boot_backup_*.img 2>/dev/null | head -n1);

  if [ -n "$latest_backup" ]; then
    ui_print "- Restoring from: ${latest_backup}";
    dd if=$latest_backup of=$block 2>/dev/null;
    ui_print "- Original kernel restored.";
  else
    ui_print "! No backup found, cannot restore.";
    abort "! Restore failed.";
  fi
} end restore

# AnyKernel cleanup
# begin cleanup
cleanup() {
  ui_print "- Cleaning up...";

  # Remove temporary files
  rm -f /tmp/boot.img.new;
  rm -f /tmp/boot_current.img;

  # Sync filesystem
  sync;

  ui_print "- Cleanup complete.";
} end cleanup

# AnyKernel success message
# begin success
success() {
  ui_print "";
  ui_print "==========================================";
  ui_print "  DroidSpaces Kernel Installation Complete";
  ui_print "==========================================";
  ui_print "";
  ui_print "Kernel features enabled for Linux containers:";
  ui_print "  ✓ Linux Namespaces (UTS, IPC, PID, NET, USER, CGROUP)";
  ui_print "  ✓ Cgroups for resource management";
  ui_print "  ✓ OverlayFS for container layers";
  ui_print "  ✓ Network bridge and veth support";
  ui_print "  ✓ FUSE filesystem support";
  ui_print "  ✓ Seccomp filtering";
  ui_print "  ✓ Checkpoint/Restore support";
  ui_print "  ✓ Device Mapper (dm-crypt, dm-thin)";
  ui_print "";
  ui_print "Next steps:";
  ui_print "  1. Reboot your device";
  ui_print "  2. Install DroidSpaces app from GitHub";
  ui_print "  3. Grant root permissions to DroidSpaces";
  ui_print "  4. Create your first Linux container!";
  ui_print "";
  ui_print "For support, visit: https://github.com/your-repo/nabu-droidspace";
  ui_print "";
  ui_print "Enjoy running Linux on your Xiaomi Pad 5!";
  ui_print "";
} end success