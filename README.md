<div align="center">

# Facetimehd Toggle

-- *A little something I made to make me and other linux on mac users happy* --

</div>

## What is this?

Just a simple systray applet to toggle facetimehd camera in MacBooks running Linux **as needed** using [`modprobe`](https://en.wikipedia.org/wiki/Modprobe).

## Why this exists?

Because no one does it. Keeping the module loaded prevents few macs from going to sleep including mine and it is painful to enable and disable using terminal when I'm in a hurry to a meeting. I hope this will be helpful for someone out there.

**Plus, this also increases the privacy**

## How to setup?

1. First you need the [facetimehd kernel module driver](https://github.com/patjak/facetimehd) to be installed:

```bash
yay -S facetimehd-dkms # arch linux syntax
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
mkinitcpio -P # arch linux syntax
reboot
```

4. Download the binary from the releases and move it to /usr/bin or build it using the following steps: 
```
sudo pacman -S rust cargo gtk3
git clone https://github.com/Chamal1120/facetimehd-toggle.git
cd facetimehd-toggle
cargo build --release
sudo cp target/release/facetimehd_toggle /usr/bin/
```

5. You can now run the applet by using the following command: `/usr/bin/facetimehd_toggle`

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
ExecStart=/usr/bin/facetimehd_toggle
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

#### Hyprland user?

1. Make sure you have hyprpolkit or another polkit agent setup.

2. Then just put below line into your hyprland config and you're done.

```bash
exec-once = env DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS <path/to/your/program>
```

*Aur Package is coming soon...*

## License
This project is Licensed under MIT license.
