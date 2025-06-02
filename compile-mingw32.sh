#!/bin/bash
set -e

PREFIX=/usr/local/mingw32-msvcrt
TARGET=i686-w64-mingw32
TARGET_TARGET="--target=$TARGET"
PREFIX_TARGET="--prefix=$PREFIX/$TARGET"
PREFIX_INSTALL="--prefix=$PREFIX --libdir=$PREFIX/lib --libexecdir=$PREFIX/libexec --includedir=$PREFIX/include --bindir=$PREFIX/bin --mandir=$PREFIX/share/man --infodir=$PREFIX/share/info"
JOBS=$(nproc)

BINUTILS_URL="https://gnu.c3sl.ufpr.br/ftp/binutils/binutils-2.40.tar.xz"
GCC_URL="https://gnu.c3sl.ufpr.br/ftp/gcc/gcc-13.1.0/gcc-13.1.0.tar.xz"
MINGW_HEADERS_URL="https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v12.0.0.tar.bz2/download"

rm -rf "$PREFIX"
mkdir -p "$PREFIX"
mkdir -p ~/src && cd ~/src

wget -c $BINUTILS_URL -O binutils.tar.xz
tar xf binutils.tar.xz

wget -c $GCC_URL -O gcc.tar.xz
tar xf gcc.tar.xz

wget -c $MINGW_HEADERS_URL -O mingw-w64.tar.bz2
tar xf mingw-w64.tar.bz2

HOST=$(~/src/gcc-13.1.0/config.guess)
HOST_HOST="--host=$HOST"
HOST_TARGET="--host=$TARGET"

cd binutils-2.40
mkdir -p build && cd build
../configure $TARGET_TARGET $HOST_HOST $PREFIX_INSTALL --disable-multilib --disable-nls
make -j$JOBS
make install

cd ~/src/mingw-w64-v12.0.0/mingw-w64-headers
mkdir -p build && cd build
../configure $PREFIX_TARGET $HOST_TARGET --enable-sdk=all --enable-idl --with-default-msvcrt=msvcrt
make install

cd ~/src/gcc-13.1.0
mkdir -p build && cd build
../configure $TARGET_TARGET $HOST_HOST $PREFIX_INSTALL --disable-multilib --enable-languages=c --disable-nls --without-headers --with-default-msvcrt=msvcrt --disable-shared --disable-threads
make all-gcc -j$JOBS
make install-gcc

cd ~/src/mingw-w64-v12.0.0/mingw-w64-crt
mkdir -p build && cd build
../configure $PREFIX_TARGET $HOST_TARGET --with-default-msvcrt=msvcrt
make -j$JOBS
make install

cd ~/src/gcc-13.1.0/build
make -j$JOBS
make install

cd ~/src/mingw-w64-v12.0.0/mingw-w64-tools/gendef
./configure $TARGET_TARGET $PREFIX_INSTALL
make -j$JOBS
make install

cd ~/src/mingw-w64-v12.0.0/mingw-w64-tools/genidl
./configure $TARGET_TARGET $PREFIX_INSTALL
make -j$JOBS
make install

cd ~/src/mingw-w64-v12.0.0/mingw-w64-tools/genpeimg
./configure $TARGET_TARGET $PREFIX_INSTALL
make -j$JOBS
make install

cd ~/src/mingw-w64-v12.0.0/mingw-w64-tools/widl
./configure $TARGET_TARGET $PREFIX_INSTALL
make -j$JOBS
make install
