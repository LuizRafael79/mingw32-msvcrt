# MinGW32 MSVCRT Toolchain

[![Build Status](https://github.com/your-user/your-repo/actions/workflows/build.yml/badge.svg)](https://github.com/your-user/your-repo/actions)

`i686-w64-mingw32` cross-compiler toolchain using **MSVCRT** as default runtime. Ideal for compiling binaries compatible with Windows 9x, 2000, XP and other old systems, avoiding UCRT.

## 🎯 Objective

Build a clean and minimalist MinGW32 toolchain with:

- binutils
- gcc (phase 1 and 2)
- mingw-w64 headers
- mingw-w64 CRT (with MSVCRT)
- mingw-w64 tools (gendef, genidl, genpeimg, widl)

## ✅ Prerequisites

- Linux with:
- `wget`, `tar`, `make`, `gcc`, `gawk`, `bison`, `flex`, `texinfo`
- Isolated environment (`chroot`, `container`, etc) recommended
- Permissions to install in `/opt` (or adjust the `PREFIX` variable)

## 🛠️ How to use

prepare and execute `compile-mingw.sh` with:
```bash
chmod +x compile-mingw.sh
./compile-mingw-sh
```


## 🧪 Post-build

Add to PATH:

```bash
export PATH=/opt/mingw32-msvcrt/bin:$PATH
```

Example of compilation:

```bash
i686-w64-mingw32-gcc -nostdlib -static-libgcc -lmingw32 hello.c -o hello.exe
```

## 🖼️ Compatibility

- Windows 95/98/ME
- Windows NT 4.0/2000/XP
- Ideal for EXEs and DLLs without modern dependencies

## 📄 License

This project only automates compilations of GNU tools under their respective licenses (GPL/LGPL/BSD).

## 📄 Note

This repository is part of a complex project comming soon early
