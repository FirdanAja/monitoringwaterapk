# Cara Test Sensor Suhu DS18B20

## ⚠️ PENTING: Pisahkan File ke Folder Berbeda!

Arduino IDE akan menggabungkan semua file `.ino` dalam 1 folder yang sama. Jadi Anda harus pisahkan file test sensor ke folder berbeda.

---

## 📁 Struktur Folder yang Benar

```
C:\Users\Windows 11\Music\
├── test\
│   ├── esp8266_water_monitoring.ino  ← Code lengkap (semua sensor)
│   └── ... (file lainnya)
│
└── test_sensor_suhu\
    └── test_sensor_suhu.ino  ← Code test sensor suhu saja
```

---

## 🚀 Langkah-Langkah Test Sensor Suhu

### **STEP 1: Buat Folder Baru**

1. Buka File Explorer
2. Buat folder baru: `C:\Users\Windows 11\Music\test_sensor_suhu\`

### **STEP 2: Copy File Test Sensor**

1. Copy file `test_sensor_suhu.ino` dari workspace Anda
2. Paste ke folder `test_sensor_suhu\`

### **STEP 3: Buka di Arduino IDE**

1. **Close semua tab** di Arduino IDE (jika ada yang terbuka)
2. Klik **File** → **Open**
3. Browse ke: `C:\Users\Windows 11\Music\test_sensor_suhu\`
4. Pilih file: `test_sensor_suhu.ino`
5. Klik **Open**

### **STEP 4: Verify & Upload**

1. Pastikan board settings sudah benar:
   - **Board**: NodeMCU 1.0 (ESP-12E Module)
   - **Port**: COM port ESP8266 Anda
   - **Upload Speed**: 115200

2. Klik **Verify** (✓) untuk compile
   - Jika ada error library, install:
     - OneWire
     - DallasTemperature

3. Klik **Upload** (→) untuk upload ke ESP8266

### **STEP 5: Buka Serial Monitor**

1. Klik **Tools** → **Serial Monitor**
2. Set baud rate: **115200**
3. Lihat output:

```
========================================
    TEST SENSOR SUHU DS18B20
    Pin: D1 (GPIO5)
========================================

Jumlah sensor terdeteksi: 1
✓ Sensor DS18B20 terdeteksi!

Mulai membaca suhu...

========================================
✓ Suhu: 26.50 °C  |  79.70 °F  ☀️  Normal
✓ Suhu: 26.48 °C  |  79.66 °F  ☀️  Normal
✓ Suhu: 26.52 °C  |  79.74 °F  ☀️  Normal
```

---

## ✅ Jika Sensor Bekerja dengan Baik

Anda akan lihat:
- ✓ Jumlah sensor terdeteksi: **1**
- ✓ Suhu terbaca dan **berubah-ubah**
- ✓ Tidak ada error

**Artinya**: Sensor DS18B20 Anda **SIAP DIPAKAI** untuk code lengkap!

---

## ❌ Jika Sensor Tidak Terbaca

Serial Monitor akan tampil:
```
Jumlah sensor terdeteksi: 0

⚠️  PERINGATAN: Tidak ada sensor DS18B20 terdeteksi!
Cek wiring:
  - VCC → 3.3V
  - GND → GND
  - DATA → D1
  - Resistor 4.7kΩ antara DATA dan VCC

❌ ERROR: Sensor tidak terbaca!
   Kemungkinan:
   - Kabel lepas
   - Resistor pull-up tidak terpasang
   - Sensor rusak
   - Pin salah
```

**Solusi**:
1. ✅ Cek wiring DS18B20:
   - VCC (merah) → 3.3V ESP8266
   - GND (hitam) → GND ESP8266
   - DATA (kuning) → D1 ESP8266

2. ✅ Pastikan resistor 4.7kΩ terpasang antara DATA dan VCC

3. ✅ Coba ganti kabel jumper (mungkin putus)

4. ✅ Coba pin lain (D2, D3, D4) dan ubah di code:
   ```cpp
   #define TEMP_SENSOR_PIN D2  // Ganti ke D2
   ```

---

## 🧪 Test Manual Sensor

Coba pegang sensor DS18B20 dengan tangan:
- Suhu akan **NAIK** dari ~26°C ke ~30°C
- Jika suhu naik, berarti sensor **BEKERJA!** ✅

---

## 🔄 Setelah Test Selesai

### **Jika Sensor Bekerja:**
1. **Close** Arduino IDE
2. **Buka** file `esp8266_water_monitoring.ino` (code lengkap)
3. **Upload** code lengkap ke ESP8266
4. Sensor suhu akan otomatis terbaca dan kirim ke Firebase! 🎉

### **Jika Sensor Tidak Bekerja:**
1. Perbaiki wiring sesuai instruksi di atas
2. Test ulang dengan `test_sensor_suhu.ino`
3. Ulangi sampai sensor terbaca

---

## 📝 Library yang Dibutuhkan

Untuk code test sensor ini, Anda hanya perlu 2 library:
1. ✅ **OneWire** (by Jim Studt, etc.)
2. ✅ **DallasTemperature** (by Miles Burton, etc.)

Install dari: **Tools** → **Manage Libraries...**

---

## 💡 Tips

- Gunakan kabel jumper yang **pendek** (< 30cm) untuk menghindari noise
- Pastikan resistor pull-up **4.7kΩ** terpasang (WAJIB!)
- Jika sensor terlalu panas (>50°C), tunggu dingin dulu
- Jangan colok sensor ke 5V, harus **3.3V**!

---

## 🎯 Kesimpulan

Code test ini untuk:
- ✅ Memastikan sensor DS18B20 bekerja
- ✅ Memastikan wiring sudah benar
- ✅ Memastikan library terinstall
- ✅ Sebelum upload code lengkap

Setelah sensor terbaca dengan baik, Anda bisa lanjut upload code lengkap `esp8266_water_monitoring.ino`!
