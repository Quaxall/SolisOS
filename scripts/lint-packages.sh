#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# ☀️ Solis OS — Paket Listesi Doğrulama (Lint)
# Paket listelerindeki hataları kontrol eder.
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

CONFIG_DIR="${1:-./config/packages}"

echo "☀️ Solis OS — Paket Listesi Doğrulama"
echo ""

ERRORS=0
WARNINGS=0

for list_file in "${CONFIG_DIR}"/*.list; do
    [ -f "$list_file" ] || continue
    
    filename=$(basename "$list_file")
    echo "📋 Kontrol: $filename"
    
    line_num=0
    while IFS= read -r raw_line || [ -n "$raw_line" ]; do
        line_num=$((line_num + 1))
        # Remove \r if present
        line="${raw_line%$'\r'}"
        
        # Boş satır veya yorum — tamam
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Baştaki/sondaki boşlukları temizle
        trimmed="${line#"${line%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
        
        if [ "$line" != "$trimmed" ]; then
            echo "  ⚠️  Satır $line_num: Baştaki/sondaki boşluk: '$line'"
            WARNINGS=$((WARNINGS + 1))
        fi
        
        # Geçersiz karakterler
        if [[ "$trimmed" =~ [^a-zA-Z0-9_.+-] ]]; then
            echo "  ❌ Satır $line_num: Geçersiz karakter: '$trimmed'"
            ERRORS=$((ERRORS + 1))
        fi
        
    done < "$list_file"
    
    # Paket sayısını göster
    pkg_count=$(grep -v '^#' "$list_file" | grep -v '^$' | wc -l)
    echo "  ✅ $pkg_count paket listelendi."
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Sonuç: $ERRORS hata, $WARNINGS uyarı"

if [ $ERRORS -gt 0 ]; then
    echo "❌ Hatalar düzeltilmeden build yapılamaz!"
    exit 1
else
    echo "✅ Tüm paket listeleri geçerli."
fi
