# ═══════════════════════════════════════════════════════════════════
# ☀️ Solis OS — VirtualBox Test Betiği (PowerShell)
# Üretilen ISO dosyasını VirtualBox ile test eder.
#
# Kullanım (PowerShell):
#   .\scripts\test-vbox.ps1
#   .\scripts\test-vbox.ps1 -IsoPath ".\output\solis-os-0.2-solstice-amd64.iso"
# ═══════════════════════════════════════════════════════════════════

param(
    [string]$IsoPath = ".\output\solis-os-0.2-solstice-amd64.iso",
    [string]$VmName = "SolisOS-Test",
    [int]$MemoryMB = 2048,
    [int]$Cpus = 2,
    [int]$DiskSizeMB = 20480,
    [switch]$LegacyBios
)

# ─── Doğrulama ───
if (-not (Test-Path $IsoPath)) {
    Write-Host "❌ ISO dosyası bulunamadı: $IsoPath" -ForegroundColor Red
    Write-Host "   Önce ISO'yu build edin: docker run --rm --privileged -v `"`$(pwd)/output:/build/output`" solis-builder"
    exit 1
}

# VBoxManage'i bul
$VBoxManage = "VBoxManage"
if (-not (Get-Command $VBoxManage -ErrorAction SilentlyContinue)) {
    $VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
    if (-not (Test-Path $VBoxManage)) {
        Write-Host "❌ VBoxManage bulunamadı! VirtualBox kurulu olduğundan emin olun." -ForegroundColor Red
        exit 1
    }
}

$IsoFullPath = (Resolve-Path $IsoPath).Path
$VdiPath = Join-Path $PWD "$VmName.vdi"

Write-Host ""
Write-Host "  ☀️ Solis OS — VirtualBox Test" -ForegroundColor Yellow
Write-Host "  ISO:    $IsoFullPath"
Write-Host "  VM:     $VmName"
Write-Host "  RAM:    ${MemoryMB}MB"
Write-Host "  CPU:    $Cpus"
Write-Host "  Boot:   $(if ($LegacyBios) { 'BIOS (Legacy)' } else { 'UEFI' })"
Write-Host ""

# ─── Eski VM varsa sil ───
$existingVm = & $VBoxManage list vms 2>$null | Select-String $VmName
if ($existingVm) {
    Write-Host "  ⚠️  Eski VM siliniyor: $VmName" -ForegroundColor Yellow
    & $VBoxManage controlvm $VmName poweroff 2>$null
    Start-Sleep -Seconds 2
    & $VBoxManage unregistervm $VmName --delete 2>$null
    Start-Sleep -Seconds 1
}

# Eski disk varsa sil
if (Test-Path $VdiPath) {
    Remove-Item $VdiPath -Force
}

# ─── VM Oluştur ───
Write-Host "  📦 VM oluşturuluyor..." -ForegroundColor Cyan

& $VBoxManage createvm --name $VmName --ostype "Ubuntu_64" --register
& $VBoxManage modifyvm $VmName `
    --memory $MemoryMB `
    --cpus $Cpus `
    --vram 128 `
    --graphicscontroller vmsvga `
    --audio-driver default `
    --audio-out on `
    --nic1 nat `
    --natpf1 "ssh,tcp,,2222,,22" `
    --clipboard-mode bidirectional `
    --draganddrop bidirectional

# Boot modu
if (-not $LegacyBios) {
    & $VBoxManage modifyvm $VmName --firmware efi
}

# ─── Depolama ───
Write-Host "  💾 Disk oluşturuluyor..." -ForegroundColor Cyan

& $VBoxManage createmedium disk --filename $VdiPath --size $DiskSizeMB --format VDI
& $VBoxManage storagectl $VmName --name "SATA" --add sata --controller IntelAhci
& $VBoxManage storageattach $VmName --storagectl "SATA" --port 0 --device 0 --type hdd --medium $VdiPath
& $VBoxManage storageattach $VmName --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium $IsoFullPath

# ─── Başlat ───
Write-Host ""
Write-Host "  🚀 VM başlatılıyor..." -ForegroundColor Green
& $VBoxManage startvm $VmName --type gui

Write-Host ""
Write-Host "  ✅ VirtualBox penceresi açıldı." -ForegroundColor Green
Write-Host "  💡 Testi bitirdikten sonra VM'i kaldırmak için:" -ForegroundColor DarkGray
Write-Host "     VBoxManage controlvm $VmName poweroff && VBoxManage unregistervm $VmName --delete" -ForegroundColor DarkGray
