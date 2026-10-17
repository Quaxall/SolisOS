#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# ☀️ Solis OS — Chroot İçi Kurulum ve Yapılandırma Betiği
# Bu betik chroot ortamı içinde çalışır.
# build-solisos.sh tarafından otomatik olarak çağrılır.
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

CONFIG_DIR="/tmp/solis-config"
BRANDING_DIR="/tmp/solis-branding"

# ─── Renk Kodları ───
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_sub() {
    echo -e "  ${CYAN}[CHROOT]${NC} $1"
}

parse_package_list() {
    # Paket listesinden yorum ve boş satırları filtrele
    local list_file="$1"
    if [ -f "$list_file" ]; then
        grep -v '^#' "$list_file" | grep -v '^$' | tr '\n' ' '
    fi
}

# ═══════════════════════════════════════════════════════════════════
# 1. APT Depolarını Yapılandır
# ═══════════════════════════════════════════════════════════════════

log_sub "APT depoları yapılandırılıyor..."

cat > /etc/apt/sources.list << 'EOF'
# Solis OS APT Kaynakları — Ubuntu Noble (24.04 LTS)
deb http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-backports main restricted universe multiverse
EOF

apt-get update -qq

# ═══════════════════════════════════════════════════════════════════
# 2. Temel Altyapı Paketlerini Kur
# ═══════════════════════════════════════════════════════════════════

log_sub "Temel altyapı paketleri kuruluyor..."

# Önce dkms ve kernel kurulumu için gerekli paketler
apt-get install -y --no-install-recommends \
    apt-utils \
    locales \
    console-setup \
    keyboard-configuration \
    initramfs-tools \
    casper \
    lupin-casper \
    discover \
    laptop-detect \
    os-prober

# Locale yapılandırması
log_sub "Locale yapılandırılıyor..."
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/# tr_TR.UTF-8 UTF-8/tr_TR.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8

# ═══════════════════════════════════════════════════════════════════
# 3. Çekirdek (Kernel) Kurulumu
# ═══════════════════════════════════════════════════════════════════

log_sub "Linux çekirdeği kuruluyor..."

apt-get install -y --no-install-recommends \
    linux-image-generic \
    linux-headers-generic

log_sub "Kernel kuruldu: $(ls /boot/vmlinuz-* | tail -1)"

# ═══════════════════════════════════════════════════════════════════
# 4. Paket Listelerinden Kurulum
# ═══════════════════════════════════════════════════════════════════

# ─── Base paketleri (kernel hariç, zaten kuruldu) ───
log_sub "Temel sistem paketleri kuruluyor (base.list)..."
BASE_PKGS=$(parse_package_list "${CONFIG_DIR}/packages/base.list")
# Kernel paketlerini çıkar (zaten kuruldu)
BASE_PKGS=$(echo "$BASE_PKGS" | sed 's/linux-image-generic//g' | sed 's/linux-headers-generic//g')
if [ -n "$BASE_PKGS" ]; then
    apt-get install -y --no-install-recommends $BASE_PKGS || {
        log_sub "⚠️  Bazı base paketleri kurulamadı, bağımsız kurulum deneniyor..."
        for pkg in $BASE_PKGS; do
            apt-get install -y --no-install-recommends "$pkg" 2>/dev/null || \
                echo "  ⚠️  Atlandı: $pkg"
        done
    }
fi

# ─── Desktop paketleri ───
log_sub "XFCE4 masaüstü ortamı kuruluyor (desktop.list)..."
DESKTOP_PKGS=$(parse_package_list "${CONFIG_DIR}/packages/desktop.list")
if [ -n "$DESKTOP_PKGS" ]; then
    apt-get install -y --no-install-recommends $DESKTOP_PKGS || {
        log_sub "⚠️  Bazı desktop paketleri kurulamadı, bağımsız kurulum deneniyor..."
        for pkg in $DESKTOP_PKGS; do
            apt-get install -y --no-install-recommends "$pkg" 2>/dev/null || \
                echo "  ⚠️  Atlandı: $pkg"
        done
    }
