/*
 * ============================================================
 * KODE ARDUINO ESP8266 - MONITORING KUALITAS AIR PDAM
 * ------------------------------------------------------------
 * Sensor:
 *   - pH Sensor      -> A0 (via voltage divider)
 *   - Turbidity      -> A0/GPIO (lihat koneksi)
 *   - DS18B20 (Suhu) -> D4 (GPIO 2)
 * Protokol:          Firebase Realtime Database
 * 
 * Library yang dibutuhkan:
 *   - Firebase ESP Client (terbaru) oleh Mobizt
 *   - OneWire
 *   - DallasTemperature
 *   - ESP8266WiFi
 * ============================================================
 */

#include <ESP8266WiFi.h>
#include <Firebase_ESP_Client.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// Menyediakan token dan RTDB Helper
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// ============================
// KONFIGURASI WiFi & FIREBASE
// ============================
#define WIFI_SSID "NAMA_WIFI_ANDA"
#define WIFI_PASSWORD "PASSWORD_WIFI_ANDA"

#define API_KEY "API_KEY_FIREBASE_ANDA"
#define DATABASE_URL "URL_DATABASE_FIREBASE_ANDA"

// Objek Firebase
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
bool signupOK = false;

// ============================
// KONFIGURASI PIN SENSOR
// ============================
#define ONE_WIRE_BUS D4      // DS18B20 Temperature Sensor
// pH dan Turbidity di A0

OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);

// TIMING
unsigned long lastMsgTime = 0;
const long INTERVAL = 5000; // Kirim setiap 5 detik ke Firebase (jangan terlalu cepat)

void setup() {
  Serial.begin(115200);
  delay(100);

  Serial.println("\n[PDAM] Monitoring - ESP8266 (FIREBASE)");
  
  sensors.begin();
  
  // Koneksi WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(500);
  }
  Serial.println("\n[WiFi] Connected!");

  // Konfigurasi Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  // Sign up anonymous untuk akses Firebase
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("[Firebase] SignUp OK");
    signupOK = true;
  } else {
    Serial.printf("[Firebase] SignUp Error: %s\n", config.signer.signupError.message.c_str());
  }

  // Assign callback function untuk auto token generation
  config.token_status_callback = tokenStatusCallback; 

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  // Baca dan kirim data sensor setiap INTERVAL
  if (Firebase.ready() && signupOK && (millis() - lastMsgTime > INTERVAL || lastMsgTime == 0)) {
    lastMsgTime = millis();
    readAndPublishSensors();
  }
}

void readAndPublishSensors() {
  // 1. Suhu
  sensors.requestTemperatures();
  float temperature = sensors.getTempCByIndex(0);
  if (temperature == DEVICE_DISCONNECTED_C) temperature = 25.0; 

  // 2. pH
  float phVoltage = readAnalogAverage(10) * (3.3 / 1023.0);
  float ph = 7.0 + ((2.5 - phVoltage) / 0.18); // Kalkulasi manual
  ph = constrain(ph, 0.0, 14.0);

  // 3. Turbidity
  float turbidityVoltage = readAnalogAverage(10) * (3.3 / 1023.0);
  float turbidity = (4.4 - turbidityVoltage) * 1500.0; // Kalkulasi turbidity SEN0189
  if (turbidityVoltage >= 4.4) turbidity = 0.0;
  turbidity = constrain(turbidity, 0.0, 1000.0);

  Serial.printf("[DATA] pH: %.2f | Turbidity: %.1f NTU | Suhu: %.1f °C\n", ph, turbidity, temperature);

  // Push Data ke Firebase Realtime Database
  String basePath = "pdam/sensor/latest";
  
  // Mengirim objek JSON ke '/latest'
  FirebaseJson json;
  json.set("ph", ph);
  json.set("turbidity", turbidity);
  json.set("temperature", temperature);
  json.set("timestamp", String(millis())); // ESP tidak punya RTC waktu lokal, kita simulasikan

  if (Firebase.RTDB.setJSON(&fbdo, basePath.c_str(), &json)) {
    Serial.println("[Firebase] Data berhasil diupdate (latest)!");
  } else {
    Serial.println("[Firebase] Error: " + fbdo.errorReason());
  }
  
  // (Opsional) Push ke '/history' untuk riwayat jika diperlukan
  // Firebase.RTDB.pushJSON(&fbdo, "pdam/sensor/history", &json);
}

float readAnalogAverage(int samples) {
  long sum = 0;
  for (int i = 0; i < samples; i++) {
    sum += analogRead(A0);
    delay(10);
  }
  return (float)sum / samples;
}
