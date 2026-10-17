#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# ☀️ Solis OS — Kurulum Sonrası Canlı Oturum Temizliği
# Bu betik Calamares kurulumu tamamlandığında hedef sistemde çalışır.
# Canlı kullanıcıyı, şifresiz sudo'yu ve live-boot araçlarını kaldırır.
# ═══════════════════════════════════════════════════════════════════

set -e

# 1. Canlı kullanıcı şifresiz sudo hakkını kaldır
rm -f /etc/sudoers.d/solis /etc/sudoers.d/solis-live 2>/dev/null || true

# 2. SDDM ve LightDM otomatik girişini kaldır (kullanıcı kendi hesabıyla giriş yapacak)
rm -f /etc/sddm.conf.d/autologin.conf 2>/dev/null || true
if [ -f /etc/lightdm/lightdm.conf ]; then
    sed -i '/autologin-user/d' /etc/lightdm/lightdm.conf 2>/dev/null || true
    sed -i '/autologin-session/d' /etc/lightdm/lightdm.conf 2>/dev/null || true
fi

# 3. Canlı oturum kullanıcısını (solis) kaldır (kullanıcı kurulum sırasında kendi hesabını oluşturdu)
if id -u solis &>/dev/null; then
    userdel -r -f solis 2>/dev/null || true
fi

# 4. Masaüstündeki kurulum kısayolunu kaldır
rm -f /home/*/Desktop/install-solis.desktop /home/*/Desktop/calamares.desktop 2>/dev/null || true
rm -f /etc/skel/Desktop/install-solis.desktop /etc/skel/Desktop/calamares.desktop 2>/dev/null || true

# 5. Kurulum araçlarını ve live-boot (casper) paketlerini hedef sistemden temizle
apt-get purge -y calamares calamares-settings-ubuntu casper 2>/dev/null || true
apt-get autoremove -y --purge 2>/dev/null || true

# 6. GRUB önyükleyicisini kurulu disk için güncelle (Windows 11 dual-boot algılansın)
if command -v update-grub &>/dev/null; then
    update-grub 2>/dev/null || true
fi

echo "✅ Solis OS kurulum sonrası temizlik tamamlandı."
