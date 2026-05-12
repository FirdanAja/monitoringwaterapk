# 🧪 Panduan Test Sensor Suhu & Kekeruhan

## 📋 **Hardware yang Dibutuhkan:**

1. ✅ ESP8266 NodeMCU
2. ✅ DS18B20 Temperature Sensor (Sensor Suhu)
3. ✅ Turbidity Sensor (Sensor Kekeruhan)
4. ✅ Resistor 4.7kΩ (untuk DS18B20)
5. ⚠️ Multiplexer CD74HC4067 (opsional, jika pakai)
6. ✅ Kabel jumper
7. ✅ Breadboard

---

## 🔌 **Wiring Diagram:**

### **A. Sensor Suhu (DS18B20):**
```
DS18B20          ESP8266
─────────────────────────
VCC (merah)   →  3.3V
GND (hitam)   →  GND
DATA (kuning) →  D1 (GPIO5)

PENTING: Resistor Pull-up 4.7kΩ
Pasang antara VCC dan DATA
(antara pin merah dan kuning)
```

### **B. Sensor Kekeruhan (Turbidity):**

**Opsi 1: Langsung ke A0 (Tanpa Multiplexer)**
```
Turbidity Sensor    ESP8266
─────────────────────────────
VCC (merah)      →  5V atau 3.3V
GND (hitam)      →  GND
Signal (kuning)  →  A0
```

**Opsi 2: Via Multiplexer CD74HC4067**
```
Turbidity Sensor    Multiplexer
─────────────────────────────────
Signal           →  C1 (Channel 1)

Multiplexer         ESP8266
─────────────────────────────
SIG              →  A0
S0               →  D5 (GPIO14)
S1               →  D6 (GPIO12)
S2               →  D7 (GPIO13)
S3               →  D8 (GPIO15)
VCC              →  3.3V
GND              →  GND
```

---

## 🚀 **Cara Menggunakan:**

### **STEP 1: Konfigurasi Program**

1. **Buka file:** `test_sensor_suhu_kekeruhan.ino`

2. **Set konfigurasi di baris 42:**
   ```cpp
   #define USE_MULTIPLEXER true   // true jika pakai multiplexer
                                   // false jika sensor langsung ke A0
   ```

3. **Jika pakai multiplexer, cek channel di baris 56:**
   ```cpp
   #define TURBIDITY_CHANNEL 1    // Turbidity di channel C1
   ```

---

### **STEP 2: Upload Program**

```bash
1. Buka Arduino IDE
2. Buka file: test_sensor_suhu_kekeruhan.ino
3. Pilih Board: NodeMCU 1.0 (ESP-12E Module)
4. Pilih Port: COM3 (sesuaikan)
5. Klik Upload
6. Tunggu "Done uploading"
```

---

### **STEP 3: Buka Serial Monitor**

```bash
1. Tools → Serial Monitor (Ctrl+Shift+M)
2. Set Baud Rate: 115200
3. Tekan tombol RESET di ESP8266
```

---

### **STEP 4: Lihat Output**

**✅ Output Normal (Kedua Sensor Bekerja):**

```
========================================
   TEST SENSOR SUHU & KEKERUHAN
========================================

✅ Multiplexer pins initialized
✅ DS18B20 initialized

========================================
Mulai membaca sensor setiap 1 detik...
========================================

🔄 ========== READING SENSORS ==========
📡 Reading DS18B20 Temperature Sensor...
   ✅ SUCCESS! Temperature: 26.50 °C
📡 Reading Turbidity Sensor...
   Using Multiplexer Channel: C1
   Raw ADC Value: 512 / 1023 → Voltage: 1.650 V
   ✅ Turbidity: 3.25 NTU → Air JERNIH 💧

========================================
         HASIL PEMBACAAN
========================================
🌡️  Suhu Air: 26.50 °C → NORMAL ✅
💧 Kekeruhan: 3.25 NTU

========================================

📊 STATUS SENSOR:
   DS18B20 (Suhu): ✅ BEKERJA NORMAL
   Turbidity (Kekeruhan): ✅ BEKERJA NORMAL
========================================
```

