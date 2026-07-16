#!/usr/bin/env bash
# build-release.sh — tpr-yt yayın (release) dosyalarını üretir.
#
#   dist/tpr-yt-windows-x64.exe     ham ikili  (güncelleyicinin indirdiği dosya)
#   dist/tpr-yt-linux-x64           ham ikili  (güncelleyicinin indirdiği dosya)
#   dist/tpr-yt-windows-x64.zip     ikili + config.default.json + README.md
#   dist/tpr-yt-linux-x64.tar.gz    ikili + config.default.json + README.md
#   dist/SHA256SUMS.txt             tüm dosyaların sağlamaları
#
# Kullanım (proje kökünden, Git Bash veya WSL):
#   scripts/build-release.sh              # her iki platform
#   scripts/build-release.sh --linux      # yalnız Linux
#   scripts/build-release.sh --windows    # yalnız Windows
#
# ---------------------------------------------------------------------------
# NEDEN LINUX İKİLİSİ STATİK DERLENİYOR
#
# Tulpar'ın AOT bağlama satırı Linux'ta glibc + libssl/libcrypto'yu DİNAMİK
# bağlar. Derleyen makinenin glibc'si ikiliye sürüm damgası olarak işlenir; v0.1.0
# yayını böyle üretildiği için yalnızca glibc >= 2.38 + libssl.so.3 olan
# dağıtımlarda (Ubuntu 24.04+) çalışıyordu. `-static` ile TÜM bağımlılıklar
# ikilinin içine girer -> "for GNU/Linux 3.2.0", hiçbir glibc sürüm bağımlılığı
# kalmaz ve ikili her x86-64 dağıtımda çalışır.
#
# -lzstd -ljitterentropy -lz neden gerekli: Ubuntu'nun libcrypto.a'sı bu
# kütüphanelere referans verir; dinamik bağlamada .so'lar bunları kendi
# içlerinde çözer, statik bağlamada ise bağlayıcı satırında açıkça belirtilmeleri
# gerekir (yoksa "undefined reference to ZSTD_decompress / jent_*").
#
# Statik glibc uyarısı (getaddrinfo/dlopen) bu uygulama için zararsızdır:
# uygulama süreç-içi DNS çözümlemesi yapmaz, ağ işlerini curl/yt-dlp alt
# süreçlerine devreder.
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
DIST="$ROOT/dist"

DO_WIN=1
DO_LINUX=1
case "${1:-}" in
    --linux)   DO_WIN=0 ;;
    --windows) DO_LINUX=0 ;;
    "")        ;;
    *) echo "Bilinmeyen secenek: $1" >&2; exit 2 ;;
esac

# Yalnizca `return "x.y.z";` satirindan oku: version.tpr'nin yorumlarinda da
# ornek surum numaralari geciyor ve gevsek bir desen onlari yakalar.
VERSION="$(grep -oE 'return[[:space:]]+"[0-9]+\.[0-9]+\.[0-9]+"' src/version.tpr \
    | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
if [ -z "$VERSION" ]; then
    echo "HATA: src/version.tpr icinden surum okunamadi." >&2
    exit 1
fi
echo "==> tpr-yt v$VERSION"

rm -rf "$DIST"
mkdir -p "$DIST"

# Tulpar `build`, yalnızca giriş dosyasının damgasına bakarak önbelleğe alır;
# yalnızca bir modül değiştiyse bayat ikili üretebilir. main.tpr'ye dokunmak
# her seferinde taze derleme garantiler.
touch src/main.tpr

# --- Windows ---------------------------------------------------------------
# Windows tarafı Tulpar'ın AOT satırında zaten `-static -static-libgcc
# -static-libstdc++` ile bağlanıyor; ek bayrak gerekmiyor -> exe her 64-bit
# Windows'ta bagimsiz calisir.
if [ "$DO_WIN" = 1 ]; then
    echo "==> Windows x64 derleniyor..."
    # Varsayilan kurulum yolu; yoksa PATH'e bak. TULPAR_WIN=<yol> ile ezilebilir.
    TULPAR_WIN="${TULPAR_WIN:-${HOME:-/c/Users/User}/AppData/Local/Programs/Tulpar/tulpar.exe}"
    if [ ! -x "$TULPAR_WIN" ]; then
        TULPAR_WIN="$(command -v tulpar.exe || command -v tulpar || true)"
    fi
    if [ -z "$TULPAR_WIN" ] || [ ! -x "$TULPAR_WIN" ]; then
        echo "HATA: Windows Tulpar bulunamadi." >&2
        echo "      TULPAR_WIN=<tulpar.exe yolu> ile belirtin." >&2
        exit 1
    fi
    "$TULPAR_WIN" build src/main.tpr "$DIST/tpr-yt" >/dev/null
    # `tulpar build <out>` Windows'ta .exe sonekini kendi ekler.
    mv -f "$DIST/tpr-yt.exe" "$DIST/tpr-yt-windows-x64.exe"
    echo "    -> dist/tpr-yt-windows-x64.exe"
