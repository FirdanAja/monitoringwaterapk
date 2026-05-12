# 📶 WiFiManager Setup Guide - TirtaSmart

## 🎯 Apa itu WiFiManager?

WiFiManager adalah library yang memungkinkan ESP8266 untuk:
- ✅ **Auto-config WiFi** tanpa hardcode SSID/password
- ✅ **Web-based setup** melalui browser
- ✅ **Menyimpan kredensial** WiFi secara otomatis
- ✅ **Reset WiFi** dengan tombol fisik
- ✅ **Fallback AP mode** jika WiFi tidak tersedia

---

## 📚 Instalasi Library

### 1. Buka Arduino IDE
### 2. Install WiFiManager Library
- **Sketch** → **Include Library** → **Manage Libraries**
- Cari: **"WiFiManager"**
- Pilih: **WiFiManager by tzapu**
- Klik: **Install**

### 3. Library Lain yang Diperlukan
Pastikan sudah terinstall:
- ✅ FirebaseESP8266 (by Mobizt)
- ✅ OneWire (by Paul Stoffregen)
- ✅ DallasTemperature (by Miles Burton)
- ✅ NTPClient (by Fabrice Weinberg)

---

## 🚀 Cara Kerja WiFiManager

### First Boot (Belum Ada WiFi Tersimpan):

```
1. ESP8266 boot up
   ↓
2. Tidak menemukan WiFi tersimpan
   ↓
3. Membuat Access Point (AP)
   SSID: "TirtaSmart-Setup"
   Password: "tirtasmart123"
   ↓
4. LED berkedip cepat (config mode)
   ↓
5. User connect ke AP dengan HP/Laptop
   ↓
6. Browser otomatis buka portal config
   (atau manual ke 192.168.4.1)
   ↓
7. User pilih WiFi dan masukkan password
   ↓
8. ESP8266 connect ke WiFi
   ↓
9. Kredensial disimpan ke EEPROM
   ↓
10. LED menyala solid (connected)
```

### Next Boot (Sudah Ada WiFi Tersimpan):

```
1. ESP8266 boot up
   ↓
2. Membaca kredensial dari EEPROM
   ↓
3. Auto-connect ke WiFi tersimpan
   ↓
4. Jika berhasil → LED menyala solid
   ↓
5. Jika gagal → Kembali ke AP mode
```

---

## 📱 Setup WiFi - Step by Step

### Step 1: Upload Kode ke ESP8266
```
1. Buka esp8266_water_monitoring.ino
2. Edit Firebase Host dan Auth
3. Upload ke ESP8266
4. Tunggu sampai selesai
```

### Step 2: First Boot
```
Serial Monitor akan menampilkan:
=================================
TirtaSmart - Water Monitoring
With WiFiManager Auto-Config
=================================

========== WiFi Manager ==========
Connecting to saved WiFi...
No saved WiFi found!
Creating Access Point...
AP Name: TirtaSmart-Setup
AP Password: tirtasmart123
AP IP: 192.168.4.1
Waiting for configuration...
```

### Step 3: Connect ke Access Point
**Dari HP atau Laptop:**
1. Buka WiFi Settings
2. Cari network: **"TirtaSmart-Setup"**
3. Connect dengan password: **"tirtasmart123"**
4. Tunggu sampai connected

### Step 4: Buka Config Portal
**Otomatis:**
- Browser akan otomatis buka portal config

**Manual (jika tidak otomatis):**
- Buka browser
- Ketik: **192.168.4.1**
- Portal config akan muncul

### Step 5: Konfigurasi WiFi
**Di Portal Config:**
1. Klik **"Configure WiFi"**
2. Pilih SSID WiFi Anda dari list
3. Masukkan password WiFi
4. Klik **"Save"**

### Step 6: ESP8266 Connect
```
Serial Monitor akan menampilkan:
✓ WiFi Connected!
SSID: YourWiFiName
IP Address: 192.168.1.100
Signal Strength: -45 dBm
==================================

========== Firebase Setup ==========
✓ Firebase Connected!
====================================

✓ System Ready!
=================================
```

### Step 7: Selesai!
- ESP8266 sekarang connected ke WiFi Anda
- Kredensial tersimpan otomatis
- Next boot akan auto-connect
- Data mulai dikirim ke Firebase

