/*
 * ============================================================
 * KODE ARDUINO ESP8266 - MONITORING KUALITAS AIR PDAM
 * ------------------------------------------------------------
 * Sensor:
 *   - pH Sensor      -> A0 (via voltage divider)
 *   - Turbidity      -> A0/GPIO (lihat koneksi)
 *   - DS18B20 (Suhu) -> D4 (GPIO 2)
 * Protokol:          MQTT
 * Broker:            IP HP/PC yang menjalankan broker MQTT
 * 
 * Library yang dibutuhkan:
 *   - PubSubClient
 *   - OneWire
 *   - DallasTemperature
 *   - ESP8266WiFi
 *   - ArduinoJson
 * ============================================================
 */

#include <ESP8266WiFi.h>
#include <PubSubClient.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <ArduinoJson.h>

// ============================
// KONFIGURASI WiFi
// ============================
const char* ssid     = "NAMA_WIFI_ANDA";
const char* password = "PASSWORD_WIFI_ANDA";

// ============================
// KONFIGURASI MQTT
// ============================
const char* mqtt_server = "192.168.1.100"; // IP Broker MQTT (HP/PC)
const int   mqtt_port   = 1883;
const char* client_id   = "esp8266_pdam";

// Topic MQTT
const char* TOPIC_ALL         = "pdam/sensor/all";
const char* TOPIC_PH          = "pdam/sensor/ph";
const char* TOPIC_TURBIDITY   = "pdam/sensor/turbidity";
const char* TOPIC_TEMPERATURE = "pdam/sensor/temperature";
const char* TOPIC_STATUS      = "pdam/status";

// ============================
// KONFIGURASI PIN SENSOR
// ============================
#define ONE_WIRE_BUS D4      // DS18B20 Temperature Sensor
#define TURBIDITY_PIN A0     // Turbidity Sensor (Analog)
// pH : Gunakan modul pH dengan output analog -> sambungkan ke A0
//      Karena ESP8266 hanya punya 1 ADC, gunakan multiplexer atau
//      baca bergantian dengan software switch

// ============================
// PIN UNTUK pH (pakai resistor divider ke A0)
// ============================
// Signal pH Module ----- [R1 10kΩ] ----- A0
// Signal pH Module ----- [R2 3.3kΩ] ----- GND
// Pengkondisian sinyal: output pH module ~0-5V, dibagi jadi 0-3.3V

// ============================
// OBJEK SENSOR
// ============================
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature sensors(&oneWire);
WiFiClient espClient;
PubSubClient mqttClient(espClient);

// ============================
// KALIBRASI SENSOR
// ============================
// pH Kalibrasi - sesuaikan berdasarkan buffer pH 4.0, 7.0, 10.0
float pH_slope     = 3.5;    // slope dari kalibrasi
float pH_intercept = 0.0;    // intercept

// Turbidity Kalibrasi
// 0 NTU ~ 4.2V output ~> ADC ~= 856
// 1000 NTU ~ 2.5V output -> ADC ~= 512

// ============================
// TIMING
// ============================
unsigned long lastMsgTime = 0;
const long INTERVAL = 3000; // Kirim setiap 3 detik

// ============================
// FUNGSI SETUP
// ============================
void setup() {
  Serial.begin(115200);
  delay(100);

  Serial.println("\n[PDAM] Monitoring Kualitas Air - ESP8266");
  Serial.println("==========================================");

  // Inisialisasi sensor suhu
  sensors.begin();
  Serial.println("[OK] Sensor DS18B20 siap");

  // Koneksi WiFi
  connectWiFi();

  // Konfigurasi MQTT
  mqttClient.setServer(mqtt_server, mqtt_port);
  mqttClient.setCallback(mqttCallback);

  // Koneksi MQTT
  connectMQTT();

  Serial.println("[READY] Sistem siap mengirim data sensor");
}

// ============================
// FUNGSI LOOP
// ============================
void loop() {
  // Jaga koneksi MQTT
  if (!mqttClient.connected()) {
    connectMQTT();
  }
  mqttClient.loop();

  // Baca dan kirim data sensor setiap INTERVAL
  unsigned long now = millis();
  if (now - lastMsgTime >= INTERVAL) {
    lastMsgTime = now;
    readAndPublishSensors();
  }
}

// ============================
// KONEKSI WiFi
// ============================
void connectWiFi() {
  Serial.printf("[WiFi] Connecting to %s", ssid);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.printf("[WiFi] Connected! IP: %s\n", WiFi.localIP().toString().c_str());
  } else {
    Serial.println("\n[WiFi] GAGAL KONEKSI! Restart...");
    ESP.restart();
  }
}

// ============================
// KONEKSI MQTT
// ============================
void connectMQTT() {
  int attempts = 0;
  while (!mqttClient.connected() && attempts < 5) {
    Serial.printf("[MQTT] Connecting to %s:%d...", mqtt_server, mqtt_port);
    
    if (mqttClient.connect(client_id, nullptr, nullptr, TOPIC_STATUS, 0, true, "offline")) {
      Serial.println(" [OK]");
      mqttClient.publish(TOPIC_STATUS, "online", true);
      Serial.println("[MQTT] Status: online");
    } else {
      Serial.printf(" Failed, rc=%d. Retry in 5s\n", mqttClient.state());
      delay(5000);
      attempts++;
    }
  }
}

// ============================
// CALLBACK MQTT (terima perintah)
// ============================
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.printf("[MQTT] Pesan diterima [%s]: %s\n", topic, message.c_str());
}

