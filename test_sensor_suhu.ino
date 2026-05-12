/*
 * TEST SENSOR SUHU DS18B20
 * Pin D1 (GPIO5) ESP8266 NodeMCU
 * 
 * Wiring:
 * DS18B20 VCC  → 3.3V
 * DS18B20 GND  → GND
 * DS18B20 DATA → D1 (GPIO5)
 * Resistor 4.7kΩ antara DATA dan VCC (pull-up)
 * 
 * Fungsi:
 * - Baca suhu setiap 1 detik
 * - Tampilkan di Serial Monitor
 * - Deteksi error sensor
 */

#include <OneWire.h>
#include <DallasTemperature.h>

// Pin Configuration
#define TEMP_SENSOR_PIN D1  // Pin D1 (GPIO5)

// Setup OneWire dan DallasTemperature
OneWire oneWire(TEMP_SENSOR_PIN);
DallasTemperature sensors(&oneWire);

void setup() {
  // Inisialisasi Serial Monitor
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n\n========================================");
  Serial.println("    TEST SENSOR SUHU DS18B20");
  Serial.println("    Pin: D1 (GPIO5)");
  Serial.println("========================================\n");
  
  // Inisialisasi sensor
  sensors.begin();
  
  // Cek jumlah sensor yang terdeteksi
  int deviceCount = sensors.getDeviceCount();
  Serial.print("Jumlah sensor terdeteksi: ");
  Serial.println(deviceCount);
  
  if (deviceCount == 0) {
    Serial.println("\n⚠️  PERINGATAN: Tidak ada sensor DS18B20 terdeteksi!");
    Serial.println("Cek wiring:");
    Serial.println("  - VCC → 3.3V");
    Serial.println("  - GND → GND");
    Serial.println("  - DATA → D1");
    Serial.println("  - Resistor 4.7kΩ antara DATA dan VCC\n");
  } else {
    Serial.println("✓ Sensor DS18B20 terdeteksi!\n");
  }
  
  Serial.println("Mulai membaca suhu...\n");
  Serial.println("========================================");
}

void loop() {
  // Request temperature dari sensor
  sensors.requestTemperatures();
  
  // Baca suhu dalam Celsius
  float tempC = sensors.getTempCByIndex(0);
  
  // Cek apakah pembacaan valid
  if (tempC == DEVICE_DISCONNECTED_C || tempC < -50 || tempC > 100) {
    // Error: Sensor tidak terbaca
    Serial.println("❌ ERROR: Sensor tidak terbaca!");
    Serial.println("   Kemungkinan:");
    Serial.println("   - Kabel lepas");
    Serial.println("   - Resistor pull-up tidak terpasang");
    Serial.println("   - Sensor rusak");
    Serial.println("   - Pin salah");
  } else {
    // Berhasil membaca suhu
    Serial.print("✓ Suhu: ");
    Serial.print(tempC, 2);  // 2 digit desimal
    Serial.print(" °C  |  ");
    
    // Konversi ke Fahrenheit
    float tempF = tempC * 9.0 / 5.0 + 32.0;
    Serial.print(tempF, 2);
    Serial.print(" °F");
    
    // Indikator suhu
    if (tempC < 15) {
      Serial.print("  ❄️  Dingin");
    } else if (tempC >= 15 && tempC < 25) {
      Serial.print("  🌡️  Sejuk");
    } else if (tempC >= 25 && tempC < 30) {
      Serial.print("  ☀️  Normal");
    } else if (tempC >= 30 && tempC < 35) {
      Serial.print("  🔥 Hangat");
    } else {
      Serial.print("  🔥🔥 Panas");
    }
    
    Serial.println();
  }
  
  // Tunggu 1 detik sebelum pembacaan berikutnya
  delay(1000);
}