---

## 🔄 Reset WiFi Settings

### Cara 1: Tombol Reset (Hardware)

**Koneksi:**
```
D3 (GPIO0) ──┬──→ Push Button ──→ GND
             │
           [10kΩ]
             │
            3.3V
```

**Cara Pakai:**
1. Tekan dan tahan tombol reset
2. Tunggu 5 detik
3. LED akan berkedip cepat
4. Serial Monitor: "RESET WIFI SETTINGS"
5. ESP8266 restart
6. Kembali ke AP mode

**Serial Monitor Output:**
```
Reset button pressed...
========== RESET WIFI SETTINGS ==========
Clearing saved WiFi credentials...
✓ WiFi settings cleared!
Restarting ESP8266...
=========================================
```

### Cara 2: Upload Ulang Kode

Jika tidak ada tombol reset:
1. Uncomment baris ini di `setup()`:
   ```cpp
   // wifiManager.resetSettings(); // Uncomment untuk reset
   ```
2. Upload kode
3. ESP8266 akan reset WiFi
4. Comment lagi dan upload ulang

### Cara 3: Erase Flash

Menggunakan esptool:
```bash
esptool.py --port COM3 erase_flash
```

---

## 🎨 Kustomisasi WiFiManager

### 1. Ubah Nama Access Point
```cpp
#define AP_NAME "MyDevice-Setup"  // Ganti nama AP
```

### 2. Ubah Password AP
```cpp
#define AP_PASSWORD "mypassword123"  // Min 8 karakter
```

### 3. Ubah Timeout Config Portal
```cpp
#define CONFIG_PORTAL_TIMEOUT 300  // 5 menit (dalam detik)
```

### 4. Custom HTML Style
```cpp
wifiManager.setCustomHeadElement(
  "<style>"
  "body{background:#1a1a2e;color:#16213e;font-family:Arial}"
  ".btn{background:#0f3460;color:#fff}"
  "</style>"
);
```

### 5. Tambah Custom Parameter
```cpp
WiFiManagerParameter custom_firebase_host("firebase", "Firebase Host", "", 100);
wifiManager.addParameter(&custom_firebase_host);
```

---

## 🔍 Monitoring & Debugging

### Serial Monitor Output

**Normal Operation:**
```
========== SENSOR READINGS ==========
pH: 7.30 pH
Turbidity: 3.00 NTU
Temperature: 27.00 °C

========== FUZZY MAMDANI ==========
Sangat Buruk: 0%
Buruk: 0%
Cukup: 66%
Baik: 33%
Sangat Baik: 0%

========== HASIL ANALISIS ==========
Quality Score: 56
Status: Layak Tidak Minum
✓ Data sent to Firebase!
```

**WiFi Disconnected:**
```
WiFi disconnected! Reconnecting...
========== WiFi Manager ==========
Connecting to saved WiFi...
✓ WiFi Connected!
```

**Config Mode:**
```
========== WiFi Manager ==========
Creating Access Point...
AP Name: TirtaSmart-Setup
AP Password: tirtasmart123
AP IP: 192.168.4.1
Waiting for configuration...
```

### LED Indicator

| LED Status | Meaning |
|------------|---------|
| **Berkedip 3x** | Startup |
| **Berkedip cepat** | Config mode (AP) |
| **Menyala solid** | Connected & Running |
| **Berkedip 1x** | Data sent to Firebase |
| **Berkedip 10x** | WiFi reset |
| **Mati** | Error / No power |

---

## 🐛 Troubleshooting

### ❌ Portal config tidak muncul
**Solusi:**
1. Pastikan connected ke AP "TirtaSmart-Setup"
2. Buka browser manual ke: **192.168.4.1**
3. Disable mobile data (jika pakai HP)
4. Coba browser lain (Chrome, Firefox)

### ❌ Tidak bisa connect ke WiFi
**Solusi:**
1. Cek password WiFi benar
2. Pastikan WiFi 2.4GHz (bukan 5GHz)
3. Cek jarak ke router
4. Cek SSID tidak hidden
5. Reset WiFi settings dan coba lagi

### ❌ ESP8266 restart terus
**Solusi:**
1. Cek power supply (min 5V 1A)
2. Cek Serial Monitor untuk error
3. Timeout config portal tercapai (tunggu 3 menit)
4. Upload ulang kode

