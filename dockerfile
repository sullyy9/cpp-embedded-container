FROM archlinux:base-20220515.0.56491

RUN pacman --noconfirm -Syu

# Install basic programs and custom glibc
RUN pacman --noconfirm -Syu && \
    pacman --noconfirm -S \
    git \
    wget \
    make \
    cmake \
    unzip \
    arm-none-eabi-gcc \
    arm-none-eabi-newlib && \
    pacman --noconfirm -Scc

    
# Install clangd
RUN wget https://github.com/clangd/clangd/releases/download/14.0.3/clangd-linux-14.0.3.zip -O ~/temp.zip && \
    unzip ~/temp.zip -d ~/clangd && \
    cp ~/clangd/*/bin/clangd /usr/local/bin/ && \
    rm ~/temp.zip && rm -R ~/clangd