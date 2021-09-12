#!/bin/bash
# 
# 
# 
# 
# Author: Marcelo Tellier Sartori Vaz



# Abort on error.
set -e



# Add users.
#---------------------------------------------------------------------------------------------------
# Remove bash stuff.
rm /etc/skel/.bash*

# Change root shell.
usermod -s '/usr/bin/fish' root

# Add user marcelotsvaz with no password.
useradd -m -s '/usr/bin/fish' -c 'Marcelo Vaz' -G wheel marcelotsvaz
passwd -d marcelotsvaz

# Add wheel to sudoers.
mkdir -m 750 /etc/sudoers.d
echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel



# Install packages.
#---------------------------------------------------------------------------------------------------
# Sign archzfs keys.
pacman-key --recv-key DDF7DB817396A49B2A2723F7403BD972F75D9D76
pacman-key --lsign-key DDF7DB817396A49B2A2723F7403BD972F75D9D76


# Pacman configuration.
#-------------------------------------------------------------------------------
cat >> /etc/pacman.conf << 'EOF'

# Custom config.
[options]
ParallelDownloads = 5
Color

[archzfs]
Server = https://archzfs.com/$repo/$arch
EOF
#-------------------------------------------------------------------------------


# Mask mkinitcpio hook.
mkdir /etc/pacman.d/hooks
ln -s /dev/null /etc/pacman.d/hooks/90-mkinitcpio-install.hook


# Install packages.
system='linux-lts linux-firmware intel-ucode base-devel linux-lts-headers mkinitcpio efibootmgr'
shell='fish exa tmux'
tools='sudo nano rsync gdisk man-db'
developmentTools='mercurial git aws-cli openssh'

pacman --noconfirm --needed -Sy ${system} ${shell} ${tools} ${developmentTools}


# Install yay.
sudo -u marcelotsvaz bash << 'EOF'
package='yay'
git clone https://aur.archlinux.org/${package}.git /tmp/${package}
( cd /tmp/${package} && makepkg --syncdeps --install --noconfirm )
rm -r /tmp/${package}
EOF


# Install AUR packages.
sudo -u marcelotsvaz yay -S mkinitcpio-numlock



# Standard configuration.
#---------------------------------------------------------------------------------------------------
# Time zone.
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime


# Hardware clock.
hwclock --systohc


# Localization.
sed -Ei 's/^#(en_US\.UTF-8 UTF-8)/\1/' /etc/locale.gen	# Uncomment #en_US.UTF-8 UTF-8.
sed -Ei 's/^#(pt_BR\.UTF-8 UTF-8)/\1/' /etc/locale.gen	# Uncomment #pt_BR.UTF-8 UTF-8.
locale-gen
#-------------------------------------------------------------------------------
cat > /etc/locale.conf << 'EOF'
LANG=en_US.UTF-8
LC_TIME=pt_BR.UTF-8
LC_MEASUREMENT=pt_BR.UTF-8
LC_PAPER=pt_BR.UTF-8
LC_TELEPHONE=pt_BR.UTF-8
EOF
#-------------------------------------------------------------------------------


# Network.
echo 'vaz-pc' > /etc/hostname

#-------------------------------------------------------------------------------
cat > /etc/systemd/network/main.network << 'EOF'
[Match]
Name = en*

[Network]
DHCP = yes
EOF
#-------------------------------------------------------------------------------
systemctl enable systemd-{networkd,resolved,timesyncd}



# Boot.
#---------------------------------------------------------------------------------------------------
# Configure mkinitcpio.
sed -Ei 's/^HOOKS=.*/HOOKS=(base zfs modconf numlock)/'	/etc/mkinitcpio.conf	# Add zfs to HOOKS and remove unneeded stuff.
sed -Ei 's/^MODULES=.*/MODULES=(zfs)/'					/etc/mkinitcpio.conf	# Add zfs to MODULES.
sed -Ei 's/^PRESETS=.*/PRESETS=(default)/'				/usr/share/mkinitcpio/hook.preset	# Remove fallback preset.


rm /etc/pacman.d/hooks/90-mkinitcpio-install.hook	# Remove symlink to /dev/null.

