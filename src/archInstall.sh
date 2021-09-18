#!/usr/bin/bash
# 
# 
# 
# 
# Author: Marcelo Tellier Sartori Vaz



# Abort on error.
set -e



# Prepare installer.
#---------------------------------------------------------------------------------------------------
sed -Ei 's/^#(ParallelDownloads)/\1/' /etc/pacman.conf	# Uncomment #ParallelDownloads


# Install ZFS.
curl -O# http://archzfs.com/archive_archzfs/zfs-linux-2.0.5_5.12.13.arch1.2-1-x86_64.pkg.tar.zst
curl -O# http://archzfs.com/archive_archzfs/zfs-utils-2.0.5-1-x86_64.pkg.tar.zst

pacman --noconfirm -U zfs-{linux,utils}-*.pkg.tar.zst

modprobe zfs



# Variables.
#---------------------------------------------------------------------------------------------------
disk='/dev/disk/by-id/ata-Samsung_SSD_840_PRO_Series_S1AXNSAD703273K'
mountPoint='/mnt/new'
backupDir='/mnt/truenas/home'
pwd='/mnt/usb'



# Partitioning and filesystem.
#---------------------------------------------------------------------------------------------------
sgdisk --clear ${disk}
sgdisk --new 1:0:+1G --change-name 1:'EFI Partition' --typecode 1:ef00 ${disk}
sgdisk --new 2:0:+450G --change-name 2:'Root Partition' --typecode 1:8304 ${disk}

sleep 1	# Wait for disk to be available.

efiPartition="${disk}-part1"
rootPartition="${disk}-part2"


# EFI Partition.
mkfs.fat -F32 ${efiPartition}


# Root Partition.

# Layout:
#
# rootPool
# ├── root
# ├── home
# └── games

# Create pool.
zpool create			\
	-o ashift=13		\
	-o autotrim=on		\
	-O xattr=sa			\
	-O acltype=posixacl	\
	-O compression=zstd	\
	-O mountpoint=none	\
	-R ${mountPoint}	\
	-f					\
	rootPool			\
	${rootPartition}

# Create datasets.
zfs create							\
	-o mountpoint=/					\
	rootPool/root

zfs create							\
	-o mountpoint=/home				\
	-o canmount=noauto				\
	-o encryption=on				\
	-o keyformat=passphrase			\
	rootPool/home

zfs create							\
	-o mountpoint=/usr/local/games	\
	rootPool/games

zfs mount rootPool/home	# Mount encrypted dataset.

# Set boot dataset.
zpool set bootfs=rootPool/root rootPool


# Mount the EFI partiton on /boot folder of the new root.
mkdir -p ${mountPoint}/boot/efi
mount ${efiPartition} ${mountPoint}/boot/efi



# Install Arch Linux.
#---------------------------------------------------------------------------------------------------
pacstrap -c ${mountPoint} base

# chroot.
arch-chroot ${mountPoint} bash -c "$(cat ${pwd}/src/archSetup1.sh)"
arch-chroot ${mountPoint} bash -c "$(cat ${pwd}/src/archSetup2.sh)"

# Can't do it inside chroot.
ln -sf /run/systemd/resolve/stub-resolv.conf ${mountPoint}/etc/resolv.conf



# Restore configuration.
#---------------------------------------------------------------------------------------------------
mkdir -p ${backupDir}
mount -t cifs //truenas.lan/marcelotsvaz ${backupDir} -o credentials=${pwd}/credentials,cifsacl
${pwd}/src/backup.py ${backupDir}/Backups/Linux ${mountPoint}
chown -R 1000:1000 ${mountPoint}/home/marcelotsvaz
umount ${backupDir}

# Create snapshot.
zfs snapshot -r rootPool@initial



# Cleanup.
#---------------------------------------------------------------------------------------------------
umount ${efiPartition}
zpool export rootPool
rm -r ${mountPoint}