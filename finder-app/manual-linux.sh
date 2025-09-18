#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
SUDO=""

if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo "This script requires root privileges; install sudo or run as root." >&2
        exit 1
    fi
fi

KERNEL_MAKE_OPTS="ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}"

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    if ! git checkout ${KERNEL_VERSION}; then
        git fetch --depth 1 origin tag ${KERNEL_VERSION}
        git checkout --detach FETCH_HEAD
        git reset --hard FETCH_HEAD
    fi

    # TODO: Add your kernel build steps here
    echo "Cleaning kernel build tree"
    make ${KERNEL_MAKE_OPTS} mrproper

    echo "Configuring the kernel"
    make ${KERNEL_MAKE_OPTS} defconfig

    echo "Building the kernel Image"
    make -j4 ${KERNEL_MAKE_OPTS} all

    echo "Build any kernel modules"
    make ${KERNEL_MAKE_OPTS} modules

    echo "Build the device tree"
    make ${KERNEL_MAKE_OPTS} dtbs

    echo "Copying the kernel Image to outdir"
    cp arch/${ARCH}/boot/Image ${OUTDIR}/
fi

echo "Adding the Image in outdir"

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    if [ -n "${SUDO}" ]; then
        ${SUDO} rm -rf ${OUTDIR}/rootfs
    else
        rm -rf ${OUTDIR}/rootfs
    fi
fi

# TODO: Create necessary base directories
mkdir -p "${OUTDIR}/rootfs"
cd "${OUTDIR}/rootfs"
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log



cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone https://git.busybox.net/busybox
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
mkdir -p ${OUTDIR}/rootfs/lib ${OUTDIR}/rootfs/lib64
cp -a ${SYSROOT}/lib/ld-linux-aarch64.so.1 ${OUTDIR}/rootfs/lib/
cp -a ${SYSROOT}/lib64/libm.so.6 ${OUTDIR}/rootfs/lib64/
cp -a ${SYSROOT}/lib64/libresolv.so.2 ${OUTDIR}/rootfs/lib64/
cp -a ${SYSROOT}/lib64/libc.so.6 ${OUTDIR}/rootfs/lib64/

# TODO: Make device nodes
if [ ! -e "${OUTDIR}/rootfs/dev/null" ]; then
    ${SUDO} mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
fi
if [ ! -e "${OUTDIR}/rootfs/dev/console" ]; then
    ${SUDO} mknod -m 600 ${OUTDIR}/rootfs/dev/console c 5 1
fi

# TODO: Clean and build the writer utility
pushd "${FINDER_APP_DIR}" > /dev/null
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
popd > /dev/null

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp -a ${FINDER_APP_DIR}/writer ${OUTDIR}/rootfs/home/
cp -a ${FINDER_APP_DIR}/finder.sh ${OUTDIR}/rootfs/home/
cp -a ${FINDER_APP_DIR}/finder-test.sh ${OUTDIR}/rootfs/home/
cp -a ${FINDER_APP_DIR}/writer.sh ${OUTDIR}/rootfs/home/
cp -a ${FINDER_APP_DIR}/autorun-qemu.sh ${OUTDIR}/rootfs/home/
cp -a ${FINDER_APP_DIR}/conf ${OUTDIR}/rootfs/home/

# TODO: Chown the root directory
${SUDO} chown -R root:root ${OUTDIR}/rootfs

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
gzip -f ${OUTDIR}/initramfs.cpio

echo "Done. Image and initramfs are in ${OUTDIR}"
