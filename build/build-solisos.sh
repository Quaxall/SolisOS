#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# ☀️ Solis OS — Ana ISO İnşa Betiği
# Tek komutla sıfırdan bootable .iso üretir.
#
# Kullanım:
#   ./build/build-solisos.sh          (Docker konteyner içinden)
#   docker run --rm --privileged \
#     -v "$(pwd)/output:/build/output" solis-builder
#
# Sürüm: 0.2 (Solstice)
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ─── Renk Kodları ───
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'  # No Color

# ─── Solis OS Sabitleri ───
SOLIS_VERSION="${SOLIS_VERSION:-0.2}"
SOLIS_CODENAME="${SOLIS_CODENAME:-solstice}"
SOLIS_ARCH="${SOLIS_ARCH:-amd64}"
SOLIS_SUITE="noble"
SOLIS_MIRROR="http://archive.ubuntu.com/ubuntu"
SOLIS_ISO_NAME="solis-os-${SOLIS_VERSION}-${SOLIS_CODENAME}-${SOLIS_ARCH}.iso"
SOLIS_ISO_LABEL="SOLIS_OS_${SOLIS_VERSION^^}"

# ─── Çalışma Dizinleri ───
BUILD_DIR="/tmp/solis-build"
ROOTFS_DIR="${BUILD_DIR}/rootfs"
ISO_STAGING="${BUILD_DIR}/iso-staging"
OUTPUT_DIR="/build/output"
PROJECT_DIR="/build"

# ─── Zamanlayıcı ───
BUILD_START=$(date +%s)

# ═══════════════════════════════════════════════════════════════════
# Yardımcı Fonksiyonlar
# ═══════════════════════════════════════════════════════════════════

log_step() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE}☀️  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

elapsed_time() {
    local end=$(date +%s)
    local diff=$((end - BUILD_START))
    local mins=$((diff / 60))
    local secs=$((diff % 60))
    echo "${mins}dk ${secs}sn"
}

cleanup_on_exit() {
    log_warn "Temizlik yapılıyor..."
    
    # Mount noktalarını kaldır (hata olsa bile)
    for mount_point in dev/pts dev proc sys run; do
        umount -lf "${ROOTFS_DIR}/${mount_point}" 2>/dev/null || true
    done
    
    log_info "Mount noktaları kaldırıldı."
}

trap cleanup_on_exit EXIT ERR INT TERM

# ═══════════════════════════════════════════════════════════════════
# Faz 0: Başlangıç Banner
# ═══════════════════════════════════════════════════════════════════

echo -e "${BOLD}${YELLOW}"
echo "  ╔═══════════════════════════════════════════════════════╗"
echo "  ║                                                       ║"
echo "  ║   ☀️  SOLIS OS — ISO BUILD SYSTEM                     ║"
echo "  ║                                                       ║"
echo "  ║   Sürüm:    ${SOLIS_VERSION} (${SOLIS_CODENAME})                          ║"
echo "  ║   Mimari:   ${SOLIS_ARCH}                                    ║"
echo "  ║   Taban:    Ubuntu ${SOLIS_SUITE}                            ║"
echo "  ║                                                       ║"
echo "  ╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ═══════════════════════════════════════════════════════════════════
# Faz 1: Bağımlılık Kontrolü
# ═══════════════════════════════════════════════════════════════════

log_step "Faz 1/7: Bağımlılık Kontrolü"

REQUIRED_TOOLS=(debootstrap mksquashfs xorriso grub-mkimage mtools)
MISSING_TOOLS=()

for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        MISSING_TOOLS+=("$tool")
    else
        log_info "✅ $tool bulundu: $(command -v "$tool")"
    fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    log_error "Eksik araçlar: ${MISSING_TOOLS[*]}"
    log_error "Lütfen Docker konteyner içinden çalıştırın veya eksik paketleri kurun."
    exit 1
fi

log_info "Tüm bağımlılıklar hazır."

# ═══════════════════════════════════════════════════════════════════
# Faz 2: Dizin Hazırlığı
# ═══════════════════════════════════════════════════════════════════

log_step "Faz 2/7: Dizin Hazırlığı"

# Önceki build kalıntılarını temizle
if [ -d "$BUILD_DIR" ]; then
    log_warn "Önceki build dizini temizleniyor: $BUILD_DIR"
    rm -rf "$BUILD_DIR"
fi

