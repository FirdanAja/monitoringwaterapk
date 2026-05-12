/*
 * TirtaSmart - Water Quality Monitoring System
 * ESP8266 + pH Sensor + Turbidity Sensor + DS18B20 Temperature Sensor
 */

#include <ESP8266WiFi.h>
#include <WiFiManager.h>
#include <FirebaseESP8266.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <NTPClient.h>
#include <WiFiUdp.h>

// ==================== KONFIGURASI WIFI & FIREBASE ====================
#define AP_NAME "TirtaSmart-Setup"
#define AP_PASSWORD "tirtasmart123"
#define API_KEY "AIzaSyAmL-BRRVsXumywqRwOrlTJRXe4JMkarPw" 
#define DATABASE_URL "https://tirtasmart-default-rtdb.asia-southeast1.firebasedatabase.app"

// ==================== PIN CONFIGURATION ====================
#define TEMP_SENSOR_PIN D1
#define MUX_SIG A0
#define MUX_S0 D5
#define MUX_S1 D6
#define MUX_S2 D7
#define MUX_S3 D8
#define LED_PIN D4 // LED Indikator baru

// Multiplexer Channel Assignment
#define PH_CHANNEL 1
#define TURBIDITY_CHANNEL 2

// ==================== SENSOR & CALIBRATION ====================
#define USE_REAL_PH_SENSOR true
#define USE_REAL_TURBIDITY_SENSOR true
#define USE_REAL_TEMP_SENSOR true

// pH Calibration
#define PH_CALIBRATION_VALUE 20.34
#define PH_SLOPE -5.70

// Turbidity Calibration (User's Calibrated Values)
#define NTU_CLEAN_ANALOG 557
#define NTU_DIRTY_ANALOG 500

// Dummy values
#define DUMMY_PH 7.0
#define DUMMY_TURBIDITY 3.0
#define DUMMY_TEMPERATURE 25.0

// ==================== GLOBAL OBJECTS ====================
WiFiManager wifiManager;
FirebaseData firebaseData;
FirebaseAuth auth;
FirebaseConfig config;
OneWire oneWire(TEMP_SENSOR_PIN);
DallasTemperature tempSensor(&oneWire);
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, "pool.ntp.org", 25200, 60000);

// ==================== GLOBAL VARIABLES = [FUZZY VARS FIRST] ====================
float fuzzy_sangat_buruk = 0.0;
float fuzzy_buruk = 0.0;
float fuzzy_cukup = 0.0;
float fuzzy_baik = 0.0;
float fuzzy_sangat_baik = 0.0;

float currentPH = 0.0;
float currentNTU = 0.0;
float currentTemp = 0.0;
float qualityScore = 0.0;
String waterStatus = "";
String waterDescription = "";
unsigned long lastSendTime = 0;
const unsigned long sendInterval = 3000;
unsigned long lastLedToggle = 0;
bool ledState = false;

// ==================== FUZZY LOGIC FUNCTIONS ====================

void fuzzifyPH(float val, float &a, float &n, float &b) {
  if (val <= 6.0) a = 1.0;
  else if (val <= 7.0) a = (7.0 - val) / 1.0;
  else a = 0.0;
  
  if (val <= 6.0 || val >= 9.0) n = 0.0;
  else if (val <= 7.0) n = (val - 6.0) / 1.0;
  else if (val <= 8.0) n = 1.0;
  else if (val <= 9.0) n = (9.0 - val) / 1.0;
  
  if (val <= 8.0) b = 0.0;
  else if (val <= 9.0) b = (val - 8.0) / 1.0;
  else b = 1.0;
}

void fuzzifyTurbidity(float val, float &b, float &ak, float &k) {
  // Bersih: 100% sampai 5.0 NTU (Sesuai script kalibrasi user)
  if (val <= 5.0) b = 1.0;
  else if (val <= 25.0) b = (25.0 - val) / 20.0;
  else b = 0.0;
  
  // Agak Keruh: Puncak di 25.0 NTU
  if (val <= 5.0 || val >= 50.0) ak = 0.0;
  else if (val <= 25.0) ak = (val - 5.0) / 20.0;
  else if (val <= 50.0) ak = (50.0 - val) / 25.0;
  
  // Keruh: Mulai dari 25.0
  if (val <= 25.0) k = 0.0;
  else if (val <= 50.0) k = (val - 25.0) / 25.0;
  else k = 1.0;
}

void fuzzifyTemperature(float val, float &d, float &s, float &t) {
  if (val <= 18.0) d = 1.0;
  else if (val <= 22.0) d = (22.0 - val) / 4.0;
  else d = 0.0;
  
  if (val <= 18.0 || val >= 32.0) s = 0.0;
  else if (val <= 22.0) s = (val - 18.0) / 4.0;
  else if (val <= 28.0) s = 1.0;
  else if (val <= 32.0) s = (32.0 - val) / 4.0;
  
  if (val <= 28.0) t = 0.0;
  else if (val <= 32.0) t = (val - 28.0) / 4.0;
  else t = 1.0;
}

