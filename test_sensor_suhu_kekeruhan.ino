/*
 * Test Sensor Suhu (DS18B20) dan Sensor Kekeruhan (Turbidity)
 * Program ini untuk mengecek apakah sensor bekerja dengan baik
 * 
 * Hardware:
 * - ESP8266 NodeMCU
 * - DS18B20 Temperature Sensor
 * - Turbidity Sensor (Analog)
 * - Multiplexer CD74HC4067 (opsional, jika pakai multiplexer)
 * 
 * Wiring:
 * DS18B20:
 *   - VCC (merah)   → 3.3V
 *   - GND (hitam)   → GND
 *   - DATA (kuning) → D1 (GPIO5)
 *   - Resistor 4.7kΩ antara VCC dan DATA
 * 
 * Turbidity Sensor:
 *   - VCC → 5V (atau 3.3V tergantung sensor)
 *   - GND → GND
 *   - Signal → A0 (jika langsung) atau via Multiplexer C1
 * 
 * Multiplexer CD74HC4067 (jika dipakai):
 *   - SIG → A0
 *   - S0 → D5 (GPIO14)
 *   - S1 → D6 (GPIO12)
 *   - S2 → D7 (GPIO13)
 *   - S3 → D8 (GPIO15)
 *   - VCC → 3.3V
 *   - GND → GND
 */

#include <OneWire.h>
#include <DallasTemperature.h>

// ==================== KONFIGURASI ====================
// Set true jika menggunakan multiplexer, false jika sensor langsung ke A0
#define USE_MULTIPLEXER false  // false = sensor langsung ke A0 (LEBIH SEDERHANA)

// Pin Configuration
#define TEMP_SENSOR_PIN D1      // DS18B20 Temperature Sensor
#define TURBIDITY_PIN A0        // Turbidity Sensor (langsung atau via multiplexer)

// Multiplexer Pins (jika USE_MULTIPLEXER = true)
#define MUX_S0 D5               // GPIO14
#define MUX_S1 D6               // GPIO12
#define MUX_S2 D7               // GPIO13
#define MUX_S3 D8               // GPIO15

// Multiplexer Channel
#define TURBIDITY_CHANNEL 1     // Turbidity Sensor di channel C1

// Turbidity Calibration
#define TURBIDITY_CLEAR_VOLTAGE 2.5   // Voltage saat air jernih
#define TURBIDITY_MAX_NTU 3000.0      // NTU maksimum sensor

// ==================== GLOBAL OBJECTS ====================
OneWire oneWire(TEMP_SENSOR_PIN);
DallasTemperature tempSensor(&oneWire);

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n\n========================================");
  Serial.println("   TEST SENSOR SUHU & KEKERUHAN");
  Serial.println("========================================\n");
  
  // Setup multiplexer pins (jika dipakai)
  if (USE_MULTIPLEXER) {
    pinMode(MUX_S0, OUTPUT);
    pinMode(MUX_S1, OUTPUT);
    pinMode(MUX_S2, OUTPUT);
    pinMode(MUX_S3, OUTPUT);
    Serial.println("✅ Multiplexer pins initialized");
  }
  
  // Setup temperature sensor
  tempSensor.begin();
  Serial.println("✅ DS18B20 initialized");
  
  Serial.println("\n========================================");
  Serial.println("Mulai membaca sensor setiap 1 detik...");
  Serial.println("========================================\n");
}

// ==================== MAIN LOOP ====================
void loop() {
  Serial.println("\n🔄 ========== READING SENSORS ==========");
  
  // Read Temperature Sensor
  float temperature = readTemperatureSensor();
  
  // Read Turbidity Sensor
  float turbidity = readTurbiditySensor();
  
  // Print Results
  printResults(temperature, turbidity);
  
  delay(1000); // Read every 1 second
}

// ==================== SENSOR FUNCTIONS ====================

