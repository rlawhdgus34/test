#!/bin/bash

DISK=$1
SIZE=`sfdisk -s $DISK`
SIZE_MB=$((SIZE >> 10))

BOOT_SZ=64
ROOTFS_SZ=3072
DATA_SZ=512
MODULE_SZ=20

let "USER_SZ = $SIZE_MB - $BOOT_SZ - $ROOTFS_SZ - $DATA_SZ - $MODULE_SZ - 4"

BOOT=boot
ROOTFS=rootfs
SYSTEMDATA=system-data
USER=user
MODULE=modules

if [[ $USER_SZ -le 100 ]]
then
   echo "We recommend to use more than 4GB disk"
   exit 0
fi

echo "========================================"
echo "Label          dev           size"
echo "========================================"
echo $BOOT"      " $DISK"1     " $BOOT_SZ "MB"
echo $ROOTFS"      " $DISK"2     " $ROOTFS_SZ "MB"
echo $SYSTEMDATA"   " $DISK"3     " $DATA_SZ "MB"
echo "[Extend]""   " $DISK"4"
echo " "$USER"      " $DISK"5     " $USER_SZ "MB"
echo " "$MODULE"      " $DISK"6     " $MODULE_SZ "MB"


MOUNT_LIST=`mount | grep $DISK | awk '{print $1}'`
for mnt in $MOUNT_LIST
do
   umount $mnt
done

echo "Remove partition table..."                                                
dd if=/dev/zero of=$DISK bs=512 count=1 conv=notrunc

sfdisk --in-order --Linux --unit M $DISK <<-__EOF__
4,$BOOT_SZ,0xE,*
,$ROOTFS_SZ,,-
,$DATA_SZ,,-
,,E,-
,$USER_SZ,,-
,$MODULE_SZ,,-
__EOF__

mkfs.vfat -F 16 ${DISK}1 -n $BOOT
mkfs.ext4 -q ${DISK}2 -L $ROOTFS -F
mkfs.ext4 -q ${DISK}3 -L $SYSTEMDATA -F
mkfs.ext4 -q ${DISK}5 -L $USER -F
mkfs.ext4 -q ${DISK}6 -L $MODULE -F
