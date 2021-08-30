#!/bin/bash

export ARCH=arm64
export PRODUCT_NAME=b2q

PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')-x86
if [ $PLATFORM == "darwin-x86" ]; then
    export LC_CTYPE=C
    export PATH="/usr/local/opt/curl/bin:$PATH"
    export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"
    export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"
    export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
    export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"
    export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
    export PKG_CONFIG_PATH=/"usr/local/opt/openssl@1.1/lib/pkgconfig:$PKG_CONFIG_PATH"

    BUILDROOT=/Volumes/Android
    KERNELDIR=$BUILDROOT/FLIP_3_SM-F711B/Kernel
    PREBUILT=$BUILDROOT/$PLATFORM/toolchains
    CLANGVER=clang-r416183d
else
    BUILDROOT=/mnt/hgfs/Android
    KERNELDIR=$BUILDROOT/FLIP_3_SM-F711B/Kernel
    PREBUILT=$BUILDROOT/$PLATFORM/toolchains
    CLANGVER=clang-r416183d
fi

cd $KERNELDIR

make clean & make mrproper
#git clean -xfd # failsafe

find . -name "*.orig" -type f -delete

if [ -d out ]; then
    rm -rf out;
fi

mkdir -p out

BUILD_CROSS_COMPILE=${PREBUILT}/aarch64-linux-android-4.9/bin/aarch64-linux-android-
KERNEL_LLVM_BIN=${PREBUILT}/$PLATFORM/$CLANGVER/bin/clang
CLANG_TRIPLE=aarch64-linux-gnu-
KERNEL_MAKE_ENV="DTC_EXT=${PREBUILT}/prebuilts-master/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"

CORES=$([ $(uname) = 'Darwin' ] && sysctl -n hw.logicalcpu_max || lscpu -p | egrep -v '^#' | wc -l)
THREADS=$([ $(uname) = 'Darwin' ] && sysctl -n hw.physicalcpu_max || lscpu -p | egrep -v '^#' | sort -u -t, -k 2,4 | wc -l)
CPU_JOB_NUM=$(expr $CORES \* $THREADS)

make -j$CPU_JOB_NUM -C ${KERNELDIR} O=${KERNELDIR}/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CONFIG_SECTION_MISMATCH_WARN_ONLY=y vendor/b2q_eur_openx_defconfig
make -j$CPU_JOB_NUM -C ${KERNELDIR} O=${KERNELDIR}/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CONFIG_SECTION_MISMATCH_WARN_ONLY=y
