#!/usr/bin/bash
# 
# Arch Linux Install Script
# 
# 
# Author: Marcelo Tellier Sartori Vaz <marcelotsvaz@gmail.com>



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
ParallelDownloads = 10
UseSyslog
VerbosePkgLists
Color

[archzfs]
Server = https://archzfs.com/$repo/$arch
EOF
#-------------------------------------------------------------------------------


# Mask mkinitcpio hook.
mkdir /etc/pacman.d/hooks
ln -s /dev/null /etc/pacman.d/hooks/90-mkinitcpio-install.hook


# Install packages.
system='linux linux-firmware intel-ucode base-devel linux-headers mkinitcpio efibootmgr systemd-ukify'
shell='fish exa htop tmux picocom'
tools='sudo nano nano-syntax-highlighting man-db man-pages jq wget gptfdisk dosfstools rsync'
developmentTools='git mercurial aws-cli-v2 openssh python-pip python-pylint yapf'

pacman --noconfirm --needed -Sy ${system} ${shell} ${tools} ${developmentTools}


# Install yay.
sudo -u marcelotsvaz bash << 'EOF'
package='yay-bin'
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
echo 'vaz-pc.lan' > /etc/hostname

#-------------------------------------------------------------------------------
cat > /etc/systemd/network/main.network << 'EOF'
[Match]
Name = en*

[Link]
Multicast = yes

[Network]
DHCP = yes
MulticastDNS = yes

[DHCPv4]
UseDomains = yes
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
Exec = /bin/sh -c '/usr/share/libalpm/scripts/mkinitcpio install && /usr/local/share/libalpm/scripts/mkinitcpio-install-unified'
NeedsTargets
EOF
#-------------------------------------------------------------------------------

mkdir -p /usr/local/share/libalpm/scripts
#-------------------------------------------------------------------------------
cat > /usr/local/share/libalpm/scripts/mkinitcpio-install-unified << 'EOF'
#!/usr/bin/bash
# Kernel parameters.
echo 'zfs=rootPool/root rw quiet udev.log_level=3' > /etc/kernel/cmdline

