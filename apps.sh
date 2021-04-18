#!/bin/bash

#### TODO ####
# bluetooth
# autostart numlockx on

#################
#### Welcome ####
#################
bootstrapper_dialog --title "Welcome" --msgbox "Welcome to the Apps Installation.\n" 6 60

##################
### User Input ###
##################

# app folder
appfolder=$(dialog --stdout --inputbox "Enter additional apps" 0 0) || exit 1
clear

yay -S --noconfirm $appfolder

##################
## Standard Apps #
##################

yay -S --noconfirm pulseaudio pavucontrol signal-desktop discord_arch_electron brave-bin ranger redshift flameshot autorandr mailspring whatsapp-for-linux thunar xidlehook numlockx intellij-idea-ultimate-edition
