# 🔍 Cara Mengecek Koneksi ESP8266 ke Firebase

## 📋 **Checklist Koneksi:**

```
☐ ESP8266 terhubung ke WiFi
☐ ESP8266 terhubung ke Firebase
☐ Data terkirim ke Firebase
☐ Data muncul di Firebase Console
☐ Aplikasi Flutter menerima data
```

---

## 🔧 **STEP 1: Cek Koneksi di ESP8266 (Serial Monitor)**

### **1.1 Upload Kode ke ESP8266**

```bash
1. Buka Arduino IDE
2. Buka file: esp8266_water_monitoring.ino
3. Pilih Board: Tools → Board → NodeMCU 1.0 (ESP-12E Module)
4. Pilih Port: Tools → Port → COM3 (sesuaikan dengan port Anda)
5. Klik Upload (ikon panah kanan atas)
6. Tunggu sampai muncul: "Done uploading"
```

### **1.2 Buka Serial Monitor**

```bash
1. Klik Tools → Serial Monitor (atau Ctrl+Shift+M)
2. Set Baud Rate di pojok kanan bawah: 115200
3. Tekan tombol RESET di ESP8266
```

### **1.3 Lihat Output Serial Monitor**

**✅ KONEKSI BERHASIL - Anda akan melihat:**

```
=================================
TirtaSmart - Water Monitoring
With WiFiManager Auto-Config
=================================

========== WiFi Manager ==========
Connecting to saved WiFi...

✓ WiFi Connected!
SSID: NamaWiFiAnda
IP Address: 192.168.1.100
Signal Strength: -45 dBm
==================================

========== Firebase Setup ==========
✓ Firebase Anonymous Sign Up OK
✓ Firebase Connected!
====================================

✓ System Ready!
=================================

========================================
         SENSOR READINGS
========================================
📶 WiFi Status: ✅ CONNECTED
   SSID: NamaWiFiAnda
   IP: 192.168.1.100
   Signal: -45 dBm
----------------------------------------
⚠️  pH: DUMMY VALUE (sensor not connected)
   pH: 7.00 pH
⚠️  Turbidity: DUMMY VALUE (sensor not connected)
   Turbidity: 3.00 NTU
✅ Temperature: REAL VALUE from DS18B20
   Temperature: 26.50 °C
----------------------------------------
         FUZZY ANALYSIS
----------------------------------------
Quality Score: 75/100
Status: Layak Minum
========================================

🔥 ========== FIREBASE SEND ==========
✅ WiFi Connected
✅ Firebase Ready

📤 Sending data to Firebase...
   Path: /monitoring/current
   Temperature: 26.50 °C
   pH: 7.00
   Turbidity: 3.00

✅ SUCCESS! Data sent to Firebase!
   Check Firebase Console:
   https://console.firebase.google.com/project/monitoring-air-pdam-8d0a8/database
✅ History data saved
========================================
```

**❌ KONEKSI GAGAL - Anda akan melihat:**

```
❌ WiFi DISCONNECTED! Cannot send to Firebase.
   Attempting to reconnect...
```

atau

```
✅ WiFi Connected
❌ Firebase NOT READY!
   Reinitializing Firebase...
```

atau

```
❌ FAILED to send data!
   Error: connection timeout
   HTTP Code: -1
```

---

## 🔥 **STEP 2: Cek Data di Firebase Console**

### **2.1 Buka Firebase Console**

```
1. Buka browser (Chrome/Firefox)
2. Kunjungi: https://console.firebase.google.com/
3. Login dengan akun Google Anda
4. Klik project: monitoring-air-pdam-8d0a8
```

### **2.2 Buka Realtime Database**

```
1. Di sidebar kiri, klik: Realtime Database
2. Atau langsung buka:
   https://console.firebase.google.com/project/monitoring-air-pdam-8d0a8/database
```

### **2.3 Cek Data Realtime**

**✅ DATA MASUK - Anda akan melihat:**