# Çalışma dizinlerini oluştur
mkdir -p "$ROOTFS_DIR"
mkdir -p "$ISO_STAGING"/{casper,boot/grub,EFI/boot,.disk}
mkdir -p "$OUTPUT_DIR"

log_info "Dizinler oluşturuldu:"
log_info "  rootfs:      $ROOTFS_DIR"
log_info "  iso-staging: $ISO_STAGING"
log_info "  output:      $OUTPUT_DIR"

# ═══════════════════════════════════════════════════════════════════
# Faz 3: Debootstrap — Minimal Root Filesystem
# ═══════════════════════════════════════════════════════════════════

log_step "Faz 3/7: Debootstrap — Ubuntu Noble Minimal Rootfs"

log_info "debootstrap başlatılıyor... (Bu adım 5-15 dakika sürebilir)"

debootstrap \
    --arch="${SOLIS_ARCH}" \
    --variant=minbase \
    --components=main,restricted,universe \
    "${SOLIS_SUITE}" \
    "${ROOTFS_DIR}" \
    "${SOLIS_MIRROR}"

log_info "Debootstrap tamamlandı. Rootfs boyutu: $(du -sh "${ROOTFS_DIR}" | cut -f1)"

# ═══════════════════════════════════════════════════════════════════
# Faz 4: Chroot Ortamını Hazırla ve Yapılandır
# ═══════════════════════════════════════════════════════════════════

log_step "Faz 4/7: Chroot Yapılandırması"

# ─── Mount noktalarını bağla ───
log_info "Mount noktaları bağlanıyor..."
mount --bind /dev     "${ROOTFS_DIR}/dev"
mount --bind /dev/pts "${ROOTFS_DIR}/dev/pts"
mount -t proc proc    "${ROOTFS_DIR}/proc"
mount -t sysfs sys    "${ROOTFS_DIR}/sys"
mount --bind /run     "${ROOTFS_DIR}/run"

# ─── DNS çözümlemesi ───
cp /etc/resolv.conf "${ROOTFS_DIR}/etc/resolv.conf"

# ─── Chroot-setup betiğini kopyala ───
cp "${PROJECT_DIR}/build/chroot-setup.sh" "${ROOTFS_DIR}/tmp/chroot-setup.sh"
chmod +x "${ROOTFS_DIR}/tmp/chroot-setup.sh"

# ─── Yapılandırma dosyalarını kopyala ───
log_info "Yapılandırma dosyaları ve Solis paketleri rootfs'e kopyalanıyor..."
mkdir -p "${ROOTFS_DIR}/tmp/solis-config"
cp -r "${PROJECT_DIR}/config/"* "${ROOTFS_DIR}/tmp/solis-config/"
cp -r "${PROJECT_DIR}/branding" "${ROOTFS_DIR}/tmp/solis-branding"
cp -r "${PROJECT_DIR}/packages" "${ROOTFS_DIR}/tmp/solis-packages"

# ─── Chroot içi kurulumu çalıştır ───
log_info "Chroot içi kurulum başlatılıyor... (Bu adım 10-30 dakika sürebilir)"

chroot "${ROOTFS_DIR}" /bin/bash /tmp/chroot-setup.sh

log_info "Chroot kurulumu tamamlandı."

# ─── Mount noktalarını kaldır ───
log_info "Mount noktaları kaldırılıyor..."
umount -lf "${ROOTFS_DIR}/run"     2>/dev/null || true
umount -lf "${ROOTFS_DIR}/sys"     2>/dev/null || true
umount -lf "${ROOTFS_DIR}/proc"    2>/dev/null || true
umount -lf "${ROOTFS_DIR}/dev/pts" 2>/dev/null || true
umount -lf "${ROOTFS_DIR}/dev"     2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════
# Faz 5: SquashFS — Dosya Sistemi Sıkıştırma
# ═══════════════════════════════════════════════════════════════════

log_step "Faz 5/7: SquashFS Sıkıştırma"

log_info "Kernel ve initrd dosyalarını ISO staging'e kopyala..."

# Kernel ve initrd'yi casper dizinine kopyala
KERNEL_FILE=$(ls "${ROOTFS_DIR}"/boot/vmlinuz-* 2>/dev/null | sort -V | tail -1)
INITRD_FILE=$(ls "${ROOTFS_DIR}"/boot/initrd.img-* 2>/dev/null | sort -V | tail -1)

if [ -z "$KERNEL_FILE" ] || [ -z "$INITRD_FILE" ]; then
    log_error "Kernel veya initrd dosyası bulunamadı!"
    ls -la "${ROOTFS_DIR}/boot/" || true
    exit 1