### ❌ Tombol reset tidak berfungsi
**Solusi:**
1. Cek koneksi D3 ke button
2. Cek pull-up resistor 10kΩ
3. Test button dengan multimeter
4. Pastikan button active LOW

### ❌ Kredensial tidak tersimpan
**Solusi:**
1. Tunggu sampai ESP8266 restart setelah save
2. Jangan cabut power saat saving
3. Cek EEPROM tidak corrupt (erase flash)

---

## 📊 Perbandingan: Hardcode vs WiFiManager

| Fitur | Hardcode | WiFiManager |
|-------|----------|-------------|
| **Setup** | Edit kode | Web portal |
| **Ganti WiFi** | Upload ulang | Portal config |
| **Multiple Device** | Edit per device | Same code |
| **User Friendly** | ❌ Tidak | ✅ Ya |
| **Security** | ❌ Password di kode | ✅ Tersimpan aman |
| **Deployment** | ❌ Sulit | ✅ Mudah |
| **Maintenance** | ❌ Perlu programmer | ✅ User bisa sendiri |

---

## 🎯 Best Practices

### 1. **Gunakan Password AP yang Kuat**
```cpp
#define AP_PASSWORD "TirtaSmart@2026!"  // Min 8 karakter
```

### 2. **Set Timeout yang Wajar**
```cpp
#define CONFIG_PORTAL_TIMEOUT 180  // 3 menit cukup
```

### 3. **Tambahkan LED Indicator**
- User tahu status device tanpa Serial Monitor
- Mudah troubleshooting

### 4. **Tambahkan Reset Button**
- User bisa reset WiFi tanpa programmer
- Penting untuk deployment

### 5. **Test di Berbagai Kondisi**
- WiFi lemah
- WiFi disconnect
- Power loss
- Multiple reconnect

---

## 🔐 Security Tips

### 1. **Jangan Gunakan Default Password**
Ganti password AP dari default:
```cpp
#define AP_PASSWORD "your-secure-password-here"
```

### 2. **Disable AP Setelah Config**
WiFiManager otomatis disable AP setelah connected.

### 3. **Enkripsi Kredensial**
WiFiManager menyimpan kredensial di EEPROM (tidak encrypted).
Untuk security lebih, gunakan SPIFFS dengan enkripsi.

### 4. **Limit Config Portal Timeout**
Jangan set timeout terlalu lama:
```cpp
#define CONFIG_PORTAL_TIMEOUT 180  // Max 3-5 menit
```

---

## 📱 Portal Config Screenshot

**Main Menu:**
```
┌─────────────────────────────┐
│      TirtaSmart Setup       │
├─────────────────────────────┤
│  [Configure WiFi]           │
│  [Info]                     │
│  [Exit]                     │
└─────────────────────────────┘
```

**WiFi List:**
```
┌─────────────────────────────┐
│    Select Your WiFi         │
├─────────────────────────────┤
│  ○ MyHomeWiFi    (-45 dBm)  │
│  ○ OfficeWiFi    (-60 dBm)  │
│  ○ NeighborWiFi  (-75 dBm)  │
├─────────────────────────────┤
│  Password: [____________]   │
│  [Save]  [Cancel]           │
└─────────────────────────────┘
```

---

## 🎉 Keuntungan WiFiManager

✅ **Mudah Deploy** - Tidak perlu edit kode per device  
✅ **User Friendly** - Setup via web browser  
✅ **Auto Reconnect** - Otomatis connect saat boot  
✅ **Fallback Mode** - Kembali ke AP jika WiFi gagal  
✅ **Kredensial Tersimpan** - Tidak perlu setup ulang  
✅ **Reset Mudah** - Via tombol atau kode  
✅ **Production Ready** - Cocok untuk deployment  

---

## 📞 Support

Jika ada masalah:
1. Cek Serial Monitor untuk error detail
2. Test dengan HP/Laptop berbeda
3. Reset WiFi settings dan coba lagi
4. Cek dokumentasi WiFiManager: https://github.com/tzapu/WiFiManager

---

**WiFiManager Setup Complete! 🎉**

**No more hardcoded WiFi credentials!**  
**Easy setup for everyone!**  
**Production ready!**
