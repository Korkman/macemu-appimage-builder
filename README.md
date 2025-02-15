# macemu-appimage-builder

[![SheepShaver i386](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/SheepShaver%20i386.yml/badge.svg)](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/SheepShaver%20i386.yml)
[![SheepShaver x86_64](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/SheepShaver%20x86_64.yml/badge.svg)](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/SheepShaver%20x86_64.yml)
[![SheepShaver aarch64](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/SheepShaver%20aarch64.yml/badge.svg)](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/SheepShaver%20aarch64.yml)

[![BasiliskII i386](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/BasiliskII%20i386.yml/badge.svg)](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/BasiliskII%20i386.yml)
[![BasiliskII x86_64](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/BasiliskII%20x86_64.yml/badge.svg)](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/BasiliskII%20x86_64.yml)
[![BasiliskII aarch64](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/BasiliskII%20aarch64.yml/badge.svg)](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/BasiliskII%20aarch64.yml)

Builds the popular classic Macintosh emulators BasiliskII (68k Macs) and SheepShaver (PowerPC Macs)
from source ([kanjitalk755's repo](https://github.com/kanjitalk755/macemu)) for 32-/64-bit x86 and 64-bit ARM Linux and creates AppImages which run instantly on many Linux desktops.

## Attention: Linux Kernel 6.5.x series on x86
Some users of Linux Kernel series 6.5.x may find the required sysctl mmap setting ineffective, rendering SheepShaver unusable. Your distro may have patched the Kernel to address the issue, so updating to the latest patch version is worth a try. If that doesn't help, update to a more recent Kernel (6.6.0 and up) or downgrade to an older one (6.5.0 or lower), in any way your distro supports this.

## Usage
Download the [latest builds](https://github.com/Korkman/macemu-appimage-builder/releases).

### Marking the downloaded files executable
Using the SheepShaver AppImage file as an example, either use your preferred file manager or a terminal to mark it executable:
```
chmod +x ./SheepShaver-x86_64.AppImage
```

### Installing with the integrated installer (optional, recommended)
The best way to install is with the integrated installer. Open a terminal and run:
```
./SheepShaver-x86_64.AppImage --install
```

The AppImage will be copied to `$HOME/.local/bin/`[^1] and a menu item will be created. Besides the default startup which will read the "nogui" setting from your config file, two more actions will be available in the context menu: one skipping and one forcing the settings GUI to show.

### Creating a menu item without installing (optional)
Open a terminal, run
```
./SheepShaver-x86_64.AppImage --add-menu-item
```
The menu item will be placed in the "System" group and will point to the current location of the AppImage. You may have to log out and log in for the menu entries to appear. Whenever moving the AppImage just run the command again to update the menu item.

### Separate menu item for forced GUI startup (optional)
If you prefer having a dedicated menu item for the settings GUI, run
```
./SheepShaver-x86_64.AppImage --add-settings-menu-item
```


### Uninstalling, removing menu items
```
./SheepShaver-x86_64.AppImage --remove-menu-items
./SheepShaver-x86_64.AppImage --uninstall
```

### Managed installation with AppImageLauncher (not recommended)
AppImageLauncher is a tool to manage AppImages in a unified and integrated way. After installation, launching any AppImage will prompt whether to move the AppImage to a central location and integrate it in the desktop menu. Custom menu item actions are unsupported in older versions. If you need the "forced settings" option, upgrade to a more recent AppImageLauncher version or add an extra menu item after AppImageLauncher relocated the AppImage (default location assumed):
```
$HOME/Applications/SheepShaver_*.AppImage --add-settings-menu-item
```

### Configuration

Guides for setting up SheepShaver and Basilisk II are available on the excellent [E-Maculation Wiki](https://www.emaculation.com/doku.php/sheepshaver_basiliskii_linux) and their [forum](https://www.emaculation.com/forum/) provides additional help. Adding
```
nogui true
```
to your .sheepshaver_prefs / .basilisk_ii_prefs is highly recommended so the settings GUI is skipped by default.

### Multiple installations
Multiple installations are possible, see [AppImage portable mode](https://docs.appimage.org/user-guide/portable-mode.html). The menu item installers will create and update only one instance, though, to keep things simple for users who move their single installation around and want to update the menu items. Copying and editing the menu item files is easy. Explore:
```
$HOME/.local/share/applications/com.github.korkman.macemu.SheepShaver.desktop
```


### CLI help and version information
```
./SheepShaver-x86_64.AppImage --help
./SheepShaver-x86_64.AppImage --version
```
The AppImage specific help is output before SheepShaver's. The --version flag will display build environment details and a combined "edition version" hash.

## FAQ

### Where to put startup.wav?
Download your favorite startup chime in WAVE format and name it startup.wav to have it play on startup. Place it into the same directory where the AppImages are located.

### Where will preferences be saved?
".sheepshaver_prefs", ".basilisk_ii_prefs" in your home directory . Unless you create directories named `SheepShaver-x86_64.AppImage.home` and `BasiliskII-x86_64.AppImage.home` within the same directory as the AppImages. See [AppImage portable mode](https://docs.appimage.org/user-guide/portable-mode.html).

### What is a "keycodes" file?
If you use an international keyboard, you need a "keycodes" file like the one you can [download here](https://raw.githubusercontent.com/Korkman/macemu-appimage-builder/main/keycodes). Place it along with your virtual disks, in your home directory - anywhere. The location has to be referenced in the prefs.

### Will AppImages run on any Linux?
AppImages are portable Linux applications containing most of the libraries required to run[^2].
Their only dependency is having FUSE available (which basically every sane Linux desktop environment has).[^3]
If you don't have FUSE available, you can extract the contained files with the startup argument --appimage-extract.
The contained executable script "AppRun" will run the application.

### Anything else I should know about the AppImage builds?
* (x86 only) The integrated scripts will inform about and try to handle low mmap addressing policies which would prevent SheepShaver from starting.
* The option "sdlrender" is currently set to "software" to maximize compatibility. You can launch with opengl rendering from the menu item context menu. Do not expect much of a difference in performance.

## Building your own

### Prerequisites for building
* Any Linux system
* Docker
* qemu-user with binfmt support for cross architecture builds
  <br>(for Debian: `apt-get install qemu-user-static`)
* AppImageLauncher NOT installed ([interferes](https://github.com/TheAssassin/AppImageLauncher/issues/407) with running AppImages inside Docker)

If you don't meet the prerequisites, the [Dockerfile](https://github.com/Korkman/macemu-appimage-builder/blob/main/docker/Dockerfile) might still be of help.

### Compile
```
git clone https://github.com/Korkman/macemu-appimage-builder.git
cd macemu-appimage-builder
sudo ./compile
```
The process will delete all files in the directory "output" and produce a new build.
`compile` takes up to three optional arguments: platform, "debug" and target stage.
Platform choices can be found within `compile`, target stage choices within the Dockerfile.
Examples:
```
# build combined package for x86_64
sudo ./compile x86_64
# build BasiliskII package only, for x86_64
sudo ./compile x86_64 basilisk2
# enter debug shell for the SheepShaver build environment in i386
sudo ./compile i386 debug buildenv-sheepshaver
```
The "debug" mode enters a shell at the desired stage instead of producing an output directory.
The compile directory is available in `/compiledir`.

### Purge docker images
Once you are satisfied with your build you can purge the created Docker images to reclaim
disk space with

```
sudo docker rmi $(sudo docker images -q macemu-build)
sudo docker system prune
```
(the latter is a generic command to delete all unused
and untagged images)

### The build process explained
Builds are done through use of a Dockerfile. The script `compile` passes configuration variables to `docker build`. This makes the base distribution easily swappable (as long as it's Debian based) and keeps build dependencies in easy to purge containers. Also each step inside the Dockerfile is cached, so iterations are quick when something breaks or changes are made.

### Build stages
Through the use of [multi-stage](https://docs.docker.com/develop/develop-images/multistage-build/) and [BuildKit](https://docs.docker.com/develop/develop-images/build_enhancements/), the process is partially parallelized.

The stage "buildenv" prepares all build dependencies, stages "buildenv-basilisk2" and "buildenv-sheepshaver" compile and package to "/output" inside the image. The stages "basilisk2", "sheepshaver" and "combined" reduce the image to the contents of "/output". The script `compile` passes options so the build process will extract the final image to the host directory ./output.


## Footnotes

[^1]: The path `$HOME/.local/bin` can in fact vary. See output of `systemd-path user-binaries`.

[^2]: Some libraries are in fact excluded and this can sometimes cause issues. Please file an issue if you encounter "missing symbol" or similar errors that point to ".so" files

[^3]: More specifically, at the time of writing, this is FUSE2 opposed to FUSE3. FUSE3 support is [on its way](https://github.com/AppImage/AppImageKit/issues/877). Some users (most notably Ubuntu 22.04 users) may need to manually `sudo add-apt-repository universe && sudo apt install libfuse2` to run AppImages in the meantime.