fi

# --- Linux (statik) --------------------------------------------------------
if [ "$DO_LINUX" = 1 ]; then
    echo "==> Linux x64 derleniyor (statik)..."
    LINUX_FLAGS="-static -lzstd -ljitterentropy -lz"

    if [ "$(uname -s)" = "Linux" ]; then
        TULPAR_LINUX="${TULPAR_LINUX:-tulpar}"
        TULPAR_AOT_LINK_FLAGS="$LINUX_FLAGS" \
            "$TULPAR_LINUX" build src/main.tpr "$DIST/tpr-yt-linux-x64" >/dev/null
    else
        # Windows'tan WSL uzerinden derle.
        WSL_DISTRO="${WSL_DISTRO:-Ubuntu}"
        TULPAR_LINUX="${TULPAR_LINUX:-/home/user/yazilim/Tulpar/tulpar}"
        WPATH="$(wslpath -u "$ROOT" 2>/dev/null || echo "/mnt/c${ROOT#/c}")"
        wsl.exe -d "$WSL_DISTRO" -- bash -lc "
            set -e
            cd '$WPATH'
            touch src/main.tpr
            TULPAR_AOT_LINK_FLAGS='$LINUX_FLAGS' '$TULPAR_LINUX' build src/main.tpr dist/tpr-yt-linux-x64 >/dev/null
            chmod +x dist/tpr-yt-linux-x64
        "
    fi

    # Tasınabilirlik denetimi: dinamik bağlanmış bir ikili sessizce yayına
    # gitmesin (v0.1.0'daki hatanın tekrarı).
    if command -v file >/dev/null 2>&1; then
        if ! file "$DIST/tpr-yt-linux-x64" | grep -q "statically linked"; then
            echo "HATA: Linux ikilisi statik degil — eski dagitimlarda calismaz." >&2
            file "$DIST/tpr-yt-linux-x64" >&2
            exit 1
        fi
    fi
    echo "    -> dist/tpr-yt-linux-x64 (statik)"
fi

# --- Paketler --------------------------------------------------------------
# Arşivlerdeki ikili sade "tpr-yt" / "tpr-yt.exe" adını taşır: güncelleyici
# (src/update.tpr) önce bu adı arar.
echo "==> Arsivler paketleniyor..."
PKG="$DIST/_pkg"

if [ -f "$DIST/tpr-yt-linux-x64" ]; then
    rm -rf "$PKG"; mkdir -p "$PKG"
    cp "$DIST/tpr-yt-linux-x64" "$PKG/tpr-yt"
    chmod +x "$PKG/tpr-yt"
    cp config.default.json README.md "$PKG/"
    tar -czf "$DIST/tpr-yt-linux-x64.tar.gz" -C "$PKG" tpr-yt config.default.json README.md
    echo "    -> dist/tpr-yt-linux-x64.tar.gz"
fi

if [ -f "$DIST/tpr-yt-windows-x64.exe" ]; then
    rm -rf "$PKG"; mkdir -p "$PKG"
    cp "$DIST/tpr-yt-windows-x64.exe" "$PKG/tpr-yt.exe"
    cp config.default.json README.md "$PKG/"
    # zip(1) Git Bash'te yok; sirayla zip -> PowerShell Compress-Archive ->
    # bsdtar (-a zip cikarir) denenir.
    if command -v zip >/dev/null 2>&1; then
        (cd "$PKG" && zip -q "$DIST/tpr-yt-windows-x64.zip" tpr-yt.exe config.default.json README.md)
    elif command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -NoProfile -Command \
            "Compress-Archive -Path '$(cygpath -w "$PKG")\\*' -DestinationPath '$(cygpath -w "$DIST")\\tpr-yt-windows-x64.zip' -Force" >/dev/null
    else
        (cd "$PKG" && tar -a -c -f "$DIST/tpr-yt-windows-x64.zip" tpr-yt.exe config.default.json README.md)
    fi
    echo "    -> dist/tpr-yt-windows-x64.zip"
fi
rm -rf "$PKG"

# --- Sağlamalar ------------------------------------------------------------
# Güncelleyici indirdiği ham ikiliyi bu listeye karşı doğrular.
# `tulpar build` ikilinin yanına ara nesne dosyası (.o) bırakır; yayına
# girmemeli (ve sağlama listesini kirletmemeli).
rm -f "$DIST"/*.o
echo "==> SHA256SUMS.txt uretiliyor..."
(cd "$DIST" && sha256sum tpr-yt-* > SHA256SUMS.txt)
cat "$DIST/SHA256SUMS.txt"

echo
echo "==> Bitti. Yayinlamak icin:"
echo "    gh release create v$VERSION dist/tpr-yt-* dist/SHA256SUMS.txt \\"
echo "      --title 'tpr-yt v$VERSION' --notes-file <notlar.md>"