---

## 🧪 **Test Sensor:**

### **Test 1: Sensor Suhu (DS18B20)**

**Cara Test:**
1. **Lihat nilai suhu** di Serial Monitor
2. **Pegang sensor** dengan tangan Anda
3. **Tunggu 5-10 detik**
4. **Nilai harus NAIK** ke ~32-35°C

**✅ Jika nilai naik:**
- Sensor bekerja dengan baik! ✅

**❌ Jika nilai tidak berubah:**
- Sensor waterproof (lambat responnya)
- Coba celupkan ke air hangat
- Atau tunggu lebih lama (15-20 detik)

---

### **Test 2: Sensor Kekeruhan (Turbidity)**

**Cara Test:**
1. **Siapkan 2 gelas:**
   - Gelas A: Air jernih (aqua)
   - Gelas B: Air keruh (campur sedikit tanah/kopi)

2. **Celupkan sensor ke Gelas A (air jernih):**
   - Nilai harus **rendah** (0-5 NTU)
   - Muncul: "Air SANGAT JERNIH ✨" atau "Air JERNIH 💧"

3. **Celupkan sensor ke Gelas B (air keruh):**
   - Nilai harus **naik** (10-50 NTU atau lebih)
   - Muncul: "Air KERUH 🌫️" atau "Air SANGAT KERUH ❌"

**✅ Jika nilai berubah sesuai kekeruhan air:**
- Sensor bekerja dengan baik! ✅

**❌ Jika nilai tidak berubah:**
- Lihat troubleshooting di bawah

---

## 🐛 **TROUBLESHOOTING:**

### **Problem 1: Sensor Suhu Menampilkan -127.0 atau ERROR**

**Gejala:**
```
❌ ERROR: Sensor not connected!
```

**Penyebab & Solusi:**

**A. Wiring Salah:**
```
Cek koneksi:
✅ VCC (merah)   → 3.3V ESP8266
✅ GND (hitam)   → GND ESP8266
✅ DATA (kuning) → D1 (GPIO5) ESP8266
✅ Resistor 4.7kΩ antara VCC dan DATA
```

**B. Resistor Pull-up Tidak Ada:**
```
Resistor 4.7kΩ WAJIB dipasang!
Tanpa resistor, sensor tidak akan terbaca.

Cara pasang:
- Satu kaki resistor ke VCC (3.3V)
- Kaki lainnya ke DATA (pin kuning sensor)
```

**C. Sensor Rusak:**
```
Coba sensor DS18B20 yang lain
```

---

### **Problem 2: Sensor Suhu Stuck di 85.0°C**

**Gejala:**
```
⚠️  WARNING: Sensor baru dinyalakan (default value)
Temperature: 85.00 °C
```

**Penyebab & Solusi:**

**A. Baru Dinyalakan:**
```
Tunggu 2-3 detik setelah power on
Nilai akan berubah ke suhu real
```

**B. Tetap 85.0 setelah 10 detik:**
```
Sensor rusak atau wiring salah
Cek wiring atau ganti sensor
```

---

### **Problem 3: Sensor Kekeruhan Selalu 0 NTU**

**Gejala:**
```
Turbidity: 0.00 NTU → Air SANGAT JERNIH ✨
(padahal air keruh)
```

**Penyebab & Solusi:**

**A. Sensor Tidak Terendam Air:**
```
Pastikan sensor terendam penuh di air
LED sensor harus menyala
```

**B. Wiring Salah:**
```
Cek koneksi:
✅ VCC → 5V atau 3.3V
✅ GND → GND
✅ Signal → A0 (atau Multiplexer C1)
```

**C. Multiplexer Channel Salah:**
```
Jika pakai multiplexer:
- Pastikan sensor di channel C1
- Cek wiring S0, S1, S2, S3
```

**D. Sensor Rusak:**
```
Test tanpa multiplexer (langsung ke A0)
Jika tetap 0, sensor rusak
```

---

### **Problem 4: Nilai Kekeruhan Tidak Masuk Akal**

**Gejala:**
```
Air jernih tapi nilai 100 NTU
Atau air keruh tapi nilai 0 NTU
```

