FROM archlinux:latest

RUN pacman-key --init
RUN pacman --noconfirm -Sy
RUN pacman --noconfirm -S archlinux-keyring 

# Install GCC and LLVM build dependencies
RUN pacman --noconfirm -Syu && \
    pacman --noconfirm -S \
    git \
    gcc \
    make \
    cmake \
    python \
    flex \
    bison \
    gperf \
    patch \
    libtool \
    diffutils \
    automake \
    gmp \
    libmpc \
    mpfr \
    base-devel

# Build and install the GCC cross compilation toolchain for arm-none-eabi
ENV PREFIX="/usr/local"
ENV TARGET=arm-none-eabi
ENV PATH="$PREFIX/bin:$PATH"
ENV GCC_RELEASE_TAG="gcc-13.1.0"
ENV LLVM_RELEASE_TAG="llvmorg-18.1.2"

RUN cd ~ && \
    git clone --depth=1 https://github.com/bminor/binutils-gdb.git && \
    mkdir ~/build && \
    cd build && \
    ../binutils-gdb/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror && \
    make -j4 CFLAGS="-O2" CXXFLAGS="-O2" && \
    make install && \
    cd ~ && \
    sudo rm -r ~/*

RUN cd ~ && \
    git clone --branch releases/$GCC_RELEASE_TAG --single-branch --depth=1 https://github.com/gcc-mirror/gcc.git && \
    cd ~/gcc && \
    ./contrib/download_prerequisites && \
    mkdir ~/build && \
    cd ~/build && \
    ../gcc/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c --without-headers --with-newlib --disable-shared --disable-threads && \
    make -j4 CFLAGS="-O2" CXXFLAGS="-O2" all-gcc && \
    make install-gcc && \
    rm -r ./* && \
# Build Newlib
    cd ~ && \
    git clone --depth=1 https://github.com/bminor/newlib.git && \
    cd ~/build && \
    ../newlib/configure --target=$TARGET --prefix="$PREFIX" && \
    make -j4 CFLAGS="-O2" CXXFLAGS="-O2" all && \
    make install && \
    rm -r ./* && \
# Fully build GCC
    ../gcc/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --with-newlib --disable-shared --disable-threads && \
    make -j4 CFLAGS="-O2" CXXFLAGS="-O2" && \
    make install && \
    cd ~ && \
    rm -r ~/* 

# Build LLVM
RUN cd ~ && \
    git clone --branch $LLVM_RELEASE_TAG --single-branch --depth=1 https://github.com/llvm/llvm-project.git && \
    mkdir ~/build && \
    cd ~/build && \
    cmake -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" -DCMAKE_BUILD_TYPE=Release  ~/llvm-project/llvm && \
    cmake --build . -j4 && \
    cmake -DCMAKE_INSTALL_PREFIX=$PREFIX -P cmake_install.cmake && \
    cd ~ && \
    rm -r ~/* 

# Uninstall GCC and LLVM build dependencies
RUN pacman --noconfirm -Rn \
    bison \
    gperf \
    patch \
    libtool \
    automake \
    base-devel && \
# Install other programs
    pacman --noconfirm -S \
    wget \
    sudo \
    meson \
    openocd \
    usbutils && \
    pacman --noconfirm -Scc

RUN wget https://muon.build/releases/edge/muon-edge-amd64-linux-static -O /usr/bin/muon && \
    chmod 775 /usr/bin/muon

COPY 60-openocd.rules /etc/udev/rules.d/

# Setup default user
ENV USER=dev
RUN useradd --create-home -s /bin/bash -m $USER && \
    echo "$USER:archlinux" | chpasswd && \
    usermod -aG wheel $USER && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/$USER
USER $USER
