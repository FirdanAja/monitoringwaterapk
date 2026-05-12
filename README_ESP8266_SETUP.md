# 🔧 Panduan Setup ESP8266 - TirtaSmart

## 📋 Komponen Hardware

### 1. **Mikrokontroler**
- ESP8266 NodeMCU V3

### 2. **Sensor**
- **pH Sensor** (Analog) - Mengukur keasaman air
- **Turbidity Sensor** (Analog) - Mengukur kekeruhan air
- **DS18B20** (Digital) - Mengukur suhu air

### 3. **Komponen Tambahan**
- Analog Multiplexer (CD4052 atau 74HC4052) - Untuk 2 sensor analog
- Resistor 4.7kΩ (untuk DS18B20 pull-up)
- Breadboard
- Kabel jumper

---

## 🔌 Koneksi Pin

### ESP8266 NodeMCU Pinout:
```
┌─────────────────────────────────┐
│         ESP8266 NodeMCU         │
├─────────────────────────────────┤
│ A0  → Multiplexer Output        │
│ D4  → DS18B20 Data Pin          │
│ D5  → Multiplexer S0            │
│ D6  → Multiplexer S1            │
│ 3V3 → Sensor VCC                │
│ GND → Sensor GND                │
└─────────────────────────────────┘
```

### Multiplexer (CD4052):
```
Channel 0 → pH Sensor Output
Channel 1 → Turbidity Sensor Output
S0 → D5
S1 → D6
COM → A0
VCC → 3.3V
GND → GND
```

### DS18B20 Temperature Sensor:
```
VCC → 3.3V
DATA → D4 (dengan pull-up resistor 4.7kΩ ke 3.3V)
GND → GND
```

### pH Sensor:
```
VCC → 5V (jika ada regulator) atau 3.3V
GND → GND
OUT → Multiplexer Channel 0
```

### Turbidity Sensor:
```
VCC → 5V (jika ada regulator) atau 3.3V
GND → GND
OUT → Multiplexer Channel 1
```

---

## 💻 Software Requirements

### 1. **Arduino IDE**
Download: https://www.arduino.cc/en/software

### 2. **ESP8266 Board Manager**
1. Buka Arduino IDE
2. File → Preferences
3. Additional Board Manager URLs:
   ```
   http://arduino.esp8266.com/stable/package_esp8266com_index.json
   ```
4. Tools → Board → Boards Manager
5. Cari "ESP8266" → Install

### 3. **Library yang Diperlukan**
Install via Library Manager (Sketch → Include Library → Manage Libraries):

- **WiFiManager** (by tzapu) ← **BARU!**
- **FirebaseESP8266** (by Mobizt)
- **OneWire** (by Paul Stoffregen)
- **DallasTemperature** (by Miles Burton)
- **NTPClient** (by Fabrice Weinberg)

---

## ⚙️ Konfigurasi Kode

### 1. **WiFi Configuration (TIDAK PERLU LAGI!)**
✅ **WiFiManager** akan handle setup WiFi otomatis!
- Tidak perlu hardcode SSID/password
- Setup via web browser
- Kredensial tersimpan otomatis

**Opsional - Kustomisasi AP:**
```cpp
#define AP_NAME "TirtaSmart-Setup"      // Nama Access Point
#define AP_PASSWORD "tirtasmart123"     // Password AP (min 8 char)
```

### 2. **Firebase Configuration**
```cpp
#define FIREBASE_HOST "monitoring-air-pdam-8d0a8-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "YOUR_FIREBASE_SECRET"
```

**Cara Mendapatkan Firebase Secret:**
1. Buka Firebase Console: https://console.firebase.google.com/
2. Pilih project: **monitoring-air-pdam-8d0a8**
3. Settings (⚙️) → Project Settings
4. Tab "Service Accounts"
5. Database Secrets → Show → Copy

### 3. **Sensor Calibration**
Sesuaikan nilai kalibrasi di kode:

```cpp
// pH Sensor
#define PH_OFFSET 0.0  // Adjust sesuai kalibrasi

// Turbidity Sensor
#define TURBIDITY_CLEAR_VOLTAGE 2.5  // Voltage saat air jernih
```

