FROM archlinux:latest

RUN pacman-key --init
RUN pacman --noconfirm -Sy
RUN pacman --noconfirm -S archlinux-keyring 

# Install basic programs and custom glibc
RUN pacman --noconfirm -Syu && \
    pacman --noconfirm -S \
    git \
    gcc \
    wget \
    make \
    cmake \
    unzip \
    sudo \
    meson \
    openocd \
    usbutils \
    arm-none-eabi-gcc \
    arm-none-eabi-gdb \
    arm-none-eabi-newlib && \
    pacman --noconfirm -Scc

RUN wget https://muon.build/releases/edge/muon-edge-amd64-linux-static -O /usr/bin/muon && \
    chmod 775 /usr/bin/muon

# Install LLVM
ENV LLVM_URL=https://github.com/llvm/llvm-project/releases/download/llvmorg-17.0.6/clang+llvm-17.0.6-x86_64-linux-gnu-ubuntu-22.04.tar.xz
RUN wget $LLVM_URL -O ~/llvm.tar.xz && \
    mkdir ~/llvm && \
    tar -xf ~/llvm.tar.xz -C ~/llvm && \
    cp ~/llvm/*/bin/* /usr/local/bin/ && \
    cp -r ~/llvm/*/lib/* /usr/local/lib/  && \
    rm ~/llvm.tar.xz && rm -R ~/llvm

COPY 60-openocd.rules /etc/udev/rules.d/

# Setup default user
ENV USER=dev
RUN useradd --create-home -s /bin/bash -m $USER && \
    echo "$USER:archlinux" | chpasswd && \
    usermod -aG wheel $USER && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/$USER
USER $USER
