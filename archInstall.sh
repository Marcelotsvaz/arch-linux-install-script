#!/bin/bash
# 
# 
# 
# 
# Author: Marcelo Tellier Sartori Vaz



# Prepare installer
####################################################################################################
reflector --protocol https --latest 25 --sort rate --save /etc/pacman.d/mirrorlist

curl -O http://archzfs.com/archive_archzfs/zfs-linux-2.0.5_5.12.13.arch1.2-1-x86_64.pkg.tar.zst
curl -O http://archzfs.com/archive_archzfs/zfs-utils-2.0.5-1-x86_64.pkg.tar.zst
pacman --noconfirm -U zfs-{linux,utils}-*.pkg.tar.zst

modprobe zfs



# Variables
####################################################################################################
mountPoint='/mnt/new'
# diskSerial='S1AXNSAD703273K'



# Partitioning and Filesystem
####################################################################################################
# disk=$(lsblk -nro PATH,SERIAL | grep ${diskSerial} | cut -d ' ' -f1)
targetDevice='/dev/disk/by-partuuid/bcde2fd2-2edb-4f31-b875-6c475a0cae7e'

efiPartition='/dev/disk/by-partuuid/58ee7a07-2189-40d7-8769-1bc4fff1ac0c'
#efiPartition=$(lsblk -nro PATH,MOUNTPOINTS | grep ' /$' | cut -d ' ' -f1)
#efiPartition=${efiPartition/%?/1}
#rootUUID=$(lsblk -nro UUID,MOUNTPOINTS | grep ' /$' | cut -d ' ' -f1)

# sgdisk --clear ${disk}
# sgdisk --new 1:0:+1M --change-name 1:'Boot' --typecode 1:ef02 ${disk}
# sgdisk --new 2:0:0 --change-name 2:'Root' ${disk}


# ZFS datasets layout:
# rootPool
# 	root
# 		default
# 		recovery
# 	data
# 		home
# 	swap

zpool create			\
	-o ashift=13		\
	-o autotrim=on		\
	-O xattr=sa			\
	-O acltype=posixacl	\
	-O compression=lz4	\
	-O mountpoint=/		\
	-O canmount=off		\
	-R ${mountPoint}	\
	-f					\
	rootPool			\
	${targetDevice}


# Root datasets.
zfs create					\
	-o mountpoint=none		\
	-o canmount=off			\
	rootPool/root

zfs create					\
	-o mountpoint=/			\
	rootPool/root/default

zfs create					\
	-o mountpoint=none		\
	rootPool/root/recovery


# Data datasets.
zfs create					\
	-o mountpoint=/			\
	-o canmount=off			\
	rootPool/data

zfs create					\
	rootPool/data/home


# zfs create					\
# 	-V 8G					\
# 	-b $(getconf PAGESIZE)	\
# 	rootPool/swap
# mkswap -f /dev/zvol/rootPool/swap
# swapon /dev/zvol/rootPool/swap


zpool set bootfs=rootPool/root/default rootPool
zfs list -o name,mountpoint,mounted


# Mount the EFI partiton on /boot folder of the new root.
mkdir ${mountPoint}/boot
mount ${efiPartition} ${mountPoint}/boot



# Install Arch Linux
####################################################################################################
pacstrap -c ${mountPoint} base



# Chroot
####################################################################################################
cp $(dirname "$0")/archSetup*.sh ${mountPoint}
arch-chroot ${mountPoint} /archSetup1.sh
arch-chroot ${mountPoint} /archSetup2.sh
rm ${mountPoint}/archSetup*.sh



# Cleanup
####################################################################################################
# Can't do it inside chroot.
ln -sf /run/systemd/resolve/stub-resolv.conf ${mountPoint}/etc/resolv.conf

umount ${efiPartition}
zpool export rootPool
rm -r ${mountPoint}