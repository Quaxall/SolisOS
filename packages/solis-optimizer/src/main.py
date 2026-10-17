#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
═══════════════════════════════════════════════════════════════════
⚡ SolisOptimizer — Sistem ve Bellek Optimizasyon Aracı
Windows 11 Fluent Design & CLI Desteği
═══════════════════════════════════════════════════════════════════
"""

import sys
import os
import subprocess
import shutil
import argparse

# Qt kütüphaneleri
try:
    from PyQt6.QtWidgets import (
        QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
        QLabel, QPushButton, QProgressBar, QFrame, QGridLayout, QMessageBox
    )
    from PyQt6.QtCore import Qt, QTimer
    from PyQt6.QtGui import QFont
    QT_LIB = "PyQt6"
except ImportError:
    try:
        from PySide6.QtWidgets import (
            QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
            QLabel, QPushButton, QProgressBar, QFrame, QGridLayout, QMessageBox
        )
        from PySide6.QtCore import Qt, QTimer
        from PySide6.QtGui import QFont
        QT_LIB = "PySide6"
    except ImportError:
        QT_LIB = None


# ─── Fluent QSS Stili ───
OPTIMIZER_STYLE = """
QMainWindow {
    background-color: #0f1017;
}

QWidget#CentralWidget {
    background-color: #0f1017;
}

QLabel#HeaderTitle {
    color: #ffffff;
    font-family: 'Inter', 'Segoe UI', sans-serif;
    font-size: 22px;
    font-weight: 700;
}

QLabel#HeaderSubtitle {
    color: #9ca3af;
    font-family: 'Inter', 'Segoe UI', sans-serif;
    font-size: 13px;
    margin-bottom: 8px;
}

QFrame#MetricCard {
    background-color: rgba(26, 29, 41, 0.75);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 10px;
    padding: 16px;
}

QFrame#MetricCard:hover {
    border: 1px solid rgba(255, 179, 0, 0.35);
}

QProgressBar {
    background-color: rgba(255, 255, 255, 0.08);
    border: none;
    border-radius: 4px;
    height: 8px;
    text-align: right;
    color: transparent;
}

QProgressBar::chunk {
    background-color: #ffb300;
    border-radius: 4px;
}

QPushButton {
    background-color: rgba(255, 255, 255, 0.07);
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 6px;
    color: #ffffff;
    font-family: 'Inter', 'Segoe UI', sans-serif;
    font-size: 13px;
    font-weight: 500;
    padding: 9px 18px;
}

QPushButton:hover {
    background-color: rgba(255, 255, 255, 0.14);
    border: 1px solid rgba(255, 255, 255, 0.25);
}

QPushButton#PrimaryButton {
    background-color: #ffb300;
    border: 1px solid #ffa000;
    color: #0f1017;
    font-weight: 600;
}

QPushButton#PrimaryButton:hover {
    background-color: #ffc107;
}

