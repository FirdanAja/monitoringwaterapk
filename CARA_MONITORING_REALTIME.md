# 📊 Cara Monitoring Data Sensor Realtime di Firebase

## 🔥 **1. Monitoring di Firebase Console (Web Browser)**

### **Langkah-langkah:**

1. **Buka Firebase Console**
   - URL: https://console.firebase.google.com/
   - Login dengan akun Google Anda
   - Pilih project: **"monitoring-air-pdam-8d0a8"**

2. **Masuk ke Realtime Database**
   - Klik menu **"Realtime Database"** di sidebar kiri
   - Atau klik: https://console.firebase.google.com/project/monitoring-air-pdam-8d0a8/database

3. **Lihat Data Realtime**
   ```
   monitoring/
     └── current/          ← Data sensor terkini (UPDATE OTOMATIS)
         ├── ph: 7.2
         ├── turbidity: 2.5
         ├── temperature: 25.3
         ├── timestamp: 1746633600000
         ├── status: "Aman"
         └── quality_score: 85.5
   ```

4. **Tips Monitoring:**
   - ✅ Data yang **berubah** akan **berkedip/highlight** kuning
   - ✅ Expand node `monitoring/current` untuk melihat semua parameter
   - ✅ Biarkan tab browser terbuka untuk monitoring realtime
   - ✅ Refresh otomatis tanpa perlu reload halaman

---

## 📱 **2. Monitoring di Aplikasi Flutter (Android/iOS)**

### **Status Koneksi:**
✅ **Firebase Realtime sudah AKTIF!**

Aplikasi Flutter Anda sekarang akan:
- 🔄 **Membaca data dari Firebase secara realtime**
- 📊 **Update otomatis** saat ESP8266 mengirim data baru
- 🔔 **Mengirim notifikasi** jika kualitas air buruk
- 💾 **Menyimpan history** ke local storage

### **Cara Menggunakan:**

1. **Jalankan Aplikasi Flutter**
   ```bash
   flutter run
   ```

2. **Lihat Dashboard**
   - Buka tab **"Beranda"**
   - Data sensor akan muncul di card:
     - pH Level
     - Turbidity (Kekeruhan)
     - Temperature (Suhu)
     - Status Kualitas Air

3. **Indikator Koneksi**
   - 🟢 **Connected** = Terhubung ke Firebase
   - 🔴 **Disconnected** = Tidak terhubung

---

## 🔧 **3. Testing Koneksi (Manual Update di Firebase)**

### **Cara Test:**

1. **Buka Firebase Console** di browser
2. **Klik node** `monitoring/current/ph`
3. **Edit nilai** (misalnya ubah dari 7.2 ke 8.0)
4. **Klik Save**
5. **Lihat aplikasi Flutter** → Nilai pH akan **update otomatis!**

### **Test Scenario:**

| Parameter | Nilai Test | Expected Result |
|-----------|------------|-----------------|
| ph | 6.0 | Status: Waspada (kuning) |
| ph | 5.5 | Status: Bahaya (merah) + Notifikasi |
| turbidity | 8.0 | Status: Waspada |
| turbidity | 12.0 | Status: Bahaya + Notifikasi |
| temperature | 32.0 | Status: Waspada |

---

## 🤖 **4. Monitoring dari ESP8266 (Hardware)**

### **Struktur Data yang Dikirim ESP8266:**

ESP8266 harus mengirim data ke Firebase dengan format:

```json
{
  "monitoring": {
    "current": {
      "ph": 7.2,
      "turbidity": 2.5,
      "temperature": 25.3,
      "timestamp": 1746633600000,
      "status": "Aman",
      "quality_score": 85.5
    }
  }
}
```

### **Path Firebase:**
```
https://monitoring-air-pdam-8d0a8-default-rtdb.firebaseio.com/monitoring/current
```

---

## 📈 **5. Monitoring History Data**

### **Di Firebase Console:**

1. Expand node `monitoring/history`
2. Setiap entry memiliki key berformat: `YYYY_MM_DD_HH_MM_SS`
3. Contoh:
   ```
   history/
     ├── 2026_05_07_14_30_00/
     ├── 2026_05_07_14_25_00/
     └── 2026_05_07_14_20_00/
   ```

### **Di Aplikasi Flutter:**

1. Buka tab **"Riwayat"**
2. Lihat list semua data historis
3. Filter berdasarkan:
   - Tanggal
   - Status kualitas air
   - Range waktu

---

## 🔒 **6. Database Rules (Keamanan)**

### **Rules Saat Ini (Development):**
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

⚠️ **PERHATIAN:** Rules ini terbuka untuk semua orang!

### **Rules untuk Production (Recommended):**
```json
{
  "rules": {
    "monitoring": {
      "current": {
        ".read": true,
        ".write": "auth != null"
      },
      "history": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    }
  }
}
```

---

## 🐛 **7. Troubleshooting**

### **Problem: Data tidak muncul di aplikasi**

**Solusi:**
1. Cek koneksi internet
2. Cek Firebase Rules (pastikan `.read: true`)
3. Cek di Firebase Console apakah data ada
4. Restart aplikasi Flutter

### **Problem: Data tidak update realtime**

**Solusi:**
1. Pastikan path Firebase benar: `monitoring/current`
2. Cek log error di console:
   ```bash
   flutter logs
   ```
3. Pastikan Firebase initialized di `main.dart`

### **Problem: ESP8266 tidak bisa kirim data**

**Solusi:**
1. Cek WiFi ESP8266
2. Cek Firebase URL di kode ESP8266
3. Cek Firebase Rules (pastikan `.write: true`)
4. Test manual update di Firebase Console dulu

---

## 📊 **8. Monitoring Tools Tambahan**

### **A. Firebase Console (Web)**
- ✅ Realtime monitoring
- ✅ Manual edit data
- ✅ Export data ke JSON
- ✅ Lihat usage & quota

### **B. Aplikasi Flutter**
- ✅ Dashboard visual
- ✅ Grafik trend
- ✅ History data
- ✅ Laporan bulanan
- ✅ Notifikasi push

### **C. Firebase CLI (Terminal)**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Export data
firebase database:get /monitoring --project monitoring-air-pdam-8d0a8

# Import data
firebase database:set /monitoring data.json --project monitoring-air-pdam-8d0a8
```

---

## 🎯 **Next Steps**

1. ✅ Import JSON ke Firebase
2. ✅ Test manual update di Firebase Console
3. ✅ Jalankan aplikasi Flutter dan lihat data update
4. ⏳ Setup ESP8266 untuk kirim data otomatis
5. ⏳ Setup authentication untuk keamanan
6. ⏳ Deploy ke production

---

## 📞 **Support**

Jika ada masalah:
1. Cek dokumentasi Firebase: https://firebase.google.com/docs/database
2. Cek log aplikasi: `flutter logs`
3. Cek Firebase Console untuk error messages

---

**Dibuat:** 7 Mei 2026  
**Project:** Monitoring Kualitas Air PDAM  
**Firebase Project ID:** monitoring-air-pdam-8d0a8
