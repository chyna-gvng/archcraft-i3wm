# POST INSTALLATION
## PLYMOUTH & GRUB
- sudo micro /etc/default/grub
- change [GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"] to [GRUB_CMDLINE_LINUX_DEFAULT="quiet splash plymouth.enable=1"]
- uncomment [GRUB_THEME="/usr/share/grub/themes/archcraft/theme.txt"]
- sudo grub-mkconfig -o /boot/grub/grub.cfg
- sudo micro /etc/mkinitcpio.conf
- modify [HOOKS=(base udev autodetect ...)] to [HOOKS=(base plymouth udev autodetect ...)]
- sudo mkinitcpio -P

## SDDM
- sudo micro /etc/sddm.conf(default from: https://github.com/archcraft-os/archcraft)
- under [Theme] add [Current=archcraft]
- sudo systemctl enable sddm
- sudo systemctl start sddm

## NETWORK MANAGER
- sudo systemctl enable NetworkManager
- sudo systemctl start NetworkManager

## TOUCHPAD
- sudo micro /etc/X11/xorg.conf.d/02-touchpad-ttc.conf(default from: https://github.com/archcraft-os/archcraft)

## ZSH
- sudo cp -r /etc/skel/.oh-my-zsh /etc/skel/.zshrc ~
- chsh -s $(which zsh)
- reboot

