# IoT MQTT Panel

Aplikasi dashboard IoT berbasis Flutter untuk monitoring dan kontrol perangkat IoT melalui protokol MQTT.

## Fitur Utama

- 📊 **Multiple Dashboard** - Buat beberapa dashboard untuk berbagai kebutuhan
- 🔌 **MQTT Connectivity** - Koneksi ke berbagai MQTT broker (public/private)
- 📈 **Real-time Visualization** - Gauge, line chart, dan widget interaktif lainnya
- 🎛️ **Device Control** - Toggle switch dan button untuk kontrol perangkat
- 💾 **Local Storage** - Semua konfigurasi tersimpan lokal menggunakan Hive
- 🌓 **Dark Mode** - Mendukung light dan dark theme

## Widget yang Tersedia

1. **Toggle Switch** - Kontrol ON/OFF dengan feedback real-time
2. **Button** - Tombol untuk trigger aksi satu kali
3. **Gauge** - Tampilan gauge untuk sensor (suhu, kelembaban, dll)
4. **Line Chart** - Grafik historical data

## Cara Penggunaan

### 1. Menambah Broker MQTT

1. Buka aplikasi
2. Tap tombol "+" atau "Add Broker"
3. Pilih "Public Brokers" untuk broker gratis atau isi manual:
   - **Name**: Nama broker (contoh: "My MQTT Broker")
   - **Host**: Alamat broker (contoh: broker.hivemq.com)
   - **Port**: Port broker (1883 untuk non-SSL, 8883 untuk SSL)
   - **Username/Password**: Opsional, jika broker memerlukan autentikasi
4. Tap "Test Connection" untuk memverifikasi
5. Tap "Save"

### 2. Membuat Dashboard

1. Dari list broker, tap broker yang ingin digunakan
2. Tap "Dashboards" dari menu
3. Tap tombol "+" untuk membuat dashboard baru
4. Beri nama dashboard
5. Tap "Save"

### 3. Menambah Widget

1. Buka dashboard
2. Tap tombol "+" di kanan bawah
3. Pilih tipe widget:
   - **Toggle Switch**: Untuk kontrol ON/OFF
   - **Button**: Untuk aksi satu kali
   - **Gauge**: Untuk menampilkan nilai sensor
   - **Line Chart**: Untuk grafik data
4. Konfigurasi widget:
   - **Title**: Nama widget
   - **Subscribe Topic**: Topic untuk menerima data (untuk gauge/chart/toggle)
   - **Publish Topic**: Topic untuk mengirim perintah (untuk toggle/button)
   - **Payloads**: Nilai yang dikirim (ON/OFF untuk toggle)
   - **Min/Max Value**: Range nilai (untuk gauge/chart)
   - **QoS Level**: Quality of Service (0, 1, atau 2)
5. Tap "Save"

## Public MQTT Brokers untuk Testing

Berikut broker MQTT public yang bisa digunakan gratis:

| Broker | Host | Port | SSL Port | Catatan |
|--------|------|------|----------|---------|
| HiveMQ | broker.hivemq.com | 1883 | 8883 | Recommended |
| Eclipse Mosquitto | test.mosquitto.org | 1883 | 8883 | Reliable |
| EMQX | broker.emqx.io | 1883 | 8883 | Fast |

**Catatan**: Broker public tidak memerlukan username/password

## Troubleshooting

### Koneksi Gagal

Jika koneksi gagal dengan error "connection attempts exceeded":

1. **Cek koneksi internet** - Pastikan perangkat terhubung ke internet
2. **Coba broker lain** - Gunakan broker.hivemq.com atau test.mosquitto.org
3. **Periksa firewall** - Beberapa firewall memblokir port MQTT (1883)
4. **Gunakan port yang benar**:
   - Port 1883 untuk koneksi non-SSL
   - Port 8883 untuk koneksi SSL/TLS
5. **Jaringan perusahaan** - Beberapa jaringan perusahaan memblokir MQTT

### Widget Tidak Update

1. Pastikan broker terkoneksi (indikator hijau di app bar)
2. Cek topic yang di-subscribe sudah benar
3. Pastikan ada device yang publish ke topic tersebut
4. Cek QoS level (mulai dengan 0)

### Testing dengan MQTT Client

Untuk testing, gunakan MQTT client seperti:
- **MQTT Explorer** (Desktop)
- **MQTT Dashboard** (Android/iOS)
- **mosquitto_pub/sub** (Command line)

Contoh publish menggunakan mosquitto_pub:
```bash
mosquitto_pub -h broker.hivemq.com -t "test/topic" -m "25.5"
```

## Contoh Penggunaan

### Monitoring Suhu

1. Buat widget **Gauge**
2. Subscribe Topic: `home/temperature`
3. Min Value: 0, Max Value: 50
4. Unit: °C

Device ESP32/Arduino publish:
```cpp
client.publish("home/temperature", "25.5");
```

### Kontrol Lampu

1. Buat widget **Toggle Switch**
2. Subscribe Topic: `home/light/status`
3. Publish Topic: `home/light/control`
4. ON Payload: `1`, OFF Payload: `0`

Device ESP32/Arduino:
```cpp
// Subscribe ke home/light/control
// Publish status ke home/light/status
if (lightOn) {
  client.publish("home/light/status", "1");
} else {
  client.publish("home/light/status", "0");
}
```

## Tech Stack

- **Flutter** - Framework UI
- **Riverpod** - State Management
- **Hive** - Local Database
- **mqtt_client** - MQTT Protocol
- **fl_chart** - Charts
- **Syncfusion Gauges** - Gauge Widgets

## Development

```bash
# Install dependencies
flutter pub get

# Generate Hive adapters
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run
```

## License
Created by Rivaldi Eka Putra