void inferenceRules(float ph_a, float ph_n, float ph_b,
                    float ntu_b, float ntu_ak, float ntu_k,
                    float t_d, float t_s, float t_t) {

  // Reset
  fuzzy_sangat_buruk = 0; fuzzy_buruk = 0; fuzzy_cukup = 0; fuzzy_baik = 0; fuzzy_sangat_baik = 0;

  // --- KATEGORI SANGAT BAIK ---
  // pH Normal + Bersih + Suhu Sedang
  fuzzy_sangat_baik = max(fuzzy_sangat_baik, min(ph_n, min(ntu_b, t_s)));

  // --- KATEGORI BAIK ---
  // pH Normal + Bersih + (Dingin/Tinggi)
  fuzzy_baik = max(fuzzy_baik, min(ph_n, min(ntu_b, t_d)));
  fuzzy_baik = max(fuzzy_baik, min(ph_n, min(ntu_b, t_t)));

  // --- KATEGORI CUKUP (WASPADA) ---
  fuzzy_cukup = max(fuzzy_cukup, min(ph_n, ntu_ak));
  fuzzy_cukup = max(fuzzy_cukup, min(ph_a, ntu_b));
  fuzzy_cukup = max(fuzzy_cukup, min(ph_b, ntu_b));

  // --- KATEGORI BURUK (BAHAYA) ---
  fuzzy_buruk = max(fuzzy_buruk, ntu_k);
  fuzzy_buruk = max(fuzzy_buruk, min(ph_a, ntu_ak));
  fuzzy_buruk = max(fuzzy_buruk, min(ph_b, ntu_ak));

  // --- KATEGORI SANGAT BURUK ---
  float ph_ekstrim = max(ph_a, ph_b);
  fuzzy_sangat_buruk = max(fuzzy_sangat_buruk, min(ph_ekstrim, ntu_k));
  fuzzy_sangat_buruk = max(fuzzy_sangat_buruk, min(ph_ekstrim, t_t));
}

float defuzzification() {
  float num = (fuzzy_sangat_buruk * 10) + (fuzzy_buruk * 30) + (fuzzy_cukup * 50) + (fuzzy_baik * 70) + (fuzzy_sangat_baik * 90);
  float den = fuzzy_sangat_buruk + fuzzy_buruk + fuzzy_cukup + fuzzy_baik + fuzzy_sangat_baik;
  return (den == 0) ? 50.0 : num / den;
}

void applyFuzzyMamdani(float ph, float ntu, float temp) {
  float ph_a, ph_n, ph_b;
  float ntu_b, ntu_ak, ntu_k;
  float t_d, t_s, t_t;

  fuzzifyPH(ph, ph_a, ph_n, ph_b);
  fuzzifyTurbidity(ntu, ntu_b, ntu_ak, ntu_k);
  fuzzifyTemperature(temp, t_d, t_s, t_t);

  inferenceRules(ph_a, ph_n, ph_b, ntu_b, ntu_ak, ntu_k, t_d, t_s, t_t);
  qualityScore = defuzzification();

  if (qualityScore >= 75) {
    waterStatus = "Aman";
    waterDescription = "Kualitas air sangat baik.";
  } else if (qualityScore >= 40) {
    waterStatus = "Waspada";
    waterDescription = "Kualitas air normal.";
  } else {
    waterStatus = "Bahaya";
    waterDescription = "Air kotor/tercemar!";
  }
}

// ==================== SENSOR FUNCTIONS ====================

void selectMuxChannel(int channel) {
  digitalWrite(MUX_S0, (channel & 0x01) ? HIGH : LOW);
  digitalWrite(MUX_S1, (channel & 0x02) ? HIGH : LOW);
  digitalWrite(MUX_S2, (channel & 0x04) ? HIGH : LOW);
  digitalWrite(MUX_S3, (channel & 0x08) ? HIGH : LOW);
  delay(20); // Sesuai script kalibrasi user
}

float readPHSensor() {
  if (!USE_REAL_PH_SENSOR) return DUMMY_PH;
  selectMuxChannel(PH_CHANNEL);
  int buffer_arr[10];
  for (int i = 0; i < 10; i++) {
    buffer_arr[i] = analogRead(MUX_SIG);
    delay(30);
  }
  for (int i = 0; i < 9; i++) {
    for (int j = i + 1; j < 10; j++) {
      if (buffer_arr[i] > buffer_arr[j]) {
        int temp = buffer_arr[i];
        buffer_arr[i] = buffer_arr[j];
        buffer_arr[j] = temp;
      }
    }
  }
  unsigned long avgval = 0;
  for (int i = 2; i < 8; i++) avgval += buffer_arr[i];
  float voltage = (avgval / 6.0) * (3.3 / 1023.0);
  float ph = (PH_SLOPE * voltage) + PH_CALIBRATION_VALUE;
  return constrain(ph, 0.0, 14.0);
}