fi

# ─── Fluent Stack paketleri ───
log_sub "Fluent Design yığını kuruluyor (fluent-stack.list)..."
FLUENT_PKGS=$(parse_package_list "${CONFIG_DIR}/packages/fluent-stack.list")
if [ -n "$FLUENT_PKGS" ]; then
    apt-get install -y --no-install-recommends $FLUENT_PKGS || {
        log_sub "⚠️  Bazı Fluent paketleri kurulamadı, bağımsız kurulum deneniyor..."
        for pkg in $FLUENT_PKGS; do
            apt-get install -y --no-install-recommends "$pkg" 2>/dev/null || \
                echo "  ⚠️  Atlandı: $pkg"
        done
    }
fi

# ─── Uygulama paketleri ───
log_sub "Varsayılan uygulamalar kuruluyor (apps.list)..."
APP_PKGS=$(parse_package_list "${CONFIG_DIR}/packages/apps.list")
if [ -n "$APP_PKGS" ]; then
    apt-get install -y --no-install-recommends $APP_PKGS || {
        log_sub "⚠️  Bazı uygulama paketleri kurulamadı, bağımsız kurulum deneniyor..."
        for pkg in $APP_PKGS; do
            apt-get install -y --no-install-recommends "$pkg" 2>/dev/null || \
                echo "  ⚠️  Atlandı: $pkg"
        done
    }
fi

# ═══════════════════════════════════════════════════════════════════
# 5. İstenmeyen Paketleri Kaldır
# ═══════════════════════════════════════════════════════════════════

log_sub "İstenmeyen paketler kaldırılıyor..."
REMOVE_PKGS=$(parse_package_list "${CONFIG_DIR}/packages/removals.list")
if [ -n "$REMOVE_PKGS" ]; then
    for pkg in $REMOVE_PKGS; do
        apt-get purge -y "$pkg" 2>/dev/null || true
    done
    apt-get autoremove -y --purge
fi

# Snap'ın yeniden kurulmasını engelle
log_sub "Snap paketinin yeniden kurulması engelleniyor..."
cat > /etc/apt/preferences.d/no-snap.pref << 'EOF'
Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF

# ═══════════════════════════════════════════════════════════════════
# 6. Fluent GTK Teması ve İkon Paketi Kurulumu
# ═══════════════════════════════════════════════════════════════════

log_sub "Fluent GTK teması kuruluyor..."

cd /tmp

# Fluent GTK Theme
if [ -d "Fluent-gtk-theme" ]; then rm -rf Fluent-gtk-theme; fi
git clone --depth=1 https://github.com/vinceliuice/Fluent-gtk-theme.git
cd Fluent-gtk-theme
./install.sh --tweaks round --dest /usr/share/themes
cd /tmp

# Fluent Icon Theme
log_sub "Fluent ikon teması kuruluyor..."
if [ -d "Fluent-icon-theme" ]; then rm -rf Fluent-icon-theme; fi
git clone --depth=1 https://github.com/vinceliuice/Fluent-icon-theme.git
cd Fluent-icon-theme
./install.sh --dest /usr/share/icons
cd /tmp

# Temizle
rm -rf /tmp/Fluent-gtk-theme /tmp/Fluent-icon-theme

log_sub "Fluent tema ve ikonlar kuruldu."

# ═══════════════════════════════════════════════════════════════════
# 7. Solis OS Branding Enjeksiyonu
# ═══════════════════════════════════════════════════════════════════

log_sub "Solis OS branding uygulanıyor..."

# os-release
cp "${BRANDING_DIR}/os-release" /etc/os-release

# lsb-release
cp "${BRANDING_DIR}/lsb-release" /etc/lsb-release

# issue (terminal hoş geldiniz)
cp "${BRANDING_DIR}/issue" /etc/issue
cp "${BRANDING_DIR}/issue" /etc/issue.net