fi

cp "$KERNEL_FILE" "${ISO_STAGING}/casper/vmlinuz"
cp "$INITRD_FILE" "${ISO_STAGING}/casper/initrd"

log_info "Kernel: $(basename "$KERNEL_FILE")"
log_info "Initrd: $(basename "$INITRD_FILE")"

# SquashFS oluştur
log_info "filesystem.squashfs oluşturuluyor... (Bu adım 5-15 dakika sürebilir)"

mksquashfs "${ROOTFS_DIR}" "${ISO_STAGING}/casper/filesystem.squashfs" \
    -comp zstd \
    -Xcompression-level 19 \
    -b 1M \
    -no-duplicates \
    -no-recovery \
    -wildcards \
    -e 'boot/vmlinuz-*' 'boot/initrd.img-*' \
    -e 'tmp/*' \
    -e 'var/cache/apt/*' \
    -e 'var/lib/apt/lists/*'

SQUASHFS_SIZE=$(du -sh "${ISO_STAGING}/casper/filesystem.squashfs" | cut -f1)
log_info "SquashFS boyutu: ${SQUASHFS_SIZE}"

# filesystem.size dosyasını oluştur (Calamares için gerekli)
printf $(du -sx --block-size=1 "${ROOTFS_DIR}" | cut -f1) > "${ISO_STAGING}/casper/filesystem.size"

# filesystem.manifest oluştur
chroot "${ROOTFS_DIR}" dpkg-query -W --showformat='${Package} ${Version}\n' \
    > "${ISO_STAGING}/casper/filesystem.manifest" 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════
# Faz 6: GRUB ve ISO Yapılandırması
# ═══════════════════════════════════════════════════════════════════

log_step "Faz 6/7: GRUB Yapılandırması ve ISO Oluşturma"

# ─── .disk bilgi dosyaları ───
echo "Solis OS ${SOLIS_VERSION} (${SOLIS_CODENAME}) - Live/Installer" > "${ISO_STAGING}/.disk/info"
echo "full-iso" > "${ISO_STAGING}/.disk/cd_type"

# ─── GRUB Temasını Kopyala ───
if [ -d "${PROJECT_DIR}/branding/grub-theme" ]; then
    log_info "GRUB Fluent teması ISO staging dizinine kopyalanıyor..."
    mkdir -p "${ISO_STAGING}/boot/grub/themes/solis"
    cp -r "${PROJECT_DIR}/branding/grub-theme/"* "${ISO_STAGING}/boot/grub/themes/solis/" 2>/dev/null || true
fi

# ─── GRUB yapılandırması (UEFI + BIOS) ───
cat > "${ISO_STAGING}/boot/grub/grub.cfg" << 'GRUB_EOF'
# ═══════════════════════════════════════════
# ☀️ Solis OS — GRUB Yapılandırması
# ═══════════════════════════════════════════

set timeout=10
set default=0

# Grafik mod ve tema
insmod all_video
insmod gfxterm
insmod png
insmod jpeg

terminal_output gfxterm

if [ -f /boot/grub/themes/solis/theme.txt ]; then
    set theme=/boot/grub/themes/solis/theme.txt
    export theme
fi

# Menü renkleri (fallback)
set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

# ─── Ana Menü ───
menuentry "☀️ Solis OS — Canlı Masaüstü Oturumu Başlat (Live)" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper username=solis hostname=solis quiet splash --- 
    initrd /casper/initrd
}

menuentry "☀️ Solis OS — Güvenli Grafik Modu (nomodeset)" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper username=solis hostname=solis nomodeset quiet splash ---
    initrd /casper/initrd
}

menuentry "🔧 Solis OS — Doğrudan Sistem Kurulumu (Calamares)" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper username=solis hostname=solis quiet splash solis-installer ---
    initrd /casper/initrd
}

menuentry "Bellek Testi (memtest86+)" {
    linux /boot/memtest86+.bin
}

menuentry "─────────────────────────────" {
    true
}

menuentry "Diskten Önyükle (mevcut sistemi başlat)" {
    exit
}
GRUB_EOF

log_info "GRUB yapılandırması yazıldı."

# ─── BIOS Boot Image ───
log_info "BIOS boot imajı oluşturuluyor..."

