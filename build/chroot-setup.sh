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
PACKAGES_DIR="/tmp/solis-packages"

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
if git clone --depth=1 https://github.com/vinceliuice/Fluent-gtk-theme.git; then
    cd Fluent-gtk-theme
    ./install.sh --tweaks round --dest /usr/share/themes 2>/dev/null || true
    # Kvantum (Qt) Fluent Temasını da sisteme kur
    if [ -d "src/other/kvantum" ]; then
        mkdir -p /usr/share/Kvantum
        cp -r src/other/kvantum/* /usr/share/Kvantum/ 2>/dev/null || true
    fi
    cd /tmp
else
    log_sub "⚠️ Fluent GTK teması indirilemedi, yedek tema kullanılacak."
fi

# Fluent Icon Theme
log_sub "Fluent ikon teması kuruluyor..."
if [ -d "Fluent-icon-theme" ]; then rm -rf Fluent-icon-theme; fi
if git clone --depth=1 https://github.com/vinceliuice/Fluent-icon-theme.git; then
    cd Fluent-icon-theme
    ./install.sh --dest /usr/share/icons 2>/dev/null || true
    cd /tmp
else
    log_sub "⚠️ Fluent ikon teması indirilemedi."
fi

# Fluent Cursor Theme (Windows 11 Tarzı İmleç)
log_sub "Fluent imleç teması kuruluyor..."
if [ -d "Fluent-cursors" ]; then rm -rf Fluent-cursors; fi
if git clone --depth=1 https://github.com/vinceliuice/Fluent-cursors.git 2>/dev/null; then
    cd Fluent-cursors
    ./install.sh --dest /usr/share/icons 2>/dev/null || true
    cd /tmp
fi

# Temizle
rm -rf /tmp/Fluent-gtk-theme /tmp/Fluent-icon-theme /tmp/Fluent-cursors

log_sub "Fluent GTK, Kvantum, ikon ve imleç temaları kuruldu."

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
# 9. picom, XFCE Panel (Windows 11 Ortalanmış) ve Fluent Tema
# ═══════════════════════════════════════════════════════════════════

log_sub "Windows 11 Fluent masaüstü ve ortalanmış görev çubuğu yapılandırılıyor..."

# /etc/skel — Varsayılan kullanıcı şablonu
SKEL="/etc/skel"
XDG_XFCE="/etc/xdg/xfce4"

mkdir -p "${SKEL}/.config/picom"
mkdir -p "${SKEL}/.config/gtk-3.0"
mkdir -p "${SKEL}/.config/autostart"
mkdir -p "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "${SKEL}/.config/xfce4/panel"
mkdir -p "${SKEL}/.config/Kvantum"
mkdir -p "${XDG_XFCE}/xfconf/xfce-perchannel-xml"
mkdir -p "${XDG_XFCE}/panel"

# ─── 1. picom Yapılandırması (Acrylic / Mica Bulanıklık & Yuvarlatılmış Köşeler) ───
if [ -f "${CONFIG_DIR}/picom/picom.conf" ]; then
    cp "${CONFIG_DIR}/picom/picom.conf" "${SKEL}/.config/picom/picom.conf"
    mkdir -p /etc/xdg/picom
    cp "${CONFIG_DIR}/picom/picom.conf" /etc/xdg/picom/picom.conf
fi

# ─── 2. GTK3 CSS (Windows 11 Floating Taskbar & Yuvarlatılmış Köşeler) ───
if [ -f "${CONFIG_DIR}/user/skel/.config/gtk-3.0/gtk.css" ]; then
    cp "${CONFIG_DIR}/user/skel/.config/gtk-3.0/gtk.css" "${SKEL}/.config/gtk-3.0/gtk.css"
fi

# ─── 3. Ortalanmış Windows 11 Görev Çubuğu (XFCE Panel) ───
if [ -f "${CONFIG_DIR}/xfce/xfce4-panel.xml" ]; then
    cp "${CONFIG_DIR}/xfce/xfce4-panel.xml" "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
    cp "${CONFIG_DIR}/xfce/xfce4-panel.xml" "${XDG_XFCE}/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
fi

# ─── 4. Whisker Menu (Windows 11 Başlat Menüsü Düzeni) ───
if [ -f "${CONFIG_DIR}/xfce/whiskermenu.rc" ]; then
    cp "${CONFIG_DIR}/xfce/whiskermenu.rc" "${SKEL}/.config/xfce4/panel/whiskermenu-2.rc"
    cp "${CONFIG_DIR}/xfce/whiskermenu.rc" "${SKEL}/.config/xfce4/panel/whiskermenu-1.rc"
    cp "${CONFIG_DIR}/xfce/whiskermenu.rc" "${XDG_XFCE}/panel/whiskermenu-2.rc"
fi

# ─── 5. Docklike Plugin (Win11 Ortalanmış Sabitlenmiş Uygulamalar) ───
if [ -f "${CONFIG_DIR}/xfce/docklike.rc" ]; then
    cp "${CONFIG_DIR}/xfce/docklike.rc" "${SKEL}/.config/xfce4/panel/docklike-3.rc"
    cp "${CONFIG_DIR}/xfce/docklike.rc" "${SKEL}/.config/xfce4/panel/docklike-1.rc"
    cp "${CONFIG_DIR}/xfce/docklike.rc" "${XDG_XFCE}/panel/docklike-3.rc"
fi

# ─── 6. XFCE Tema & Pencere Ayarları ───
if [ -f "${CONFIG_DIR}/xfce/xsettings.xml" ]; then
    cp "${CONFIG_DIR}/xfce/xsettings.xml" "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml"
    cp "${CONFIG_DIR}/xfce/xsettings.xml" "${XDG_XFCE}/xfconf/xfce-perchannel-xml/xsettings.xml"
fi

if [ -f "${CONFIG_DIR}/xfce/xfwm4.xml" ]; then
    cp "${CONFIG_DIR}/xfce/xfwm4.xml" "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml"
    cp "${CONFIG_DIR}/xfce/xfwm4.xml" "${XDG_XFCE}/xfconf/xfce-perchannel-xml/xfwm4.xml"
fi

if [ -f "${CONFIG_DIR}/xfce/xfce4-desktop.xml" ]; then
    cp "${CONFIG_DIR}/xfce/xfce4-desktop.xml" "${SKEL}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
    cp "${CONFIG_DIR}/xfce/xfce4-desktop.xml" "${XDG_XFCE}/xfconf/xfce-perchannel-xml/xfce4-desktop.xml"
fi

# ─── 7. Varsayılan Yardımcı Uygulamalar ───
cat > "${SKEL}/.config/xfce4/helpers.rc" << 'EOF'
WebBrowser=firefox
TerminalEmulator=xfce4-terminal
FileManager=thunar
EOF

# ─── 8. Kvantum / Qt Fluent Tema Yapılandırması ───
cat > "${SKEL}/.config/Kvantum/kvantum.kvconfig" << 'EOF'
[General]
theme=KvFluent
EOF

# Sistem geneli Qt çevre değişkenleri
cat >> /etc/environment << 'EOF'
QT_STYLE_OVERRIDE=kvantum
QT_QPA_PLATFORMTHEME=qt5ct
EOF

# ─── 9. Oturum Açılışında Otomatik Başlatılacaklar (Autostart) ───
# picom Compositor
cat > "${SKEL}/.config/autostart/picom.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Picom Compositor
Comment=Solis OS Fluent Design compositor
Exec=picom -b --config /etc/skel/.config/picom/picom.conf
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

# Ağ Yöneticisi Tepsisi (nm-applet)
cat > "${SKEL}/.config/autostart/nm-applet.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Network Manager Applet
Comment=Solis OS Network Status Indicator
Exec=nm-applet
Icon=nm-device-wireless
Terminal=false
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Pano Yöneticisi (Clipman)
cat > "${SKEL}/.config/autostart/xfce4-clipman.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Clipman
Comment=Solis OS Clipboard Manager
Exec=xfce4-clipman
Icon=xfce4-clipman-plugin
Terminal=false
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

# ─── 10. Solis Tema Değiştirici Aracı (Dark / Light Switcher) ───
cat > /usr/local/bin/solis-theme << 'EOF'
#!/bin/bash
# Solis OS Dinamik Koyu / Açık Mod Değiştirici
MODE="${1:-dark}"

if [ "$MODE" = "light" ]; then
    xfconf-query -c xsettings -p /Net/ThemeName -s "Fluent-round-Light" 2>/dev/null || true
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Fluent" 2>/dev/null || true
    xfconf-query -c xfwm4 -p /general/theme -s "Fluent-round-Light" 2>/dev/null || true
    echo "☀️ Solis OS Açık Moda Geçildi."
else
    xfconf-query -c xsettings -p /Net/ThemeName -s "Fluent-round-Dark" 2>/dev/null || true
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Fluent-dark" 2>/dev/null || true
    xfconf-query -c xfwm4 -p /general/theme -s "Fluent-round-Dark" 2>/dev/null || true
    echo "🌙 Solis OS Koyu Moda Geçildi."
fi
EOF
chmod +x /usr/local/bin/solis-theme

log_sub "Windows 11 panel, Whisker menü ve tema yapılandırması tamamlandı."

# ═══════════════════════════════════════════════════════════════════
# 10. Wayland KWin & Görüntü Yöneticisi (SDDM / LightDM Autologin)
# ═══════════════════════════════════════════════════════════════════

log_sub "Wayland mimarisi ve otomatik giriş yapılandırılıyor..."

# ─── KWin Wayland Yapılandırması (Akıcı Animasyonlar & Acrylic Blur) ───
if [ -d "${CONFIG_DIR}/kwin" ]; then
    mkdir -p /etc/xdg
    mkdir -p "${SKEL}/.config"
    cp -r "${CONFIG_DIR}/kwin/"* /etc/xdg/ 2>/dev/null || true
    cp -r "${CONFIG_DIR}/kwin/"* "${SKEL}/.config/" 2>/dev/null || true
    log_sub "  ✅ KWin Wayland Glide/Scale ve Akrilik efektleri uygulandı."
fi

# ─── SDDM Yapılandırması (Varsayılan Wayland Giriş Yöneticisi) ───
mkdir -p /etc/sddm.conf.d
if [ -f "${CONFIG_DIR}/sddm/autologin.conf" ]; then
    cp "${CONFIG_DIR}/sddm/autologin.conf" /etc/sddm.conf.d/autologin.conf
fi

# SDDM kuruluysa varsayılan yap
if command -v sddm &>/dev/null; then
    log_sub "  ✅ SDDM Wayland görüntü yöneticisi etkinleştiriliyor..."
    systemctl set-default graphical.target 2>/dev/null || true
    systemctl enable sddm 2>/dev/null || true
    echo "/usr/bin/sddm" > /etc/X11/default-display-manager 2>/dev/null || true
fi

# ─── LightDM Yedek Yapılandırması (Wayland Oturumu Destekli) ───
mkdir -p /etc/lightdm/lightdm.conf.d

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

cat > /etc/lightdm/lightdm.conf << 'EOF'
[Seat:*]
autologin-guest = false
autologin-user = solis
autologin-user-timeout = 0
autologin-session = plasmawayland
user-session = plasmawayland
greeter-session = lightdm-gtk-greeter

[SeatDefaults]
autologin-guest = false
autologin-user = solis
autologin-user-timeout = 0
autologin-session = plasmawayland
user-session = plasmawayland
greeter-session = lightdm-gtk-greeter
EOF

cat > /etc/pam.d/lightdm-autologin << 'EOF'
#%PAM-1.0
auth      requisite pam_nologin.so
auth      required  pam_permit.so
@include common-account
session [success=ok ignore=ignore default=bad] pam_selinux.so close
session   required  pam_limits.so
@include common-session
session [success=ok ignore=ignore default=bad] pam_selinux.so open
session   optional  pam_keyinit.so force revoke
@include common-password
EOF

# ═══════════════════════════════════════════════════════════════════
# 11. Canlı Oturum Kullanıcısı (solis) Oluşturma ve Hazırlama
# ═══════════════════════════════════════════════════════════════════

log_sub "Canlı oturum kullanıcısı (solis) yapılandırılıyor..."

groupadd -r autologin 2>/dev/null || true
groupadd -r nopasswdlogin 2>/dev/null || true

useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev,bluetooth,lpadmin,autologin,nopasswdlogin solis 2>/dev/null || true
usermod -a -G autologin,nopasswdlogin,sudo solis 2>/dev/null || true

echo "solis ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/solis
chmod 440 /etc/sudoers.d/solis
passwd -d solis 2>/dev/null || true

# Wayland oturum başlatıcı (.xsession fallback)
cat > /home/solis/.xsession << 'EOF'
if command -v startplasma-wayland &>/dev/null; then
    exec startplasma-wayland
else
    exec startxfce4
fi
EOF
chmod +x /home/solis/.xsession

# ═══════════════════════════════════════════════════════════════════
# 11b. Standalone Sistem Uygulamaları (LocalSend & Obsidian)
# ═══════════════════════════════════════════════════════════════════

log_sub "Standalone uygulamalar (LocalSend & Obsidian) indiriliyor ve kuruluyor..."

# 1. LocalSend (.deb)
LOCALSEND_URL="https://github.com/localsend/localsend/releases/download/v1.14.0/LocalSend-1.14.0-linux-x86-64.deb"
if curl -fsSL -o /tmp/localsend.deb "$LOCALSEND_URL" 2>/dev/null || wget -q -O /tmp/localsend.deb "$LOCALSEND_URL" 2>/dev/null; then
    dpkg -i /tmp/localsend.deb 2>/dev/null || apt-get install -f -y 2>/dev/null || true
    rm -f /tmp/localsend.deb
    log_sub "  ✅ LocalSend başarıyla kuruldu."
else
    log_sub "  ⚠️ LocalSend paketi indirilemedi (ağ gereksinimi)."
fi

# 2. Obsidian (.deb)
OBSIDIAN_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v1.5.12/obsidian_1.5.12_amd64.deb"
if curl -fsSL -o /tmp/obsidian.deb "$OBSIDIAN_URL" 2>/dev/null || wget -q -O /tmp/obsidian.deb "$OBSIDIAN_URL" 2>/dev/null; then
    dpkg -i /tmp/obsidian.deb 2>/dev/null || apt-get install -f -y 2>/dev/null || true
    rm -f /tmp/obsidian.deb
    log_sub "  ✅ Obsidian başarıyla kuruldu."
else
    log_sub "  ⚠️ Obsidian paketi indirilemedi (ağ gereksinimi)."
fi

# ═══════════════════════════════════════════════════════════════════
# 11c. Solis OS Özel WinUI 3 Araçları (Welcome Center & SolisOptimizer)
# ═══════════════════════════════════════════════════════════════════

log_sub "Solis OS özel WinUI 3 sistem araçları kuruluyor..."

# PEP 668 Korumalı Python Paket Kurulumu
if command -v pip3 &>/dev/null; then
    log_sub "  PyQt-Fluent-Widgets ve psutil kuruluyor (--break-system-packages)..."
    pip3 install --no-cache-dir --break-system-packages "PyQt-Fluent-Widgets[full]" psutil 2>/dev/null || \
    pip3 install --no-cache-dir "PyQt-Fluent-Widgets[full]" psutil 2>/dev/null || true
fi

# Solis Welcome Center
if [ -f "${PACKAGES_DIR}/solis-welcome/src/main.py" ]; then
    mkdir -p /usr/share/solis-welcome
    cp "${PACKAGES_DIR}/solis-welcome/src/main.py" /usr/local/bin/solis-welcome
    chmod +x /usr/local/bin/solis-welcome
    
    if [ -f "${PACKAGES_DIR}/solis-welcome/solis-welcome.desktop" ]; then
        cp "${PACKAGES_DIR}/solis-welcome/solis-welcome.desktop" /usr/share/applications/
        mkdir -p "${SKEL}/.config/autostart" /etc/xdg/autostart
        cp "${PACKAGES_DIR}/solis-welcome/solis-welcome.desktop" "${SKEL}/.config/autostart/"
        cp "${PACKAGES_DIR}/solis-welcome/solis-welcome.desktop" /etc/xdg/autostart/
    fi
    log_sub "  ✅ Solis Welcome Center kuruldu ve autostart'a bağlandı."
fi

# SolisOptimizer
if [ -f "${PACKAGES_DIR}/solis-optimizer/src/main.py" ]; then
    mkdir -p /usr/share/solis-optimizer
    cp "${PACKAGES_DIR}/solis-optimizer/src/main.py" /usr/local/bin/solis-optimizer
    chmod +x /usr/local/bin/solis-optimizer
    
    if [ -f "${PACKAGES_DIR}/solis-optimizer/solis-optimizer.desktop" ]; then
        cp "${PACKAGES_DIR}/solis-optimizer/solis-optimizer.desktop" /usr/share/applications/
    fi
    log_sub "  ✅ SolisOptimizer başarıyla kuruldu."
fi

# Şifresiz RAM Temizleme Yardımcısı
cat > /usr/local/bin/solis-ram-clean << 'EOF'
#!/bin/bash
sync
echo 3 > /proc/sys/vm/drop_caches
EOF
chmod +x /usr/local/bin/solis-ram-clean

# ─── Polkit Yetkilendirme Ajanı (GUI Root Parola Penceresi) ───
cat > /usr/local/bin/solis-polkit-agent << 'EOF'
#!/bin/bash
for agent in \
    /usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1 \
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 \
    /usr/libexec/polkit-kde-authentication-agent-1 \
    /usr/bin/lxpolkit; do
    if [ -x "$agent" ]; then
        exec "$agent"
    fi
done
EOF
chmod +x /usr/local/bin/solis-polkit-agent

mkdir -p /etc/xdg/autostart "${SKEL}/.config/autostart"
if [ -f "${CONFIG_DIR}/user/skel/.config/autostart/polkit-agent.desktop" ]; then
    cp "${CONFIG_DIR}/user/skel/.config/autostart/polkit-agent.desktop" /etc/xdg/autostart/
    cp "${CONFIG_DIR}/user/skel/.config/autostart/polkit-agent.desktop" "${SKEL}/.config/autostart/"
fi

# ─── Calamares Kurulum Aracı & Masaüstü Kısayolu ───
mkdir -p "${SKEL}/Desktop"
if [ -f "${CONFIG_DIR}/user/skel/Desktop/install-solis.desktop" ]; then
    cp "${CONFIG_DIR}/user/skel/Desktop/install-solis.desktop" "${SKEL}/Desktop/"
    chmod +x "${SKEL}/Desktop/install-solis.desktop"
fi

if [ -d "${PACKAGES_DIR}/solis-installer-config/branding/solis" ]; then
    mkdir -p /usr/share/calamares/branding/solis
    cp -r "${PACKAGES_DIR}/solis-installer-config/branding/solis/"* /usr/share/calamares/branding/solis/
    if [ -f "${BRANDING_DIR}/logo/solis-logo.svg" ]; then
        cp "${BRANDING_DIR}/logo/solis-logo.svg" /usr/share/calamares/branding/solis/
    fi
    log_sub "  ✅ Calamares Solis OS Fluent teması entegre edildi."
fi

# ─── Fastfetch & Terminal Solis Karşılama ───
mkdir -p "${SKEL}/.config/fastfetch"
if [ -f "${CONFIG_DIR}/user/skel/.config/fastfetch/config.jsonc" ]; then
    cp "${CONFIG_DIR}/user/skel/.config/fastfetch/config.jsonc" "${SKEL}/.config/fastfetch/"
fi

# .bashrc içine fastfetch ekle
if ! grep -q "fastfetch" "${SKEL}/.bashrc" 2>/dev/null; then
    cat >> "${SKEL}/.bashrc" << 'EOF'

# ☀️ Solis OS Terminal Başlangıç Özeti
if [ -x /usr/bin/fastfetch ] && [ -n "$PS1" ]; then
    fastfetch
fi
EOF
fi

# ─── Donanım ve Çekirdek Servislerini Etkinleştir ───
log_sub "Donanım, güç, ses ve ağ servisleri etkinleştiriliyor..."
systemctl enable NetworkManager 2>/dev/null || true
systemctl enable bluetooth 2>/dev/null || true
systemctl enable power-profiles-daemon 2>/dev/null || true
systemctl enable cups 2>/dev/null || true

# /etc/skel şablonunu kullanıcının ev dizinine kopyala ve izinleri ata
mkdir -p /home/solis/Desktop
cp -r "${SKEL}/." /home/solis/
chown -R solis:solis /home/solis/
chmod +x /home/solis/Desktop/*.desktop 2>/dev/null || true

log_sub "Canlı oturum, Wayland, donanım servisleri ve Calamares başarıyla hazırlandı."

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
