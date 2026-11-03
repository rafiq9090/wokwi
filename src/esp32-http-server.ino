#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <Wire.h>
#include <math.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <LiquidCrystal_I2C.h>

Adafruit_MPU6050 mpu;
LiquidCrystal_I2C lcd(0x27, 16, 2);
WebServer apiServer(80);

const char *WIFI_SSID = "Wokwi-GUEST";
const char *WIFI_PASSWORD = "";

#define GREEN_LED 2
#define YELLOW_LED 4
#define RED_LED 16
#define BUZZER 5
#define CANCEL_BUTTON 18

#define IMPACT_G 2.5
#define FREEFALL_G 0.5
#define REQUIRE_FREEFALL 0
#define FREEFALL_WINDOW 500
#define ROTATION_DPS 180.0
#define ROTATION_WINDOW 700
#define STRONG_IMPACT_G 3.0
#define SAMPLE_MS 20
#define WARNING_MS 10000
#define CANCELLED_MS 2000
#define COOLDOWN_MS 3000
#define ALARM_MS 15000
#define REARM_G 1.8
#define REARM_STABLE_MS 1000
#define CANCEL_HOLD_MS 2000

enum State { NORMAL, WARNING, ALARM, CANCELLED };
State state = NORMAL;

unsigned long stateStart = 0;
unsigned long lastSample = 0;
unsigned long lastLcd = 0;
unsigned long lastPrint = 0;
unsigned long lastBuzz = 0;
unsigned long cooldownEnd = 0;
unsigned long freeFallTime = 0;
unsigned long rotationTime = 0;
unsigned long rearmStart = 0;
bool freeFall = false;
bool rotationSeen = false;
bool buzzOn = false;
bool armed = true;

unsigned long cancelHoldStart = 0;
bool cancelHoldTriggered = false;
float latestAccG = 1.0;
float latestRotationDps = 0.0;

String lcdLine[2] = {"", ""};

const char *stateName() {
  switch (state) {
    case WARNING: return "warning";
    case ALARM: return "alarm";
    case CANCELLED: return "cancelled";
    case NORMAL: return "normal";
  }
  return "unknown";
}

void handleStatus() {
  String response = "{\"deviceId\":\"fall-device-001\",\"state\":\"";
  response += stateName();
  response += "\",\"armed\":";
  response += armed ? "true" : "false";
  response += ",\"accelerationG\":";
  response += String(latestAccG, 2);
  response += ",\"rotationDps\":";
  response += String(latestRotationDps, 1);
  response += ",\"uptimeMs\":";
  response += String(millis());
  response += "}";
  apiServer.sendHeader("Access-Control-Allow-Origin", "*");
  apiServer.send(200, "application/json", response);
}

void connectNetwork() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi");
  unsigned long started = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - started < 10000) {
    delay(250);
    Serial.print(".");
  }
  Serial.println();
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("Device API: http://");
    Serial.println(WiFi.localIP());
    apiServer.on("/api/status", HTTP_GET, handleStatus);
    apiServer.begin();
  } else {
    Serial.println("WiFi unavailable; local detection continues.");
  }
}

void lcdPrint(uint8_t row, String text) {
  while (text.length() < 16) text += ' ';
  text = text.substring(0, 16);
  if (text != lcdLine[row]) {
    lcdLine[row] = text;
    lcd.setCursor(0, row);
    lcd.print(text);
  }
}

void setLeds(bool green, bool yellow, bool red) {
  digitalWrite(GREEN_LED, green);
  digitalWrite(YELLOW_LED, yellow);
  digitalWrite(RED_LED, red);
}

void buzzer(bool on) {
  buzzOn = on;
  if (on) {
    tone(BUZZER, 2000);
  } else {
    noTone(BUZZER);
  }
}

void beep(unsigned long onMs, unsigned long offMs) {
  unsigned long now = millis();
  if (buzzOn && now - lastBuzz >= onMs) {
    buzzer(false);
    lastBuzz = now;
  } else if (!buzzOn && now - lastBuzz >= offMs) {
    buzzer(true);
    lastBuzz = now;
  }
}

bool cooldownExpired(unsigned long now) {
  return (long)(now - cooldownEnd) > 0;
}

bool cancelHeld() {
  bool reading = digitalRead(CANCEL_BUTTON);

  if (reading == LOW) {
    if (cancelHoldStart == 0) {
      cancelHoldStart = millis();
      cancelHoldTriggered = false;
    }
    if (!cancelHoldTriggered && millis() - cancelHoldStart >= CANCEL_HOLD_MS) {
      cancelHoldTriggered = true;
      return true;
    }
  } else {
    cancelHoldStart = 0;
    cancelHoldTriggered = false;
  }
  return false;
}

void setState(State newState) {
  state = newState;
  stateStart = millis();
  cancelHoldStart = 0;
  cancelHoldTriggered = false;
  buzzer(false);
  lastBuzz = millis();

  switch (newState) {
    case NORMAL:
      setLeds(HIGH, LOW, LOW);
      break;
    case WARNING:
      setLeds(LOW, HIGH, LOW);
      Serial.println("Possible fall detected - waiting for cancel...");
      break;
    case ALARM:
      setLeds(LOW, LOW, HIGH);
      Serial.println("====================");
      Serial.println("   FALL DETECTED!");
      Serial.println("====================");
      Serial.println("Alert should be sent to caregiver.");
      break;
    case CANCELLED:
      setLeds(HIGH, LOW, LOW);
      Serial.println("Fall alert cancelled.");
      break;
  }
}

