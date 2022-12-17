FROM archlinux:base-20220515.0.56491

RUN pacman-key --init
RUN pacman --noconfirm -Sy
RUN pacman --noconfirm -S archlinux-keyring 

# Install basic programs and custom glibc
RUN pacman --noconfirm -Syu && \
    pacman --noconfirm -S \
    git \
    wget \
    make \
    cmake \
    unzip \
    sudo \
    clang \
    meson \
    openocd \
    usbutils \
    arm-none-eabi-gcc \
    arm-none-eabi-gdb \
    arm-none-eabi-newlib && \
    pacman --noconfirm -Scc

RUN wget https://muon.build/releases/edge/muon-edge-amd64-linux-static -O /usr/bin/muon && \
    chmod 775 /usr/bin/muon

COPY 60-openocd.rules /etc/udev/rules.d/
RUN /lib/systemd/systemd-udevd --daemon && \
    udevadm trigger && \ 
    udevadm control --reload-rules || echo "done"

# Setup default user
ENV USER=developer
RUN useradd --create-home -s /bin/bash -m $USER && \
    echo "$USER:archlinux" | chpasswd && \
    usermod -aG wheel $USER && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/$USER
USER $USER