// Select multiplexer channel
void selectMuxChannel(int channel) {
  if (!USE_MULTIPLEXER) return;
  
  digitalWrite(MUX_S0, (channel & 0x01) ? HIGH : LOW);
  digitalWrite(MUX_S1, (channel & 0x02) ? HIGH : LOW);
  digitalWrite(MUX_S2, (channel & 0x04) ? HIGH : LOW);
  digitalWrite(MUX_S3, (channel & 0x08) ? HIGH : LOW);
  delay(10); // Stabilization delay
}

// Read Temperature Sensor (DS18B20)
float readTemperatureSensor() {
  Serial.println("📡 Reading DS18B20 Temperature Sensor...");
  
  tempSensor.requestTemperatures();
  float temp = tempSensor.getTempCByIndex(0);
  
  // Check if reading is valid
  if (temp == DEVICE_DISCONNECTED_C) {
    Serial.println("   ❌ ERROR: Sensor not connected!");
    Serial.println("   Check wiring:");
    Serial.println("      - VCC (merah)   → 3.3V");
    Serial.println("      - GND (hitam)   → GND");
    Serial.println("      - DATA (kuning) → D1 (GPIO5)");
    Serial.println("      - Resistor 4.7kΩ antara VCC dan DATA");
    return -127.0;
  }
  
  if (temp == 85.0) {
    Serial.println("   ⚠️  WARNING: Sensor baru dinyalakan (default value)");
    Serial.println("   Tunggu 2-3 detik untuk nilai real...");
    return temp;
  }
  
  if (temp < -50 || temp > 100) {
    Serial.println("   ❌ ERROR: Nilai tidak masuk akal!");
    Serial.print("   Raw value: ");
    Serial.println(temp);
    return -127.0;
  }
  
  Serial.print("   ✅ SUCCESS! Temperature: ");
  Serial.print(temp, 2);
  Serial.println(" °C");
  
  return temp;
}

// Read Turbidity Sensor
float readTurbiditySensor() {
  Serial.println("📡 Reading Turbidity Sensor...");
  
  // Select multiplexer channel (jika pakai multiplexer)
  if (USE_MULTIPLEXER) {
    selectMuxChannel(TURBIDITY_CHANNEL);
    Serial.print("   Using Multiplexer Channel: C");
    Serial.println(TURBIDITY_CHANNEL);
  }
  
  // Read analog value (average 10 readings)
  int sensorValue = 0;
  for (int i = 0; i < 10; i++) {
    sensorValue += analogRead(TURBIDITY_PIN);
    delay(10);
  }
  sensorValue = sensorValue / 10;
  
  Serial.print("   Raw ADC Value: ");
  Serial.print(sensorValue);
  Serial.print(" / 1023");
  
  // Convert to voltage (ESP8266 ADC: 0-1023 = 0-3.3V)
  float voltage = sensorValue * (3.3 / 1023.0);
  Serial.print(" → Voltage: ");
  Serial.print(voltage, 3);
  Serial.println(" V");
  
  // Convert voltage to NTU
  float ntu = 0.0;
  
  if (voltage < TURBIDITY_CLEAR_VOLTAGE) {
    // Formula konversi (sesuaikan dengan sensor Anda)
    ntu = -1120.4 * sq(voltage) + 5742.3 * voltage - 4352.9;
  } else {
    ntu = 0.0; // Air sangat jernih
  }
  
  // Constrain NTU to valid range
  ntu = constrain(ntu, 0.0, TURBIDITY_MAX_NTU);
  
  Serial.print("   ✅ Turbidity: ");
  Serial.print(ntu, 2);
  Serial.print(" NTU");
  
  // Interpretasi
  if (ntu < 1.0) {
    Serial.println(" → Air SANGAT JERNIH ✨");
  } else if (ntu < 5.0) {
    Serial.println(" → Air JERNIH 💧");
  } else if (ntu < 10.0) {
    Serial.println(" → Air AGAK KERUH ⚠️");
  } else if (ntu < 25.0) {
    Serial.println(" → Air KERUH 🌫️");
  } else {
    Serial.println(" → Air SANGAT KERUH ❌");
  }
  
  return ntu;
}

