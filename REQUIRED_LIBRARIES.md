# Required Arduino Libraries for TirtaSmart ESP8266

## Cara Install Library di Arduino IDE

1. Buka Arduino IDE
2. Klik **Tools** → **Manage Libraries...** (atau tekan Ctrl+Shift+I)
3. Di kotak pencarian, ketik nama library
4. Klik **Install**

---

## Daftar Library yang Harus Diinstall

### 1. **ESP8266 Board Package** (WAJIB)
- **Nama**: ESP8266 by ESP8266 Community
- **Cara Install**:
  1. Buka **File** → **Preferences**
  2. Di "Additional Board Manager URLs", tambahkan:
     ```
     http://arduino.esp8266.com/stable/package_esp8266com_index.json
     ```
  3. Klik **OK**
  4. Buka **Tools** → **Board** → **Boards Manager**
  5. Cari "ESP8266" dan install **esp8266 by ESP8266 Community**
  6. Pilih board: **Tools** → **Board** → **ESP8266 Boards** → **NodeMCU 1.0 (ESP-12E Module)**

---

### 2. **WiFiManager** (WAJIB)
- **Nama**: WiFiManager by tzapu
- **Versi**: 2.0.16-rc.2 atau lebih baru
- **Fungsi**: Auto-config WiFi tanpa hardcode SSID/password
- **Cara Install**: Library Manager → cari "WiFiManager" → install yang by **tzapu**

---

### 3. **Firebase ESP8266 Client** (WAJIB)
- **Nama**: Firebase Arduino Client Library for ESP8266 and ESP32
- **Author**: Mobizt
- **Versi**: 4.3.0 atau lebih baru
- **Fungsi**: Koneksi ke Firebase Realtime Database
- **Cara Install**: 
  1. Library Manager → cari "Firebase ESP8266 Client"
  2. Install yang by **Mobizt** (BUKAN yang by Google)
  3. Library ini sudah include TokenHelper dan RTDBHelper

**PENTING**: Pastikan install library Firebase by **Mobizt**, bukan yang lain!

---

### 4. **OneWire** (WAJIB)
- **Nama**: OneWire by Jim Studt, Tom Pollard, etc.
- **Versi**: 2.3.7 atau lebih baru
- **Fungsi**: Komunikasi dengan sensor DS18B20
- **Cara Install**: Library Manager → cari "OneWire" → install

---

### 5. **DallasTemperature** (WAJIB)
- **Nama**: DallasTemperature by Miles Burton, etc.
- **Versi**: 3.9.0 atau lebih baru
- **Fungsi**: Library untuk sensor suhu DS18B20
- **Cara Install**: Library Manager → cari "DallasTemperature" → install

---

### 6. **NTPClient** (WAJIB)
- **Nama**: NTPClient by Fabrice Weinberg
- **Versi**: 3.2.1 atau lebih baru
- **Fungsi**: Mendapatkan waktu dari internet (timestamp)
- **Cara Install**: Library Manager → cari "NTPClient" → install

---

## Library Bawaan ESP8266 (Tidak Perlu Install)

Library berikut sudah termasuk dalam ESP8266 Board Package:
- **ESP8266WiFi** (sudah ada di ESP8266 core)
- **WiFiUdp** (sudah ada di ESP8266 core)

---

## Verifikasi Library Sudah Terinstall

Setelah install semua library, cek di:
**Sketch** → **Include Library** → Lihat daftar library

Pastikan ada:
- ✅ WiFiManager
- ✅ Firebase ESP8266 Client (by Mobizt)
- ✅ OneWire
- ✅ DallasTemperature
- ✅ NTPClient

---

## Troubleshooting

### Error: "Firebase_ESP8266_Client.h: No such file or directory"
**Solusi**: 
- Uninstall library Firebase yang lama
- Install ulang **Firebase Arduino Client Library for ESP8266 and ESP32** by **Mobizt**
- Restart Arduino IDE

### Error: "WiFiManager.h: No such file or directory"
**Solusi**: 
- Install **WiFiManager by tzapu** versi 2.0.16-rc.2 atau lebih baru
- Restart Arduino IDE

### Error: "OneWire.h: No such file or directory"
**Solusi**: 
- Install **OneWire** dari Library Manager
- Restart Arduino IDE

---

## Setelah Install Semua Library

1. Restart Arduino IDE
2. Buka file `esp8266_water_monitoring.ino`
3. Klik **Verify** (✓) untuk compile
4. Jika tidak ada error, siap upload ke ESP8266!

---

## Board Settings untuk Upload

Sebelum upload, pastikan setting board sudah benar:

```
Tools → Board: "NodeMCU 1.0 (ESP-12E Module)"
Tools → Upload Speed: "115200"
Tools → CPU Frequency: "80 MHz"
Tools → Flash Size: "4MB (FS:2MB OTA:~1019KB)"
Tools → Port: [Pilih COM port ESP8266 Anda]
```

---

## Urutan Install (Recommended)

1. ✅ Install ESP8266 Board Package
2. ✅ Install WiFiManager
3. ✅ Install Firebase ESP8266 Client (by Mobizt)
4. ✅ Install OneWire
5. ✅ Install DallasTemperature
6. ✅ Install NTPClient
7. ✅ Restart Arduino IDE
8. ✅ Compile & Upload!

---

**Catatan**: Jika masih ada error setelah install semua library, coba:
1. Close Arduino IDE
2. Hapus folder cache Arduino di: `C:\Users\[Username]\AppData\Local\Arduino15\`
3. Buka Arduino IDE lagi
4. Install ulang library yang bermasalah
