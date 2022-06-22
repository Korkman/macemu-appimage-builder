# macemu-appimage-builder
[![BasiliskII x86_64](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/BasiliskII%20x86_64.yml/badge.svg)](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/BasiliskII%20x86_64.yml) [![SheepShaver x86_64](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/SheepShaver%20x86_64.yml/badge.svg)](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/SheepShaver%20x86_64.yml) [![BasiliskII i386](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/BasiliskII%20i386.yml/badge.svg)](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/BasiliskII%20i386.yml) [![SheepShaver i386](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/SheepShaver%20i386.yml/badge.svg)](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/SheepShaver%20i386.yml)

Builds the popular classic Macintosh emulators BasiliskII (68k Macs) and SheepShaver (PowerPC Macs)
from source ([kanjitalk755's repo](https://github.com/kanjitalk755/macemu)) for 32-bit and 64-bit x86 Linux and creates AppImages which run instantly on many Linux desktops.

## Usage
Download the [latest builds](https://github.com/Korkman/macemu-appimage-builder/releases).

### Marking the downloaded files executable
Using the SheepShaver AppImage file as an example, either use your preferred file manager or a terminal to mark it executable:
```
chmod +x ./SheepShaver-x86_64.AppImage
```

### Installing with the integrated installer (optional)
The best way to install is with the integrated installer. Open a terminal and run:
```
./SheepShaver-x86_64.AppImage --install
```

The AppImage will be copied to `$HOME/.local/bin/`[^1] and two menu items will be created: one forcing startup without and one with GUI.

### Creating menu items without installing
Open a terminal, run
```
./SheepShaver-x86_64.AppImage --add-menu-items
```
The menu items will be placed in the "System" group and will point to the current location of the AppImage. You may have to log out and log in for the menu entries to appear. After changing the AppImage location just run the command again to update the menu items.

### Uninstalling, removing menu items
```
./SheepShaver-x86_64.AppImage --remove-menu-items
./SheepShaver-x86_64.AppImage --uninstall
```

### Managed installation with AppImage Launcher (not recommended)
AppImage Launcher is a tool to manage AppImage installations in a unified and integrated way. Unfortunately this means a single menu item per AppImage, which works okay for SheepShaver and BasiliskII, but is not ideal. The dedicated non-GUI menu item is important for advanced users who edit and comment their prefs file which would be overwritten by the GUI starter. You can still get them after AppImage Launcher relocated the AppImage. Simply start with `--add-menu-items` at the new location (usually in `$HOME/Applications`).

### Configuration

Guides for setting up SheepShaver and Basilisk II are available on the excellent [E-Maculation Wiki](https://www.emaculation.com/doku.php/sheepshaver_basiliskii_linux) and their [forum](https://www.emaculation.com/forum/) provides additional help.

## FAQ

### Where to put startup.wav?
Download your favorite startup chime in WAVE format and name it startup.wav to have it play on startup. Place it into the same directory where the AppImages are located.

### Where will preferences be saved?
".sheepshaver_prefs", ".basilisk_ii_prefs" in your home directory . Unless…

…you create directories named `SheepShaver-x86_64.AppImage.home` and `BasiliskII-x86_64.AppImage.home` within the same directory as the AppImages. See [AppImage portable mode](https://docs.appimage.org/user-guide/portable-mode.html).

### What is a "keycodes" file?
If you use an international keyboard, you need a "keycodes" file like the one you can [download here](https://raw.githubusercontent.com/Korkman/macemu-appimage-builder/main/keycodes). Place it along with your virtual disks, in your home directory - anywhere. The location has to be referenced in the prefs.

### Will AppImages run on any Linux?
AppImages are portable Linux applications containing most of the libraries required to run[^2].
Their only dependency is having FUSE available (which basically every sane Linux desktop environment has).[^3]
If you don't have FUSE available, you can extract the contained files with the startup argument --appimage-extract.
The contained executable script "AppRun" will run the application.

### Anything else I should know about the AppImage builds?
* The integrated scripts will inform about and try to handle low mmap addressing policies which would prevent SheepShaver from starting.
* The option "sdlrender" is currently set to "software" to maximize compatibility. You can change this by editing the .desktop files in `~/.local/share/applications` and appending `--sdlrender opengl`. Do not expect much of a difference in performance.

## Building your own

### Prerequisites for building
* Any Linux system
* Docker
* qemu-user with binfmt support for cross architecture builds
  <br>(for Debian: `apt-get install qemu-user-static`)
* AppImage Launcher NOT installed ([interferes](https://github.com/TheAssassin/AppImageLauncher/issues/407) with running AppImages inside Docker)

If you don't meet the prerequisites the [Dockerfile](https://github.com/Korkman/macemu-appimage-builder/blob/main/docker/Dockerfile), might still be of help.

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