// Print Results
void printResults(float temp, float turb) {
  Serial.println("\n========================================");
  Serial.println("         HASIL PEMBACAAN");
  Serial.println("========================================");
  
  // Temperature
  Serial.print("🌡️  Suhu Air: ");
  if (temp == -127.0) {
    Serial.println("ERROR - Sensor tidak terbaca");
  } else if (temp == 85.0) {
    Serial.println("85.0 °C (Nilai default, tunggu...)");
  } else {
    Serial.print(temp, 2);
    Serial.print(" °C");
    
    // Interpretasi suhu
    if (temp < 15.0) {
      Serial.println(" → SANGAT DINGIN ❄️");
    } else if (temp < 20.0) {
      Serial.println(" → DINGIN 🧊");
    } else if (temp < 30.0) {
      Serial.println(" → NORMAL ✅");
    } else if (temp < 35.0) {
      Serial.println(" → HANGAT 🌡️");
    } else {
      Serial.println(" → PANAS 🔥");
    }
  }
  
  // Turbidity
  Serial.print("💧 Kekeruhan: ");
  Serial.print(turb, 2);
  Serial.println(" NTU");
  
  Serial.println("========================================");
  
  // Status Sensor
  Serial.println("\n📊 STATUS SENSOR:");
  
  // Temperature Sensor Status
  Serial.print("   DS18B20 (Suhu): ");
  if (temp == -127.0) {
    Serial.println("❌ ERROR / TIDAK TERHUBUNG");
  } else if (temp == 85.0) {
    Serial.println("⏳ WARMING UP...");
  } else {
    Serial.println("✅ BEKERJA NORMAL");
  }
  
  // Turbidity Sensor Status
  Serial.print("   Turbidity (Kekeruhan): ");
  if (turb >= 0 && turb < TURBIDITY_MAX_NTU) {
    Serial.println("✅ BEKERJA NORMAL");
  } else {
    Serial.println("⚠️  CEK KALIBRASI");
  }
  
  Serial.println("========================================\n");
}

// ==================== TIPS TROUBLESHOOTING ====================
/*
 * TROUBLESHOOTING SENSOR SUHU (DS18B20):
 * 
 * 1. Jika muncul -127.0 atau DEVICE_DISCONNECTED:
 *    - Cek wiring VCC, GND, DATA
 *    - Pastikan resistor pull-up 4.7kΩ terpasang
 *    - Coba ganti sensor DS18B20
 * 
 * 2. Jika nilai stuck di 85.0:
 *    - Tunggu 2-3 detik setelah power on
 *    - Jika tetap 85.0, sensor rusak
 * 
 * 3. Jika nilai tidak berubah saat dipegang:
 *    - Sensor mungkin waterproof (lambat responnya)
 *    - Tunggu 10-15 detik
 *    - Atau celupkan ke air hangat untuk test
 * 
 * TROUBLESHOOTING SENSOR KEKERUHAN (TURBIDITY):
 * 
 * 1. Jika nilai selalu 0 NTU:
 *    - Sensor mungkin tidak terendam air
 *    - Cek wiring VCC, GND, Signal
 *    - Cek apakah LED sensor menyala
 * 
 * 2. Jika nilai tidak masuk akal (terlalu tinggi/rendah):
 *    - Perlu kalibrasi ulang
 *    - Sesuaikan konstanta TURBIDITY_CLEAR_VOLTAGE
 *    - Sesuaikan formula konversi
 * 
 * 3. Cara kalibrasi:
 *    - Celupkan sensor ke air jernih (aqua)
 *    - Catat voltage yang muncul
 *    - Set TURBIDITY_CLEAR_VOLTAGE = voltage tersebut
 * 
 * 4. Jika pakai multiplexer:
 *    - Pastikan channel benar (C1 untuk turbidity)
 *    - Cek wiring multiplexer S0-S3
 *    - Test tanpa multiplexer dulu (langsung ke A0)
 */