```
monitoring/
  └── current/
      ├── ph: 7
      ├── turbidity: 3
      ├── temperature: 26.5    ← ✅ NILAI INI HARUS BERUBAH!
      ├── quality_score: 75.5
      ├── status: "Layak Minum"
      ├── fuzzy_result: "Air sangat baik..."
      └── timestamp: 1746633600000
```

**Cara Cek Perubahan:**
1. Klik node `monitoring` untuk expand
2. Klik node `current` untuk expand
3. Lihat nilai `temperature`
4. **Tunggu 3 detik** → Nilai harus **berkedip/highlight kuning** saat berubah
5. Jika sensor suhu Anda bekerja, nilai akan berubah sesuai suhu real

**❌ DATA TIDAK MASUK - Anda akan melihat:**

```
monitoring/
  (kosong atau tidak ada node current)
```

---

## 📱 **STEP 3: Cek di Aplikasi Flutter**

### **3.1 Jalankan Aplikasi**

```bash
# Di terminal/command prompt:
cd path/to/your/flutter/project
flutter run
```

### **3.2 Lihat Dashboard**

```
1. Buka aplikasi di HP/Emulator
2. Lihat tab "Beranda"
3. Cek card "Suhu Air"
4. Nilai harus update otomatis setiap 3 detik
```

**✅ APLIKASI TERHUBUNG:**
- Card "Suhu Air" menampilkan nilai real
- Nilai berubah setiap 3 detik
- Status koneksi: 🟢 Connected

**❌ APLIKASI TIDAK TERHUBUNG:**
- Card "Suhu Air" tidak ada data
- Status koneksi: 🔴 Disconnected
- Atau aplikasi crash

---

## 🐛 **TROUBLESHOOTING:**

### **Problem 1: WiFi Tidak Connect**

**Gejala:**
```
❌ WiFi DISCONNECTED!
```

**Solusi:**
1. **Reset WiFi credentials:**
   - Tekan dan tahan tombol FLASH di ESP8266 selama 5 detik
   - ESP8266 akan restart dan membuat Access Point
   
2. **Connect ke AP "TirtaSmart-Setup":**
   - Di HP, buka WiFi settings
   - Connect ke: `TirtaSmart-Setup`
   - Password: `tirtasmart123`
   
3. **Setup WiFi:**
   - Browser akan otomatis terbuka ke 192.168.4.1
   - Jika tidak, buka manual: http://192.168.4.1
   - Pilih WiFi Anda dan masukkan password
   - Klik Save
   
4. **ESP8266 akan restart** dan connect ke WiFi Anda

---

### **Problem 2: Firebase Error**

**Gejala:**
```
❌ FAILED to send data!
   Error: connection timeout
   HTTP Code: -1
```

**Solusi:**

**A. Cek Firebase Rules:**
1. Buka Firebase Console
2. Klik Realtime Database → Rules
3. Pastikan rules seperti ini:
   ```json
   {
     "rules": {
       "monitoring": {
         ".read": true,
         ".write": true
       }
     }
   }
   ```
4. Klik **Publish**

**B. Cek API Key dan Database URL:**
1. Buka file `esp8266_water_monitoring.ino`
2. Cek baris 30-31:
   ```cpp
   #define API_KEY "AIzaSyB9MMUBh-YR8uOkhk8hZISWCWLVaRHXttY"
   #define DATABASE_URL "https://monitoring-air-pdam-8d0a8-default-rtdb.firebaseio.com"
   ```
3. Pastikan sesuai dengan project Anda

**C. Restart ESP8266:**
1. Tekan tombol RESET di ESP8266
2. Tunggu sampai connect ulang

---

### **Problem 3: Sensor Suhu Tidak Terbaca**

**Gejala:**
```
⚠️  DS18B20 Error! Using dummy value
Temperature: 25.00 °C
```

**Solusi:**

**A. Cek Wiring:**
```
DS18B20 Pin:
- VCC (merah)   → 3.3V ESP8266
- GND (hitam)   → GND ESP8266
- DATA (kuning) → D1 (GPIO5) ESP8266

Resistor Pull-up:
- 4.7kΩ antara VCC dan DATA
```