void cancelAlert() {
  setState(CANCELLED);
  cooldownEnd = millis() + CANCELLED_MS + COOLDOWN_MS;
  armed = false;
}

void setup() {
  Serial.begin(115200);

  pinMode(GREEN_LED, OUTPUT);
  pinMode(YELLOW_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(BUZZER, OUTPUT);
  pinMode(CANCEL_BUTTON, INPUT_PULLUP);

  Wire.begin(21, 22);
  lcd.init();
  lcd.backlight();

  if (!mpu.begin()) {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("MPU6050 Error!");
    Serial.println("MPU6050 not found!");
    setLeds(LOW, LOW, HIGH);
    while (1) delay(100);
  }

  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Fall Detection");
  lcd.setCursor(0, 1);
  lcd.print("System Ready");
  delay(2000);

  lcd.clear();
  lcdLine[0] = "";
  lcdLine[1] = "";
  setState(NORMAL);
  connectNetwork();
}

void loop() {
  unsigned long now = millis();
  if (WiFi.status() == WL_CONNECTED) apiServer.handleClient();

  if (state == WARNING && cancelHeld()) {
    cancelAlert();
  }

  if (now - lastSample < SAMPLE_MS) {
    if (state == WARNING) beep(150, 850);
    if (state == ALARM) beep(250, 250);
    return;
  }
  lastSample = now;

  sensors_event_t acceleration, gyro, temperature;
  mpu.getEvent(&acceleration, &gyro, &temperature);

  float accG = sqrt(acceleration.acceleration.x * acceleration.acceleration.x +
                    acceleration.acceleration.y * acceleration.acceleration.y +
                    acceleration.acceleration.z * acceleration.acceleration.z) / 9.81;

  float rotationDps = sqrt(gyro.gyro.x * gyro.gyro.x +
                           gyro.gyro.y * gyro.gyro.y +
                           gyro.gyro.z * gyro.gyro.z) * 180.0 / PI;
  latestAccG = accG;
  latestRotationDps = rotationDps;

  if (!isfinite(accG)) {
    buzzer(false);
    setLeds(LOW, LOW, HIGH);
    lcdPrint(0, "Sensor Error");
    lcdPrint(1, "Check MPU6050");
    Serial.println("Invalid MPU6050 data.");
    delay(SAMPLE_MS);
    return;
  }

  if (now - lastPrint >= 200) {
    lastPrint = now;
    Serial.print("Total: ");
    Serial.print(accG, 2);
    Serial.print(" G, Rotation: ");
    Serial.print(rotationDps, 1);
    Serial.println(" deg/s");
  }

  switch (state) {
    case NORMAL: {
      if (accG < FREEFALL_G) {
        freeFall = true;
        freeFallTime = now;
      }
      if (freeFall && now - freeFallTime > FREEFALL_WINDOW) freeFall = false;
      if (rotationDps > ROTATION_DPS) {
        rotationSeen = true;
        rotationTime = now;
      }
      if (rotationSeen && now - rotationTime > ROTATION_WINDOW) rotationSeen = false;
      if (!armed) {
        if (accG < REARM_G) {
          if (rearmStart == 0) rearmStart = now;
          if (now - rearmStart >= REARM_STABLE_MS) {
            armed = true;
            rearmStart = 0;
          }
        } else {
          rearmStart = 0;
        }
      }

      bool impact = armed && (accG > IMPACT_G);
#if REQUIRE_FREEFALL
      impact = impact && freeFall;
#endif

      bool possibleFall = armed &&
              ((impact && (freeFall || rotationSeen)) ||
               accG > STRONG_IMPACT_G);

      if (possibleFall && cooldownExpired(now)) {
        freeFall = false;
        rotationSeen = false;
        armed = false;
        setState(WARNING);
        break;
      }

      if (now - lastLcd >= 250) {
        lastLcd = now;
        lcdPrint(0, "Status: NORMAL");
        lcdPrint(1, "Acc:" + String(accG, 2) + "G");
      }
      break;
    }

    case WARNING: {
      unsigned long elapsed = now - stateStart;
      if (elapsed >= WARNING_MS) {
        setState(ALARM);
        break;
      }
      beep(150, 850);
      lcdPrint(0, "Fall? Hold 2s");
      lcdPrint(1, "Alert in: " + String((WARNING_MS - elapsed) / 1000 + 1) + "s");
      break;
    }

    case ALARM:
      if (now - stateStart >= ALARM_MS) {
        Serial.println("Alarm timed out - returning to NORMAL.");
        cooldownEnd = now + COOLDOWN_MS;
        lcdLine[0] = "";
        lcdLine[1] = "";
        setState(NORMAL);
        break;
      }
      beep(250, 250);
      lcdPrint(0, "!!! FALL !!!");
      lcdPrint(1, "Emergency!");
      break;

    case CANCELLED:
      lcdPrint(0, "Alert Cancelled");
      lcdPrint(1, "System Normal");
      if (now - stateStart >= CANCELLED_MS) {
        lcdLine[0] = "";
        lcdLine[1] = "";
        setState(NORMAL);
      }
      break;
  }
}
