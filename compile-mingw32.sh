#!/bin/bash
set -e

# Configurações
PREFIX=/usr/local
TARGET=i686-w64-mingw32
JOBS=$(nproc)

# URLs dos fontes (você pode mudar o mirror)
BINUTILS_URL="https://gnu.c3sl.ufpr.br/ftp/binutils/binutils-2.40.tar.xz"
GCC_URL="https://gnu.c3sl.ufpr.br/ftp/gcc/gcc-13.1.0/gcc-13.1.0.tar.xz"
MINGW_HEADERS_URL="https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v12.0.0.tar.bz2/download"
MINGWCRT_URL="https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v12.0.0.tar.bz2/download"  # mesmo pacote, só vai extrair a pasta crt depois

# Limpa instalações antigas
echo "Limpando $PREFIX..."
rm -rf "$PREFIX"
mkdir -p "$PREFIX"

# Baixa e extrai fontes
mkdir -p ~/src && cd ~/src

echo "Baixando binutils..."
wget -c $BINUTILS_URL -O binutils.tar.xz
tar xf binutils.tar.xz

echo "Baixando gcc..."
wget -c $GCC_URL -O gcc.tar.xz
tar xf gcc.tar.xz

echo "Baixando mingw-w64 (headers + crt)..."
wget -c $MINGW_HEADERS_URL -O mingw-w64.tar.bz2
tar xf mingw-w64.tar.bz2

HOST=$(~/src/gcc-13.1.0/config.guess)

# Compila e instala binutils
cd binutils-2.40
mkdir -p build && cd build
../configure --target=$TARGET --host=$HOST --prefix=$PREFIX --disable-multilib --disable-nls
make -j$JOBS
make install

# Instala os headers do mingw-w64 (apenas headers)
cd ~/src/mingw-w64-v12.0.0/mingw-w64-headers
mkdir -p build && cd build
../configure --prefix=$PREFIX/$TARGET --host=$TARGET --enable-sdk=all --enable-idl --with-default-msvcrt=msvcrt
make install

# Compila gcc fase 1 (apenas o compilador C, sem libs)
cd ~/src/gcc-13.1.0
./contrib/download_prerequisites
mkdir -p build && cd build
../configure --target=$TARGET --host=$HOST --prefix=$PREFIX --disable-multilib --enable-languages=c --disable-nls --without-headers --with-default-msvcrt=msvcrt --disable-shared --disable-threads
make all-gcc -j$JOBS
make install-gcc

# crt - msvcrt
echo "Compilando o CRT do mingw-w64 (msvcrt fallback)..."
cd ~/src/mingw-w64-v12.0.0/mingw-w64-crt
mkdir -p build && cd build
# Configure com o host e target invertidos como manda a documentação mingw-w64 para crt
../configure --host=$TARGET --prefix=$PREFIX/$TARGET --with-default-msvcrt=msvcrt
make -j$JOBS
make install

# gcc phase 2
cd ~/src/gcc-13.1.0/build
make -j$JOBS
make install

echo "Compilando tools do mingw-w64..."

echo "Compilando gendef"
cd ~/src/mingw-w64-v12.0.0/mingw-w64-tools/gendef
./configure
make -j$JOBS
make install

echo "Compilando genidl"
cd ~/src/mingw-w64-v12.0.0/mingw-w64-tools/genidl
./configure
make -j$JOBS
make install

echo "Compilando genpeimg"
cd ~/src/mingw-w64-v12.0.0/mingw-w64-tools/genpeimg
./configure
make -j$JOBS
make install

echo "Compilando widl"
cd ~/src/mingw-w64-v12.0.0/mingw-w64-tools/widl
./configure --target=$TARGET --prefix=$PREFIX --bindir=$PREFIX/bin
make -j$JOBS
make install

echo "Build completo! Verifique o PATH: export PATH=$PREFIX/bin:\$PATH"