# Hostname
echo "solis" > /etc/hostname
cat > /etc/hosts << 'EOF'
127.0.0.1   localhost
127.0.1.1   solis

::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

# Solis yapılandırma dizini
mkdir -p /etc/solis

# Plymouth Teması
if [ -d "${BRANDING_DIR}/plymouth/solis-theme" ]; then
    log_sub "Plymouth Solis açılış teması kuruluyor..."
    mkdir -p /usr/share/plymouth/themes/solis-theme
    cp -r "${BRANDING_DIR}/plymouth/solis-theme/"* /usr/share/plymouth/themes/solis-theme/ 2>/dev/null || true
    if command -v plymouth-set-default-theme &>/dev/null; then
        plymouth-set-default-theme -R solis-theme 2>/dev/null || true
    fi
fi

# Duvar Kağıtları
if [ -d "${BRANDING_DIR}/wallpapers" ]; then
    log_sub "Solis duvar kağıtları kopyalanıyor..."
    mkdir -p /usr/share/backgrounds/solis
    cp -r "${BRANDING_DIR}/wallpapers/"* /usr/share/backgrounds/solis/ 2>/dev/null || true
fi

# Logolar ve İkonlar
if [ -d "${BRANDING_DIR}/logo" ]; then
    log_sub "Solis logoları ve simgeleri kopyalanıyor..."
    mkdir -p /usr/share/pixmaps/solis /usr/share/icons/hicolor/scalable/apps
    cp "${BRANDING_DIR}/logo/solis-logo.svg" /usr/share/pixmaps/solis/ 2>/dev/null || true
    cp "${BRANDING_DIR}/logo/solis-logo.svg" /usr/share/icons/hicolor/scalable/apps/solis-logo.svg 2>/dev/null || true
    cp "${BRANDING_DIR}/logo/solis-startmenu-icon.svg" /usr/share/pixmaps/solis/ 2>/dev/null || true
fi

# GRUB Teması
if [ -d "${BRANDING_DIR}/grub-theme" ]; then
    log_sub "GRUB Solis Fluent teması kopyalanıyor..."
    mkdir -p /boot/grub/themes/solis
    cp -r "${BRANDING_DIR}/grub-theme/"* /boot/grub/themes/solis/ 2>/dev/null || true
fi

log_sub "Branding tamamlandı: $(cat /etc/os-release | grep PRETTY_NAME)"

# ═══════════════════════════════════════════════════════════════════
# 8. Sistem Yapılandırması (sysctl, zram, journal, servisler)
# ═══════════════════════════════════════════════════════════════════

log_sub "Sistem yapılandırması uygulanıyor..."

# sysctl
mkdir -p /etc/sysctl.d
cp "${CONFIG_DIR}/system/sysctl.conf" /etc/sysctl.d/99-solis.conf

# zram
mkdir -p /etc/systemd/zram-generator.conf.d
cp "${CONFIG_DIR}/system/zram.conf" /etc/systemd/zram-generator.conf

# journald
mkdir -p /etc/systemd/journald.conf.d
cp "${CONFIG_DIR}/system/journald.conf" /etc/systemd/journald.conf.d/solis.conf