#-------------------------------------------------------------------------------
cat > /etc/pacman.d/hooks/90-mkinitcpio-install.hook << 'EOF'
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Target = usr/lib/modules/*/vmlinuz
Target = usr/lib/initcpio/*

[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Target = intel-ucode
Target = amd-ucode

[Action]
Description = Updating linux initcpios...
When = PostTransaction
Exec = /bin/sh -c '/usr/share/libalpm/scripts/mkinitcpio-install && /usr/local/share/libalpm/scripts/mkinitcpio-install-unified'
NeedsTargets
EOF
#-------------------------------------------------------------------------------

mkdir -p /usr/local/share/libalpm/scripts
#-------------------------------------------------------------------------------
cat > /usr/local/share/libalpm/scripts/mkinitcpio-install-unified << 'EOF'
#!/bin/bash
kernelParameters='zfs=rootPool/root/default rw quiet udev.log_level=3'

cd /boot
for kernel in vmlinuz-*; do
	pkgbase=${kernel#vmlinuz-}
	
	# Unified image.
	objcopy																														\
		--change-section-vma .osrel=0x20000		--add-section .osrel='/usr/lib/os-release'										\
		--change-section-vma .cmdline=0x30000	--add-section .cmdline=<(echo ${kernelParameters})								\
		--change-section-vma .splash=0x40000	--add-section .splash='/usr/share/systemd/bootctl/splash-arch.bmp'				\
		--change-section-vma .linux=0x2000000	--add-section .linux="vmlinuz-${pkgbase}"										\
		--change-section-vma .initrd=0x3000000	--add-section .initrd=<(cat $(compgen -G *-ucode.img) initramfs-${pkgbase}.img)	\
		'/usr/lib/systemd/boot/efi/linuxx64.efi.stub'																			\
		"efi/${pkgbase}.efi"
	
	# UEFI boot entry.
	efiPartition="/dev/disk/by-partuuid/$(lsblk -nro PARTUUID,MOUNTPOINTS | grep ' /boot/efi$' | cut -d ' ' -f1)"
	
	if [[ ${pkgbase} != 'linux.efi' ]]; then
		variant=" (${pkgbase#linux-})"
	fi
	
	efibootmgr							\
		--create						\
		--disk "${efiPartition}"		\
		--label "Arch Linux${variant}"	\
		--loader "/${pkgbase}.efi"
done
EOF
#-------------------------------------------------------------------------------
chmod +x /usr/local/share/libalpm/scripts/mkinitcpio-install-unified


# Install the kernel.
pacman --noconfirm -S linux-lts zfs-dkms
systemctl enable zfs-mount zfs.target



# Mount EFI partition on boot.
efiPartition="/dev/disk/by-partuuid/$(lsblk -nro PARTUUID,MOUNTPOINTS | grep ' /boot/efi$' | cut -d ' ' -f1)"
#-------------------------------------------------------------------------------
cat > /etc/systemd/system/boot-efi.mount << EOF
[Unit]
Description = Mount EFI partition

[Mount]
What = ${efiPartition}
Where = /boot/efi
Type = vfat
Options = rw

[Install]
WantedBy = multi-user.target
EOF
#-------------------------------------------------------------------------------

systemctl enable boot-efi.mount



# Custom configuration.
#---------------------------------------------------------------------------------------------------
# OpenSSL.
sed -Ei 's/^\[ new_oids \]$/\.include custom\.cnf\n\n\0/' /etc/ssl/openssl.cnf	# Add ".include custom.cnf".
#-------------------------------------------------------------------------------
cat > /etc/ssl/custom.cnf << 'EOF'
# Custom configuration.
openssl_conf = default_conf

[default_conf]
ssl_conf = ssl_sect

[ssl_sect]
system_default = system_default_sect

[system_default_sect]
MinProtocol = TLSv1.2
CipherSuites = TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384
CipherString = ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-RSA-AES256-GCM-SHA384;
Curves = X25519:secp521r1
EOF
#-------------------------------------------------------------------------------


# SSH.
#-------------------------------------------------------------------------------
cat >> /etc/ssh/sshd_config << 'EOF'


# Custom configuration.
PasswordAuthentication no

PubkeyAcceptedKeyTypes ssh-ed25519

KexAlgorithms curve25519-sha256
HostKeyAlgorithms ssh-ed25519
Ciphers chacha20-poly1305@openssh.com
MACs hmac-sha2-512-etm@openssh.com
EOF
#-------------------------------------------------------------------------------
systemctl enable sshd



# Mount SMB shares.
#---------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
cat > /etc/systemd/system/mnt-truenas-home.mount << 'EOF'
[Unit]
Description = Mount SMB shares

[Mount]
What = //truenas.lan/marcelotsvaz
Where = /mnt/truenas/home
Type = cifs
Options = credentials=/etc/samba/credentials/truenas,uid=marcelotsvaz,gid=marcelotsvaz,cifsacl

[Install]
WantedBy = multi-user.target
EOF
#-------------------------------------------------------------------------------
cat > /etc/systemd/system/mnt-truenas-media.mount << 'EOF'
[Unit]
Description = Mount SMB shares

[Mount]
What = //truenas.lan/media
Where = /mnt/truenas/media
Type = cifs
Options = credentials=/etc/samba/credentials/truenas,uid=marcelotsvaz,gid=marcelotsvaz,cifsacl

[Install]
WantedBy = multi-user.target
EOF
#-------------------------------------------------------------------------------
systemctl enable mnt-truenas-home.mount mnt-truenas-media.mount

mkdir -pm 700 /etc/samba/credentials

touch /etc/samba/credentials/truenas && chmod 600 ${_}