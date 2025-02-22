

<h1 align="center">WWCTWArch (forked by trq)</h1>


<!---![arch1-min](https://user-images.githubusercontent.com/45036971/150820690-b1ea7ee4-14ff-41cb-8db6-429251fe3e83.png)--->

<!---![arch2-min](https://user-images.githubusercontent.com/45036971/150820747-bfd0a2cf-b778-4e5a-883e-af6fbc6bf19f.png)--->



---

# General

This script is for my specific fully configured Arch Installation with a heavily patched DWM, DWM-Blocks and all the apps I need. During the installation there are several options you can choose to customize the installation to your needs. The color scheme is Onedark.
To Install just boot from the latest Arch ISO http://archlinux.org and execute the first command below. The other scripts will execute automatically.

### Install Modes that are supported

| Mode           | UEFI | BIOS |
| -------------- | ---- | ---: |
| Linux only     | X    |    X |
| Dual-Boot      | X    |
| SDA Controller | X    |    X |
| Nvme Contoller | X    |

The patches applied to the Suckless programms can be found in the depending repositories below.

A big shout out to the wonderful people who are doing such great work to explain linux stuff to the masses.

Derek Taylor (Distrotube)
https://www.youtube.com/channel/UCVls1GmFKf6WlTraIb_IaJg

Luke Smith
https://www.youtube.com/channel/UC2eYFnH61tmytImy1mTYvhA

The Linux Cast
https://www.youtube.com/channel/UCylGUf9BvQooEFjgdNudoQg

### Repositories that are used for the installation

-   Suckless DWM https://github.com/BennyOe/dwm
-   DWM Blocks https://github.com/BennyOe/dwmblocks
-   Suckless Simple Terminal https://github.com/papitz/SimpleTerminal
-   Dotfiles https://github.com/BennyOe/.dotfiles
-   NVim https://github.com/papitz/nvim
-   Wallpaper https://github.com/BennyOe/wallpaper

---

# Installation

#### Dual Boot Installation (Optional)

-   Install Windows
-   Resize Windows partition for the Linux install
-   Install Arch with this script
-   DO NOT CREATE ADDITIONAL PARTITIONS BEFORE INSTALLING ARCH!!!

#### adding Windows to grub manually if needed

get the UUID from the EFI partition with ```lsblk -o +UUID```

edit the ```/etc/grub.d/40_custom``` and add the following code

    menuentry "Windows 10" --class windows --class os {
    insmod ntfs
    search --no-floppy --set=root --fs-uuid YOUR_UUID_HERE
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
    }
install update-grub ```yay -S update-grub``` \
run ```sudo update-grub```

---

#### WLAN

if running a device with WLAN run these commands to connect to the internet

    iwctl device list
    iwctl station <DEVICE> scan
    iwctl station <DEVICE> get-networks
    iwctl station <DEVICE> connect <SSID>
    
---

## Run the base install script

to fetch and execute the script run the command:

    curl -sL https://git.io/JOWEH | bash

#### Install XOrg, DWM & Applications

This script gets called automatically after the base install script. If you wish to execute manually, please run

    curl -sL https://git.io/JOBJn | bash

---

# Post installation

Enable the sudo command promt for a password run the commands

    su
    visudo
    uncomment the line %wheel ALL=(ALL) ALL
    comment the line %wheel ALL=(ALL) NOPASSWD: ALL

#### Intellij and java applications

to get java swing or java fx applications working in dwm add this line to your ```/etc/profile```

     export _JAVA_AWT_WM_NONREPARENTING=1

#### Autologin in lightdm

uncomment the following line in ```/etc/lightdm/lightdm.conf``` and add your user

    [Seat:*]
    autologin-user=<USERNAME>

execute the following commands

    groupadd -r autologin
    gpasswd -a <USENAME> autologin

to avoid race conditions uncomment the following line

      #logind-check-graphical=false

#### autorandr

1. Set the desired screen layout with arandr or xrandr
2. Save the config with `autorandr -s <PROFILENAME>`

#### pulse audio

disable switching to idle mode if audio is not used
comment out the following line in ```/etc/pulse/default.pa``` and restart

    # load-module module-suspend-on-idle

#### spotifyd

to set the password in your keyring execute the following command

    secret-tool store --label='name you choose' application rust-keyring service spotifyd username <your-username>
    
it should look something like this
    
![image](https://user-images.githubusercontent.com/45036971/150825941-e5fb33b9-31a7-41fe-be41-59d1f6d9c7cd.png)
    
to setup the spotifyd daemon create ```~/.config/spotifyd/spotifyd.conf``` and add this config [config file](https://spotifyd.github.io/spotifyd/config/File.html) or take the one from the ```~/.dotfiles``` folder

#### Sync the systemclock

    systemctl enable systemd-timesyncd.service

#### Auto mount network drives

create a file where you store your username and password

    username=<USERNAME>
    password=<PASSWORD>

in /etc/fstab create entry

    # Local drive
     UUID=<UUID>                          /home/<USER>/<MOUNTPOINT>         ntfs-3g         umask=000,dmask=027,fmask=137,uid=1000,gid=1000,windows_names       0 0

    # Network mount
    //192.168.1**.**/<SHARE>              /home/<USER>/<MOUNTPOINT>         cifs            uid=1000,credentials=/home/<CREDENTIAL FILE>,iocharset=utf8,x-systemd.automount    0 0

mount with Label

    LABEL=<DEVICENAME>  <MOUNTPOINT>    <FSTYPE>    umask=000,dmask=027,fmask=137,uid=1000,gid=1000,windows_names       0 0

#### Power button

set the following line in ```/etc/systemd/logind.conf```

    HandlePowerKey=suspend

#### Keyring authentication at login

add the following two lines at ```/etc/pam.d/login```

    auth optional pam_gnome_keyring.so
    session optional pam_gnome_keyring.so auto_start

Login keyring needs to be the default keyring. Can be set via seahorse.

#### setting standard applications with thunar

    open settings manager
    set default apps
    set terminal emulator to /usr/local/bin/st
    on "others" filter "plain"
    for text/plain choose application
    use a custom command
    st -e nvim

#### setting up docker

    systemctl enable docker
    systemctl start docker
    sudo groupadd docker
    sudo usermod -aG docker $USER

#### Neo-Vim

run ```:PackerSync```to intall all Vim plugins etc

---

# Surface

On Surface devices run the following commands to install the Surface kernel

    sudo mount /dev/nvme0n1p1 /boot/EFI

    curl -s https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc | sudo pacman-key --add -
    
    sudo pacman-key --finger 56C464BAAC421453
    sudo pacman-key --lsign-key 56C464BAAC421453

    sudo curl https://raw.githubusercontent.com/BennyOe/arch_install/main/surfacePacman.conf -o /etc/pacman.conf

    sudo pacman -Syu
    sudo pacman -S linux-surface linux-surface-headers iptsd
    sudo systemctl enable iptsd

    sudo grub-mkconfig -o /boot/grub/grub.cfg

    Set the resolution and scale of the device in the ```~/.dwm/autostart.sh```

In  ```~/.dotfiles``` change the branch to ```surface``` and run ```./setsymlinks.sh``` then reboot the surface. 
    
# Known Problem Fixes

#### when booting takes over 1 minute

edit ```/etc/fstab``` and comment out the swap partition line

#### bluetooth not starting

check if the Bluetooth service is running

    systemctl status bluetooth.service

if not enable it

    systemctl enable --now bluetooth.service

---

# Key Bindings

#### Basic controls

| Key                  |                 Action |
| -------------------- | ---------------------: |
| mod + space          |      Rofi App launcher |
| mod + return         |               terminal |
| mod + b              |              togglebar |
| mod + j              |       focus stack down |
| mod + k              |         focus stack up |
| mod + up             |  increase master count |
| mod + down           |  decrease master count |
| mod + l              |   increase master size |
| mod + h              |   decrease master size |
| mod + shift + j      |   move window stack up |
| mod + shift +k       | move window stack down |
| mod + shift + return |   toggle master window |
| mod + tab            |     cycle through tags |
| mod + q              |            kill window |

#### Layout manipulation

| Key                 |        Action |
| ------------------- | ------------: |
| mod + ctrl + comma  | cyclelayout - |
| mod + ctrl + period | cyclelayout + |

#### Switch to specific layouts

| Key                |                  Action |
| ------------------ | ----------------------: |
| mod + m            |       set master layout |
| mod + f            |              fullscreen |
| mod + space        |      toggle last layout |
| mod + shift +space |          togglefloating |
| mod + 0            |           view all tags |
| mod + shift + 0    | move window to all tags |

#### switching between monitors

| Key                |              Action |
| ------------------ | ------------------: |
| mod + comma        |  focus prev monitor |
| mod + period       |  focus next monitor |
| mod + ctrl + left  | tag to prev monitor |
| mod + ctrl + right | tag to next monitor |

#### Gaps

| Key             |         Action |
| --------------- | -------------: |
| mod + y         |  increase gaps |
| mod + shift + y | decreaase gaps |
| mod + ctrl y    |    toggle gaps |
| mod + alt + y   |   default gaps |

#### Scratchpads

| Key                 |            Action |
| ------------------- | ----------------: |
| mod + p             |     togglescratch |
| mod + minus         |   scratchpad show |
| mod + shift + minus |   scratchpad hide |
| mod + =             | scratchpad remove |

#### Tags

| Key                     |        Action |
| ----------------------- | ------------: |
| mod + backspace         | shutdown menu |
| mod + shift + backspace |      quit dwm |
| mod + shift + r         |    reload dwm |

#### Keyboard Layout

| Key            |                  Action |
| -------------- | ----------------------: |
| mod + ctrl + e |     switch to US layout |
| mod + ctrl + d | switch to german layout |

#### Apps

| Key             |                  Action |
| --------------- | ----------------------: |
| mod + c         |           brave browser |
| mod + x         |                  ranger |
| mod + e         |                  thunar |
| mod + ctrl + l  |         multilockscreen |
| mod + shift + c | discord signal whatsapp |
| mod + shift + t |              kill picom |
| mod + ctrl + t  |             start picom |
| mod + ctrl + m  |             pavucontrol |
| mod + shift + m |              mailspring |
| mod + shift + s |               flameshot |
| mod + ctrl + e  |        english keyboard |
| mod + ctrl + d  |         german keyboard |

---

# Installed Applications

### Base install

    iw wpa_supplicant dialog wpa_actiond sudo grub efibootmgr dosfstools os-prober mtools base linux linux-firmware
    base-devel vim networkmanager git man bash

### GUI install

    $graphicsdriver xorg xorg-xinit picom nitrogen rofi dunst yay nerd-fonts-jetbrains-mono pacman-contrib
    archlinux-contrib sysstat ttf-font-awesome dmenu network-manager-applet gnu-free-fonts zsh papirus-icon-theme
    gtk4 arc-gtk-theme lxappearance timeshift grub-customizer polkit polkit-gnome feh bluez bluez-utils blueman
    viewnior xcape multilockscreen libxft-bgra lsd pulseaudio pulseaudio-alsa pavucontrol pa-applet-git ponymix
    ranger redshift thunar numlockx zathura htop-vim-git neofetch nodejs npm python-pynvim xarchiver unzip ueberzug
    lightdm lightdm-mini-greeter zsh-theme-powerlevel10k-git neovim zsh oh-my-zsh zsh-autosuggestions
    zsh-syntax-highlighting vim-plug gotop gotop cifs-utils ntfs-3g xclip zathura-pdf-mupdf udisks thunar-volman
    pulseaudio-bluetooth lazygit pamixer gvfs xfce4-settings zip-3.0-9 bat ripgrep fd networkmanager-openconnect xdotool seahorse

##### Optional

    signal-desktop discord brave-bin flameshot autorandr mailspring whatsapp-for-linux xidlehook
    intellij-idea-ultimate-edition intellij-idea-ultimate-edition-jre jre-openjdk vlc spotify-tui playerctl spotifyd docker docker-compose

---

############

### TODO

############

-   dwm fake fullscreen fix
-   test nvme with bios
-   test dual with bios
-   ctags dwm
