[![Build MinGW32 MSVCRT (Arch)](https://github.com/LuizRafael79/mingw32-msvcrt/actions/workflows/main.yml/badge.svg)](https://github.com/LuizRafael79/mingw32-msvcrt/actions/workflows/main.yml)
[![license](https://img.shields.io/badge/license-MIXED-blue.svg)](LICENSE)
[![platform](https://img.shields.io/badge/platform-Linux-lightgreen)](#)
[![platform](https://img.shields.io/badge/platform-Windows-red)](#)
[![platform](https://img.shields.io/badge/platform-MacOS-red)](#)


# MinGW32 MSVCRT Toolchain

cross-compiler toolchain using **MSVCRT** as default runtime.
Default target: `i586-w64-mingw32`. Optional overlay: `i686-w64-mingw32`.

Ideal for compiling binaries compatible with **Windows 95/98/ME, 2000, XP** and other old systems, avoiding UCRT, while allowing **SSE2 and AVX** for modern CPUs when desired.

## 🎯 Objective

Build a clean and minimalist MinGW32 toolchain with:

- binutils
- gcc (phase 1)
- mingw-w64 headers
- mingw-w64 CRT (with MSVCRT)
- gcc (phase 2 - according to mingw32 to make Toolchains or Canadian Cross, is necessary to make GCC in two phases)
- mingw-w64 tools (gendef, genidl, genpeimg, widl)

Supports:

- **Legacy Windows** (95/98/ME/NT4/2000/XP)
- **Modern CPU features** (SSE2, AVX) for newer systems, selectable per-project.

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

⚡ Using the Compiler:

## Legacy-safe builds (Win9x/98/ME/NT4) - default, nothing speial:

```bash
i586-w64-mingw32-gcc main.c -o main.exe
```

## Win2000+:
```bash
i586-w64-mingw32-gcc main.c -o main.exe -DWINVER=0x500 -D_WIN32_WINNT=0x500
```

## WinXP+"
```bash
i586-w64-mingw32-gcc main.c -o main.exe -DWINVER=0x501 -D_WIN32_WINNT=0x501
```

## Enable SSE2 (Pentium 4+):
```bash
i586-w64-mingw32-gcc main.c -o main.exe -msse2 -mfpmath=sse
```
(Will **not** run on 9x/NT4-era hardware.)

# Enable AVX (Sandy Bridge+ and OS support):

```bash
i586-w64-mingw32-gcc main.c -o main.exe -mavx
```
AVX needs an OS that saves/restores  YMM state. **Windows XP does not**; think Windows 7 SP1+.

# C++ small/static Runtime if desired:
```bash
i586-w64-mingw32-g++ main.cpp -o main.exe -static-libgcc -static-libstd++
```

# i686 overlay builds:
```bash
i686-w64-mingw32-gcc main.c -o main.exe
```
**Uses `--with-arch=pentiumpro` internally for i686 optimizations**

Example with Legacy flags:
```bash
i586-w64-mingw32-gcc -nostdlib -static-libgcc -lmingw32 hello.c -o hello.exe
```

## 🖼️ Compatibility

- Generate code for Windows 95/98/ME/2k/XP
- Compatible with Windows NT4/2000/XP
- Don't Work with UCRT (but you have to test it)
- Works with MSVCRT (tested)

## 📄 License

This project only automates compilations of GNU tools under their respective licenses (GPL/LGPL/BSD).

## 📄 Note

This repository is part of a complex project comming soon early

## 🗂️ Feature Matrix

| Target Windows | Compiler Flag | CPU Features | Notes |
|----------------|---------------|--------------|-------|
| Windows 95/98/ME | `i586-w64-mingw32-gcc` | Pentium / MMX | Legacy safe |
| Windows NT4/2000 | `-DWINVER=0x0500 -D_WIN32_WINNT=0x0500` | SSE optional | Modern CPUs can enable SSE2 |
| Windows XP | `-DWINVER=0x0501 -D_WIN32_WINNT=0x0501` | SSE2 default | Works on most XP-era CPUs |
| Windows 7+ | `-DWINVER=0x0601 -D_WIN32_WINNT=0x0601` | SSE2 / AVX optional | Enable AVX with `-mavx` |
| Modern CPUs | `-msse2 -mavx` | SSE2 / AVX | Only for CPUs that support it, may break legacy Windows |
