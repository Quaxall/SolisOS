#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# ☀️ Solis OS — QEMU Test Betiği
# Üretilen ISO dosyasını QEMU/KVM ile test eder.
#
# Kullanım:
#   ./scripts/test-qemu.sh [iso-dosyası] [bios|uefi]
#
# Örnekler:
#   ./scripts/test-qemu.sh output/solis-os-0.2-solstice-amd64.iso uefi
#   ./scripts/test-qemu.sh                     # varsayılan ISO, UEFI
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ─── Parametreler ───
ISO_PATH="${1:-./output/solis-os-0.2-solstice-amd64.iso}"
MODE="${2:-uefi}"
RAM="${3:-2G}"
CPUS="${4:-2}"

# ─── Doğrulama ───
if [ ! -f "$ISO_PATH" ]; then
    echo "❌ ISO dosyası bulunamadı: $ISO_PATH"
    echo ""
    echo "Kullanım: $0 [iso-dosyası] [bios|uefi] [ram] [cpu]"
    echo "Örnek:    $0 output/solis-os-0.2-solstice-amd64.iso uefi 2G 2"
    exit 1
fi

if ! command -v qemu-system-x86_64 &>/dev/null; then
    echo "❌ qemu-system-x86_64 bulunamadı!"
    echo "   Kurulum: sudo apt install qemu-system-x86 ovmf"
    exit 1
fi

echo "☀️ Solis OS — QEMU Test"
echo "  ISO:  $ISO_PATH"
echo "  Mod:  $MODE"
echo "  RAM:  $RAM"
echo "  CPU:  $CPUS"
echo ""

# ─── QEMU Başlat ───
COMMON_ARGS=(
    -m "$RAM"
    -smp "$CPUS"
    -cdrom "$ISO_PATH"
    -boot d
    -device virtio-net-pci,netdev=net0
    -netdev user,id=net0
    -usb
    -device usb-tablet
    -name "Solis OS Test (${MODE^^})"
)

# KVM desteğini kontrol et
if [ -e /dev/kvm ]; then
    COMMON_ARGS+=(-enable-kvm -cpu host)
    echo "  KVM:  ✅ Etkin"
else
    echo "  KVM:  ⚠️  Devre dışı (yavaş emülasyon)"
fi

if [ "$MODE" = "uefi" ]; then
    # OVMF firmware'ini bul
    OVMF_PATH=""
    for path in \
        /usr/share/ovmf/OVMF.fd \
        /usr/share/OVMF/OVMF_CODE.fd \
        /usr/share/edk2/ovmf/OVMF_CODE.fd \
        /usr/share/qemu/OVMF.fd; do
        if [ -f "$path" ]; then
            OVMF_PATH="$path"
            break
        fi
    done

    if [ -z "$OVMF_PATH" ]; then
        echo "❌ OVMF firmware bulunamadı!"
        echo "   Kurulum: sudo apt install ovmf"
        exit 1
    fi

    echo "  OVMF: $OVMF_PATH"
    echo ""
    echo "  🚀 UEFI modunda başlatılıyor..."

    qemu-system-x86_64 \
        "${COMMON_ARGS[@]}" \
        -bios "$OVMF_PATH" \
        -vga virtio \
        -display gtk
else
    echo ""
    echo "  🚀 BIOS (Legacy) modunda başlatılıyor..."

    qemu-system-x86_64 \
        "${COMMON_ARGS[@]}" \
        -vga std \
        -display gtk
fi