**Solusi: Kalibrasi Sensor**

**Langkah Kalibrasi:**

1. **Celupkan sensor ke air jernih (aqua)**
2. **Lihat nilai Voltage di Serial Monitor:**
   ```
   Raw ADC Value: 512 / 1023 → Voltage: 1.650 V
   ```
3. **Catat nilai Voltage** (contoh: 1.650 V)
4. **Edit file `test_sensor_suhu_kekeruhan.ino` baris 58:**
   ```cpp
   #define TURBIDITY_CLEAR_VOLTAGE 1.650  // Ganti dengan nilai Anda
   ```
5. **Upload ulang program**
6. **Test lagi** dengan air jernih dan air keruh

---

### **Problem 5: Multiplexer Tidak Bekerja**

**Gejala:**
```
Nilai sensor tidak terbaca atau selalu 0
```

**Solusi:**

**A. Test Tanpa Multiplexer Dulu:**
```
1. Set USE_MULTIPLEXER = false
2. Hubungkan sensor langsung ke A0
3. Upload ulang program
4. Jika sensor bekerja, masalah di multiplexer
```

**B. Cek Wiring Multiplexer:**
```
✅ SIG → A0
✅ S0 → D5 (GPIO14)
✅ S1 → D6 (GPIO12)
✅ S2 → D7 (GPIO13)
✅ S3 → D8 (GPIO15)
✅ VCC → 3.3V
✅ GND → GND
```

**C. Cek Channel:**
```
Pastikan sensor di channel yang benar
Turbidity di C1 (channel 1)
```

---

## 📊 **Interpretasi Hasil:**

### **Suhu Air:**
| Suhu (°C) | Status | Keterangan |
|-----------|--------|------------|
| < 15 | ❄️ Sangat Dingin | Tidak normal untuk air minum |
| 15-20 | 🧊 Dingin | Air dingin, normal |
| 20-30 | ✅ Normal | Suhu ideal air minum |
| 30-35 | 🌡️ Hangat | Agak hangat |
| > 35 | 🔥 Panas | Terlalu panas |

### **Kekeruhan (NTU):**
| NTU | Status | Keterangan |
|-----|--------|------------|
| 0-1 | ✨ Sangat Jernih | Air sangat bersih |
| 1-5 | 💧 Jernih | Air bersih, layak minum |
| 5-10 | ⚠️ Agak Keruh | Perlu perhatian |
| 10-25 | 🌫️ Keruh | Tidak layak minum |
| > 25 | ❌ Sangat Keruh | Sangat kotor |

---

## ✅ **Checklist Test Berhasil:**

- [ ] Program berhasil di-upload
- [ ] Serial Monitor menampilkan output
- [ ] Sensor suhu menampilkan nilai (bukan -127 atau 85)
- [ ] Nilai suhu berubah saat sensor dipegang
- [ ] Sensor kekeruhan menampilkan nilai
- [ ] Nilai kekeruhan berubah saat dicelup ke air jernih vs air keruh
- [ ] Tidak ada error di Serial Monitor

---

## 🎯 **Setelah Test Berhasil:**

Jika kedua sensor sudah bekerja dengan baik:

1. ✅ **Aktifkan sensor di program utama:**
   - Buka: `esp8266_water_monitoring.ino`
   - Ubah baris 50-51:
     ```cpp
     #define USE_REAL_PH_SENSOR false        // pH belum ada
     #define USE_REAL_TURBIDITY_SENSOR true  // ← Ubah jadi true
     #define USE_REAL_TEMP_SENSOR true       // ← Sudah true
     ```

2. ✅ **Upload program utama**

3. ✅ **Data real dari sensor akan dikirim ke Firebase!**

---

## 📸 **Kirim Screenshot:**

Jika ada masalah, kirim screenshot dari:
1. **Serial Monitor** (full output)
2. **Foto wiring** sensor Anda

Saya akan bantu troubleshooting! 🚀

---

**Dibuat:** 7 Mei 2026  
**Project:** TirtaSmart - Water Monitoring  
**File:** test_sensor_suhu_kekeruhan.ino
