FROM archlinux:base-20220515.0.56491

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
    openocd \
    usbutils \
    arm-none-eabi-gcc \
    arm-none-eabi-gdb \
    arm-none-eabi-newlib && \
    pacman --noconfirm -Scc

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