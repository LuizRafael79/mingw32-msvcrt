#!/bin/bash
set -e

##################
# Configurations #
##################

BINUTILS_VER=2.40
GCC_VER=13.1.0
MINGW_VER=12.0.0

THREADS="--enable-threads=win32"
TC_ARCH="win32"
BUILD_DIR="/opt/$TC_ARCH"
PREFIX="$BUILD_DIR"
TARGET="i686-w64-mingw32"
JOBS="$(nproc)"
SOURCE="src-$TC_ARCH"

#########################
# URLs of sources files #
#########################

BINUTILS_URL="https://gnu.c3sl.ufpr.br/ftp/binutils/binutils-${BINUTILS_VER}.tar.xz" 
GCC_URL="https://gnu.c3sl.ufpr.br/ftp/gcc/gcc-13.1.0/gcc-${GCC_VER}.tar.xz" 
MINGW_URL="https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/mingw-w64-v${MINGW_VER}.tar.bz2/download" 

##################################################
# Generic function to download and extract files #
##################################################

download_and_extract() {
    if [ "$#" -ne 3 ]; then
        echo "Use: download_and_extract <url> <archive> <extraction-directory>"
        return 1
    fi

    local url="$1"
    local archive="$2"
    local extract_dir="$3"
    local lockfile="${archive}.lock"

    # If lockfile exists and extract_dir exists, skip all
    if [ -f "$lockfile" ] && [ -d "$extract_dir" ]; then
        echo "Lockfile '$lockfile' and directory '$extract_dir' exist. Skipping download and extraction."
        return 0
    fi

    # If lockfile exists but archive is missing (user deleted archive manually)
    if [ -f "$lockfile" ] && [ ! -f "$archive" ]; then
        echo "Lockfile exists but archive '$archive' missing. Removing stale lockfile."
        rm -f "$lockfile"
    fi

    # Function to test archive integrity for .xz compressed tarballs
    test_archive() {
        if [[ "$archive" == *.tar.xz ]]; then
            xz -t "$archive" 2>/dev/null
            return $?
        else
            # Could add tests for other archive types if needed
            return 0
        fi
    }

    # If archive doesn't exist, download and create lockfile
    if [ ! -f "$archive" ]; then
        echo "Archive '$archive' not found. Downloading..."
        wget -c "$url" -O "$archive" || { echo "Download error, check the script!"; exit 1; }
        echo "$$" > "$lockfile" || { echo "Failed to create lockfile."; exit 1; }

        if [ -d "$extract_dir" ]; then
            echo "Directory '$extract_dir' exists. Removing before extraction..."
            rm -rf "$extract_dir" || { echo "Failed to remove directory '$extract_dir'"; exit 1; }
        fi

        echo "Extracting '$archive'..."
        tar xf "$archive" || { echo "Extraction error for file '$archive'. Possibly corrupted."; exit 1; }
        return 0
    fi

    # Archive exists but no lockfile, test archive integrity
    if [ ! -f "$lockfile" ]; then
        echo "Lockfile missing but archive '$archive' exists. Testing archive integrity..."
        if ! test_archive; then
            echo "Archive '$archive' corrupted or incomplete. Re-downloading..."
            wget -c "$url" -O "$archive" || { echo "Download error, check the script!"; exit 1; }
        fi

        # After download or if test passed, recreate lockfile
        echo "$$" > "$lockfile" || { echo "Failed to create lockfile."; exit 1; }

        if [ -d "$extract_dir" ]; then
            echo "Directory '$extract_dir' exists. Removing before extraction..."
            rm -rf "$extract_dir" || { echo "Failed to remove directory '$extract_dir'"; exit 1; }
        fi

        echo "Extracting '$archive'..."
        tar xf "$archive" || { echo "Extraction error for file '$archive'. Possibly corrupted."; exit 1; }
        return 0
    fi

    # If here, lockfile missing, archive missing — just in case (shouldn't happen)
    echo "Unexpected state. Please check manually."
    return 1
}

###############################
# Download and Extract source #
###############################

mkdir -p ~/$SOURCE && cd ~/$SOURCE

echo "Binutils $BINUTILS_VER"
download_and_extract "$BINUTILS_URL" "binutils-${BINUTILS_VER}.tar.xz" "binutils-${BINUTILS_VER}"

echo "GCC $GCC_VER"
download_and_extract "$GCC_URL" "gcc-${GCC_VER}.tar.xz" "gcc-${GCC_VER}"

echo "mingw-w64 $MINGW_VER"
download_and_extract "$MINGW_URL" "mingw-w64v-${MINGW_VER}.tar.bz2" "mingw-w64-v${MINGW_VER}"

HOST=$(~/$SOURCE/gcc-13.1.0/config.guess)

