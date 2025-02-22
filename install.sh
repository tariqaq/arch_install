#!/bin/bash
curl -sL bit.ly/installpacmanconf > /etc/pacman.conf
curl -sL bit.ly/installmirrorlist > /etc/pacman.d/mirrorlist
pacman -Sy --noconfirm dialog

#################
#### Welcome ####
#################


bootstrapper_dialog --title "Welcome" --msgbox "Welcome to the Arch installation.\n" 6 60
dialog --stdout --msgbox "Welcome to the Arch installation.\nThis script will install the base Arch system" 0 0
dialog --stdout --msgbox "!!!This script deletes the harddrive you select without further warning!!!" 0 0

####################
#### User Input ####
####################

lang=$(dialog --title 'Keyboard Layout' --stdout --default-item '1' --menu 'Select:' 0 0 0 1 'English' 2 'German')

# load the keyboard layout
if [ $lang == 2 ]; then 
printf "loading german keyboard layout...\n"
sleep 1
loadkeys de-latin1
fi

# the harddrive select
devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)
device=$(dialog --stdout --menu "Select installation disk" 0 0 0 ${devicelist}) || exit 1

# Dual Boot
dualboot=0
exec 3>&1
selection=$(dialog \
        --title "Dual Boot" \
        --clear \
        --menu "Please select:" 0 0 4 \
        "1" "Only Linux" \
        "2" "Windows Dual Boot (only with EFI)" \
    2>&1 1>&3)
case $selection in
    0 )
        clear
        echo "Program terminated."
        ;;
    1 )
        dualboot=0
        echo "${dualboot}"
        ;;
    2 )
        dualboot=1
        echo "${dualboot}"
        ;;
esac

# hostname
hostname=$(dialog --stdout --inputbox "Enter hostname" 0 0) || exit 1
clear
: ${hostname:?"hostname cannot be empty"}

# admin
user=$(dialog --stdout --inputbox "Enter admin username" 0 0) || exit 1
clear
: ${user:?"user cannot be empty"}

# password
password=$(dialog --stdout --passwordbox "Enter admin password" 0 0) || exit 1
clear
: ${password:?"password cannot be empty"}
password2=$(dialog --stdout --passwordbox "Enter admin password again" 0 0) || exit 1
clear
[[ "$password" == "$password2" ]] || ( printf "Passwords did not match"; exit 1; )

clear

# check if the system is booted in EFI or BIOS mode
printf "checking the system for bootmode\n\n"
sleep 1
bootmode="efi"
if [ -d "/sys/firmware/efi/efivars" ]; then
    printf "the system is in EFI Mode\n"
    sleep 2
else
    if [ $dualboot -eq 1 ]; then
        printf "Dualboot not supported in bios mode\n"
        exit 1
    fi
    printf "the system is in BIOS Mode\n"
     if [[ "${device}" == "/dev/nvme"* ]]; then
        printf "nvme controller not supported with bios\n"
        sleep 3
        exit 1
     fi
    bootmode="bios"
    sleep 2
fi

clear
# check if the internet is working
printf "checking the internet connection\n\n"
sleep 1
if ping -c 1 archlinux.org &>/dev/null; then
    printf "Internet connection working...\n"
    sleep 2
else
    printf "Internet connection not working\n"
    # Wlan or Ethernet
    printf "Do you use Wlan for the installation? [y]/n\n"
    read wlan < /dev/tty

    if [[ $wlan == "Y" || $wlan == "y" ]]; then
        clear
        iwctl device list
        printf "pick device\n"
        read device < /dev/tty
        iwctl station $device scan
        iwctl station $device get-networks
        printf "pick SSID\n"
        read ssid < /dev/tty
        printf "enter password\n"
        read wlan_pw < /dev/tty
        iwctl --passphrase=$wlan_pw station $device connect $ssid
        sleep 2
        while ! ping -c 1 archlinux.org &>/dev/null;
        do
            printf "connection unsuccessful...\n"
            printf "enter password\n"
            read wlan_pw < /dev/tty
            iwctl --passphrase=$pw station $device connect $ssid
        done
        printf "Internet connection working...\n"
    else
        printf "please check your connection...\n press a key to exit"
        read < /dev/tty
        exit -1
    fi
