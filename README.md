<div align="center">

# Facetimehd Toggle

-- *A little something I made to make me and other linux on mac users happy* --

</div>

## What is this?

Just a simple systray applet to toggle facetimehd camera in MacBooks running Linux **as needed** using [`modprobe`](https://en.wikipedia.org/wiki/Modprobe).

## Why this exists?

Because no one does it. Keeping the module loaded prevents few macs from going to sleep including mine and it is painful to enable and disable using terminal when I'm in a hurry to a meeting. I hope this will be helpful for someone out there.

### About this fork
This fork adds handling for a related issue: leaving the camera module loaded
can also prevent ASPM-dependent CPU power states (C6/C7) from being reached,
while disabling ASPM outright causes image artifacts while the camera is
active. This fork toggles ASPM alongside the module load/unload, and adds a
suspend hook so the camera is safely unloaded before the system sleeps.

**Plus, this also increases the privacy**

## ASPM handling
Some MacBook models exhibit a tradeoff on the FaceTime HD camera's PCIe link:
with ASPM enabled, the CPU can reach deeper power states (C6/C7), but the
camera produces image artifacts while active. With ASPM disabled, the camera
is clean but the CPU is kept out of its deepest idle states.

This fork resolves the tradeoff by only enabling ASPM while the camera is
off:

| Camera state | ASPM     | Trade-off                          |
|---|---|---|
| Enabled  | Disabled | Clean image, CPU stays out of C6/C7   |
| Disabled | Enabled  | CPU can reach C6/C7                   |

This is handled by `facetimehd-camera-on.sh` and `facetimehd-camera-off.sh`,
both of which call the generic `facetimehd-aspm-set.sh` (adapted from
[mcgrof's aspm-tuning.sh](http://wireless.kernel.org/en/users/Documentation/ASPM),
see license header in that file).

**Hardware note:** the PCIe addresses (`ROOT_COMPLEX`/`ENDPOINT`) in these
scripts are hardcoded for a MacBook Pro 13" Early 2015. If you're on a
different model, find your own addresses with `lspci -t` and update the
values at the top of `facetimehd-camera-on.sh` and `facetimehd-camera-off.sh`
before installing.


## How to setup?

### Setup FacetimeHD kernel module driver
Same commands for both Debian and Arch-based distros, unless separately listed.


1. First you need the [facetimehd kernel module driver](https://github.com/patjak/facetimehd) to be installed:

   Fedora: Use copr [frgt10/facetimehd-dkms](https://copr.fedorainfracloud.org/coprs/frgt10/facetimehd-dkms/)
   
   Debian: Follow the instructions [here](https://github.com/patjak/facetimehd/wiki/Installation#get-started-on-debian).

   Arch:

   ```bash
   yay -S facetimehd-dkms # arch linux syntax
   ```

2. Disable it from loading at startup:
  
   ```bash
   sudo vim /etc/modprobe.d/blacklist-facetimehd.conf # this will open the file with vim
   ```

   then add following line to it.

   ```bash
   blacklist facetimehd
   ```

3. Rebuild the `initramfs` and reboot the system:

   Fedora:
   
   ```bash
   sudo dracut --force --regenerate-all
   reboot
   ```

   Debian:

   ```bash
   update-initramfs -u
   ```

   Arch:

   ```bash
   mkinitcpio -P # arch linux syntax
   reboot
   ```

4. Install dependencies

   Fedora:

   ```bash
   sudo dnf install cargo atk-devel gdk-pixbuf2-devel glib2-devel pango-devel gtk3-devel cairo-devel libayatana-appindicator3
   ```

   Debian:

   ```bash
   sudo apt install cargo libglib2.0-dev libpango1.0-dev libatk1.0-dev libgdk-pixbuf-2.0-dev libgtk-3-dev
   ```

   Arch:

   ```bash
   sudo pacman -S rust cargo gtk3
   ```

5. Download the binary from the releases and move it to /usr/bin or build it using the following steps:

   ```
   git clone https://github.com/lakotamm/facetimehd-toggle.git
   cd facetimehd-toggle
   cargo build --release
   sudo cp target/release/facetimehd_toggle /usr/bin/
   ```

6. Install the ASPM scripts

   ```bash
   sudo cp facetimehd-aspm-set.sh facetimehd-camera-on.sh facetimehd-camera-off.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/facetimehd-aspm-set.sh /usr/local/bin/facetimehd-camera-{on,off}.sh
   ```

7. Suspend safety (optional but recommended)
  
   To make sure the camera doesn't interfere with suspend, install the sleep hook so it's always unloaded before the system sleeps:


   ```bash
   sudo cp facetimehd-sleep.sh /usr/lib/systemd/system-sleep/
   sudo chmod +x /usr/lib/systemd/system-sleep/facetimehd-sleep.sh
   ```

   The camera stays off after resume — you'll need to re-enable it manually from the tray icon if you need it again

8. Set up service enabling ASPM on boot (optional but recommended)

   
   After booting, the camera by default does not have enabled power saving, and it will block the CPU from going to C6/C7 states, even if the facetimehd module is unloaded. The solution is to use a service to enable ASPM on boot. 

   ```bash
   sudo cp facetimehd-aspm-boot.service /etc/systemd/system/
   sudo systemctl enable facetimehd-aspm-boot.service
   ```
   
10. You can now run the applet by using the following command: `/usr/bin/facetimehd_toggle`

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


## License
This project is licensed under the MIT license.

`facetimehd-aspm-set.sh` is adapted from a script originally written by
Luis R. Rodriguez, distributed under an ISC-style license — see the header
comment in that file for the original terms.