**B. Cek Kode:**
1. Buka file `esp8266_water_monitoring.ino`
2. Cek baris 52:
   ```cpp
   #define USE_REAL_TEMP_SENSOR true  // ← Harus true
   ```

**C. Test Sensor:**
1. Upload kode test sederhana:
   ```cpp
   #include <OneWire.h>
   #include <DallasTemperature.h>
   
   #define TEMP_PIN D1
   OneWire oneWire(TEMP_PIN);
   DallasTemperature sensors(&oneWire);
   
   void setup() {
     Serial.begin(115200);
     sensors.begin();
   }
   
   void loop() {
     sensors.requestTemperatures();
     float temp = sensors.getTempCByIndex(0);
     Serial.print("Temperature: ");
     Serial.println(temp);
     delay(1000);
   }
   ```
2. Jika muncul nilai real (bukan -127 atau 85), sensor OK
3. Jika tetap error, ganti sensor DS18B20

---

### **Problem 4: Data Tidak Update di Firebase**

**Gejala:**
- Serial Monitor: ✅ SUCCESS! Data sent to Firebase!
- Firebase Console: Data tidak berubah

**Solusi:**

**A. Refresh Firebase Console:**
1. Tekan F5 atau Ctrl+R di browser
2. Atau close dan buka ulang tab

**B. Cek Timestamp:**
1. Lihat nilai `timestamp` di Firebase
2. Jika tidak berubah, berarti data tidak masuk
3. Cek error di Serial Monitor

**C. Cek Path Firebase:**
1. Pastikan path: `/monitoring/current`
2. Bukan `/monitoring/current/` (dengan slash di akhir)

---

### **Problem 5: Aplikasi Flutter Tidak Update**

**Gejala:**
- Firebase Console: Data berubah ✅
- Aplikasi Flutter: Data tidak update ❌

**Solusi:**

**A. Restart Aplikasi:**
```bash
# Stop aplikasi
flutter run

# Atau hot restart
Tekan R di terminal
```

**B. Cek Koneksi Internet HP:**
1. Pastikan HP terhubung ke internet
2. Test buka browser di HP

**C. Cek Firebase Rules:**
1. Pastikan `.read: true`
2. Publish rules

**D. Cek Log Flutter:**
```bash
flutter logs
```
Lihat apakah ada error Firebase

---

## 📊 **Test Koneksi Lengkap:**

### **Test 1: WiFi Connection**
```
✅ Serial Monitor menampilkan: "✓ WiFi Connected!"
✅ IP Address muncul (contoh: 192.168.1.100)
```

### **Test 2: Firebase Connection**
```
✅ Serial Monitor menampilkan: "✓ Firebase Connected!"
✅ Serial Monitor menampilkan: "✅ SUCCESS! Data sent to Firebase!"
```

### **Test 3: Data di Firebase**
```
✅ Firebase Console menampilkan node: monitoring/current
✅ Nilai temperature berubah setiap 3 detik (berkedip kuning)
```

### **Test 4: Aplikasi Flutter**
```
✅ Aplikasi menampilkan data sensor
✅ Card "Suhu Air" update otomatis
✅ Status: 🟢 Connected
```

---

## 🎯 **Checklist Akhir:**

Jika semua ini ✅, maka koneksi BERHASIL:

- [ ] Serial Monitor: ✅ WiFi Connected
- [ ] Serial Monitor: ✅ Firebase Connected
- [ ] Serial Monitor: ✅ SUCCESS! Data sent to Firebase!
- [ ] Firebase Console: Data muncul di `/monitoring/current`
- [ ] Firebase Console: Nilai `temperature` berubah setiap 3 detik
- [ ] Aplikasi Flutter: Data muncul di dashboard
- [ ] Aplikasi Flutter: Status 🟢 Connected

---

## 📞 **Masih Bermasalah?**

Kirim screenshot dari:
1. Serial Monitor (full output)
2. Firebase Console (node monitoring/current)
3. Aplikasi Flutter (dashboard)

Saya akan bantu debug lebih lanjut! 🚀

---

**Dibuat:** 7 Mei 2026  
**Project:** TirtaSmart - Water Monitoring  
**Version:** 1.0
