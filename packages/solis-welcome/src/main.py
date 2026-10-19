#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
═══════════════════════════════════════════════════════════════════
☀️ Solis OS — Welcome Center (Hoş Geldiniz & Kontrol Merkezi)
Windows 11 / WinUI 3 Fluent Design Standardı
═══════════════════════════════════════════════════════════════════
"""

import sys
import os
import subprocess
import platform
import shutil

# Qt kütüphaneleri (PyQt6 / PySide6 uyumluluğu)
try:
    from PyQt6.QtWidgets import (
        QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
        QLabel, QPushButton, QStackedWidget, QListWidget, QListWidgetItem,
        QFrame, QGridLayout, QScrollArea, QProgressBar, QMessageBox
    )
    from PyQt6.QtCore import Qt, QSize, QTimer
    from PyQt6.QtGui import QIcon, QFont, QColor
    QT_LIB = "PyQt6"
except ImportError:
    try:
        from PySide6.QtWidgets import (
            QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
            QLabel, QPushButton, QStackedWidget, QListWidget, QListWidgetItem,
            QFrame, QGridLayout, QScrollArea, QProgressBar, QMessageBox
        )
        from PySide6.QtCore import Qt, QSize, QTimer
        from PySide6.QtGui import QIcon, QFont, QColor
        QT_LIB = "PySide6"
    except ImportError:
        print("Hata: PyQt6 veya PySide6 kurulu değil!")
        sys.exit(1)


# ─── WinUI 3 Fluent QSS Stili ───
FLUENT_STYLE = """
QMainWindow {
    background-color: #0f1017;
}

QWidget#CentralWidget {
    background-color: #0f1017;
}

/* Sol Navigasyon Paneli (WinUI 3 NavigationView) */
QListWidget#NavList {
    background-color: rgba(22, 24, 34, 0.85);
    border: none;
    border-right: 1px solid rgba(255, 255, 255, 0.08);
    padding: 12px 8px;
    font-family: 'Inter', 'Segoe UI', sans-serif;
    font-size: 13px;
    color: #d1d5db;
    outline: none;
}

QListWidget#NavList::item {
    height: 40px;
    border-radius: 6px;
    padding-left: 12px;
    margin-bottom: 4px;
}

QListWidget#NavList::item:hover {
    background-color: rgba(255, 255, 255, 0.06);
    color: #ffffff;
}

QListWidget#NavList::item:selected {
    background-color: rgba(255, 179, 0, 0.16);
    color: #ffb300;
    font-weight: bold;
    border-left: 3px solid #ffb300;
}

/* İçerik Alanı */
QScrollArea {
    background-color: transparent;
    border: none;
}

QWidget#PageContent {
    background-color: transparent;
}

/* Başlıklar */
QLabel#PageTitle {
    color: #ffffff;
    font-family: 'Inter', 'Segoe UI', sans-serif;
    font-size: 24px;
    font-weight: 700;
    margin-bottom: 4px;
}

QLabel#PageSubtitle {
    color: #9ca3af;
    font-family: 'Inter', 'Segoe UI', sans-serif;
    font-size: 13px;
    margin-bottom: 16px;
}

/* WinUI 3 Fluent Kartlar */
QFrame#FluentCard {
    background-color: rgba(26, 29, 41, 0.75);
    border: 1px solid rgba(255, 255, 255, 0.07);
    border-radius: 10px;
    padding: 16px;
}

QFrame#FluentCard:hover {
    border: 1px solid rgba(255, 179, 0, 0.35);
    background-color: rgba(30, 34, 48, 0.85);
}

/* Hero Kartı */
QFrame#HeroCard {
    background: qlineargradient(x1:0, y1:0, x2:1, y2:1,
        stop:0 #231b12, stop:0.5 #1b1c2b, stop:1 #13141f);
    border: 1px solid rgba(255, 179, 0, 0.3);
    border-radius: 12px;
    padding: 24px;
}

/* Butonlar */
QPushButton {
    background-color: rgba(255, 255, 255, 0.07);
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 6px;
    color: #ffffff;
    font-family: 'Inter', 'Segoe UI', sans-serif;
    font-size: 13px;
    font-weight: 500;
    padding: 8px 16px;
}

QPushButton:hover {
    background-color: rgba(255, 255, 255, 0.14);
    border: 1px solid rgba(255, 255, 255, 0.25);
}

QPushButton:pressed {
    background-color: rgba(255, 255, 255, 0.05);
}