float mapFloat(float x, float in_min, float in_max, float out_min, float out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

float readTurbiditySensor() {
  if (!USE_REAL_TURBIDITY_SENSOR) return DUMMY_TURBIDITY;
  selectMuxChannel(TURBIDITY_CHANNEL);
  
  // Sampling lebih banyak untuk stabilitas
  long total = 0;
  for (int i = 0; i < 50; i++) {
    total += analogRead(MUX_SIG);
    delay(5);
  }
  float avgAnalog = total / 50.0;
  
  // Menggunakan mapFloat agar lebih presisi dan tidak loncat-loncat
  float ntu = mapFloat(avgAnalog, NTU_DIRTY_ANALOG, NTU_CLEAN_ANALOG, 50.0, 1.0);
  return constrain(ntu, 1.0, 50.0);
}

float readTemperatureSensor() {
  if (!USE_REAL_TEMP_SENSOR) return DUMMY_TEMPERATURE;
  tempSensor.requestTemperatures();
  float temp = tempSensor.getTempCByIndex(0);
  if (temp == DEVICE_DISCONNECTED_C || temp < -50 || temp > 100) return DUMMY_TEMPERATURE;
  return temp;
}

// ==================== WIFI & FIREBASE ====================

void connectWiFiManager() {
  wifiManager.setConfigPortalTimeout(180);
  if (!wifiManager.autoConnect(AP_NAME, AP_PASSWORD)) {
    delay(3000);
    ESP.restart();
  }
}

void setupFirebase() {
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase OK");
  }
  config.token_status_callback = tokenStatusCallback;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  // ==================== PRESENCE SYSTEM ====================
  if (Firebase.ready()) {
    // Set status online saat ini
    Firebase.setBool(firebaseData, "/monitoring/status/online", true);
    
    // Daftarkan aksi otomatis saat terputus (Presence System)
    Firebase.setOptions(firebaseData, 1); // Enable onDisconnect
    Firebase.onDisconnectSetBool(firebaseData, "/monitoring/status/online", false);
    
    Serial.println("Presence System: Online & onDisconnect registered");
  }
}

void sendToFirebase() {
  if (WiFi.status() != WL_CONNECTED || !Firebase.ready()) return;
  
  unsigned long epochMillis = timeClient.getEpochTime() * 1000UL;
  FirebaseJson json;
  json.set("ph", currentPH);
  json.set("turbidity", currentNTU);
  json.set("temperature", currentTemp);
  json.set("quality_score", qualityScore);
  json.set("status", waterStatus);
  json.set("fuzzy_result", waterDescription);
  json.set("timestamp", (double)epochMillis); 

  Firebase.setJSON(firebaseData, "/monitoring/current", json);
}

// ==================== SETUP & LOOP ====================

void setup() {
  Serial.begin(115200);
  pinMode(MUX_S0, OUTPUT);
  pinMode(MUX_S1, OUTPUT);
  pinMode(MUX_S2, OUTPUT);
  pinMode(MUX_S3, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  
  tempSensor.begin();
  connectWiFiManager();
  timeClient.begin();
  timeClient.update();
  setupFirebase();
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) connectWiFiManager();
  timeClient.update();

  float rawPH = readPHSensor();
  float rawNTU = readTurbiditySensor();
  float rawTemp = readTemperatureSensor();

  // Moving Average / EMA Filter agar nilai stabil (tidak loncat-loncat)
  currentPH = (currentPH == 0) ? rawPH : (currentPH * 0.7) + (rawPH * 0.3);
  currentNTU = (currentNTU == 0) ? rawNTU : (currentNTU * 0.7) + (rawNTU * 0.3);
  currentTemp = (currentTemp == 0) ? rawTemp : (currentTemp * 0.7) + (rawTemp * 0.3);

  applyFuzzyMamdani(currentPH, currentNTU, currentTemp);

  if (millis() - lastSendTime >= sendInterval) {
    sendToFirebase();
    lastSendTime = millis();
    
    // Serial monitor debugging
    Serial.print("pH: "); Serial.print(currentPH);
    Serial.print(" | NTU: "); Serial.print(currentNTU);
    Serial.print(" | Temp: "); Serial.print(currentTemp);
    Serial.print(" | Status: "); Serial.println(waterStatus);
  }

  // ==================== LED BLINK LOGIC (Hanya saat Bahaya) ====================
  if (waterStatus == "Bahaya") {
    if (millis() - lastLedToggle >= 50) {
      ledState = !ledState;
      digitalWrite(LED_PIN, ledState ? HIGH : LOW);
      lastLedToggle = millis();
    }
  } else {
    digitalWrite(LED_PIN, HIGH); // Mati jika Aman/Waspada (Active Low)
  }

  delay(10); // Kecilkan delay agar responsif terhadap kedipan LED
}
