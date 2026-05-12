# 🌡️ Testing Sensor Suhu DS18B20

## ✅ **Status Sensor:**
- ✅ **Sensor Suhu (DS18B20):** AKTIF
- ⏳ **Sensor pH:** Belum terpasang (menggunakan dummy value)
- ⏳ **Sensor Turbidity:** Belum terpasang (menggunakan dummy value)

---

## 🔧 **Konfigurasi di ESP8266:**

Di file `esp8266_water_monitoring.ino` baris 50-52:

```cpp
#define USE_REAL_PH_SENSOR false        // ❌ Sensor pH belum ada
#define USE_REAL_TURBIDITY_SENSOR false // ❌ Sensor turbidity belum ada
#define USE_REAL_TEMP_SENSOR true       // ✅ Sensor suhu AKTIF
```

---

## 📊 **Format Data yang Dikirim ke Firebase:**

### **Path Firebase:**
```
/monitoring/current
```

### **Struktur Data:**
```json
{
  "ph": 7.0,                    // ⏳ Dummy (sensor belum ada)
  "turbidity": 3.0,             // ⏳ Dummy (sensor belum ada)
  "temperature": 26.5,          // ✅ REAL dari DS18B20
  "quality_score": 75.5,
  "status": "Layak Minum",
  "fuzzy_result": "Air sangat baik dan aman untuk diminum.",
  "timestamp": 1746633600000
}
```

---

## 🧪 **Cara Testing:**

### **1. Upload Kode ke ESP8266**

```bash
# Di Arduino IDE:
1. Buka file: esp8266_water_monitoring.ino
2. Pilih Board: NodeMCU 1.0 (ESP-12E Module)
3. Pilih Port: COM3 (sesuaikan dengan port Anda)
4. Klik Upload
```

### **2. Monitor Serial (Debugging)**

```bash
# Buka Serial Monitor (Ctrl+Shift+M)
# Set Baud Rate: 115200

# Output yang akan muncul:
=================================
TirtaSmart - Water Monitoring
With WiFiManager Auto-Config
=================================

========== WiFi Manager ==========
Connecting to saved WiFi...
✓ WiFi Connected!
SSID: YourWiFiName
IP Address: 192.168.1.100
Signal Strength: -45 dBm
==================================

========== Firebase Setup ==========
✓ Firebase Anonymous Sign Up OK
✓ Firebase Connected!
====================================

✓ System Ready!
=================================

========== SENSOR READINGS ==========
⚠️  Using DUMMY pH value (sensor not connected)
⚠️  Using DUMMY Turbidity value (sensor not connected)
pH: 7.00 pH
Turbidity: 3.00 NTU
Temperature: 26.50 °C    ← ✅ INI NILAI REAL DARI SENSOR!

========== FUZZY MAMDANI ==========
Sangat Buruk: 0%
Buruk: 0%
Cukup: 0%
Baik: 30%
Sangat Baik: 70%

========== HASIL ANALISIS ==========
Quality Score: 75
Status: Layak Minum
Deskripsi: Air sangat baik dan aman untuk diminum.
=====================================

✓ Data sent to Firebase!
   Temperature: 26.50 °C    ← ✅ KONFIRMASI DATA TERKIRIM
```

### **3. Cek di Firebase Console**

1. Buka: https://console.firebase.google.com/
2. Pilih project: **monitoring-air-pdam-8d0a8**
3. Klik **Realtime Database**
4. Expand: `monitoring` → `current`
5. Lihat nilai **`temperature`** → Harus berubah sesuai sensor!

### **4. Cek di Aplikasi Flutter**

1. Jalankan aplikasi Flutter:
   ```bash
   flutter run
   ```

2. Buka tab **"Beranda"**

3. Lihat card **"Suhu Air"**:
   - Nilai harus **update otomatis** setiap 3 detik
   - Nilai harus **sesuai dengan sensor DS18B20**

---

## 🔥 **Test Sensor Suhu:**

