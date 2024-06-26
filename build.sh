#!/bin/bash
#
# Copyright (C) 2019-2024 Panagiotis Englezos <panagiotisegl@gmail.com>
#
# Android Build script 
#
# Usage (in root of source):
# 	./build.sh [options]
#

# Override host metadata to make builds more reproducible and avoid leaking info
export BUILD_USERNAME=Kevin
export BUILD_HOSTNAME=android-build

# Device defaults
DEVICE='hanoip'
BUILD_TYPE='userdebug'

# Setup ccache
ccache () {
    export CCACHE_EXEC=$(command -v ccache)
    export CCACHE_DIR=$(pwd)/.ccache
    export USE_CCACHE=1
    ccache -M 50G
}

# Setup zram
zram () {
    sudo swapoff --all
    sudo bash -c "echo 64G > /sys/block/zram0/disksize"
    sudo mkswap --label zram0 /dev/zram0
    sudo swapon --priority 32767 /dev/zram0
}

# Clean sources
clean () {
    source build/envsetup.sh
    source $(gettop)/vendor/lineage/vars/aosp_target_release
    lunch lineage_${DEVICE}-${aosp_target_release}-${BUILD_TYPE}
    make clean && rm -rf out
}

installclean () {
    source build/envsetup.sh
    source $(gettop)/vendor/lineage/vars/aosp_target_release
    lunch lineage_${DEVICE}-${aosp_target_release}-${BUILD_TYPE}
    make installclean
}

# Apply patches
patches () {
    . build/envsetup.sh
    croot
    
    PATCHES_PATH=$PWD/vendor/extra/patches

    for project_name in $(cd "${PATCHES_PATH}"; echo */); do
        project_path="$(tr _ / <<<$project_name)"

        cd $(gettop)/${project_path}
        git am "${PATCHES_PATH}"/${project_name}/*.patch --no-gpg-sign
        git am --abort &> /dev/null
    done

    croot
}

# Build ROM
build () {
    source build/envsetup.sh
    source $(gettop)/vendor/lineage/vars/aosp_target_release
    lunch lineage_${DEVICE}-${aosp_target_release}-${BUILD_TYPE}
    make bacon
}

# Build kernel image
kernel () {
    source build/envsetup.sh
    source $(gettop)/vendor/lineage/vars/aosp_target_release
    lunch lineage_${DEVICE}-${aosp_target_release}-${BUILD_TYPE}
    make bootimage
}


# Usage information when there are no arguments
if [[ $# -eq 0 ]]; then
	echo -e "\nUsage: ./build.sh [options]\n"
	echo "Options:"
    echo "  -cc, --ccache                  Setup ccache"
    echo "  -z, --zram                     Setup zram"
	echo "  -c, --clean                    Clean entire build directory"
	echo "  -i, --installclean             Dirty build"
	echo "  -p, --patches                  Apply patches"
	echo "  -b, --build                    Perform ROM build"
	echo "  -k, --kernel                   Perform kernel image build"
	echo ""
	exit 0
fi

# Parse arguments
while [[ "$#" -gt 0 ]]; do case $1 in
    -cc|--ccache) ccache;;
    -z|--zram) zram;;
	-c|--clean) clean;;
	-i|--installclean) installclean;;
	-p|--patches) patches;;
	-b|--build) build;;
	-k|--kernel) kernel;;
	*) echo "Unknown parameter passed: $1"; exit 1;;
esac; shift; done