QFrame#InfoBox {
    background-color: rgba(30, 41, 59, 0.6);
    border-left: 4px solid #ffb300;
    border-radius: 6px;
    padding: 12px;
}
"""


def get_memory_info():
    """Linux /proc/meminfo üzerinden bellek istatistiklerini çeker."""
    mem = {}
    try:
        with open("/proc/meminfo", "r") as f:
            for line in f:
                parts = line.split(":")
                if len(parts) == 2:
                    key = parts[0].strip()
                    val = parts[1].strip().split()[0]
                    mem[key] = int(val)
        total = mem.get("MemTotal", 0) // 1024
        available = mem.get("MemAvailable", 0) // 1024
        used = total - available
        cached = (mem.get("Cached", 0) + mem.get("Buffers", 0)) // 1024
        pct = int((used / total) * 100) if total > 0 else 0
        return {"total": total, "used": used, "available": available, "cached": cached, "pct": pct}
    except Exception:
        return {"total": 8192, "used": 2048, "available": 6144, "cached": 512, "pct": 25}


def get_disk_info():
    """Kök disk doluluğunu çeker."""
    try:
        total, used, free = shutil.disk_usage("/")
        total_gb = total // (1024**3)
        used_gb = used // (1024**3)
        pct = int((used / total) * 100) if total > 0 else 0
        return {"total": total_gb, "used": used_gb, "pct": pct}
    except Exception:
        return {"total": 100, "used": 15, "pct": 15}


# ─── CLI Modu ───
def run_cli(args):
    print("⚡ SolisOptimizer CLI v0.2")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    mem = get_memory_info()
    disk = get_disk_info()
    
    if args.status or args.all:
        print(f"📊 Bellek (RAM):  {mem['used']} MB / {mem['total']} MB (%{mem['pct']})")
        print(f"💾 Disk (/):      {disk['used']} GB / {disk['total']} GB (%{disk['pct']})")
        print(f"📦 Önbellek:      {mem['cached']} MB")
        
    if args.ram or args.all:
        print("\n🧹 RAM Önbelleği temizleniyor...")
        cmd = "sync && echo 3 | pkexec tee /proc/sys/vm/drop_caches"
        res = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        new_mem = get_memory_info()
        freed = mem['used'] - new_mem['used']
        if freed > 0:
            print(f"✅ {freed} MB bellek serbest bırakıldı!")
        else:
            print("✅ Bellek önbelleği optimize edildi.")
            
    if args.clean or args.all:
        print("\n🗑️ Sistem paket ve log önbelleği temizleniyor...")
        subprocess.run("pkexec apt-get clean && rm -rf ~/.cache/thumbnails/* 2>/dev/null", shell=True)
        subprocess.run("pkexec journalctl --vacuum-size=50M 2>/dev/null", shell=True)
        print("✅ Sistem temizliği tamamlandı.")
        
    print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")


if QT_LIB:
    class SolisOptimizerGUI(QMainWindow):
        def __init__(self):
            super().__init__()
            self.setWindowTitle("⚡ SolisOptimizer")
            self.resize(760, 520)
            self.setMinimumSize(680, 480)
            
            central = QWidget()
            central.setObjectName("CentralWidget")
            self.setCentralWidget(central)
            
            layout = QVBoxLayout(central)
            layout.setContentsMargins(32, 28, 32, 28)
            layout.setSpacing(18)
            
            # Başlık
            title = QLabel("⚡ SolisOptimizer")
            title.setObjectName("HeaderTitle")
            subtitle = QLabel("Sistem performansı, bellek yönetimi ve disk önbellek temizleyici.")
            subtitle.setObjectName("HeaderSubtitle")
            layout.addWidget(title)
            layout.addWidget(subtitle)
            
            # ─── Metrik Kartları ───
            grid = QGridLayout()
            grid.setSpacing(14)
            
            # 1. RAM Kartı
            self.ram_card = QFrame()
            self.ram_card.setObjectName("MetricCard")
            rc_layout = QVBoxLayout(self.ram_card)
            
            self.ram_lbl = QLabel("Bellek (RAM) Kullanımı")
            self.ram_lbl.setStyleSheet("color: #ffffff; font-weight: 600; font-size: 14px;")
            self.ram_val = QLabel("Hesaplanıyor...")
            self.ram_val.setStyleSheet("color: #ffb300; font-size: 20px; font-weight: 700;")
            self.ram_bar = QProgressBar()
            
            rc_layout.addWidget(self.ram_lbl)
            rc_layout.addWidget(self.ram_val)
            rc_layout.addWidget(self.ram_bar)
            grid.addWidget(self.ram_card, 0, 0)
            
            # 2. Disk Kartı
            self.disk_card = QFrame()
            self.disk_card.setObjectName("MetricCard")
            dc_layout = QVBoxLayout(self.disk_card)
            
            self.disk_lbl = QLabel("Kök Disk (/) Alanı")
            self.disk_lbl.setStyleSheet("color: #ffffff; font-weight: 600; font-size: 14px;")
            self.disk_val = QLabel("Hesaplanıyor...")
            self.disk_val.setStyleSheet("color: #38bdf8; font-size: 20px; font-weight: 700;")
            self.disk_bar = QProgressBar()
            self.disk_bar.setStyleSheet("QProgressBar::chunk { background-color: #38bdf8; }")
            
            dc_layout.addWidget(self.disk_lbl)
            dc_layout.addWidget(self.disk_val)
            dc_layout.addWidget(self.disk_bar)
            grid.addWidget(self.disk_card, 0, 1)
            
            layout.addLayout(grid)
            
            # ─── Eylem Kartı ───
            actions_card = QFrame()
            actions_card.setObjectName("MetricCard")
            ac_layout = QVBoxLayout(actions_card)
            
            ac_title = QLabel("Hızlı Sistem Bakımı")
            ac_title.setStyleSheet("color: #ffffff; font-size: 15px; font-weight: 600;")
            ac_layout.addWidget(ac_title)
            
            btn_box = QHBoxLayout()
            
            self.clean_ram_btn = QPushButton("🧹 RAM Önbelleğini Boşalt")
            self.clean_ram_btn.setObjectName("PrimaryButton")
            self.clean_ram_btn.clicked.connect(self.clean_ram)
            
            self.clean_sys_btn = QPushButton("🗑️ Gereksiz Dosyaları Temizle")
            self.clean_sys_btn.clicked.connect(self.clean_system)
            
            btn_box.addWidget(self.clean_ram_btn)
            btn_box.addWidget(self.clean_sys_btn)
            ac_layout.addLayout(btn_box)
            layout.addWidget(actions_card)
            
            # ─── Bilgi Kutusu ───
            self.info_box = QFrame()
            self.info_box.setObjectName("InfoBox")
            ib_layout = QVBoxLayout(self.info_box)
            self.status_msg = QLabel("Solis OS ZRAM ve Linux çekirdek bellek optimizasyonları devrede.")
            self.status_msg.setStyleSheet("color: #d1d5db; font-size: 12px;")
            ib_layout.addWidget(self.status_msg)
            layout.addWidget(self.info_box)
            
            layout.addStretch()
            self.setStyleSheet(OPTIMIZER_STYLE)
            
            # Düzenli güncelleme zamanlayıcısı (2 saniyede bir)
            self.timer = QTimer(self)
            self.timer.timeout.connect(self.refresh_stats)
            self.timer.start(2000)
            self.refresh_stats()

        def refresh_stats(self):
            mem = get_memory_info()
            disk = get_disk_info()
            
            self.ram_val.setText(f"{mem['used']} MB / {mem['total']} MB (%{mem['pct']})")
            self.ram_bar.setValue(mem['pct'])
            
            self.disk_val.setText(f"{disk['used']} GB / {disk['total']} GB (%{disk['pct']})")
            self.disk_bar.setValue(disk['pct'])

        def clean_ram(self):
            cmd = "sync && echo 3 | pkexec tee /proc/sys/vm/drop_caches"
            subprocess.Popen(cmd, shell=True)
            self.status_msg.setText("✅ RAM önbellekleri boşaltıldı, bellek serbest bırakıldı.")
            QTimer.singleShot(1000, self.refresh_stats)

        def clean_system(self):
            cmd = "pkexec bash -c 'apt-get clean && journalctl --vacuum-size=50M && rm -rf ~/.cache/thumbnails/*'"
            subprocess.Popen(cmd, shell=True)
            self.status_msg.setText("✅ Paket önbellekleri ve loglar başarıyla temizlendi.")


def main():
    parser = argparse.ArgumentParser(description="SolisOptimizer CLI & GUI")
    parser.add_argument("--status", action="store_true", help="Sistem bellek ve disk durumunu göster")
    parser.add_argument("--ram", action="store_true", help="RAM önbelleğini boşalt")
    parser.add_argument("--clean", action="store_true", help="APT ve sistem önbelleklerini temizle")
    parser.add_argument("--all", action="store_true", help="Tüm optimizasyonları çalıştır")
    parser.add_argument("--gui", action="store_true", help="Grafik arayüzü zorla başlat")
    args = parser.parse_args()
    
    # CLI argümanı verildiyse terminal modunda çalış
    if args.status or args.ram or args.clean or args.all:
        run_cli(args)
        return
        
    # Aksi halde GUI modunu başlat
    if QT_LIB:
        app = QApplication(sys.argv)
        win = SolisOptimizerGUI()
        win.show()
        sys.exit(app.exec())
    else:
        run_cli(args)


if __name__ == "__main__":
    main()
