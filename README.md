# tpr-yt

**YouTube oynatma listesi / video → yüksek kaliteli MP3 indirici.**
[TulparLang](https://tulparlang.dev) ile yazıldı. Windows ve Linux'ta çalışır.

Uygulama bir **orkestratör**dür: kullanıcı arayüzünü, oynatma listesi
ayrıştırmayı, ayarları ve akışı TulparLang yönetir; ağır işi (YouTube
çıkarımı + MP3 kodlama) kanıtlanmış `yt-dlp` ve `ffmpeg` araçlarına devreder.

---

## Özellikler

- 🚀 **İlk başlatmada otomatik bağımlılık kurulumu** — eksik `yt-dlp`, `ffmpeg`
  ve `deno` araçlarını `bin/` klasörüne otomatik indirir (yönetici hakkı /
  paket yöneticisi / PATH ayarı gerekmez)
- 🎵 Oynatma listesi **veya** tek video indirme
- 🔊 **Yüksek kaliteli MP3** (varsayılan `--audio-quality 0` ≈ 245–320 kbps VBR)
- 🏷️ Metadata + kapak resmi gömme
- ⏭️ Arşiv tabanlı **atla/devam et** (inen parçalar tekrar inmez)
- 🩺 Başlangıçta bağımlılık denetimi (`doctor`)
- ⚙️ `config.json` ile kalıcı ayarlar + menü içi ayar editörü
- 🎨 Renkli terminal menüsü
- 🖥️ Tek kaynak, Windows + Linux (çapraz-platform yol/komut soyutlaması)
- ⬆️ **Kendini güncelleme** — menüden GitHub'daki son sürümü indirir, SHA256
  ile doğrular ve kendini değiştirir

---

## Kurulum

[**Releases**](https://github.com/hamer1818/tpr-yt/releases/latest) sayfasından
kendi platformunuzun dosyasını indirin — kurulum gerekmez, tek dosya.

| Dosya | Platform |
|---|---|
| `tpr-yt-windows-x64.zip` | Windows 64-bit (binary + config + README) |
| `tpr-yt-linux-x64.tar.gz` | Linux x86-64 (binary + config + README) |
| `tpr-yt-windows-x64.exe` | Yalnız Windows binary |
| `tpr-yt-linux-x64` | Yalnız Linux binary |

```bash
# Linux
tar -xzf tpr-yt-linux-x64.tar.gz && cd tpr-yt* 2>/dev/null || true
chmod +x tpr-yt && ./tpr-yt
```

Windows'ta `tpr-yt-windows-x64.zip` içeriğini bir klasöre çıkarıp
`tpr-yt.exe`'yi çalıştırın.

**Sürüm uyumluluğu:** Her iki ikili de **statik** bağlanır — hiçbir sistem
kütüphanesine bağımlı değildir:

- **Windows:** her 64-bit Windows (DLL gerekmez)
- **Linux:** her x86-64 dağıtım — **glibc 2.17 ve üzeri**. CentOS 7, Debian 10,
  Ubuntu 20.04/22.04/24.04+ üzerinde test edildi.

> `sha256sum -c SHA256SUMS.txt` (Windows: `certutil -hashfile <dosya> SHA256`)
> ile indirdiğiniz dosyayı doğrulayabilirsiniz.

---

## Gereksinimler

Uygulama, çalışma araçlarını (yt-dlp, ffmpeg, deno) **ilk başlatmada otomatik
indirir** — bunları elle kurmanıza gerek yoktur. Otomatik indirme için sistemde
yalnızca şunlar bulunmalıdır (modern Windows 10/11 ve çoğu Linux'ta hazır gelir):

- **curl** — indirme için (Windows 10 1803+ ve Linux'ta yerleşik)
- **tar** — arşiv açma için (Windows 10 17063+ zip'i de açar; Linux'ta tar.xz)
- **python3** (yalnız Linux, `unzip` yoksa deno zip'ini açmak için — çoğu dağıtımda hazır)

Otomatik indirilen araçlar:

| Araç | Neden | Otomatik kaynak |
|---|---|---|
| **yt-dlp** | YouTube çıkarımı + indirme | GitHub Releases (tek binary) |
| **ffmpeg** | MP3 kodlama (yt-dlp altında kullanır) | Statik build (BtbN/johnvansickle) |
| **deno** | Güncel yt-dlp YouTube çıkarımı için JS runtime | GitHub Releases |

Ayrıca uygulamayı **kaynaktan** derlemek/çalıştırmak için
[TulparLang](https://tulparlang.dev) gerekir.

> **Araç çözümü:** Uygulama önce kendi yanındaki `bin/` klasörüne bakar
> (Windows: `bin\yt-dlp.exe`; Linux: `bin/yt-dlp`), yoksa `PATH`'e güvenir.
> Otomatik kurulum araçları `bin/` içine indirir, böylece yönetici hakkı veya
> PATH ayarı gerekmez.
>
> **Otomatik kurulumu kapatmak** için `config.json`'da `"auto_install": false`
> yapın; bu durumda araçları elle `bin/`'e koyabilir veya PATH'e ekleyebilirsiniz
> (Windows: `winget install yt-dlp Gyan.FFmpeg DenoLand.Deno`).

---

## Çalıştırma

Proje kök dizininden:

```bash
# Kaynaktan doğrudan çalıştır (AOT derler + çalıştırır)
tulpar src/main.tpr
```

## Derleme (tek binary)

```bash
# Linux / macOS
tulpar build src/main.tpr tpr-yt
./tpr-yt

# Windows (PowerShell)
tulpar build src\main.tpr tpr-yt
.\tpr-yt.exe
```

> `tulpar build` yalnızca **giriş dosyasının** damgasına bakarak önbelleğe alır;
> sadece bir modülü (ör. `src/ui.tpr`) değiştirdiyseniz bayat ikili üretebilir.
> Derlemeden önce `touch src/main.tpr` yapın.

### Yayın (release) dosyaları

```bash
scripts/build-release.sh            # Windows exe + statik Linux ikilisi
scripts/build-release.sh --linux    # yalnız Linux
```

`dist/` altına ham ikilileri, arşivleri ve `SHA256SUMS.txt`'i üretir.

Linux ikilisi **statik** bağlanır (`TULPAR_AOT_LINK_FLAGS="-static ..."`).
Tulpar'ın AOT bağlama satırı Linux'ta glibc + libssl'i dinamik bağlar; bu da
ikiliyi derleyen makinenin glibc sürümüne çivilerdi (v0.1.0 yalnızca
glibc ≥ 2.38 olan dağıtımlarda çalışıyordu). Statik bağlama bu bağımlılığı
tamamen kaldırır. Derleme için `libjitterentropy3-dev`, `libzstd-dev`,
`zlib1g-dev` gerekir (Ubuntu'nun `libcrypto.a`'sının statik bağlamada açıkça
belirtilmesi gereken bağımlılıkları).

---

## Kullanım

Program interaktif bir menü açar:

```
--- Menu ---
  1) Bagimlilik denetimi (doctor)
  2) URL indir (oynatma listesi veya video)
  3) Ayarlari goster / degistir
  4) Guncellemeleri kontrol et
  0) Cikis
```

- **2**'yi seçin, bir YouTube URL'si yapıştırın. Program metadata çeker,
  parça sayısını/başlıkları gösterir, onay ister, sonra indirir.
- İndirilen MP3'ler `output_dir` (varsayılan `downloads/`) altına yazılır.
- **3** ile çıktı klasörü, kaliteyi ve gömme seçeneklerini değiştirin;
  ayarlar `config.json`'a kaydedilir.
- **4** ile GitHub'daki son sürüme bakar; yenisi varsa onayınızla indirir,
  SHA256 sağlamasını doğrular ve kendini günceller (aşağıya bakın).

---

## Güncelleme

Menüden **4**'ü seçin. Uygulama:

1. GitHub API'den en son yayın etiketini çeker ve kendi sürümüyle karşılaştırır,
2. yeni sürüm varsa onay ister, ikiliyi + `SHA256SUMS.txt`'i indirir,
3. **SHA256 sağlamasını doğrular** (uyuşmazsa güncellemeyi iptal eder),
4. çalışan ikiliyi `.old` uzantısıyla yedekleyip yenisini yerine koyar.

Ardından uygulamayı yeniden başlatın; `.old` yedeği bir sonraki açılışta
otomatik silinir.

> Güncelleyici ikiliyi **çalışma dizininde** `tpr-yt(.exe)` ya da indirdiğiniz
> ham ad (`tpr-yt-linux-x64` / `tpr-yt-windows-x64.exe`) olarak arar; dosyayı
> başka bir ada değiştirdiyseniz güncellemeyi elle yapmanız gerekir.
> Kaynaktan (`tulpar src/main.tpr`) çalıştırırken güncelleme yapılmaz.

---

## Ayarlar (`config.json`)

İlk çalıştırmada `config.default.json` temel alınır; menüden değiştirdiğinizde
`config.json` yazılır. Alanlar:

| Alan | Açıklama | Varsayılan |
|---|---|---|
| `output_dir` | İndirme klasörü | `downloads` |
| `audio_format` | Ses formatı | `mp3` |
| `audio_quality` | `0`=en yüksek VBR, ya da `320`/`256`/`192` | `0` |
| `embed_metadata` | Şarkı adı/sanatçı gömülsün mü | `true` |
| `embed_thumbnail` | Kapak resmi gömülsün mü | `true` |
| `use_archive` | İnen parçaları atla (devam et) | `true` |
| `archive_file` | Arşiv dosyası adı (çıktı klasörü altında) | `archive.txt` |
| `name_template` | yt-dlp çıktı isim şablonu | `%(playlist_index)s - %(title)s.%(ext)s` |
| `concurrency` | Eş zamanlı parça (yt-dlp `-N`) | `1` |

**Sabit 320k CBR** isterseniz `audio_quality`'i `320` yapın.

---

## Mimari

```
tpr-yt/
├── src/
│   ├── main.tpr       # giriş + menü kontrolcüsü (tüm modülleri buradan import eder)
│   ├── version.tpr    # app_version() — sürüm tek kaynak-doğruluk
│   ├── platform.tpr   # OS tespiti, yol ayracı, araç/silme yardımcıları
│   ├── util.tpr       # renkli çıktı, log, string yardımcıları
│   ├── config.tpr     # config yükle/kaydet + JSON yardımcıları
│   ├── installer.tpr  # eksik araçları bin/ klasörüne otomatik indirir
│   ├── ytdlp.tpr      # yt-dlp sarmalayıcı: metadata + indirme komutu
│   ├── download.tpr   # akış: metadata → özet → onay → indir → rapor
│   ├── update.tpr     # GitHub Releases üzerinden kendini güncelleme
│   ├── ui.tpr         # banner, menü, ayar editörü
│   └── deps.tpr       # bağımlılık doctor
├── scripts/
│   └── build-release.sh   # yayın ikilileri + arşivler + SHA256SUMS.txt
├── config.default.json
└── README.md
```

**Köprü mekanizması:** Tulpar'da alt-süreç stdout'unu yakalayan builtin
olmadığından, yt-dlp'nin JSON metadata'sı bir dosyaya yönlendirilir
(`yt-dlp -J ... > ._tpr_meta.json`), sonra `read_file` + `fromJson` ile
okunur. İndirme komutu `sys_run` ile çalıştırılır; yt-dlp'nin ilerleme
çıktısı canlı olarak terminale akar.

---

## Bilinen sınırlamalar

- **Komut satırı argümanı yok:** Tulpar derlenmiş binary'ye argv geçirmez;
  uygulama bu yüzden interaktif + `config.json` tabanlıdır (`tpr-yt <url>`
  desteklenmez).
- **İnce ilerleme çubuğu yok:** yt-dlp'nin kendi canlı çıktısı gösterilir.
- **Unicode başlık gösterimi:** Bazı Latin-dışı başlıklar özet listesinde
  ham kaçış dizisi olarak görünebilir (yalnızca ekran; indirilen dosya adı
  yt-dlp tarafından doğru üretilir).
- **YouTube ToS:** Yalnızca indirme hakkına sahip olduğunuz içerik için
  kullanın.

---

## Lisans

MIT (veya proje sahibinin tercihi).