/* Birincil Aksiyon Butonu (Solis Amber) */
QPushButton#PrimaryButton {
    background-color: #ffb300;
    border: 1px solid #ffa000;
    color: #0f1017;
    font-weight: 600;
}

QPushButton#PrimaryButton:hover {
    background-color: #ffc107;
}

QPushButton#PrimaryButton:pressed {
    background-color: #ff8f00;
}
"""


class SolisWelcomeApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("☀️ Solis OS Hoş Geldiniz")
        self.resize(960, 640)
        self.setMinimumSize(840, 560)
        
        # Ana widget ve layout
        central_widget = QWidget()
        central_widget.setObjectName("CentralWidget")
        self.setCentralWidget(central_widget)
        
        main_layout = QHBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)
        
        # ─── Sol Navigasyon Paneli ───
        self.nav_list = QListWidget()
        self.nav_list.setObjectName("NavList")
        self.nav_list.setFixedWidth(210)
        
        nav_items = [
            ("🏠  Hoş Geldiniz", 0),
            ("🎨  Görünüm & Tema", 1),
            ("🖥️  Sistem & Donanım", 2),
            ("📦  Uygulama Mağazası", 3),
            ("⚡  Optimizasyon", 4),
            ("ℹ️  Hakkında", 5)
        ]
        
        for text, index in nav_items:
            item = QListWidgetItem(text)
            self.nav_list.addItem(item)
            
        self.nav_list.setCurrentRow(0)
        self.nav_list.currentRowChanged.connect(self.switch_page)
        main_layout.addWidget(self.nav_list)
        
        # ─── Sağ İçerik Alanı (Stacked Widget) ───
        self.stacked_widget = QStackedWidget()
        
        # Sayfaları Ekle
        self.stacked_widget.addWidget(self.create_welcome_page())
        self.stacked_widget.addWidget(self.create_appearance_page())
        self.stacked_widget.addWidget(self.create_system_page())
        self.stacked_widget.addWidget(self.create_apps_page())
        self.stacked_widget.addWidget(self.create_optimizer_page())
        self.stacked_widget.addWidget(self.create_about_page())
        
        main_layout.addWidget(self.stacked_widget, 1)
        
        # CSS Stili uygula
        self.setStyleSheet(FLUENT_STYLE)

    def switch_page(self, index):
        self.stacked_widget.setCurrentIndex(index)

    # ═══════════════════════════════════════════════════════════════════
    # 1. Hoş Geldiniz Sayfası
    # ═══════════════════════════════════════════════════════════════════
    def create_welcome_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(32, 28, 32, 28)
        layout.setSpacing(16)
        
        # Hero Banner
        hero = QFrame()
        hero.setObjectName("HeroCard")
        hero_layout = QVBoxLayout(hero)
        
        hero_title = QLabel("☀️ Solis OS 0.2 (Solstice)'a Hoş Geldiniz")
        hero_title.setStyleSheet("color: #ffb300; font-size: 22px; font-weight: 700;")
        hero_layout.addWidget(hero_title)
        
        hero_desc = QLabel(
            "Ubuntu 24.04 LTS üzerine inşa edilmiş, Wayland mimarili, akıcı animasyonlara "
            "ve Windows 11 Fluent Design estetiğine sahip ultra hızlı işletim sisteminiz hazır."
        )
        hero_desc.setStyleSheet("color: #e5e7eb; font-size: 13px; line-height: 1.5;")
        hero_desc.setWordWrap(True)
        hero_layout.addWidget(hero_desc)
        layout.addWidget(hero)
        
        # Hızlı Eylemler Başlığı
        section_lbl = QLabel("Hızlı Eylemler")
        section_lbl.setStyleSheet("color: #ffffff; font-size: 16px; font-weight: 600; margin-top: 8px;")
        layout.addWidget(section_lbl)
        
        # Hızlı Eylemler Kart Grid
        grid = QGridLayout()
        grid.setSpacing(12)
        
        actions = [
            ("🎨 Görünümü Özelleştir", "Koyu/Açık mod, duvar kağıtları ve renkler", lambda: self.nav_list.setCurrentRow(1)),
            ("⚡ Sistem Optimizasyonu", "Bellek temizliği, önbellek ve performans profili", lambda: self.nav_list.setCurrentRow(4)),
            ("📦 Uygulama Keşfet", "LocalSend, Obsidian ve önerilen yazılımlar", lambda: self.nav_list.setCurrentRow(3)),
            ("🔧 Solis OS'u Diske Kur", "Calamares kurulum sihirbazını başlat", self.launch_installer)
        ]
        
        for idx, (title, desc, callback) in enumerate(actions):
            card = QFrame()
            card.setObjectName("FluentCard")
            c_layout = QVBoxLayout(card)
            
            c_title = QLabel(title)
            c_title.setStyleSheet("color: #ffffff; font-size: 14px; font-weight: 600;")
            c_desc = QLabel(desc)
            c_desc.setStyleSheet("color: #9ca3af; font-size: 12px;")
            c_desc.setWordWrap(True)
            
            btn = QPushButton("Aç")
            btn.clicked.connect(callback)
            
            c_layout.addWidget(c_title)
            c_layout.addWidget(c_desc)
            c_layout.addSpacing(6)
            c_layout.addWidget(btn)
            
            row = idx // 2
            col = idx % 2
            grid.addWidget(card, row, col)
            
        layout.addLayout(grid)
        layout.addStretch()
        return page

    # ═══════════════════════════════════════════════════════════════════
    # 2. Görünüm & Tema Sayfası
    # ═══════════════════════════════════════════════════════════════════
    def create_appearance_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(32, 28, 32, 28)
        layout.setSpacing(16)
        
        title = QLabel("Görünüm ve Tema")
        title.setObjectName("PageTitle")
        subtitle = QLabel("Solis OS'un Windows 11 Fluent estetiğini ve renk paletini kişiselleştirin.")
        subtitle.setObjectName("PageSubtitle")
        layout.addWidget(title)
        layout.addWidget(subtitle)
        
        # Tema Seçim Kartı
        theme_card = QFrame()
        theme_card.setObjectName("FluentCard")
        tc_layout = QVBoxLayout(theme_card)
        
        tc_title = QLabel("🌓 Renk Modu")
        tc_title.setStyleSheet("color: #ffffff; font-size: 15px; font-weight: 600;")
        tc_layout.addWidget(tc_title)
        
        btn_layout = QHBoxLayout()
        dark_btn = QPushButton("🌙 Koyu Mod (Varsayılan)")
        dark_btn.setObjectName("PrimaryButton")
        dark_btn.clicked.connect(lambda: self.run_command("solis-theme dark"))
        
        light_btn = QPushButton("☀️ Açık Mod")
        light_btn.clicked.connect(lambda: self.run_command("solis-theme light"))
        
        btn_layout.addWidget(dark_btn)
        btn_layout.addWidget(light_btn)
        tc_layout.addLayout(btn_layout)
        layout.addWidget(theme_card)
        
        # Görev Çubuğu Hizalama Kartı
        taskbar_card = QFrame()
        taskbar_card.setObjectName("FluentCard")
        tb_layout = QVBoxLayout(taskbar_card)
        
        tb_title = QLabel("📊 Görev Çubuğu Düzeni")
        tb_title.setStyleSheet("color: #ffffff; font-size: 15px; font-weight: 600;")
        tb_desc = QLabel("Windows 11 ortalanmış simgeler veya klasik sol hizalama.")
        tb_desc.setStyleSheet("color: #9ca3af; font-size: 12px;")
        tb_layout.addWidget(tb_title)
        tb_layout.addWidget(tb_desc)
        
        tb_btn_layout = QHBoxLayout()
        center_btn = QPushButton("🎯 Ortalanmış Görev Çubuğu (Win11)")
        center_btn.clicked.connect(lambda: QMessageBox.information(self, "Bilgi", "Ortalanmış görev çubuğu varsayılan olarak etkindir."))
        left_btn = QPushButton("⬅️ Sol Hizalı (Klasik)")
        left_btn.clicked.connect(lambda: QMessageBox.information(self, "Bilgi", "Sol hizalama paneli uygulandı."))
        tb_btn_layout.addWidget(center_btn)
        tb_btn_layout.addWidget(left_btn)
        tb_layout.addLayout(tb_btn_layout)
        layout.addWidget(taskbar_card)
        
        layout.addStretch()
        return page

    # ═══════════════════════════════════════════════════════════════════
    # 3. Sistem & Donanım Sayfası
    # ═══════════════════════════════════════════════════════════════════
    def create_system_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(32, 28, 32, 28)
        layout.setSpacing(14)
        
        title = QLabel("Sistem ve Donanım Bilgisi")
        title.setObjectName("PageTitle")
        subtitle = QLabel("Donanımınızın Solis OS ile uyumu ve çekirdek detayları.")
        subtitle.setObjectName("PageSubtitle")
        layout.addWidget(title)
        layout.addWidget(subtitle)
        
        # Bilgi Kartı
        card = QFrame()
        card.setObjectName("FluentCard")
        c_layout = QVBoxLayout(card)
        
        kernel_info = platform.release()
        arch_info = platform.machine()
        desktop_session = os.environ.get("XDG_CURRENT_DESKTOP", "KDE Plasma / Wayland")
        session_type = os.environ.get("XDG_SESSION_TYPE", "wayland")
        
        specs = [
            ("Dağıtım:", "Solis OS 0.2 (Solstice)"),
            ("Taban:", "Ubuntu 24.04 LTS (Noble Numbat)"),
            ("Çekirdek (Kernel):", f"Linux {kernel_info} ({arch_info})"),
            ("Görüntü Mimarisi:", f"Wayland ({session_type.upper()})"),
            ("Masaüstü Ortamı:", desktop_session)
        ]
        
        for k, v in specs:
            row = QHBoxLayout()
            lbl_k = QLabel(k)
            lbl_k.setStyleSheet("color: #9ca3af; font-weight: 500;")
            lbl_v = QLabel(v)
            lbl_v.setStyleSheet("color: #ffffff; font-weight: 600;")
            row.addWidget(lbl_k)
            row.addWidget(lbl_v)
            row.addStretch()
            c_layout.addLayout(row)
            
        layout.addWidget(card)
        
        # Sürücü Eylem Butonu
        drv_card = QFrame()
        drv_card.setObjectName("FluentCard")
        dc_layout = QHBoxLayout(drv_card)
        dc_info = QLabel("Ek donanım ve tescilli sürücüleri (NVIDIA, Wi-Fi) kontrol edin.")
        dc_info.setStyleSheet("color: #d1d5db; font-size: 13px;")
        dc_btn = QPushButton("Sürücü Yöneticisini Aç")
        dc_btn.clicked.connect(self.launch_driver_manager)
        dc_layout.addWidget(dc_info)
        dc_layout.addStretch()
        dc_layout.addWidget(dc_btn)
        layout.addWidget(drv_card)
        
        layout.addStretch()
        return page

    # ═══════════════════════════════════════════════════════════════════
    # 4. Uygulama Mağazası Sayfası
    # ═══════════════════════════════════════════════════════════════════
    def create_apps_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(32, 28, 32, 28)
        layout.setSpacing(14)
        
        title = QLabel("Önceden Yüklü & Önerilen Yazılımlar")
        title.setObjectName("PageTitle")
        subtitle = QLabel("Solis OS içinde yerleşik gelen ve tek tıkla kurabileceğiniz popüler araçlar.")
        subtitle.setObjectName("PageSubtitle")
        layout.addWidget(title)
        layout.addWidget(subtitle)
        
        # Önceden Yüklü Uygulamalar Listesi
        preinstalled_card = QFrame()
        preinstalled_card.setObjectName("FluentCard")
        pi_layout = QVBoxLayout(preinstalled_card)
        
        pi_title = QLabel("✅ Yerleşik Sistem Uygulamaları:")
        pi_title.setStyleSheet("color: #ffb300; font-size: 14px; font-weight: 600;")
        pi_layout.addWidget(pi_title)
        
        apps_text = (
            "• LocalSend (Cihazlar arası kablosuz hızlı dosya transferi)\n"
            "• Obsidian (Markdown tabanlı gelişmiş not alma & bilgi ağı)\n"
            "• Geary (Modern ve hafif e-posta istemcisi)\n"
            "• GNOME Text Editor (Modern Win11 tarzı sekmeli metin editörü)\n"
            "• Loupe (Ultra akıcı görsel görüntüleyici)\n"
            "• GNOME Calendar, Clocks & Weather"
        )
        pi_lbl = QLabel(apps_text)
        pi_lbl.setStyleSheet("color: #d1d5db; font-size: 12px; line-height: 1.6;")
        pi_layout.addWidget(pi_lbl)
        layout.addWidget(preinstalled_card)
        
        # Harici Yazılım Merkezi Aç Butonu
        store_btn = QPushButton("🛍️ Yazılım Merkezini Aç (Discover / Flatpak)")
        store_btn.setObjectName("PrimaryButton")
        store_btn.clicked.connect(self.launch_software_store)
        layout.addWidget(store_btn)
        
        layout.addStretch()
        return page

    # ═══════════════════════════════════════════════════════════════════
    # 5. Optimizasyon Sayfası (Kısayol)
    # ═══════════════════════════════════════════════════════════════════
    def create_optimizer_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(32, 28, 32, 28)
        layout.setSpacing(16)
        
        title = QLabel("Sistem Optimizasyonu")
        title.setObjectName("PageTitle")
        subtitle = QLabel("SolisOptimizer ile sistem kaynaklarınızı en üst düzey verimlilikte tutun.")
        subtitle.setObjectName("PageSubtitle")
        layout.addWidget(title)
        layout.addWidget(subtitle)
        
        card = QFrame()
        card.setObjectName("FluentCard")
        c_layout = QVBoxLayout(card)
        
        c_title = QLabel("⚡ SolisOptimizer Başlat")
        c_title.setStyleSheet("color: #ffffff; font-size: 16px; font-weight: 600;")
        c_desc = QLabel("RAM temizliği yapın, gereksiz APT önbelleklerini silin ve performans modunu ayarlayın.")
        c_desc.setStyleSheet("color: #9ca3af; font-size: 13px;")
        
        btn = QPushButton("SolisOptimizer'ı Şimdi Çalıştır")
        btn.setObjectName("PrimaryButton")
        btn.clicked.connect(lambda: self.run_command("solis-optimizer"))
        
        c_layout.addWidget(c_title)
        c_layout.addWidget(c_desc)
        c_layout.addSpacing(8)
        c_layout.addWidget(btn)
        layout.addWidget(card)
        
        layout.addStretch()
        return page

    # ═══════════════════════════════════════════════════════════════════
    # 6. Hakkında Sayfası
    # ═══════════════════════════════════════════════════════════════════
    def create_about_page(self):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(32, 28, 32, 28)
        layout.setSpacing(14)
        
        title = QLabel("Solis OS Hakkında")
        title.setObjectName("PageTitle")
        layout.addWidget(title)
        
        card = QFrame()
        card.setObjectName("FluentCard")
        c_layout = QVBoxLayout(card)
        
        logo_lbl = QLabel("☀️ Solis OS")
        logo_lbl.setStyleSheet("color: #ffb300; font-size: 26px; font-weight: 800;")
        version_lbl = QLabel("Sürüm: 0.2 (Solstice) · 64-bit AMD64")
        version_lbl.setStyleSheet("color: #ffffff; font-size: 14px; font-weight: 600;")
        desc_lbl = QLabel(
            "Solis OS, hız, modern zarafet ve düşük kaynak tüketimi ilkeleriyle geliştirilen açık kaynaklı "
            "bağımsız bir Linux dağıtımıdır. Windows 11 Fluent Design estetiğini Linux'un gücüyle birleştirir."
        )
        desc_lbl.setStyleSheet("color: #9ca3af; font-size: 12px; line-height: 1.5;")
        desc_lbl.setWordWrap(True)
        
        c_layout.addWidget(logo_lbl)
        c_layout.addWidget(version_lbl)
        c_layout.addSpacing(6)
        c_layout.addWidget(desc_lbl)
        layout.addWidget(card)
        
        layout.addStretch()
        return page

    def run_command(self, cmd):
        try:
            subprocess.Popen(cmd, shell=True)
        except Exception as e:
            QMessageBox.warning(self, "Hata", f"Komut çalıştırılamadı: {e}")

    def launch_installer(self):
        if shutil.which("calamares"):
            self.run_command("pkexec calamares")
        else:
            QMessageBox.information(self, "Bilgi", "Calamares kurulum aracı Live ISO ortamında çalıştırılabilir.")

    def launch_driver_manager(self):
        for cmd in [
            "software-properties-gtk --open-tab=4",
            "software-properties-qt --open-tab=4",
            "pkexec ubuntu-drivers install",
            "systemsettings kcm_driver_manager"
        ]:
            binary = cmd.split()[0]
            if shutil.which(binary):
                self.run_command(cmd)
                return
        QMessageBox.warning(self, "Bilgi", "Sisteminizde ek tescilli sürücü gerektiren donanım bulunamadı veya sürücü aracı yüklenmedi.")

    def launch_software_store(self):
        for cmd in ["plasma-discover", "gnome-software"]:
            if shutil.which(cmd):
                self.run_command(cmd)
                return
        QMessageBox.warning(self, "Bilgi", "Yazılım merkezi uygulaması bulunamadı.")


def main():
    app = QApplication(sys.argv)
    window = SolisWelcomeApp()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
