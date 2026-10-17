FROM ubuntu:24.04

LABEL maintainer="Solis OS Team"
LABEL description="Solis OS ISO Build Environment"

# ─── Ortam Değişkenleri ───
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Istanbul
ENV SOLIS_VERSION="0.2"
ENV SOLIS_CODENAME="solstice"
ENV SOLIS_ARCH="amd64"

# ─── Build Bağımlılıkları ───
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Temel araçlar
    debootstrap \
    squashfs-tools \
    xorriso \
    mtools \
    dosfstools \
    binutils \
    # GRUB (BIOS + UEFI)
    grub-pc-bin \
    grub-efi-amd64-bin \
    grub-efi-amd64-signed \
    shim-signed \
    grub-common \
    grub2-common \
    isolinux \
    syslinux-utils \
    # Yardımcı araçlar
    git \
    wget \
    curl \
    sudo \
    ca-certificates \
    gnupg \
    lsb-release \
    rsync \
    patch \
    # Dosya sistemi araçları
    e2fsprogs \
    fdisk \
    parted \
    && rm -rf /var/lib/apt/lists/*

# ─── Çalışma Dizini ───
WORKDIR /build

# ─── Proje Dosyalarını Kopyala ───
COPY . /build/

# ─── Build Betiklerine Çalıştırma İzni Ver ───
RUN chmod +x build/*.sh && \
    chmod +x scripts/*.sh 2>/dev/null || true

# ─── Giriş Noktası ───
ENTRYPOINT ["./build/build-solisos.sh"]
