# macemu-appimage-builder
Builds the popular classic Macintosh emulators BasiliskII (68k Macs) and SheepShaver (PowerPC Macs)
from source ([kanjitalk755's repo](https://github.com/kanjitalk755/macemu)) for 32-bit and 64-bit x86 Linux and creates AppImages which run instantly on many Linux desktops.

Download the [latest build](https://github.com/Korkman/macemu-appimage-builder/releases/latest)

[![BasiliskII amd64](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/BasiliskII%20amd64.yml/badge.svg)](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/BasiliskII%20amd64.yml) [![SheepShaver amd64](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/SheepShaver%20amd64.yml/badge.svg)](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/SheepShaver%20amd64.yml) [![BasiliskII i386](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/BasiliskII%20i386.yml/badge.svg)](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/BasiliskII%20i386.yml) [![SheepShaver i386](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/SheepShaver%20i386.yml/badge.svg)](https://github.com/Korkman/macemu-appimage-builder/actions/workflows/SheepShaver%20i386.yml)

## Download contents
```
BasiliskII       - launcher for the 68k emulator
BasiliskIIGUI    - launcher for the 68k emulator GUI
SheepShaver      - launcher for the PPC emulator
SheepShaverGUI   - launcher for the PPC emulator GUI
macemuAppImages/ - contains the actual AppImages

Install          - script to install as applications into home directory
installFiles/    - contains .desktop files and .png icons for the installation
```

## About the launchers
They are mostly optional. They make GUI and non-GUI startup easily accessible.
The main point is to generate the AppImages in the directory `macemuAppImages`. You
can skip the launchers if you want to.

## Install (optional)
The install script will copy launchers and AppImages to `$HOME/.local/bin/`[^1] and create
menu entries for the application menu for convenience. You may have to log out and log in
for the menu entries to appear. Also, make sure your PATH variable contains the installer
destination directory (true for sane Linux distros).

## Where to put startup.wav
Download your favorite startup chime in WAVE format and name it startup.wav to have it play on startup. Place it right into `macemuAppImages`. When installed it is located in `$HOME/.local/bin/macemuAppImages`[^1].

## Where will preferences be saved
In your home directory. Unless…

…you create directories named `SheepShaver.AppImage.home` and `BasiliskII.AppImage.home` within `macemuAppImages`. See [AppImage portable mode](https://docs.appimage.org/user-guide/portable-mode.html).

## If SheepShaver doesn't start
Try running SheepShaver in a terminal to see constructive error messages.
One common problem is that Linux by default disallows low memory access, which SheepShaver unfortunately requires.
The launchers provide further instructions.

## AppImage compatibility
AppImages are portable Linux applications containing all the libraries required to run[^2].
Their only dependency is having FUSE available (which basically every sane Linux desktop environment has).[^3]
If you don't have FUSE available, your can extract the contained files with the startup argument --appimage-extract.
The contained executable script "AppRun" will run the application.

## Guides on SheepShaver and Basilisk II
See the excellent [E-Maculation Wiki](https://www.emaculation.com/doku.php/ubuntu) and [forum](https://www.emaculation.com/forum/)
# Building your own

## Prerequisites for building
* Any Linux system
* Docker
* qemu-user with binfmt support for cross architecture builds
  <br>(for Debian: `apt-get install qemu-user-static`)
* AppImage Launcher NOT installed (interferes with running AppImages inside Docker)

If you don't meet the prerequisites the [Dockerfile](https://github.com/Korkman/macemu-appimage-builder/blob/main/docker/Dockerfile) might still be of help.

## Compile
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
# build combined package for amd64
sudo ./compile amd64
# build BasiliskII package only, for amd64
sudo ./compile amd64 basilisk2
# enter debug shell for the SheepShaver build environment in i386
sudo ./compile i386 debug buildenv-sheepshaver
```
The "debug" mode enters a shell at the desired stage instead of producing an output directory.
The compile directory is available in `/compiledir`.

## Purge docker images
Once you are satisfied with your build you can purge the created Docker images to reclaim
disk space with

```
sudo docker rmi $(sudo docker images -q macemu-build)
sudo docker system prune
```
(the latter is a generic command to delete all unused
and untagged images)

## The build process explained
Builds are done through use of a Dockerfile. The script `compile` passes configuration variables to `docker build`. This makes the base distribution easily swappable (as long as it's Debian based) and keeps build dependencies in easy to purge containers. Also each step inside the Dockerfile is cached, so iterations are quick when something breaks or changes are made.

## Build stages
Through the use of [multi-stage](https://docs.docker.com/develop/develop-images/multistage-build/) and [BuildKit](https://docs.docker.com/develop/develop-images/build_enhancements/), the process is partially parallelized.

The stage "buildenv" prepares all build dependencies, stages "buildenv-basilisk2" and "buildenv-sheepshaver" compile and package to "/output" inside the image. The stages "basilisk2", "sheepshaver" and "combined" reduce the image to the contents of "/output". The script `compile` will then extract "/output" to the host "./output".


# Footnotes

[^1]: The path `$HOME/.local/bin` can in fact vary. See output of `systemd-path user-binaries`.

[^2]: Some libraries are in fact excluded and this can sometimes cause issues. Please file an issue if you encounter "missing symbol" or similar errors that point to ".so" files

[^3]: More specifically, at the time of writing, this is FUSE2 opposed to FUSE3. FUSE3 support is [on its way](https://github.com/AppImage/AppImageKit/issues/877). Some users (most notably Ubuntu 22.04 users) may need to manually `sudo add-apt-repository universe && sudo apt install libfuse2` to run AppImages in the meantime.