# Servisleri devre dışı bırak
if [ -f "${CONFIG_DIR}/system/disabled-services.list" ]; then
    while IFS= read -r service; do
        # Yorum ve boş satırları atla
        [[ "$service" =~ ^#.*$ ]] && continue
        [[ -z "$service" ]] && continue
        
        log_sub "  Servis devre dışı: $service"
        systemctl disable "$service" 2>/dev/null || true
        systemctl mask "$service" 2>/dev/null || true
    done < "${CONFIG_DIR}/system/disabled-services.list"
fi

# ═══════════════════════════════════════════════════════════════════
# 9. picom ve XFCE Panel Yapılandırması (Win11 Görünümü)
# ═══════════════════════════════════════════════════════════════════

log_sub "picom ve Win11 panel yapılandırması uygulanıyor..."

# /etc/skel — Varsayılan kullanıcı yapılandırması
SKEL="/etc/skel"

# picom yapılandırması
mkdir -p "${SKEL}/.config/picom"
cp "${CONFIG_DIR}/picom/picom.conf" "${SKEL}/.config/picom/picom.conf"

# GTK CSS (floating panel)
mkdir -p "${SKEL}/.config/gtk-3.0"
cp "${CONFIG_DIR}/user/skel/.config/gtk-3.0/gtk.css" "${SKEL}/.config/gtk-3.0/gtk.css"

# picom autostart (oturum açılışında otomatik başlat)
mkdir -p "${SKEL}/.config/autostart"
cat > "${SKEL}/.config/autostart/picom.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Picom Compositor
Comment=Solis OS Fluent Design compositor
Exec=picom -b --config ~/.config/picom/picom.conf
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

# XFCE varsayılan tema ayarları
mkdir -p "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml"

# xsettings — GTK tema, ikon, font
cat > "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Fluent-round-Dark"/>
    <property name="IconThemeName" type="string" value="Fluent-dark"/>
    <property name="CursorThemeName" type="string" value="Adwaita"/>
    <property name="CursorSize" type="int" value="24"/>
    <property name="EnableEventSounds" type="bool" value="false"/>
    <property name="EnableInputFeedbackSounds" type="bool" value="false"/>
    <property name="SoundThemeName" type="string" value="freedesktop"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Inter 10"/>
    <property name="MonospaceFontName" type="string" value="Cascadia Code 10"/>
    <property name="CursorThemeName" type="string" value="Adwaita"/>
    <property name="CursorThemeSize" type="int" value="24"/>
    <property name="ButtonImages" type="bool" value="true"/>
    <property name="MenuImages" type="bool" value="true"/>
  </property>
  <property name="Xft" type="empty">
    <property name="Antialias" type="int" value="1"/>
    <property name="HintStyle" type="string" value="hintslight"/>
    <property name="Hinting" type="int" value="1"/>
    <property name="RGBA" type="string" value="rgb"/>
    <property name="DPI" type="int" value="-1"/>
  </property>
</channel>
EOF

# xfwm4 — Pencere yöneticisi tema
cat > "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Fluent-round-Dark"/>
    <property name="title_font" type="string" value="Inter Bold 10"/>
    <property name="use_compositing" type="bool" value="false"/>
    <property name="placement_ratio" type="int" value="50"/>
    <property name="cycle_minimum" type="bool" value="true"/>
    <property name="easy_click" type="string" value="Super"/>
    <property name="shadow_opacity" type="int" value="50"/>
    <property name="title_alignment" type="string" value="center"/>
  </property>
</channel>
EOF

# xfce4-desktop — Duvar kağıdı
cat > "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorVirtual-1" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/solis/solis-default.jpg"/>
        </property>
      </property>
    </property>
  </property>
  <property name="desktop-icons" type="empty">
    <property name="style" type="int" value="0"/>
  </property>
</channel>
EOF

log_sub "Win11 panel ve tema yapılandırması tamamlandı."

# ═══════════════════════════════════════════════════════════════════
# 10. LightDM (Login Ekranı) Yapılandırması
# ═══════════════════════════════════════════════════════════════════

log_sub "LightDM yapılandırılıyor..."

mkdir -p /etc/lightdm
cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'EOF'
[greeter]
theme-name = Fluent-round-Dark
icon-theme-name = Fluent-dark
font-name = Inter 11
cursor-theme-name = Adwaita
cursor-theme-size = 24
background = /usr/share/backgrounds/solis/solis-default.jpg
default-user-image = #solis-logo
hide-user-image = false
clock-format = %H:%M · %d %b %Y
indicators = ~host;~spacer;~clock;~spacer;~session;~power
position = 50%,center 50%,center
panel-position = bottom
EOF

# Autologin ayarı — Live oturum için
cat > /etc/lightdm/lightdm.conf << 'EOF'
[SeatDefaults]
autologin-guest = false
autologin-user = solis
autologin-user-timeout = 0
user-session = xfce
greeter-session = lightdm-gtk-greeter
EOF

# ═══════════════════════════════════════════════════════════════════
# 11. Live Oturum Kullanıcısı Oluştur
# ═══════════════════════════════════════════════════════════════════

log_sub "Live oturum kullanıcısı oluşturuluyor..."

# solis kullanıcısını oluştur (parola olmadan, sudo yetkili)
useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev,bluetooth,lpadmin solis 2>/dev/null || true
echo "solis ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/solis
chmod 440 /etc/sudoers.d/solis

# Parolasız giriş (Live oturum için)
passwd -d solis 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════
# 12. Flatpak Depoları
# ═══════════════════════════════════════════════════════════════════

log_sub "Flatpak yapılandırılıyor..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════
# 13. GRUB Yapılandırması (Kurulu Sistem İçin)
# ═══════════════════════════════════════════════════════════════════

log_sub "GRUB varsayılan yapılandırması ayarlanıyor..."

# GRUB kernel parametreleri
CMDLINE_PARAMS=""
if [ -f "${CONFIG_DIR}/kernel/cmdline.conf" ]; then
    CMDLINE_PARAMS=$(grep -v '^#' "${CONFIG_DIR}/kernel/cmdline.conf" | grep -v '^$' | tr '\n' ' ')
fi

cat > /etc/default/grub << EOF
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="Solis OS"
GRUB_CMDLINE_LINUX_DEFAULT="${CMDLINE_PARAMS}"
GRUB_CMDLINE_LINUX=""
GRUB_DISABLE_OS_PROBER=false
EOF

if [ -f "/boot/grub/themes/solis/theme.txt" ]; then
    echo 'GRUB_THEME="/boot/grub/themes/solis/theme.txt"' >> /etc/default/grub
fi

# ═══════════════════════════════════════════════════════════════════
# 14. Varsayılan Duvar Kağıdı Kontrolü
# ═══════════════════════════════════════════════════════════════════

log_sub "Varsayılan duvar kağıdı kontrol ediliyor..."
mkdir -p /usr/share/backgrounds/solis

if [ ! -f /usr/share/backgrounds/solis/solis-default.jpg ]; then
    if command -v convert &>/dev/null; then
        convert -size 1920x1080 \
            -define gradient:angle=135 \
            gradient:'#1a1a2e-#16213e' \
            /usr/share/backgrounds/solis/solis-default.jpg
    else
        log_sub "  ⚠️  Placeholder duvar kağıdı oluşturuluyor"
        touch /usr/share/backgrounds/solis/solis-default.jpg
    fi
else
    log_sub "  ✅ Solis varsayılan Bloom duvar kağıdı mevcut."
fi

# ═══════════════════════════════════════════════════════════════════
# 15. NetworkManager yapılandırması
# ═══════════════════════════════════════════════════════════════════

log_sub "NetworkManager yapılandırılıyor..."
systemctl enable NetworkManager 2>/dev/null || true

# ═══════════════════════════════════════════════════════════════════
# 16. Temizlik
# ═══════════════════════════════════════════════════════════════════

log_sub "Chroot temizliği yapılıyor..."

# APT cache temizle
apt-get clean
apt-get autoremove -y --purge
rm -rf /var/cache/apt/archives/*
rm -rf /var/lib/apt/lists/*

# Geçici dosyaları temizle
rm -rf /tmp/*
rm -rf /var/tmp/*

# Bash geçmişini temizle
rm -f /root/.bash_history
rm -f /home/solis/.bash_history 2>/dev/null || true

# Log dosyalarını temizle
find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null || true
find /var/log -type f -name "*.gz" -delete 2>/dev/null || true

# Machine-id temizle (her kurulumda yeniden oluşturulacak)
truncate -s 0 /etc/machine-id

log_sub "═══════════════════════════════════════════════════"
log_sub "☀️  Chroot kurulumu tamamlandı!"
log_sub "═══════════════════════════════════════════════════"
