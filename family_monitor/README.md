# Care Circle Family Monitor

Flutter family-monitor app for the ESP32 fall detector.

## Local Hardware Connection

1. Set `WIFI_SSID` and `WIFI_PASSWORD` in the ESP32 sketch.
2. Build and upload the firmware:

```powershell
py -m platformio run --target upload
```

3. Read the ESP32 IP address from the serial monitor.
4. Connect the phone and ESP32 to the same Wi-Fi network.
5. Run the app with the ESP32 address:

```powershell
flutter run --dart-define=ESP32_URL=http://192.168.1.42
```

The app polls `GET /api/status` every two seconds. Without `ESP32_URL`, it stays in demo mode.

The local HTTP mode is for development only. Use HTTPS and authenticated access before connecting a real safety device.
