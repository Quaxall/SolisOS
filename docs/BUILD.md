# Solis OS — Build Kılavuzu

## Gereksinimler

### Windows 11 + WSL2 Ortamı (Önerilen)
1. **WSL2** kurulu ve çalışır durumda
2. **Docker Desktop** kurulu, WSL2 backend etkin
3. **~10 GB** boş disk alanı
4. İnternet bağlantısı

### Linux Ortamı (Alternatif)
1. Docker veya Podman kurulu
2. Veya doğrudan: `debootstrap`, `squashfs-tools`, `xorriso`, `grub-pc-bin`, `grub-efi-amd64-bin`

---

## Hızlı Build

```bash
# 1. Projeyi klonla
git clone https://github.com/solis-os/solis-os.git
cd solis-os

# 2. Docker imajını oluştur (~2 dakika)
docker build -t solis-builder -f build/Dockerfile .

# 3. ISO'yu üret (~15-30 dakika)
docker run --rm --privileged \
  -v "$(pwd)/output:/build/output" \
  solis-builder

# 4. Çıktıyı kontrol et
ls -lh output/
sha256sum -c output/SHA256SUMS
```

---

## Test

### QEMU (WSL2 / Linux)
```bash
# UEFI modu
./scripts/test-qemu.sh output/solis-os-0.2-solstice-amd64.iso uefi

# BIOS modu
./scripts/test-qemu.sh output/solis-os-0.2-solstice-amd64.iso bios
```

### VirtualBox (Windows)
```powershell
.\scripts\test-vbox.ps1 -IsoPath ".\output\solis-os-0.2-solstice-amd64.iso"
```

---

## Özelleştirme

### Paket Ekleme/Çıkarma
- `config/packages/apps.list` — Kullanıcı uygulamaları
- `config/packages/desktop.list` — Masaüstü bileşenleri
- `config/packages/removals.list` — Kaldırılacak paketler

### Tema Değiştirme
- `config/picom/picom.conf` — Compositor efektleri
- `config/user/skel/.config/gtk-3.0/gtk.css` — Panel CSS
- `build/chroot-setup.sh` → Bölüm 6 — GTK tema kurulumu

### Branding
- `branding/os-release` — İşletim sistemi kimliği
- `branding/issue` — Terminal hoş geldiniz mesajı
