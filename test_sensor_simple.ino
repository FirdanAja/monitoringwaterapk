/*
 * Test Sensor Suhu & Kekeruhan - VERSI SEDERHANA
 * 
 * Wiring:
 * DS18B20:      VCC→3.3V, GND→GND, DATA→D1 + Resistor 4.7kΩ
 * Turbidity:    VCC→5V, GND→GND, Signal→A0
 */

#include <OneWire.h>
#include <DallasTemperature.h>

// Pin Configuration
#define TEMP_PIN D1
#define TURB_PIN A0

OneWire oneWire(TEMP_PIN);
DallasTemperature tempSensor(&oneWire);

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  tempSensor.begin();
  
  Serial.println("\n=== TEST SENSOR SUHU & KEKERUHAN ===\n");
}

void loop() {
  // Baca Sensor Suhu
  tempSensor.requestTemperatures();
  float temp = tempSensor.getTempCByIndex(0);
  
  // Baca Sensor Kekeruhan
  int adc = 0;
  for (int i = 0; i < 10; i++) {
    adc += analogRead(TURB_PIN);
    delay(10);
  }
  adc = adc / 10;
  float voltage = adc * (3.3 / 1023.0);
  
  // ⚠️ KALIBRASI: Ubah nilai ini sesuai hasil kalibrasi Anda!
  // Cara: Upload kalibrasi_turbidity.ino, celup ke air bersih, catat voltage
  float clearVoltage = 0.551;  // ← UBAH NILAI INI sesuai hasil kalibrasi!
  
  // Hitung NTU
  float ntu = 0.0;
  if (voltage < clearVoltage) {
    ntu = -1120.4 * voltage * voltage + 5742.3 * voltage - 4352.9;
  }
  ntu = constrain(ntu, 0.0, 3000.0);
  
  // Print Hasil
  Serial.println("─────────────────────────────────");
  
  // Suhu
  Serial.print("🌡️  Suhu: ");
  if (temp == -127.0 || temp == 85.0) {
    Serial.print(temp, 1);
    Serial.println(" °C [ERROR/WARMING UP]");
  } else {
    Serial.print(temp, 1);
    Serial.print(" °C");
    if (temp < 20) Serial.println(" [DINGIN]");
    else if (temp < 30) Serial.println(" [NORMAL]");
    else Serial.println(" [PANAS]");
  }
  
  // Kekeruhan
  Serial.print("💧 Kekeruhan: ");
  Serial.print(ntu, 1);
  Serial.print(" NTU (ADC:");
  Serial.print(adc);
  Serial.print(", V:");
  Serial.print(voltage, 2);
  Serial.print(")");
  if (ntu < 5) Serial.println(" [JERNIH]");
  else if (ntu < 10) Serial.println(" [AGAK KERUH]");
  else Serial.println(" [KERUH]");
  
  Serial.println("─────────────────────────────────\n");
  
  delay(2000); // Update setiap 2 detik
}
