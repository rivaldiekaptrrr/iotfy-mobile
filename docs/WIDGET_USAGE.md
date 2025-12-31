# Panduan Penggunaan Widget Valiot Dashboard

Dokumen ini menjelaskan cara konfigurasi dan penggunaan setiap tipe widget yang tersedia di aplikasi Valiot Dashboard.

## 1. Toggle Switch
Digunakan untuk mengontrol status ON/OFF (boolean) dari sebuah device, misalnya lampu atau relay.

**Konfigurasi:**
- **Title**: Nama widget (misal: "Lampu Ruang Tamu").
- **Subscribe Topic**: Topik MQTT untuk mendengarkan status terkini dari device.
  - *Contoh*: `home/livingroom/light/status`
- **Publish Topic**: Topik MQTT untuk mengirim perintah saat switch ditekan.
  - *Contoh*: `home/livingroom/light/set`
- **On Payload**: Payload yang dikirim/diterima untuk status ON (default: `ON`).
- **Off Payload**: Payload yang dikirim/diterima untuk status OFF (default: `OFF`).
- **Color**: Warna aksen switch saat aktif.

---

## 2. Button
Digunakan untuk mengirim perintah sesaat (push button), misalnya untuk reset device atau trigger aksi tertentu.

**Konfigurasi:**
- **Title**: Label tombol (misal: "Reset Device").
- **Publish Topic**: Topik MQTT tujuan pengiriman perintah.
  - *Contoh*: `device/control/reset`
- **Payload**: Pesan yang akan dikirim saat tombol ditekan.
  - *Contoh*: `true`, `1`, atau JSON `{ "action": "reset" }`.
- **Icon**: Ikon visual tombol.
- **Color**: Warna tombol.

---

## 3. Slider Control
Digunakan untuk mengontrol nilai angka dalam rentang tertentu, misalnya intensitas lampu (dimmer) atau kecepatan kipas.

**Konfigurasi:**
- **Title**: Label widget (misal: "Kecerahan Lampu").
- **Subscribe Topic**: Topik untuk membaca nilai saat ini.
- **Publish Topic**: Topik untuk mengirim nilai baru saat slider digeser.
- **Min Value**: Nilai minimum slider (misal: `0`).
- **Max Value**: Nilai maksimum slider (misal: `100`).
- **Unit**: Satuan nilai (opsional, misal: `%`).
- **Color**: Warna bar slider.

---

## 4. Gauge (Analog Meter)
Digunakan untuk memvisualisasikan data sensor berupa angka dalam bentuk meteran analog, seperti suhu, kelembaban, atau tekanan.

**Konfigurasi:**
- **Title**: Label widget (misal: "Suhu Mesin").
- **Subscribe Topic**: Topik MQTT sumber data sensor.
- **Min Value**: Batas bawah tampilan gauge.
- **Max Value**: Batas atas tampilan gauge.
- **Unit**: Satuan yang ditampilkan (misal: `°C`, `Psi`).
- **Color**: Warna indikator gauge.

---

## 5. Line Chart (Grafik)
Digunakan untuk menampilkan riwayat data sensor dari waktu ke waktu (time-series).

**Konfigurasi:**
- **Title**: Label grafik.
- **Subscribe Topic**: Topik MQTT sumber data.
- **Min Value / Max Value**: Rentang sumbu Y (vertikal).
- **Unit**: Satuan data.
- **Color**: Warna garis grafik.
- *Catatan*: Grafik akan mereset riwayatnya jika aplikasi direstart, kecuali terhubung ke broker yang mengirimkan riwayat (retain/history plugin).

---

## 6. Text Display
Widget sederhana untuk menampilkan data mentah (raw string/number) dari MQTT.

**Konfigurasi:**
- **Title**: Label (misal: "Status System").
- **Subscribe Topic**: Topik yang akan ditampilkan isinya apa adanya.

---

## 7. Map Tracker
Digunakan untuk melacak posisi device (GPS) secara real-time pada peta.

**Konfigurasi:**
- **Title**: Nama tracker (misal: "Truk Logistik 1").
- **Subscribe Topic**: Topik MQTT yang mengirimkan koordinat lat/long.
  - *Format Data*: Harus berupa string "lat,long" (contoh: `-6.200000,106.816666`) atau JSON (tergantung implementasi parser saat ini mendukung csv lat,lng).
- **Map Marker Icon**: Ikon penanda di peta (pilih dari daftar icon kendaraan/marker).
- **Color**: Warna path/marker.

---

##8. Alarm Panel
Digunakan untuk menampilkan daftar alarm/alert secara real-time berdasarkan rule engine yang telah dikonfigurasi.

**Konfigurasi:**
- **Title**: Nama panel (misal: "Recent Alarms").
- **Tidak memerlukan topic** - Data alarm otomatis ditarik dari Rule Engine.

**Fitur:**
- Tampilkan 3 alarm terbaru di panel.
- Klik "Details" untuk melihat 10 alarm terbaru.
- Setiap alarm menampilkan:
  - **Severity**: Critical (merah), Major (orange), Minor (kuning)
  - **Sensor Name**: Nama widget/sensor yang memicu alarm
  - **Start Time**: Waktu mulai alarm
  - **Duration**: Durasi alarm (dihitung otomatis endTime - startTime)
  - **Status**: Active, Acknowledged, atau Cleared

**Acknowledge Alarm:**
- Buka Detail Screen
- Klik tombol "ACK" pada alarm yang ingin di-acknowledge
- Alarm yang di-acknowledge akan tetap tampil namun diberi badge "ACKNOWLEDGED"

**Auto-Clear:**
- Alarm akan otomatis cleared saat kondisi sensor kembali normal (tidak perlu manual clear)
- Alarm yang acknowledged tidak akan auto-clear

**Integrasi dengan Rule Engine:**
- Alarm dibuat otomatis saat Rule Engine trige
- Severity ditentukan saat membuat rule (bukan auto-detect)
- Untuk membuat rule: Klik ikon "⚙️ Rule" → Add Rule → Set severity

**Best Practice:**
- Gunakan severity sesuai tingkat urgensi:
  - **Critical**: Sistem down, bahaya keamanan
  - **Major**: Performa degradasi signifikan
  - **Minor**: Warning, informasi penting tapi tidak urgent