###################################
# Built and install Binutils 2.40 #
###################################

echo "Starting Binutils build..."
cd binutils-${BINUTILS_VER}
mkdir -p build && cd build
../configure --target=$TARGET --host=$HOST --prefix=$PREFIX --with-sysroot=$PREFIX --disable-multilib --disable-nls
make -j$JOBS
make install

##################################
# Install Mingw-w64 Headers Only #
##################################

echo "Starting Mingw Headers Install"
cd ~/$SOURCE/mingw-w64-v${MINGW_VER}/mingw-w64-headers
mkdir -p build && cd build

################################################
# Configure with the $Prefix/$Target in Prefix #
# and --host=$TARGET in -host                  #
# as per Mingw/GCC documentation for Toolchain #
################################################

../configure --prefix=$PREFIX/$TARGET --host=$TARGET --with-sysroot=$PREFIX --enable-sdk=all --enable-idl --with-default-msvcrt=msvcrt
make install

echo "Creating Symlinks"
ln -s $PREFIX/$TARGET $PREFIX/mingw
ln -s $PREFIX/$TARGET/lib $PREFIX/$TARGET/lib64
echo ""
echo "Now mingw and lib64 is symlinked" 
echo "to correct paths accepted by GCC"
echo ""
echo "Refreshing PATH" #note: this change is valid during the script use only
PATH=$PATH:$PREFIX/bin:$PREFIX/$TARGET/bin
echo ""
echo "Verify if PATH is the correct one - desired output"
echo "is $PREFIX/bin:$PREFIX/$TARGET/bin:/usr/bin etc"
echo "Building PATH is -> $PATH" 
echo ""
echo "if PATH is empty or wrong, abort script and check"
echo ""
#read -p "Press Enter to continue..."

##################################################
# Built GCC Phase 1 (Only compiler without libs) #
##################################################
echo "Preparing GCC ${GCC_VER} to build"                   
cd ~/$SOURCE/gcc-${GCC_VER}
# Download GCC Pre Requisites
echo "Downloading GCC Pre Requisites"
./contrib/download_prerequisites
mkdir -p build && cd build

##########################################
# Configure GGC for Phase 1              # 
# as per GCC documentation for Toolchain #
##########################################
echo "Building GCC ${GCC_VERSION} with C only"
# Building with c++ cause errors about SSE2 and AVX, help to fix that is appreciated
../configure --target=$TARGET --host=$HOST --prefix=$PREFIX --with-sysroot=$PREFIX --disable-multilib --enable-languages=c --disable-nls --without-headers --with-default-msvcrt=msvcrt --disable-shared $THREADS
make all-gcc -j$JOBS
make install-gcc

###############################################
# Built and Install Mingw-w64 CRT with MSVCRT #
###############################################

echo "Building mingw-w64 CRT with MSVCRT"
cd ~/$SOURCE/mingw-w64-v${MINGW_VER}/mingw-w64-crt
mkdir -p build && cd build

################################################
# Configure with the $Prefix/$Target in Prefix #
# and --host=$TARGET in -host                  #
# as per Mingw/GCC documentation for Toolchain #
################################################

../configure --host=$TARGET --prefix=$PREFIX/$TARGET --with-sysroot=$PREFIX --with-default-msvcrt=msvcrt
make -j$JOBS
make install

############################################
# Built GCC Phase 2 (Continues the Phase 1 #
############################################
echo "Building GCC ${GCC_VER} Phase 2"
cd ~/$SOURCE/gcc-13.1.0/build

##########################################
# Configure GGC for Phase 2              #
# as per GCC documentation for Toolchain #
##########################################

make -j$JOBS
make install

#################################
# Building Mingw-W64 Tools like #
# Gendef                        #
# Genidl                        #
# Genpeigm                      #
# Widl                          #     
#################################

echo "Building Mingw-w64 tools"

echo "Building gendef"
cd ~/$SOURCE/mingw-w64-v12.0.0/mingw-w64-tools/gendef
./configure
make -j$JOBS
make install

echo "Building genidl"
cd ~/$SOURCE/mingw-w64-v12.0.0/mingw-w64-tools/genidl
./configure
make -j$JOBS
make install

echo "Building genpeimg"
cd ~/$SOURCE/mingw-w64-v12.0.0/mingw-w64-tools/genpeimg
./configure
make -j$JOBS
make install

echo "Building widl"
cd ~/$SOURCE/mingw-w64-v12.0.0/mingw-w64-tools/widl
./configure --target=$TARGET --prefix=$PREFIX --bindir=$PREFIX/bin
make -j$JOBS
make install

echo "Built all done! Toolchain is located in $TARGET"
echo "Don't forget to add the $TARGET in PATH to use"
