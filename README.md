# 🚀 IoTify Platform (Valiot Dashboard)

![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B)
![State Management](https://img.shields.io/badge/State_Management-Riverpod-purple)
![Database](https://img.shields.io/badge/Database-Hive-orange)

**The ultimate MQTT-based IoT Dashboard for professionals and hobbyists.**  
Monitor sensors, control devices, and automate your smart home or industrial projects with a beautiful, real-time, and offline-first interface.

---

## ✨ Key Features

### 🔌 **Connectivity & Compatibility**
- **Universal MQTT Support**: Connect to any broker (HiveMQ, Mosquitto, EMQX, AWS IoT, Azure).
- **SSL/TLS Secure Connection**: Enterprise-grade security support (MQTTS).
- **Multi-Broker Management**: Manage multiple connections and dashboards simultaneously.

### 📊 **Rich Visualization**
- **Dynamic Widgets**:
  - 🎚️ **Sliders & Knobs** for precise control (PWM/Dimmer).
  - 🔘 **Toggle Switches & Buttons** for instant actions.
  - 📈 **Real-time Charts** for data trending and history.
  - 🌡️ **Gauges** for visual sensor monitoring.
  - 📝 **Text Displays** for status and general data.

### 🤖 **Intelligent Automation (Rule Engine)**
Turn your dashboard into a smart controller with the built-in **Automation Engine**. No cloud required!
- **Triggers**: 
  - 📡 **Widget Value**: E.g., "If Temp > 30°C".
  - ⏰ **Schedule**: Daily, Weekly, One-time, or Intervals.
- **Actions**:
  - 🔔 **Notifications**: Show warnings or alerts.
  - 🎛️ **Control Devices**: Automatically turn other widgets ON/OFF (Inter-widget communication).
  - 📡 **Publish MQTT**: Send custom commands to devices.
- **Activity Log**: Track every automation event with detailed success/failure history.

### 🎨 **Premium User Experience**
- **Dark/Light Mode**: Fully optimized theme for day and night usage.
- **Real-time Updates**: Zero latency with optimized MQTT packet handling.
- **Responsive Design**: Works perfectly on Mobile (Touch) and Desktop (Mouse).

---

## 🚀 Getting Started

### 1. Installation

```bash
# Clone the repository
git clone https://github.com/rivaldisinkoprima/valiotdashboard.git

# Install dependencies
flutter pub get

# Generate Hive adapters (Database)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### 2. Configure a Broker
1. Open the app and click **+ Add Broker**.
2. Select a template (e.g., HiveMQ Public) or enter custom details.
3. Click **Test Connection** → **Save**.

### 3. Build Your Dashboard
1. Go to **Dashboards** tab.
2. Add widgets by clicking the **+** button.
3. Configure **Topics**:
   - **Subscribe Topic**: To receive data (e.g., `home/livingroom/temp`)
   - **Publish Topic**: To send commands (e.g., `home/livingroom/light`)

### 4. Set Up Automation
Example: **"Turn on Fan when Hot"**
1. Go to **Automation Rules** → **+ Add Rule**.
2. **Trigger**: Widget Value (Select "Temp Sensor" > 30).
3. **Action**: Control Widget (Set "Fan Switch" → ON).
4. Save & Enjoy! 🎉

---

## 🧪 Testing with MQTT

You can test the dashboard using public brokers:

| Broker | Host | Port | SSL Port |
|--------|------|------|----------|
| **HiveMQ** | `broker.hivemq.com` | 1883 | 8883 |
| **Mosquitto** | `test.mosquitto.org` | 1883 | 8883 |
| **EMQX** | `broker.emqx.io` | 1883 | 8883 |

**Example Command (Mosquitto CLI):**
```bash
# Send temperature data
mosquitto_pub -h broker.hivemq.com -t "home/temp" -m "28.5"

# Subscribe to switch command
mosquitto_sub -h broker.hivemq.com -t "home/switch"
```

---

## 🛠️ Tech Stack

Built with ❤️ using best-in-class Flutter packages:
- **Flutter**: Cross-platform UI toolkit.
- **Riverpod**: Robust, testable state management.
- **Hive**: Blazing fast local NoSQL database.
- **mqtt_client**: Reliable machine-to-machine messaging.
- **fl_chart**: Beautiful interactive charts.
- **Syncfusion Gauges**: Professional visualization components.

---

## 📝 License

Developed by **Rivaldi Eka Putra**.  
All rights reserved © 2026.