grub-mkstandalone \
    --format=i386-pc \
    --output="${BUILD_DIR}/bios.img" \
    --install-modules="linux normal iso9660 biosdisk memdisk search tar ls" \
    --modules="linux normal iso9660 biosdisk search" \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=${ISO_STAGING}/boot/grub/grub.cfg"

# core.img oluştur
cat /usr/lib/grub/i386-pc/cdboot.img "${BUILD_DIR}/bios.img" > "${ISO_STAGING}/boot/grub/bios.img"

# ─── UEFI Boot Image ───
log_info "UEFI boot imajı oluşturuluyor..."

grub-mkstandalone \
    --format=x86_64-efi \
    --output="${BUILD_DIR}/bootx64.efi" \
    --install-modules="linux normal iso9660 memdisk search tar ls efi_gop efi_uga" \
    --modules="linux normal iso9660 search" \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=${ISO_STAGING}/boot/grub/grub.cfg"

# EFI system partition imajı oluştur
EFI_IMG="${ISO_STAGING}/EFI/efiboot.img"
EFI_IMG_SIZE_KB=4096  # 4 MB

dd if=/dev/zero of="${EFI_IMG}" bs=1K count=${EFI_IMG_SIZE_KB}
mkfs.vfat "${EFI_IMG}"

# EFI dosyalarını imaja kopyala
MTOOLS_SKIP_CHECK=1 mmd -i "${EFI_IMG}" ::/EFI ::/EFI/boot
MTOOLS_SKIP_CHECK=1 mcopy -i "${EFI_IMG}" "${BUILD_DIR}/bootx64.efi" ::/EFI/boot/bootx64.efi

cp "${BUILD_DIR}/bootx64.efi" "${ISO_STAGING}/EFI/boot/bootx64.efi"

log_info "UEFI boot imajı hazır."

# ─── Hibrit ISO Oluştur ───
log_info "Hibrit ISO oluşturuluyor: ${SOLIS_ISO_NAME}"

xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "${SOLIS_ISO_LABEL}" \
    -appid "Solis OS ${SOLIS_VERSION} Live/Installer" \
    -publisher "Solis OS Project" \
    -preparer "build-solisos.sh" \
    -eltorito-boot boot/grub/bios.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --eltorito-catalog boot/grub/boot.cat \
    --grub2-boot-info \
    --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -eltorito-alt-boot \
        -e EFI/efiboot.img \
        -no-emul-boot \
    -output "${OUTPUT_DIR}/${SOLIS_ISO_NAME}" \
    "${ISO_STAGING}"

# ═══════════════════════════════════════════════════════════════════
# Faz 7: Doğrulama ve Sonuç
# ═══════════════════════════════════════════════════════════════════

log_step "Faz 7/7: Doğrulama ve Sonuç"

ISO_PATH="${OUTPUT_DIR}/${SOLIS_ISO_NAME}"

if [ -f "$ISO_PATH" ]; then
    # SHA256 hash oluştur
    cd "$OUTPUT_DIR"
    sha256sum "${SOLIS_ISO_NAME}" > SHA256SUMS
    cd /build

    ISO_SIZE=$(du -sh "$ISO_PATH" | cut -f1)
    ISO_SHA=$(sha256sum "$ISO_PATH" | cut -d' ' -f1)
    BUILD_TIME=$(elapsed_time)

    echo -e "\n${GREEN}${BOLD}"
    echo "  ╔═══════════════════════════════════════════════════════╗"
    echo "  ║                                                       ║"
    echo "  ║   ☀️  SOLIS OS — BUILD TAMAMLANDI!                    ║"
    echo "  ║                                                       ║"
    echo "  ╠═══════════════════════════════════════════════════════╣"
    echo "  ║                                                       ║"
    echo "  ║   ISO:     ${SOLIS_ISO_NAME}              ║"
    echo "  ║   Boyut:   ${ISO_SIZE}                                  ║"
    echo "  ║   Süre:    ${BUILD_TIME}                              ║"
    echo "  ║   Konum:   ${OUTPUT_DIR}/                             ║"
    echo "  ║                                                       ║"
    echo "  ║   SHA256:  ${ISO_SHA:0:32}...  ║"
    echo "  ║                                                       ║"
    echo "  ╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    log_info "ISO doğrulaması başarılı."
    log_info "Test etmek için: ./scripts/test-qemu.sh ${OUTPUT_DIR}/${SOLIS_ISO_NAME}"
else
    log_error "ISO dosyası oluşturulamadı!"
    log_error "Beklenen konum: ${ISO_PATH}"
    exit 1
fi