// ============================
// BACA SENSOR DAN PUBLISH
// ============================
void readAndPublishSensors() {
  // --- 1. Baca Suhu ---
  sensors.requestTemperatures();
  float temperature = sensors.getTempCByIndex(0);
  
  // Validasi suhu
  if (temperature == DEVICE_DISCONNECTED_C) {
    Serial.println("[ERROR] DS18B20 tidak terdeteksi!");
    temperature = 25.0; // nilai default
  }

  // --- 2. Baca pH ---
  // Baca ADC rata-rata 10 kali untuk stabilitas
  float phVoltage = readAnalogAverage(10) * (3.3 / 1023.0);
  float ph = calculatePH(phVoltage);
  ph = constrain(ph, 0.0, 14.0);

  // --- 3. Baca Turbidity ---
  // Untuk ESP8266 dengan 1 ADC, switch ke turbidity setelah pH
  // Jika pakai multiplexer (CD4051): set channel terlebih dahulu
  // Jika sensor turbidity digital: baca dari pin digital
  float turbidityVoltage = readAnalogAverage(10) * (3.3 / 1023.0);
  float turbidity = calculateTurbidity(turbidityVoltage);
  turbidity = constrain(turbidity, 0.0, 1000.0);

  // --- 4. Print ke Serial ---
  Serial.printf("[DATA] pH=%.2f | Turbidity=%.1f NTU | Suhu=%.1f°C\n",
                ph, turbidity, temperature);

  // --- 5. Publish individual topics ---
  char buffer[20];
  
  snprintf(buffer, sizeof(buffer), "%.2f", ph);
  mqttClient.publish(TOPIC_PH, buffer);
  
  snprintf(buffer, sizeof(buffer), "%.1f", turbidity);
  mqttClient.publish(TOPIC_TURBIDITY, buffer);
  
  snprintf(buffer, sizeof(buffer), "%.1f", temperature);
  mqttClient.publish(TOPIC_TEMPERATURE, buffer);

  // --- 6. Publish JSON ke TOPIC_ALL ---
  StaticJsonDocument<200> doc;
  doc["ph"]          = ph;
  doc["turbidity"]   = turbidity;
  doc["temperature"] = temperature;
  doc["timestamp"]   = millis();
  doc["device"]      = client_id;

  char jsonBuffer[200];
  serializeJson(doc, jsonBuffer);
  mqttClient.publish(TOPIC_ALL, jsonBuffer);

  Serial.printf("[MQTT] Dikirim: %s\n", jsonBuffer);
}

// ============================
// BACA ADC RATA-RATA
// ============================
float readAnalogAverage(int samples) {
  long sum = 0;
  for (int i = 0; i < samples; i++) {
    sum += analogRead(A0);
    delay(10);
  }
  return (float)sum / samples;
}

// ============================
// KALKULASI pH
// ============================
float calculatePH(float voltage) {
  // Formula pH berdasarkan tegangan sensor pH
  // Sesuaikan nilai ini berdasarkan kalibrasi nyata
  // pH 7 biasanya ~2.5V
  // pH 4 biasanya ~3.0V
  // pH 10 biasanya ~2.0V
  
  // Linear interpolation: ph = slope * voltage + intercept
  // Contoh kalibrasi sederhana:
  float ph = 7.0 + ((2.5 - voltage) / 0.18);
  return ph;
}

// ============================
// KALKULASI TURBIDITY
// ============================
float calculateTurbidity(float voltage) {
  // Ini adalah fungsi linear untuk sensor turbidity SEN0189
  // 4.5V = sangat jernih (0 NTU)
  // 2.5V = sangat keruh (~3000 NTU)
  // Sesuaikan berdasarkan sensor yang digunakan
  
  if (voltage >= 4.4) {
    return 0.0; // Sangat jernih
  }
  
  // NTU = (4.4V - voltage) * 1500 NTU/V (perkiraan linear)
  float ntu = (4.4 - voltage) * 1500.0;
  return constrain(ntu, 0.0, 1000.0);
}

/*
 * ============================================================
 * SKEMA KONEKSI HARDWARE
 * ============================================================
 * 
 * ESP8266 (NodeMCU) Pinout:
 * ┌──────────────────────────────────┐
 * │ SENSOR SUHU (DS18B20)            │
 * │   DS18B20 VCC  -> 3.3V           │
 * │   DS18B20 GND  -> GND            │
 * │   DS18B20 DATA -> D4 (GPIO2)     │
 * │   4.7kΩ antara VCC dan DATA      │
 * │                                  │
 * │ SENSOR pH (Modul pH Generic)     │
 * │   Module VCC  -> 5V (Vin NodeMCU)│
 * │   Module GND  -> GND             │
 * │   Module Po   -> Mux Out / A0    │
 * │   (Perlu voltage divider ke 3.3V │
 * │    jika output 0-5V)             │
 * │                                  │
 * │ SENSOR TURBIDITY (SEN0189)       │
 * │   Turbidity VCC -> 5V            │
 * │   Turbidity GND -> GND           │
 * │   Turbidity OUT -> Mux In / A0   │
 * │                                  │
 * │ CATATAN: Karena ESP8266 hanya    │
 * │ punya 1 ADC (A0), gunakan:       │
 * │  1. Multiplexer CD4051 (disarankan)│
 * │  2. Atau baca bergantian dengan  │
 * │     waktu delay yang cukup       │
 * └──────────────────────────────────┘
 * 
 * Konfigurasi MQTT Broker:
 * - Install Mosquitto di PC/laptop
 * - mosquitto -v (untuk start broker)
 * - Pastikan ESP8266 dan HP satu jaringan WiFi
 * - IP broker = IP PC di jaringan lokal
 * ============================================================
 */
