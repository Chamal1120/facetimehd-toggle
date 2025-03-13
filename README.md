<div align="center">

# Facetimehd Toggle

-- *A little something I made to make me and other linux mac users happy* --

</div>

## What is this?

Just a simple systray toggle for enabling and disabling facetimehd camera as needed using `modprobe`.

## Why this exists?

Because no one does it. Keeping the module loaded prevents few macs from going to sleep including mine and it is painful to enable and disable using terminal when I'm in a hurry to a meeting. I hope this will be helpful for someone out there. That's why I publish this.

**Plus, this also increases the privacy**

## How to setup?

1. First you need the [facetimehd camera kernel module driver](https://github.com/patjak/facetimehd) to be installed:

```bash
yay -S facetimehd-dkms # on a arch based distro with yay can use this command
```

2. Disable it from loading at startup:

```bash
sudo vim /etc/modprobe.d/blacklist-facetimehd.conf # this will open the file with vim
```

then add following line to it.

```
blacklist facetimehd
```

3. Rebuild the `initramfs` and reboot the system:

```bash
mkinitcpio -P # for non arch distro's syntax may vary
reboot
```

4. Grab the binary and install to anywhere you like:

## Make the systray auto start on boot

#### Using systemd

1. Create systemd unit:

```bash
mkdir -p ~/.config/systemd/user
vim ~/.config/systemd/user/facetimehd-toggle.service
```

and add following,
```
[Unit]
Description=FaceTimeHD Toggle Tray
After=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/facetimehd-toggle
Restart=on-failure

[Install]
WantedBy=default.target
```

2. Enable and start the service:

```bash
systemctl --user enable facetimehd-toggle.service
systemctl --user start facetimehd-toggle.service
```

3. Check status:

```
systemctl --user status facetimehd-toggle.service
```

*Aur Package is coming soon...*

## Contributing

This software is licensed under MIT and any contribution is very much welcome. 

## Thank You