cd /boot
for kernel in vmlinuz-*; do
	pkgbase=${kernel#vmlinuz-}
	
	# Unified image.
	/usr/lib/systemd/ukify build							\
		--linux vmlinuz-${pkgbase}							\
		--initrd *-ucode.img								\
		--initrd initramfs-${pkgbase}.img					\
		--cmdline @/etc/kernel/cmdline						\
		--os-release @/usr/lib/os-release					\
		--splash /usr/share/systemd/bootctl/splash-arch.bmp	\
		--output "efi/${pkgbase}.efi"
	
	# UEFI boot entry.
	efiPartition="/dev/disk/by-partuuid/$(lsblk -nro PARTUUID,MOUNTPOINTS | grep ' /boot/efi$' | cut -d ' ' -f1)"
	
	if [[ ${pkgbase} != 'linux' ]]; then
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
pacman --noconfirm -S linux zfs-dkms
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

[Install]
WantedBy = multi-user.target
EOF
#-------------------------------------------------------------------------------

systemctl enable boot-efi.mount



# Custom configuration.
#---------------------------------------------------------------------------------------------------
# Unlock home dataset on login.
#-------------------------------------------------------------------------------
cat > /usr/local/lib/unlockHomeDataset << 'EOF'
#!/usr/bin/bash

# Abort on error.
set -e

dataset='rootPool/home'

# If the dataset is already mounted, do nothing.
if [[ $( zfs get -Ho value mounted ${dataset} ) == no ]]; then
	zfs load-key ${dataset} <<< "$(cat -)"
	zfs mount ${dataset}
fi
EOF
#-------------------------------------------------------------------------------
chmod +x /usr/local/lib/unlockHomeDataset

echo 'auth       required                    pam_exec.so          expose_authtok /usr/local/lib/unlockHomeDataset' >> /etc/pam.d/system-auth


# Automatic snapshots.

# Snapshot script.
#-------------------------------------------------------------------------------
cat > /usr/local/bin/backup << 'EOF'
#!/usr/bin/fish

set -x SSH_AUTH_SOCK /run/user/1000/ssh-agent.socket

set datasets rootPool rootPool/root rootPool/home rootPool/games
set backupDataset dataPool/backups
set sshTarget marcelotsvaz@truenas.lan

set currentTime $(date +'%Y-%m-%dT%H:%M')

if set -q argv[1]
	set backupSource $argv[1]
else
	set backupSource manual
end


echo Starting $backupSource backup at $currentTime.


for dataset in $datasets
	echo Backing up dataset $dataset.
	set newSnapshot $dataset@$backupSource-$currentTime
	zfs snapshot $newSnapshot
	
	echo Uploading snapshot $newSnapshot to dataset $backupDataset at $sshTarget.
	set lastUploadedSnapshot $(ssh $sshTarget zfs list -Ht snapshot -s creation -o name $backupDataset/$dataset)[-1]
	set lastUploadedSnapshot $(string replace --regex "^.+@" @ $lastUploadedSnapshot)
	zfs send -pwI $lastUploadedSnapshot $newSnapshot \
	| ssh $sshTarget zfs receive -Fux mountpoint $backupDataset/$dataset
end
EOF
#-------------------------------------------------------------------------------
chmod +x /usr/local/bin/backup

# Snapshot service.
#-------------------------------------------------------------------------------
cat > /etc/systemd/system/backup.service << 'EOF'
[Unit]
Description = Backup

[Service]
Type = oneshot

ExecStart = /usr/local/bin/backup daily
EOF
#-------------------------------------------------------------------------------

# Snapshot timer.
#-------------------------------------------------------------------------------
cat > /etc/systemd/system/backup.timer << 'EOF'
[Unit]
Description = Backup Timer
Requires = network-online.target
After = network-online.target

[Timer]
OnCalendar = daily

[Install]
WantedBy = timers.target
EOF
#-------------------------------------------------------------------------------
systemctl enable backup.timer


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
CipherSuites = TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384:TLS_AES_128_GCM_SHA256
CipherString = ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256
Curves = X25519:secp521r1:secp384r1
EOF
#-------------------------------------------------------------------------------


# SSH.
#-------------------------------------------------------------------------------
cat > /etc/systemd/user/ssh-agent.service << 'EOF'
[Unit]
Description = SSH Key Agent

[Service]
Type = simple
ExecStart = /usr/bin/ssh-agent -Da %t/ssh-agent.socket

[Install]
WantedBy = default.target
EOF
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
cat >> /etc/ssh/ssh_config << 'EOF'


# Custom configuration.
UserKnownHostsFile ~/.config/ssh/known_hosts

Match LocalUser marcelotsvaz
	Include /home/marcelotsvaz/.config/ssh/config
EOF
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
cat >> /etc/ssh/sshd_config << 'EOF'


# Custom configuration.
AuthorizedKeysFile .config/ssh/authorized_keys

PasswordAuthentication no

PubkeyAcceptedKeyTypes ssh-ed25519

KexAlgorithms curve25519-sha256
HostKeyAlgorithms ssh-ed25519
Ciphers chacha20-poly1305@openssh.com
MACs hmac-sha2-512-etm@openssh.com
EOF
#-------------------------------------------------------------------------------

systemctl --global enable ssh-agent
systemctl enable sshd



# Mount SMB shares.
#---------------------------------------------------------------------------------------------------
# truenas.lan shares.
#-------------------------------------------------------------------------------
cat > /etc/systemd/system/mnt-truenas-home.mount << 'EOF'
[Unit]
After = nss-lookup.target
Description = Mount SMB shares

[Mount]
What = //truenas.lan/marcelotsvaz
Where = /mnt/truenas/home
Type = cifs
Options = credentials=/etc/samba/credentials/truenas,uid=marcelotsvaz,gid=marcelotsvaz,cifsacl,nofail

[Install]
WantedBy = multi-user.target
EOF
#-------------------------------------------------------------------------------
cat > /etc/systemd/system/mnt-truenas-media.mount << 'EOF'
[Unit]
After = nss-lookup.target
Description = Mount SMB shares

[Mount]
What = //truenas.lan/media
Where = /mnt/truenas/media
Type = cifs
Options = credentials=/etc/samba/credentials/truenas,uid=marcelotsvaz,gid=marcelotsvaz,cifsacl,nofail

[Install]
WantedBy = multi-user.target
EOF
#-------------------------------------------------------------------------------
cat > /etc/systemd/system/mnt-truenas-backups.mount << 'EOF'
[Unit]
After = nss-lookup.target
Description = Mount SMB shares

[Mount]
What = //truenas.lan/Backup
Where = /mnt/truenas/backups
Type = cifs
Options = credentials=/etc/samba/credentials/truenas,uid=marcelotsvaz,gid=marcelotsvaz,cifsacl,nofail

[Install]
WantedBy = multi-user.target
EOF
#-------------------------------------------------------------------------------
systemctl enable mnt-truenas-home.mount mnt-truenas-media.mount mnt-truenas-backups.mount

mkdir -pm 700 /etc/samba/credentials

touch /etc/samba/credentials/truenas && chmod 600 ${_}