# ============================================
# DroidSpaces Kernel Build - Makefile
# ============================================

# Device configuration
DEVICE := nabu
DEVICE_NAME := Xiaomi Pad 5

# Kernel configuration
KERNEL_VERSION := 6.1.10
DEFCONFIG := xiaomi_nabu_droidspace_defconfig

# Build configuration
ARCH := arm64
CROSS_COMPILE := aarch64-linux-gnu-
BUILD_THREADS := $(shell nproc)

# Directories
KERNEL_DIR := kernel
OUTPUT_DIR := out
RELEASE_DIR := release
LOG_DIR := logs
ANYKERNEL_DIR := AnyKernel3

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

# ============================================
# Default target
# ============================================
.PHONY: all help setup kernel modules dtbs package clean flash

all: help

# ============================================
# Help target
# ============================================
help:
	@echo "$(BLUE)==========================================$(NC)"
	@echo "$(GREEN)  DroidSpaces Kernel Build System$(NC)"
	@echo "$(GREEN)  Device: $(DEVICE_NAME) ($(DEVICE))$(NC)"
	@echo "$(BLUE)==========================================$(NC)"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@echo ""
	@echo "  $(GREEN)setup$(NC)       - Setup build environment"
	@echo "  $(GREEN)clone$(NC)       - Clone kernel source"
	@echo "  $(GREEN)config$(NC)      - Apply DroidSpaces configuration"
	@echo "  $(GREEN)kernel$(NC)      - Compile kernel image"
	@echo "  $(GREEN)modules$(NC)     - Compile kernel modules"
	@echo "  $(GREEN)dtbs$(NC)        - Compile device tree blobs"
	@echo "  $(GREEN)build$(NC)       - Build everything (kernel + modules + dtbs)"
	@echo "  $(GREEN)package$(NC)     - Create AnyKernel3 package"
	@echo "  $(GREEN)release$(NC)     - Create release package"
	@echo "  $(GREEN)flash$(NC)       - Flash kernel via ADB"
	@echo "  $(GREEN)clean$(NC)       - Clean build directory"
	@echo "  $(GREEN)distclean$(NC)   - Clean everything"
	@echo ""
	@echo "$(YELLOW)Quick start:$(NC)"
	@echo "  make setup      # Setup environment"
	@echo "  make clone      # Get kernel source"
	@echo "  make config     # Apply configuration"
	@echo "  make build      # Compile kernel"
	@echo "  make package    # Create flashable zip"
	@echo ""
	@echo "$(YELLOW)For more information, see README.md$(NC)"

# ============================================
# Setup targets
# ============================================
setup:
	@echo "$(BLUE)Setting up build environment...$(NC)"
	@mkdir -p $(OUTPUT_DIR) $(RELEASE_DIR) $(LOG_DIR)
	@echo "$(GREEN)Build directories created$(NC)"
	@echo "$(BLUE)Checking required tools...$(NC)"
	@which git >/dev/null 2>&1 || (echo "$(RED)Error: git not found$(NC)" && exit 1)
	@which make >/dev/null 2>&1 || (echo "$(RED)Error: make not found$(NC)" && exit 1)
	@which $(CROSS_COMPILE)gcc >/dev/null 2>&1 || (echo "$(RED)Error: cross-compiler not found$(NC)" && exit 1)
	@echo "$(GREEN)Build environment ready$(NC)"

# ============================================
# Clone kernel
# ============================================
clone:
	@echo "$(BLUE)Cloning kernel source...$(NC)"
	@if [ -d "$(KERNEL_DIR)" ]; then \
		echo "$(YELLOW)Kernel directory already exists$(NC)"; \
		echo "$(YELLOW)Updating...$(NC)"; \
		cd $(KERNEL_DIR) && git pull; \
	else \
		echo "$(BLUE)Cloning from GitHub...$(NC)"; \
		git clone --depth=1 https://github.com/maverickjb/linux-6.1.10.git $(KERNEL_DIR); \
	fi
	@echo "$(GREEN)Kernel source ready$(NC)"

# ============================================
# Configuration
# ============================================
config:
	@echo "$(BLUE)Applying DroidSpaces configuration...$(NC)"
	@if [ -d "$(KERNEL_DIR)" ]; then \
		cd $(KERNEL_DIR) && \
		make ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) $(DEFCONFIG) && \
		echo "$(GREEN)Configuration applied$(NC)"; \
	else \
		echo "$(RED)Error: Kernel directory not found$(NC)"; \
		echo "$(YELLOW)Run 'make clone' first$(NC)"; \
		exit 1; \
	fi

# ============================================
# Build targets
# ============================================
kernel:
	@echo "$(BLUE)Compiling kernel image...$(NC)"
	@if [ -d "$(KERNEL_DIR)" ]; then \
		cd $(KERNEL_DIR) && \
		make -j$(BUILD_THREADS) \
			ARCH=$(ARCH) \
			CROSS_COMPILE=$(CROSS_COMPILE) \
			Image 2>&1 | tee ../$(LOG_DIR)/kernel.log; \
		echo "$(GREEN)Kernel image compiled$(NC)"; \
	else \
		echo "$(RED)Error: Kernel directory not found$(NC)"; \
		exit 1; \
	fi

modules:
	@echo "$(BLUE)Compiling kernel modules...$(NC)"
	@if [ -d "$(KERNEL_DIR)" ]; then \
		cd $(KERNEL_DIR) && \
		make -j$(BUILD_THREADS) \
			ARCH=$(ARCH) \
			CROSS_COMPILE=$(CROSS_COMPILE) \
			modules 2>&1 | tee ../$(LOG_DIR)/modules.log; \
		echo "$(GREEN)Kernel modules compiled$(NC)"; \
	else \
		echo "$(RED)Error: Kernel directory not found$(NC)"; \
		exit 1; \
	fi

