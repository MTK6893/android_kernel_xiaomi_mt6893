#!/bin/bash

# Source user environment
source ~/.bashrc && source ~/.profile

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to install required packages
# install_deps() {
#   local packages=("curl" "ccache" "make" "libssl-dev")
#    # build-essential
#
#    for package in "${packages[@]}"; do
#        if ! dpkg -s "$package" >/dev/null 2>&1; then
#            log "Installing $package..."
#            sudo apt-get install -y "$package"
#        else
#            log "$package is already installed."
#        fi
#    done
#}

# Function to install the zyc-clang toolchain
# install_zyc_clang_toolchain() {
#     mkdir -p "$ZYC_CLANG_DIR" && cd "$ZYC_CLANG_DIR" || return 1
#     
#     log "Downloading zyc-clang toolchain..."
#     #curl -LO "https://gh.llkk.cc/https://github.com/ZyCromerZ/Clang/releases/download/20.0.0git-20241110-release/Clang-20.0.0git-20241110.tar.gz"
# 
#     log "Extracting zyc-clang toolchain..."
#     #tar -xzf "Clang-16.0.6-20240430.tar.gz"
# 
#     #echo "Clang-16.0.6-20240430.tar.gz" > "$last_download_file"
#     log "Zyc-clang toolchain updated successfully."
# 
#     cd - || return 1
# }

# Function to build the kernel
build_kernel() {
    local make_options=(
        O=out
        ARCH=arm64
        SUBARCH=ARM64
        LLVM=1
        LLVM_IAS=0
        CC="ccache clang"
        HOSTCC=clang
        HOSTCXX=clang++
        CLANG_TRIPLE=aarch64-linux-gnu-
        CROSS_COMPILE=aarch64-linux-gnu-
        CROSS_COMPILE_ARM32=arm-linux-gnueabi-
        AR=llvm-ar
        HOSTAR=llvm-ar
        AS=llvm-as
        NM=llvm-nm
        LD=ld.lld
        HOSTLD=ld.lld
        STRIP=llvm-strip
        OBJCOPY=llvm-objcopy
        OBJDUMP=llvm-objdump
        OBJSIZE=llvm-size
        READELF=llvm-readelf
    )

    log "Cleaning build environment..."
    make "${make_options[@]}" \
        clean \
        mrproper \
        设备配置文件

    log "Building the kernel..."
    make -j$(nproc --all) \
        "${make_options[@]}" \
        CONFIG_NO_ERROR_ON_MISMATCH=y 2>&1 | tee error.log
}

# Function to build the boot image
build_boot_img() {
    cd boot || return 1

    # Check if stock_boot.img is present
    if [ ! -f "stock_boot.img" ]; then
        log "Error: stock_boot.img not found. Please add the boot image to this directory."
        cd - || return 1
        return 1
    fi

    local boot_image_name="boot_$(date +%Y%m%d_%H%M%S).img"

    log "Unpacking boot image..."
    ./magiskboot unpack stock_boot.img || return 1

    log "Removing existing kernel..."
    rm -f kernel

    log "Copying built kernel..."
    cp ../out/arch/arm64/boot/Image kernel || return 1

    log "Repacking boot image..."
    ./magiskboot repack stock_boot.img "$boot_image_name" || return 1

    log "Cleaning up..."
    rm -f dtb kernel ramdisk.cpio

    log "Boot image created: $boot_image_name"

    cd - || return 1
}


# Install required packages for compiling
# install_deps

#### Toolchain ####
#--- ZyC Clang ---#
ZYC_CLANG_DIR="$HOME/toolchains/zyc-clang"
#install_zyc_clang_toolchain
export PATH="$ZYC_CLANG_DIR/bin:$PATH"

# Cleanup
rm -rf out/ error.log
# ccache -Cz

# Setup CCache
ccache -M 32G
log "CCache setup 32GB."

# Build the kernel
log "Starting kernel build process..."
build_kernel

# Make boot.img
log "Starting making the boot.img process..."
build_boot_img
