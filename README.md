[![Build MinGW32 MSVCRT (Arch)](https://github.com/LuizRafael79/mingw32-msvcrt/actions/workflows/main.yml/badge.svg)](https://github.com/LuizRafael79/mingw32-msvcrt/actions/workflows/main.yml)
[![license](https://img.shields.io/badge/license-MIXED-blue.svg)](LICENSE)
[![platform](https://img.shields.io/badge/platform-Linux-lightgreen)](#)
[![platform](https://img.shields.io/badge/platform-Windows-red)](#)
[![platform](https://img.shields.io/badge/platform-MacOS-red)](#)


# MinGW32 MSVCRT Toolchain

`i686-w64-mingw32` cross-compiler toolchain using **MSVCRT** as default runtime. Ideal for compiling binaries compatible with Windows 9x, 2000, XP and other old systems, avoiding UCRT.

## 🎯 Objective

Build a clean and minimalist MinGW32 toolchain with:

- binutils
- gcc (phase 1)
- mingw-w64 headers
- mingw-w64 CRT (with MSVCRT)
- gcc (phase 2 - according to mingw32 to make Toolchains or Canadian Cross, is necessary to make GCC in two phases)
- mingw-w64 tools (gendef, genidl, genpeimg, widl)

## ✅ Prerequisites

- Linux with:
- `wget`, `tar`, `make`, `gcc`, `gawk`, `bison`, `flex`, `texinfo`
- Isolated environment (`chroot`, `container`, etc) recommended
- Permissions to install in `/opt` (or adjust the `PREFIX` variable)

## 🛠️ How to use

prepare a CHROOT development environment so that your new toolchain does not have problems with your current environment (which probably already has a toolchain) as this can cause problems, to make a clean toolchain, you MUST create a clean development environment in CHROOT or Docker (if you know how to create one)

Below are brief instructions for creating a CHROOT environment in Arch Linux, but this can be reproduced in any distro of your choice, just create the CHROOT according to your distro

1 - install the devtools package (if it is not already installed)
```bash
sudo pacman -S devtools
```
2 - Create the CHROOT directory wherever you want (I recommend it to be in the HOME folder)
```bash
mkdir -p ~/chroot/mingw-root
```
3 - Create the clean environment in CHROOT (the command will already install the base tools and git inside the CHROOT, include something if necessary) (if you wish)
```bash
sudo mkarchroot ~/chroot/mingw-root/root base-devel git
```
4 - Enter your new isolated environment
```bash
sudo arch-nspawn ~/chroot/mingw-root/root
```
5 - Inside the CHROOT install the extra dependencies
```bash
pacman -Syu --noconfirm \
gcc binutils gmp mpfr mpc zlib isl git \
mingw-w64-headers mingw-w64-crt \
make autoconf automake texinfo
```
6 - Clone this repository
```bash
git clone https://github.com/LuizRafael79/mingw32-msvcrt
```

## Prepare the script for use

prepare and execute `compile-mingw.sh` with:
```bash
chmod +x compile-mingw.sh
./compile-mingw-sh
```

## 🧪 Post-build

Add to PATH:

```bash
export PATH=$PREFIX/bin:$PATH
edit accordingly your PREFIX configuration
```

Example of compilation:

```bash
i686-w64-mingw32-gcc -nostdlib -static-libgcc -lmingw32 hello.c -o hello.exe
```

## 🖼️ Compatibility

- Generate code for Windows 95/98/ME/2k/XP
- Compatible with Windows NT 4.0/2k/XP
- Don't Work with UCRT (but you have to test it)
- Works with MSVCRT (tested)

## 📄 License

This project only automates compilations of GNU tools under their respective licenses (GPL/LGPL/BSD).

## 📄 Note

This repository is part of a complex project comming soon early