**Cara Kalibrasi pH:**
1. Celupkan sensor ke larutan pH 7.0 (buffer solution)
2. Baca nilai pH di Serial Monitor
3. Jika tidak 7.0, adjust `PH_OFFSET`
4. Ulangi sampai akurat

**Cara Kalibrasi Turbidity:**
1. Celupkan sensor ke air jernih (distilled water)
2. Baca voltage di Serial Monitor
3. Set `TURBIDITY_CLEAR_VOLTAGE` sesuai nilai tersebut

---

## 📤 Upload Kode ke ESP8266

### 1. **Buka Arduino IDE**
- File → Open → Pilih `esp8266_water_monitoring.ino`

### 2. **Pilih Board**
- Tools → Board → ESP8266 Boards → NodeMCU 1.0 (ESP-12E Module)

### 3. **Pilih Port**
- Tools → Port → Pilih COM port ESP8266 Anda

### 4. **Upload**
- Klik tombol Upload (→)
- Tunggu sampai "Done uploading"

### 5. **Setup WiFi via WiFiManager**
**First Boot:**
1. ESP8266 akan membuat Access Point
2. SSID: **"TirtaSmart-Setup"**
3. Password: **"tirtasmart123"**
4. Connect ke AP dengan HP/Laptop
5. Browser otomatis buka portal config (atau manual ke **192.168.4.1**)
6. Pilih WiFi Anda dan masukkan password
7. Klik Save
8. ESP8266 akan connect dan menyimpan kredensial

**Next Boot:**
- ESP8266 otomatis connect ke WiFi tersimpan
- Tidak perlu setup lagi!

📖 **Panduan lengkap:** Lihat `WIFI_MANAGER_GUIDE.md`

### 6. **Monitor Serial**
- Tools → Serial Monitor
- Set baud rate: **115200**
- Lihat output data sensor

---

## 🧪 Testing

### 1. **Test Koneksi WiFi**
Serial Monitor akan menampilkan:
```
========== WiFi Manager ==========
Connecting to saved WiFi...
✓ WiFi Connected!
SSID: YourWiFiName
IP Address: 192.168.1.100
Signal Strength: -45 dBm
==================================
```

**Jika First Boot (belum ada WiFi tersimpan):**
```
========== WiFi Manager ==========
No saved WiFi found!
Creating Access Point...
AP Name: TirtaSmart-Setup
AP Password: tirtasmart123
AP IP: 192.168.4.1
Waiting for configuration...
```
→ Connect ke AP dan setup via browser!

### 2. **Test Firebase**
Serial Monitor akan menampilkan:
```
Firebase Connected!
✓ Data sent to Firebase!
```

### 3. **Test Sensor Readings**
Serial Monitor akan menampilkan:
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
Deskripsi: Air cukup bersih untuk kebutuhan MCK...
```

### 4. **Test Firebase Realtime**
1. Buka Firebase Console
2. Realtime Database
3. Lihat data di path `/monitoring/current`
4. Data akan update setiap 3 detik

---

## 🔬 Fuzzy Mamdani Implementation

### 1. **Fuzzifikasi (Input)**
Mengubah nilai crisp menjadi fuzzy membership:

**pH (0-14):**
- Sangat Asam: 0-5.5
- Asam: 5.0-6.5
- Normal: 6.5-8.5
- Basa: 8.0-9.5
- Sangat Basa: 9.0-14.0

**Turbidity (0-20 NTU):**
- Jernih: 0-1.0
- Agak Keruh: 0.5-3.0
- Keruh: 2.5-5.0
- Sangat Keruh: 4.5-20.0

**Temperature (0-50°C):**
- Sangat Dingin: 0-15
- Dingin: 10-20
- Normal: 20-30
- Panas: 28-40
- Sangat Panas: 38-50

### 2. **Inference Rule Base**
27 aturan fuzzy, contoh:
- **Rule 1:** IF pH Normal AND NTU Jernih AND Temp Normal THEN Sangat Baik
- **Rule 2:** IF pH Normal AND NTU Jernih AND Temp Dingin THEN Baik
- **Rule 3:** IF pH Normal AND NTU Agak Keruh AND Temp Normal THEN Baik
- **Rule 4:** IF pH Normal AND NTU Keruh AND Temp Normal THEN Cukup
- dst...

### 3. **Defuzzifikasi (Output)**
Menggunakan **Centroid Method (COG)**:
```
Quality Score = Σ(μi × ci) / Σμi

