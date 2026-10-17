# ☀️ Solis OS

**Modern, hafif ve Windows 11 Fluent Design estetiğinde Ubuntu tabanlı Linux dağıtımı.**

> Sürüm: 0.2 · Kod Adı: **Solstice** · Taban: Ubuntu 24.04 LTS (Noble Numbat)

---

## 🎯 Vizyon

Solis OS, Ubuntu'nun güvenilir paket tabanı üzerine kurulu, Windows 11'in modern Fluent Design estetiğini Linux dünyasına taşıyan, günlük kullanıcılar için tasarlanmış hafif bir işletim sistemidir.

### Temel Özellikler
- **Windows 11 Görünümü:** Fluent GTK teması, ortalanmış görev çubuğu, Mica/Acrylic efektleri
- **Hafif & Hızlı:** XFCE4 tabanlı, < 600 MB idle RAM kullanımı
- **Modern Araçlar:** WinUI 3 tarzı Solis Welcome Center ve SolisOptimizer
- **Snap-Free:** Temiz, bloatware'siz Ubuntu deneyimi
- **Kolay Kurulum:** Calamares ile tek tıkla kurulum

---

## 🏗️ Build (ISO Oluşturma)

### Gereksinimler
- Docker Desktop (Windows 11 + WSL2 veya Linux)
- ~10 GB boş disk alanı
- İnternet bağlantısı

### Hızlı Başlangıç
```bash
# 1. Docker build imajını oluştur
docker build -t solis-builder -f build/Dockerfile .

# 2. ISO'yu üret (~15-30 dakika)
docker run --rm --privileged \
  -v "$(pwd)/output:/build/output" \
  solis-builder

# 3. Çıktı
ls -lh output/solis-os-0.2-solstice-amd64.iso
```

### Test
```bash
# QEMU ile test (Linux/WSL2)
./scripts/test-qemu.sh output/solis-os-0.2-solstice-amd64.iso uefi

# VirtualBox ile test (Windows PowerShell)
.\scripts\test-vbox.ps1
```

---

## 📁 Proje Yapısı

```
solis-os/
├── build/          # ISO üretim altyapısı (Dockerfile, build betikleri)
├── config/         # Paket listeleri, kernel, sistem ve masaüstü yapılandırması
├── branding/       # Görsel kimlik (GRUB, Plymouth, tema, ikonlar, logo)
├── packages/       # Solis OS'a özel araçlar (Welcome, Optimizer)
├── scripts/        # Test ve otomasyon betikleri
├── docs/           # Proje belgeleri
└── output/         # Üretilen ISO dosyaları (git-ignored)
```

---

## 📋 Teknoloji Yığını

| Katman | Teknoloji |
|--------|-----------|
| Taban | Ubuntu 24.04 LTS (Noble Numbat) |
| Çekirdek | linux-image-generic |
| Masaüstü | XFCE4 |
| Tema | Fluent GTK Theme (vinceliuice) |
| İkonlar | Fluent Icon Theme |
| Compositor | picom (blur, shadows, rounded corners) |
| Font | Inter (Segoe UI alternatifi) |
| Solis Araçları | PySide6 + PyQt-Fluent-Widgets |
| Kurulum | Calamares |
| Build | Docker + debootstrap + squashfs + xorriso |

---

## 📄 Lisans

GPL-3.0 — Ayrıntılar için [LICENSE](LICENSE) dosyasına bakın.
