#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# ☀️ Solis OS — Build Temizlik Betiği
# Önceki build kalıntılarını temizler.
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

BUILD_DIR="/tmp/solis-build"

echo "☀️ Solis OS — Build temizliği başlatılıyor..."

# Mount noktalarını kaldır
for mount_point in dev/pts dev proc sys run; do
    if mountpoint -q "${BUILD_DIR}/rootfs/${mount_point}" 2>/dev/null; then
        echo "  Umount: ${BUILD_DIR}/rootfs/${mount_point}"
        umount -lf "${BUILD_DIR}/rootfs/${mount_point}" 2>/dev/null || true
    fi
done

# Build dizinini sil
if [ -d "$BUILD_DIR" ]; then
    echo "  Siliniyor: $BUILD_DIR"
    rm -rf "$BUILD_DIR"
fi

echo "✅ Temizlik tamamlandı."