dtbs:
	@echo "$(BLUE)Compiling device tree blobs...$(NC)"
	@if [ -d "$(KERNEL_DIR)" ]; then \
		cd $(KERNEL_DIR) && \
		make -j$(BUILD_THREADS) \
			ARCH=$(ARCH) \
			CROSS_COMPILE=$(CROSS_COMPILE) \
			dtbs 2>&1 | tee ../$(LOG_DIR)/dtbs.log; \
		echo "$(GREEN)Device tree blobs compiled$(NC)"; \
	else \
		echo "$(RED)Error: Kernel directory not found$(NC)"; \
		exit 1; \
	fi

build: kernel modules dtbs
	@echo "$(GREEN)Build completed successfully$(NC)"

# ============================================
# Package targets
# ============================================
package:
	@echo "$(BLUE)Creating AnyKernel3 package...$(NC)"
	@chmod +x build.sh
	@./build.sh -n -p
	@echo "$(GREEN)Package created$(NC)"

release: package
	@echo "$(BLUE)Creating release package...$(NC)"
	@echo "$(GREEN)Release package ready$(NC)"

# ============================================
# Flash target
# ============================================
flash:
	@echo "$(BLUE)Flashing kernel via ADB...$(NC)"
	@echo "$(YELLOW)WARNING: This will flash the kernel to your device!$(NC)"
	@echo "$(YELLOW)Make sure your device is connected and in bootloader mode$(NC)"
	@read -p "Continue? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "$(BLUE)Flashing...$(NC)"
	@adb reboot bootloader
	@sleep 5
	@fastboot flash boot $(OUTPUT_DIR)/Image
	@fastboot reboot
	@echo "$(GREEN)Kernel flashed successfully$(NC)"

# ============================================
# Clean targets
# ============================================
clean:
	@echo "$(BLUE)Cleaning build directory...$(NC)"
	@if [ -d "$(KERNEL_DIR)" ]; then \
		cd $(KERNEL_DIR) && \
		make ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) clean; \
	fi
	@rm -rf $(OUTPUT_DIR)
	@rm -rf $(LOG_DIR)
	@echo "$(GREEN)Build directory cleaned$(NC)"

distclean: clean
	@echo "$(BLUE)Cleaning everything...$(NC)"
	@rm -rf $(KERNEL_DIR)
	@rm -rf $(RELEASE_DIR)
	@echo "$(GREEN)Everything cleaned$(NC)"

# ============================================
# Development targets
# ============================================
menuconfig:
	@echo "$(BLUE)Opening kernel configuration menu...$(NC)"
	@if [ -d "$(KERNEL_DIR)" ]; then \
		cd $(KERNEL_DIR) && \
		make ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) menuconfig; \
	else \
		echo "$(RED)Error: Kernel directory not found$(NC)"; \
		exit 1; \
	fi

defconfig:
	@echo "$(BLUE)Regenerating defconfig...$(NC)"
	@if [ -d "$(KERNEL_DIR)" ]; then \
		cd $(KERNEL_DIR) && \
		make ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) savedefconfig && \
		cp defconfig arch/arm64/configs/$(DEFCONFIG) && \
		echo "$(GREEN)Defconfig regenerated$(NC)"; \
	else \
		echo "$(RED)Error: Kernel directory not found$(NC)"; \
		exit 1; \
	fi

# ============================================
# Utility targets
# ============================================
info:
	@echo "$(BLUE)Build Information:$(NC)"
	@echo "  Device: $(DEVICE_NAME) ($(DEVICE))"
	@echo "  Kernel: $(KERNEL_VERSION)"
	@echo "  Config: $(DEFCONFIG)"
	@echo "  Arch: $(ARCH)"
	@echo "  Compiler: $(CROSS_COMPILE)"
	@echo "  Threads: $(BUILD_THREADS)"
	@echo "  Kernel Dir: $(KERNEL_DIR)"
	@echo "  Output Dir: $(OUTPUT_DIR)"

check:
	@echo "$(BLUE)Checking build environment...$(NC)"
	@which git >/dev/null 2>&1 && echo "$(GREEN)✓ git$(NC)" || echo "$(RED)✗ git$(NC)"
	@which make >/dev/null 2>&1 && echo "$(GREEN)✓ make$(NC)" || echo "$(RED)✗ make$(NC)"
	@which $(CROSS_COMPILE)gcc >/dev/null 2>&1 && echo "$(GREEN)✓ $(CROSS_COMPILE)gcc$(NC)" || echo "$(RED)✗ $(CROSS_COMPILE)gcc$(NC)"
	@which flex >/dev/null 2>&1 && echo "$(GREEN)✓ flex$(NC)" || echo "$(RED)✗ flex$(NC)"
	@which bison >/dev/null 2>&1 && echo "$(GREEN)✓ bison$(NC)" || echo "$(RED)✗ bison$(NC)"
	@which bc >/dev/null 2>&1 && echo "$(GREEN)✓ bc$(NC)" || echo "$(RED)✗ bc$(NC)"
	@test -d "$(KERNEL_DIR)" && echo "$(GREEN)✓ Kernel source$(NC)" || echo "$(YELLOW)⚠ Kernel source not cloned$(NC)"
	@test -f "$(KERNEL_DIR)/.config" && echo "$(GREEN)✓ Kernel configured$(NC)" || echo "$(YELLOW)⚠ Kernel not configured$(NC)"