fi
clear

# update the system clock
clear
printf "updating the system clock\n"
sleep 2
timedatectl set-ntp true
timedatectl status


########################
#### Disk Partition ####
########################
clear
printf "Starting to partition the disk\n"
sleep 2
part_swap=""
part_boot=""
part_root=""

if [ $dualboot -eq 0 ]; then
    swap_size=$(free --mebi | awk '/Mem:/ {print $2}')
    if [ $bootmode == "efi" ]; then
        swap_end=$(( $swap_size + 512 + 1 ))MiB

        parted --script "${device}" -- mklabel gpt \
            mkpart ESP fat32 1Mib 512MiB \
            set 1 boot on \
            mkpart primary linux-swap 512MiB ${swap_end} \
            mkpart primary ext4 ${swap_end} 100%

        if [[ "${device}" == "/dev/nvme"* ]]; then
        # no dualboot, efi, nvme
            part_boot="${device}p1"
            part_swap="${device}p2"
            part_root="${device}p3"

        else
        # no dualboot, efi, sda
            part_boot="${device}1"
            part_swap="${device}2"
            part_root="${device}3"
        fi

        mkfs.vfat -F32 "${part_boot}"
    else #  bios mode
        swap_end=$(( $swap_size + 1 ))MiB
        parted --script "${device}" -- mklabel msdos \
            mkpart primary linux-swap 1MiB ${swap_end} \
            set 1 boot on \
            mkpart primary ext4 ${swap_end} 100%
        if [[ "${device}" == "/dev/nvme"* ]]; then
        # no dualboot, bios, nvme
            part_swap="${device}p1"
            part_root="${device}p2"
        else
        # no dualboot, bios, sda
            part_swap="${device}1"
            part_root="${device}2"
        fi
    fi
    mkswap "${part_swap}"
    mkfs.ext4 "${part_root}"

    swapon "${part_swap}"

else # dualboot, efi
    startSector=$(parted "${device}" <<< 'unit MiB print' | awk 'FNR==14 {print $3}')
    startSector=${startSector::-3}
    startSector=$((startSector + 1))

    endSector=$(parted "${device}" <<< 'unit MiB print' | awk 'FNR==15 {print $2}')
    endSector=${endSector::-3}
    endSector=$((endSector - 1))


    clear
    printf "Starting to partition the disk\n"
    sleep 2
    swap_size=$(free --mebi | awk '/Mem:/ {print $2}')
    swap_end=$(( $swap_size + ${startSector} ))MiB

    parted --script "${device}" -- mkpart primary linux-swap ${startSector}MiB ${swap_end} \
        mkpart primary ext4 ${swap_end} ${endSector}MiB

    if [[ "${device}" == "/dev/nvme"* ]]; then
    # dualboot, efi, nvme
        part_boot="${device}p1"
        part_swap="${device}p5"
        part_root="${device}p6"
    else
    # dualboot, efi, sda
        part_boot="${device}1"
        part_swap="${device}5"
        part_root="${device}6"
    fi

    mkswap "${part_swap}"
    mkfs.ext4 "${part_root}"

    swapon "${part_swap}"
fi

######################
#### Install Arch ####
######################

mount ${part_root} /mnt
#mkdir /mnt/boot/EFI
#mount ${part_boot} /mnt/boot/EFI

clear
printf "beginning with Arch installation\n"
sleep 5

pacstrap /mnt base linux-zen linux-zen-headers linux-firmware base-devel vim nano networkmanager git man bash iwd

#configure the system
printf "setting fstab\n"
genfstab -U /mnt >> /mnt/etc/fstab

clear
printf "\n Arch is installed.\n\n"
sleep 5

###############################
#### Configure base system ####
###############################
clear
printf "Configure base system \n\n"
sleep 5

arch-chroot /mnt /bin/bash <<EOF
echo "Setting and generating locale"
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen

export LANG=en_US.UTF-8
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "Setting time zone"
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

clear
printf "setting keyboard layout\n"
if [ $lang == 2 ]; then
echo "KEYMAP=de-latin1" >> /etc/vconsole.conf
fi

if [ $dualboot == 1 ]; then
timedatectl set-local-rtc 1 --adjust-system-clock
else
timedatectl set-ntp true
fi

echo "Setting hostname"
echo $hostname > /etc/hostname
sed -i "/localhost/s/$/ $hostname/" /etc/hosts
echo "Installing wifi packages"
curl -sL bit.ly/installpacmanconf > /mnt/etc/pacman.conf
curl -sL bit.ly/installmirrorlist > /mnt/etc/pacman.d/mirrorlist
pacman --noconfirm -S iw wpa_supplicant dialog wpa_actiond sudo
echo "Generating initramfs(not editing conf)"
echo "Setting root password"
echo "root:${password}" | chpasswd
useradd -m -G wheel,uucp,video,audio,storage,games,input "$user"
echo "$user:${password}" | chpasswd
printf "setting the hosts file\n"
echo "127.0.0.1    localhost \n" >> /etc/hosts
echo "::1    localhost \n" >> /etc/hosts
echo "127.0.1.1    ${hostname}.localdomain    ${hostname}" >> /etc/hosts
systemctl enable NetworkManager
mkinitcpio -P
EOF


#########################
#### User Management ####
#########################
clear
printf "user setup\n"
sleep 5
#arch-chroot /mnt useradd -m -G wheel,uucp,video,audio,storage,games,input "$user"
#echo "$user:$password" | chpasswd --root /mnt
#echo "root:$password" | chpasswd --root /mnt
arch-chroot /mnt visudo << EOF
:%s/^# %wheel ALL=(ALL:ALL) NO/%wheel ALL=(ALL:ALL) NO/g
:wq
EOF

#############################
#### Install boot loader ####
#############################
#    curl -sL https://github.com/BennyOe/arch_install/blob/main/xenlism-grub-arch-2k.tar.xz?raw=true > /tmp/grubtheme.tar.xz
#    tar xvf /tmp/grubtheme.tar.xz --directory /tmp
#    chmod +x /tmp/xenlism-grub-arch-2k/install.sh
#    cd /tmp/xenlism-grub-arch-2k/
#    source ./install.sh    
#    rm -rf /tmp/xenlism-grub-arch-2k
#############################
clear
printf "Installing Grub boot loader\n"
sleep 5

if [ $bootmode == "efi" ]; then
    arch-chroot /mnt /bin/bash <<EOF
    mkdir /boot/EFI
    mount $part_boot /boot/EFI
    pacman -S --noconfirm grub efibootmgr dosfstools os-prober mtools
    grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck

    clear
    printf "not setting grub theme...\n"
    grub-mkconfig -o /boot/grub/grub.cfg
EOF
else
    arch-chroot /mnt /bin/bash <<EOF
    pacman -S --noconfirm grub dosfstools os-prober mtools
    grub-install --target=i386-pc $device
    grub-mkconfig -o /boot/grub/grub.cfg
EOF
fi
#curl -sL https://git.io/J1M42 > /mnt/etc/pacman.conf
curl -sL bit.ly/installpacmanconf > /mnt/etc/pacman.conf
clear
printf "Installation finished successfully\n\n"
sleep 5

while true
do
    read -r -p "Would you like to install the window manager? [Y/n] " input < /dev/tty

    case $input in
        [yY][eE][sS]|[yY])
            curl -sL bit.ly/guiscript > /mnt/home/$user/guiscript
            chmod +x /mnt/home/$user/guiscript
            printf "source ~/guiscript" >> /mnt/home/$user/.bashrc
            clear
            printf "setup the GUI install script\n"
            sleep 2
            break
            ;;
        [nN][oO]|[nN])
            break
            ;;
        *)
            echo "Invalid input..."
            ;;
    esac
done

# reboot
clear
printf "rebooting the system...\n"
printf "press a key to continue...\n"
read < /dev/tty
reboot
