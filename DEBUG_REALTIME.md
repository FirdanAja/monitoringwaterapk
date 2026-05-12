# 🐛 Debug Realtime Connection - Step by Step

## 🎯 **Tujuan:**
Memastikan data dari sensor suhu ESP8266 → Firebase → Aplikasi Flutter secara realtime

---

## ✅ **STEP 1: Cek ESP8266 Kirim Data ke Firebase**

### **1.1 Buka Serial Monitor ESP8266**
```
Arduino IDE → Tools → Serial Monitor
Baud Rate: 115200
```

### **1.2 Harus Muncul:**
```
🔥 ========== FIREBASE SEND ==========
✅ WiFi Connected
✅ Firebase Ready

📤 Sending data to Firebase...
   Path: /monitoring/current
   Temperature: 26.50 °C    ← NILAI REAL DARI SENSOR
   pH: 7.00
   Turbidity: 3.00

✅ SUCCESS! Data sent to Firebase!    ← PENTING!
✅ History data saved
========================================
```

**❌ Jika TIDAK muncul "SUCCESS":**
- ESP8266 belum terhubung ke Firebase
- Cek WiFi connection
- Cek Firebase Rules

---

## ✅ **STEP 2: Cek Data di Firebase Console**

### **2.1 Buka Firebase Console**
```
https://console.firebase.google.com/
→ Pilih project: monitoring-air-pdam-8d0a8
→ Klik: Realtime Database
```

### **2.2 Cek Node monitoring/current**
```
monitoring/
  └── current/
      ├── ph: 7
      ├── turbidity: 3
      ├── temperature: 26.5    ← HARUS BERUBAH SETIAP 3 DETIK!
      ├── quality_score: 75.5
      ├── status: "Layak Minum"
      ├── fuzzy_result: "Air sangat baik..."
      └── timestamp: 1746633600000
```

### **2.3 Test Perubahan:**
1. **Lihat nilai temperature**
2. **Tunggu 3 detik**
3. **Nilai harus berkedip kuning** (artinya berubah)
4. **Pegang sensor dengan tangan** → Suhu naik
5. **Lihat di Firebase** → Nilai temperature naik

**❌ Jika data TIDAK berubah:**
- ESP8266 tidak mengirim data
- Cek Serial Monitor ESP8266
- Cek Firebase Rules (harus `.write: true`)

---

## ✅ **STEP 3: Cek Aplikasi Flutter Menerima Data**

### **3.1 Jalankan Aplikasi dengan Log**
```bash
# Stop aplikasi jika sedang running
# Lalu jalankan dengan command:
flutter run
```

### **3.2 Lihat Log di Terminal**

**✅ KONEKSI BERHASIL - Harus muncul:**
```
🔥 Starting Firebase Stream...
📍 Listening to: monitoring/current

📥 Firebase Data Received!
✅ Data is NOT null
📊 Raw Data from Firebase:
   pH: 7.0
   Turbidity: 3.0
   Temperature: 26.5
   Status: Layak Minum
✅ Parsed Values:
   pH: 7.0
   Turbidity: 3.0
   Temperature: 26.5 °C
✅ SensorData created, calling _onSensorDataReceived...
📲 _onSensorDataReceived called
   Temperature: 26.5 °C
   pH: 7.0
   Turbidity: 3.0
🔔 Calling notifyListeners()...
✅ notifyListeners() called - UI should rebuild!
```

**❌ KONEKSI GAGAL - Jika muncul:**
```
⚠️  Data is NULL - No data in Firebase!
```
Artinya: Firebase kosong, ESP8266 belum kirim data

**❌ Jika muncul:**
```
❌ Firebase Stream Error: [error message]
```
Artinya: Ada masalah koneksi Firebase

**❌ Jika TIDAK ADA LOG sama sekali:**
Artinya: Firebase stream tidak jalan

---

## ✅ **STEP 4: Cek UI Aplikasi**

### **4.1 Buka Tab "Beranda"**

### **4.2 Lihat Card Sensor:**
- **Card "pH Level"** → Harus ada nilai (7.0)
- **Card "Kekeruhan"** → Harus ada nilai (3.0 NTU)
- **Card "Suhu Air"** → Harus ada nilai REAL dari sensor (26.5°C)

### **4.3 Test Realtime:**
1. **Pegang sensor suhu** dengan tangan
2. **Tunggu 3 detik**
3. **Lihat card "Suhu Air"** → Nilai harus naik ke ~32-35°C
4. **Lepas sensor**
5. **Tunggu 3 detik**
6. **Nilai harus turun** kembali

**✅ Jika nilai berubah:** REALTIME BERHASIL! 🎉

