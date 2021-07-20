#!/bin/bash
# 
# 
# 
# 
# Author: Marcelo Tellier Sartori Vaz



# Install packages
####################################################################################################
#-------------------------------------------------------------------------------
cat >> /etc/pacman.conf << 'EOF'
[archzfs]
Server = https://archzfs.com/$repo/$arch
EOF
#-------------------------------------------------------------------------------

# archzfs keys.
pacman-key --keyserver keyserver.ubuntu.com --recv-key DDF7DB817396A49B2A2723F7403BD972F75D9D76
pacman-key --lsign-key DDF7DB817396A49B2A2723F7403BD972F75D9D76

system='linux linux-firmware intel-ucode zfs-linux mkinitcpio efibootmgr'
toolsCli='sudo nano zsh tmux gdisk man-db openssh'
pacman --noconfirm -Sy ${system} ${toolsCli}

systemctl enable zfs-mount zfs.target



# Standard Configuration
####################################################################################################
# Time zone.
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime


# Hardware clock.
hwclock --systohc


# Localization.
sed -Ei 's/^#(en_US\.UTF-8 UTF-8)/\1/' /etc/locale.gen # Uncomment #en_US.UTF-8 UTF-8.
sed -Ei 's/^#(pt_BR\.UTF-8 UTF-8)/\1/' /etc/locale.gen # Uncomment #pt_BR.UTF-8 UTF-8.
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf


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



# Boot
####################################################################################################
efiPartUuid='58ee7a07-2189-40d7-8769-1bc4fff1ac0c'

# Generate initramfs.
hooks='base udev autodetect modconf block keyboard zfs filesystems'
sed -Ei "s/^HOOKS=.*/HOOKS=(${hooks})/" /etc/mkinitcpio.conf # Add zfs to HOOKS.
# sed -Ei "s/^MODULES=.*/MODULES=('amdgpu')/" /etc/mkinitcpio.conf # Add amdgpu to MODULES.
sed -Ei "s/^PRESETS=.*/PRESETS=('default')/" /etc/mkinitcpio.d/linux.preset # Remove fallback preset.

mkinitcpio -p linux

# --disk "/dev/disk/by-partuuid/${efiPartUuid}"	\
# UEFI boot entry.
efibootmgr										\
--create										\
--disk /dev/sda									\
--part 1										\
--label 'Arch Linux'							\
--loader '/vmlinuz-linux'						\
--unicode 'initrd=\intel-ucode.img initrd=\initramfs-linux.img zfs=rootPool/root/default rw'


# Mount EFI partition on boot.
echo "PARTUUID=${efiPartUuid}	/boot	vfat	rw	0	0" >> /etc/fstab



# Custom Configuration
####################################################################################################
# Users.
mkdir -m 700 /etc/skel/.ssh
touch /etc/skel/.ssh/authorized_keys
rm /etc/skel/.bash*

useradd -mG wheel marcelotsvaz
passwd -d marcelotsvaz


# Sudo.
echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel


# OpenSSL.
sed -Ei 's/^\[ new_oids \]$/\.include custom\.cnf\n\0/' /etc/ssl/openssl.cnf # Add ".include custom.cnf".
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


# Bash.
#-------------------------------------------------------------------------------
cat >> /etc/bash.bashrc << 'EOF'


# Custom configuration.
green='\[\e[0;32m\]'
blue='\[\e[1;34m\]'
reset='\[\e[m\]'
PS1="[\A][${green}\u@\h ${blue}\w${reset}]\$ "

alias grep='grep --color=auto'
alias ls='ls --color=auto'
EOF
#-------------------------------------------------------------------------------