Dimana:
μi = membership value
ci = centroid value (10, 30, 50, 70, 90)
```

**Output:**
- 75-100: Layak Minum (Sangat Baik/Baik)
- 50-74: Layak Tidak Minum (Cukup)
- 0-49: Tidak Layak Minum (Buruk/Sangat Buruk)

---

## 📊 Struktur Data Firebase

```json
{
  "monitoring": {
    "current": {
      "ph": 7.3,
      "ntu": 3.0,
      "temperature": 27.0,
      "quality_score": 56,
      "status": "Layak Tidak Minum",
      "description": "Air cukup bersih...",
      "timestamp": "2026-05-01 23:28:00",
      "fuzzy": {
        "sangat_buruk": 0,
        "buruk": 0,
        "cukup": 66,
        "baik": 33,
        "sangat_baik": 0
      }
    },
    "history": [
      {
        "time": "2026-05-01 23:28:00",
        "ph": 7.28,
        "ntu": 9.0,
        "temperature": 28.0,
        "score": 40,
        "status": "Tidak Layak Minum"
      }
    ]
  }
}
```

---

## 🐛 Troubleshooting

### ❌ WiFi tidak connect
**Solusi:**
- Cek SSID dan password benar
- Pastikan WiFi 2.4GHz (ESP8266 tidak support 5GHz)
- Cek jarak ke router

### ❌ Firebase error
**Solusi:**
- Cek Firebase Host dan Auth benar
- Pastikan Database Rules allow read/write
- Cek koneksi internet

### ❌ Sensor tidak terbaca
**Solusi:**
- Cek koneksi kabel
- Cek power supply (3.3V atau 5V)
- Cek pin multiplexer
- Test sensor satu per satu

### ❌ Nilai sensor tidak akurat
**Solusi:**
- Lakukan kalibrasi ulang
- Bersihkan sensor (terutama pH dan turbidity)
- Cek voltage reference

### ❌ DS18B20 return -127°C
**Solusi:**
- Cek pull-up resistor 4.7kΩ
- Cek koneksi DATA pin
- Cek power supply

---

## 🔄 Update Aplikasi Flutter

Setelah ESP8266 running, update aplikasi Flutter untuk membaca dari Firebase:

### 1. Edit `sensor_provider.dart`
Uncomment fungsi `_startFirebaseStream()`:

```dart
Future<void> initialize() async {
  // ...
  _startFirebaseStream(); // ← Aktifkan ini
  // _startDummyStream(); // ← Nonaktifkan ini
}
```

### 2. Run Aplikasi
```bash
flutter run
```

### 3. Lihat Data Real-time
Data dari ESP8266 akan muncul di aplikasi secara real-time!

---

## 📈 Monitoring & Maintenance

### Daily Check:
- ✅ Cek koneksi WiFi
- ✅ Cek data masuk ke Firebase
- ✅ Cek aplikasi update real-time

### Weekly Maintenance:
- 🧹 Bersihkan sensor (pH dan turbidity)
- 🔋 Cek power supply
- 📊 Review data history

### Monthly Calibration:
- 🔬 Kalibrasi pH sensor dengan buffer solution
- 💧 Kalibrasi turbidity dengan air jernih
- 🌡️ Verifikasi temperature sensor

---

## 🎯 Next Steps

1. ✅ Upload kode ke ESP8266
2. ✅ Test semua sensor
3. ✅ Verifikasi data di Firebase
4. ✅ Update aplikasi Flutter
5. ✅ Deploy sistem ke lokasi PDAM
6. ✅ Monitor dan maintenance rutin

---

## 📞 Support

Jika ada masalah:
1. Cek Serial Monitor untuk error message
2. Cek Firebase Console untuk data
3. Cek koneksi hardware
4. Review dokumentasi ini

---

**Sistem monitoring kualitas air PDAM siap digunakan! 🎉**

**Hardware:** ESP8266 + 3 Sensors  
**Protocol:** WiFi + Firebase  
**Method:** Fuzzy Mamdani  
**Update Rate:** 3 seconds  
