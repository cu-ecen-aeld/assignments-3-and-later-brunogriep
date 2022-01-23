#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.10.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]; then
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
  git checkout ${KERNEL_VERSION}

  # TODO: Add your kernel build steps here
  echo "build clean"
  make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper

  echo "build defconfig"
  make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig

  echo "build vmlinux"
  make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all

  echo "build modules"
  make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules

  echo "build device tree"
  make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]; then
  echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
  sudo rm -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
if [ ! -d "${OUTDIR}" ]; then
  echo "The directory \"$OUTDIR\" does not exist... Creating it"
  mkdir -p "$dir"
fi

echo "Changing directory to \"$OUTDIR\""
mkdir -p "${OUTDIR}/rootfs"
cd "${OUTDIR}/rootfs"
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

echo "BusyBox"
cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]; then
  echo "cloning BusyBox"
  git clone git://busybox.net/busybox.git
  cd busybox
  git checkout ${BUSYBOX_VERSION}
  # TODO:  Configure busybox
  make distclean
  make defconfig
  # make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
else
  cd busybox
fi

# TODO: Make and install busybox
make -j4 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make -j4 CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
echo "Add library dependencies to rootfs"
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
cp -a "${SYSROOT}"/lib/* "${OUTDIR}"/rootfs/lib
cp -a "${SYSROOT}"/lib64/* "${OUTDIR}"/rootfs/lib64
# cd ${OUTDIR}/rootfs
# cp $SYSROOT/lib/ld-linux-aarch64.so.1 lib
# cp $SYSROOT/lib64/ld-2.31.so lib64
# cp $SYSROOT/lib64/libc.so.6 lib64
# cp $SYSROOT/lib64/libc-2.31.so lib64
# cp $SYSROOT/lib64/libm.so.6 lib64
# cp $SYSROOT/lib64/libm-2.31.so lib64
# cp $SYSROOT/lib64/libresolv.so.2 lib64
# cp $SYSROOT/lib64/libresolv-2.31.so lib64

# TODO: Make device nodes
echo "Make device nodes"
cd ${OUTDIR}/rootfs
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1
sudo mknod -m 666 dev/tty c 5 0
# sudo mknod -m 666 "${OUTDIR}"/rootfs/dev/null c 1 3
# sudo mknod -m 600 "${OUTDIR}"/rootfs/dev/console c 5 1

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
echo "Clean and build the writer utility"
if [ -f "${FINDER_APP_DIR}/writer" ]; then
  echo "writer exists. Cleaning up..."
  # make -C "${FINDER_APP_DIR}" clean
  make clean
fi
# make -C "${FINDER_APP_DIR}" CROSS_COMPILE=${CROSS_COMPILE}
make CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
echo "Copying finder related scripts to ${OUTDIR}/rootfs/home"
cp "${FINDER_APP_DIR}"/finder.sh "${OUTDIR}"/rootfs/home/.
cp "${FINDER_APP_DIR}"/finder-test.sh "${OUTDIR}"/rootfs/home/.
cp "${FINDER_APP_DIR}"/autorun-qemu.sh "${OUTDIR}"/rootfs/home/.
cp "${FINDER_APP_DIR}"/writer.sh "${OUTDIR}"/rootfs/home/.
cp "${FINDER_APP_DIR}"/writer "${OUTDIR}"/rootfs/home/.
# cp "${FINDER_APP_DIR}"/writer.c "${OUTDIR}"/rootfs/home/.
# mkdir -p "${OUTDIR}"/rootfs/home/conf q
cp -r ${FINDER_APP_DIR}/conf/ ${OUTDIR}/rootfs/home
# cp -r "${FINDER_APP_DIR}"/conf/assignment.txt "${OUTDIR}"/rootfs/home/conf/.
# cp -r "${FINDER_APP_DIR}"/conf/username.txt "${OUTDIR}"/rootfs/home/conf/.

# TODO: Chown the root directory
echo "Chown the root director"
# sudo chown -R root:root "${OUTDIR}"/rootfs
cd ${OUTDIR}/rootfs
sudo chown -R root:root *

# TODO: Create initramfs.cpio.gz
echo "Create initramfs.cpio.gz"
cd "${OUTDIR}"/rootfs
find . | cpio -H newc -ov --owner root:root >../initramfs.cpio
cd ..
gzip initramfs.cpio
