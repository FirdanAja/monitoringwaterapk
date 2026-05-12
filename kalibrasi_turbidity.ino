/*
 * KALIBRASI SENSOR KEKERUHAN
 * 
 * Program ini untuk mencari nilai kalibrasi sensor turbidity Anda
 * 
 * Cara Pakai:
 * 1. Upload program ini
 * 2. Celupkan sensor ke AIR BERSIH (aqua/air mineral)
 * 3. Tunggu 10 detik, lihat nilai AVERAGE VOLTAGE
 * 4. Catat nilai tersebut untuk kalibrasi
 */

#define TURB_PIN A0

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n╔════════════════════════════════════════╗");
  Serial.println("║  KALIBRASI SENSOR KEKERUHAN (TURBIDITY) ║");
  Serial.println("╚════════════════════════════════════════╝\n");
  Serial.println("INSTRUKSI:");
  Serial.println("1. Celupkan sensor ke AIR BERSIH (aqua)");
  Serial.println("2. Tunggu 10 detik");
  Serial.println("3. Catat nilai AVERAGE VOLTAGE\n");
  Serial.println("Mulai membaca dalam 3 detik...\n");
  delay(3000);
}

void loop() {
  Serial.println("═══════════════════════════════════════");
  Serial.println("  MEMBACA SENSOR (10 detik)...");
  Serial.println("═══════════════════════════════════════\n");
  
  float totalVoltage = 0;
  int readings = 0;
  
  // Baca sensor selama 10 detik
  for (int second = 1; second <= 10; second++) {
    // Baca ADC (average 10 readings)
    int adc = 0;
    for (int i = 0; i < 10; i++) {
      adc += analogRead(TURB_PIN);
      delay(10);
    }
    adc = adc / 10;
    
    // Convert to voltage
    float voltage = adc * (3.3 / 1023.0);
    totalVoltage += voltage;
    readings++;
    
    // Print per detik
    Serial.print("Detik ");
    Serial.print(second);
    Serial.print(": ADC=");
    Serial.print(adc);
    Serial.print(" → Voltage=");
    Serial.print(voltage, 3);
    Serial.println(" V");
    
    delay(900); // Total 1 detik per loop
  }
  
  // Hitung rata-rata
  float avgVoltage = totalVoltage / readings;
  
  Serial.println("\n═══════════════════════════════════════");
  Serial.println("  HASIL KALIBRASI:");
  Serial.println("═══════════════════════════════════════");
  Serial.print("✅ AVERAGE VOLTAGE: ");
  Serial.print(avgVoltage, 3);
  Serial.println(" V");
  Serial.println("═══════════════════════════════════════\n");
  
  Serial.println("📝 LANGKAH SELANJUTNYA:");
  Serial.println("───────────────────────────────────────");
  Serial.println("1. Catat nilai AVERAGE VOLTAGE di atas");
  Serial.print("   Contoh: ");
  Serial.print(avgVoltage, 3);
  Serial.println(" V");
  Serial.println("\n2. Buka file: test_sensor_simple.ino");
  Serial.println("\n3. Ubah baris 27 menjadi:");
  Serial.print("   float clearVoltage = ");
  Serial.print(avgVoltage, 3);
  Serial.println(";");
  Serial.println("\n4. Upload ulang test_sensor_simple.ino");
  Serial.println("───────────────────────────────────────\n");
  
  Serial.println("Tekan RESET untuk kalibrasi ulang\n");
  Serial.println("Menunggu 30 detik sebelum membaca lagi...\n");
  
  delay(30000); // Tunggu 30 detik sebelum loop lagi
}