**❌ Jika nilai TIDAK berubah:**
- Lanjut ke troubleshooting

---

## 🔧 **TROUBLESHOOTING:**

### **Problem 1: ESP8266 Kirim Data, tapi Firebase Kosong**

**Cek Firebase Rules:**
```json
{
  "rules": {
    "monitoring": {
      ".read": true,
      ".write": true    ← HARUS TRUE!
    }
  }
}
```

**Cara Set Rules:**
1. Firebase Console → Realtime Database → Rules
2. Copy paste rules di atas
3. Klik **Publish**

---

### **Problem 2: Firebase Ada Data, tapi Aplikasi Tidak Update**

**Solusi A: Restart Aplikasi**
```bash
# Stop aplikasi (Ctrl+C di terminal)
# Jalankan ulang:
flutter run
```

**Solusi B: Hot Restart**
```bash
# Saat aplikasi running, tekan:
R (capital R)
```

**Solusi C: Cek Internet HP**
- Pastikan HP terhubung ke internet
- Test buka browser di HP

**Solusi D: Clear Cache**
```bash
flutter clean
flutter pub get
flutter run
```

---

### **Problem 3: Log Menampilkan "Data is NULL"**

**Artinya:** Node `monitoring/current` kosong di Firebase

**Solusi:**
1. **Cek ESP8266 Serial Monitor** → Harus ada "SUCCESS!"
2. **Cek Firebase Console** → Harus ada data di `monitoring/current`
3. **Jika Firebase kosong:**
   - Upload ulang kode ESP8266
   - Atau import JSON manual (gunakan `firebase_import_simple.json`)

**Cara Import JSON Manual:**
1. Buka Firebase Console → Realtime Database
2. Klik ⋮ (3 titik) → Import JSON
3. Upload file: `firebase_import_simple.json`
4. Klik Import
5. Restart aplikasi Flutter

---

### **Problem 4: Aplikasi Crash atau Error**

**Cek Log Error:**
```bash
flutter logs
```

**Error Umum:**

**A. "Permission denied"**
```
Solusi: Cek Firebase Rules, set .read: true
```

**B. "Failed to connect"**
```
Solusi: Cek internet HP, restart aplikasi
```

**C. "Type cast error"**
```
Solusi: Format data Firebase salah, import ulang JSON
```

---

## 🧪 **TEST LENGKAP:**

### **Test 1: ESP8266 → Firebase**
```
✅ Serial Monitor: "✅ SUCCESS! Data sent to Firebase!"
✅ Firebase Console: Data muncul di monitoring/current
✅ Firebase Console: Nilai temperature berubah setiap 3 detik
```

### **Test 2: Firebase → Aplikasi Flutter**
```
✅ Flutter Log: "📥 Firebase Data Received!"
✅ Flutter Log: "✅ notifyListeners() called"
✅ Aplikasi: Card "Suhu Air" menampilkan nilai
```

### **Test 3: Realtime Update**
```
✅ Pegang sensor → Suhu naik di Serial Monitor
✅ Tunggu 3 detik → Suhu naik di Firebase Console
✅ Tunggu 3 detik → Suhu naik di Aplikasi Flutter
```

---

## 📊 **Diagram Alur Data:**

```
Sensor DS18B20
    ↓ (baca suhu)
ESP8266
    ↓ (kirim via WiFi)
Firebase Realtime Database
    ↓ (stream realtime)
Aplikasi Flutter
    ↓ (tampilkan di UI)
User melihat data realtime! ✅
```

---

## 🎯 **Checklist Akhir:**

Jika semua ini ✅, maka REALTIME BERHASIL:

- [ ] Serial Monitor: ✅ SUCCESS! Data sent to Firebase!
- [ ] Firebase Console: Data ada di monitoring/current
- [ ] Firebase Console: Nilai berubah setiap 3 detik (berkedip)
- [ ] Flutter Log: 📥 Firebase Data Received!
- [ ] Flutter Log: ✅ notifyListeners() called
- [ ] Aplikasi: Card sensor menampilkan data
- [ ] Aplikasi: Nilai update otomatis setiap 3 detik
- [ ] Test: Pegang sensor → Nilai naik di aplikasi

---

## 📸 **Jika Masih Bermasalah:**

Kirim screenshot dari:
1. **Serial Monitor ESP8266** (full output)
2. **Firebase Console** (node monitoring/current)
3. **Flutter Terminal** (log output)
4. **Aplikasi Flutter** (screenshot dashboard)

Saya akan bantu debug lebih detail! 🚀

---

**Dibuat:** 7 Mei 2026  
**Project:** TirtaSmart - Water Monitoring  
**Version:** 2.0 - With Full Debugging