### **Test 1: Suhu Ruangan (Normal)**
- **Cara:** Biarkan sensor di suhu ruangan
- **Expected:** 24-28°C
- **Status:** Normal (hijau)

### **Test 2: Suhu Dingin**
- **Cara:** Pegang sensor dengan tangan yang dingin / es
- **Expected:** < 20°C
- **Status:** Dingin (biru)

### **Test 3: Suhu Panas**
- **Cara:** Pegang sensor dengan tangan / air hangat
- **Expected:** > 30°C
- **Status:** Panas (merah/orange)

### **Test 4: Suhu Air**
- **Cara:** Celupkan sensor ke air
- **Expected:** Sesuai suhu air (biasanya 20-25°C)
- **Status:** Normal

---

## 📱 **Monitoring Realtime:**

### **Di Firebase Console:**
1. Buka node `monitoring/current/temperature`
2. Nilai akan **berkedip** saat berubah
3. Update setiap **3 detik**

### **Di Aplikasi Flutter:**
1. Card "Suhu Air" akan update otomatis
2. Grafik akan menampilkan trend suhu
3. Notifikasi jika suhu abnormal

---

## 🐛 **Troubleshooting:**

### **Problem: Suhu tidak berubah di Firebase**

**Cek 1: Sensor terhubung dengan benar?**
```
DS18B20 Pin:
- VCC (merah)  → 3.3V ESP8266
- GND (hitam)  → GND ESP8266
- DATA (kuning) → D1 (GPIO5) ESP8266
- Resistor 4.7kΩ antara VCC dan DATA
```

**Cek 2: Serial Monitor menampilkan nilai real?**
```bash
# Jika muncul:
Temperature: 26.50 °C    ← ✅ Sensor OK

# Jika muncul:
⚠️  DS18B20 Error! Using dummy value
Temperature: 25.00 °C    ← ❌ Sensor error/tidak terhubung
```

**Cek 3: WiFi dan Firebase terhubung?**
```bash
# Harus muncul:
✓ WiFi Connected!
✓ Firebase Connected!
✓ Data sent to Firebase!
```

### **Problem: Nilai suhu tidak masuk akal (85°C atau -127°C)**

**Solusi:**
- Sensor tidak terhubung dengan benar
- Cek kabel DATA (kuning) ke pin D1
- Cek resistor pull-up 4.7kΩ
- Restart ESP8266

### **Problem: Aplikasi Flutter tidak update**

**Solusi:**
1. Cek koneksi internet HP
2. Restart aplikasi Flutter
3. Cek Firebase Rules (harus `.read: true`)
4. Cek di Firebase Console apakah data masuk

---

## 📊 **Dummy Values (Sensor Belum Ada):**

Saat ini, karena sensor pH dan Turbidity belum terpasang:

| Parameter | Nilai Dummy | Keterangan |
|-----------|-------------|------------|
| pH | 7.0 | Netral (normal) |
| Turbidity | 3.0 NTU | Agak keruh (normal) |
| Temperature | **REAL** | ✅ Dari sensor DS18B20 |

**Nanti setelah sensor pH dan Turbidity terpasang:**
1. Ubah `USE_REAL_PH_SENSOR` menjadi `true`
2. Ubah `USE_REAL_TURBIDITY_SENSOR` menjadi `true`
3. Upload ulang kode ke ESP8266

---

## 🎯 **Next Steps:**

1. ✅ Test sensor suhu (DS18B20)
2. ✅ Pastikan data masuk ke Firebase
3. ✅ Pastikan aplikasi Flutter update otomatis
4. ⏳ Pasang sensor pH
5. ⏳ Pasang sensor Turbidity
6. ⏳ Kalibrasi semua sensor

---

## 📞 **Kontak Support:**

Jika ada masalah:
1. Cek Serial Monitor untuk error messages
2. Cek Firebase Console untuk data
3. Cek aplikasi Flutter untuk update

---

**Dibuat:** 7 Mei 2026  
**Project:** TirtaSmart - Water Monitoring  
**Hardware:** ESP8266 + DS18B20
