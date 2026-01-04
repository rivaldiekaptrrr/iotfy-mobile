# Panduan Penggunaan Widget Valiot Dashboard

Dokumen ini menjelaskan cara konfigurasi dan penggunaan setiap tipe widget yang tersedia di aplikasi Valiot Dashboard.

## 1. Toggle Switch
Digunakan untuk mengontrol status ON/OFF (boolean) dari sebuah device, misalnya lampu atau relay.

**Konfigurasi:**
- **Title**: Nama widget (misal: "Lampu Ruang Tamu").
- **Subscribe Topic** (Opsional): Topik MQTT untuk mendengarkan status terkini.
- **Publish Topic**: Topik MQTT untuk mengirim perintah.
- **On/Off Payload**: Payload untuk status (default: `ON`/`OFF`).

## 2. Button
Digunakan untuk mengirim perintah sesaat (push button), misalnya untuk reset device.

**Konfigurasi:**
- **Title**: Label tombol (misal: "Reset Device").
- **Publish Topic**: Topik MQTT tujuan pengiriman perintah.
- **Color**: Warna tombol.

## 3. Slider Control
Mengontrol nilai angka dalam rentang tertentu, misalnya dimmer lampu.

**Konfigurasi:**
- **Title**: Label widget.
- **Publish Topic**: Topik untuk mengirim nilai.
- **Subscribe Topic** (Opsional): Topik bacaan status.
- **Min/Max Value**: Rentang nilai.

## 4. Gauge & Radial Gauge
Visualisasi meteran analog untuk data sensor seperti suhu atau tekanan.

**Konfigurasi:**
- **Subscribe Topic**: Sumber data sensor.
- **Min/Max Value**: Batas bawah/atas tampilan.
- **Warning/Critical Threshold**: Batas nilai untuk indikator warna kuning/merah.

## 5. Line Chart
Menampilkan riwayat data sensor (time-series).

**Konfigurasi:**
- **Subscribe Topic**: Sumber data.
- **Warning/Critical Threshold**: Garis batas horizontal pada grafik.

## 6. Liquid Tank
Visualisasi level cairan dalam tangki dengan animasi gelombang.

**Konfigurasi:**
- **Subscribe Topic**: Data level (angka).
- **Min/Max Value**: Kapasitas tangki (Min = kosong, Max = penuh).
- **Color**: Warna cairan.

## 7. Segmented Switch
Kontrol multi-state untuk memilih mode (misal: Low, Med, High).

**Konfigurasi:**
- **Publish Topic**: Topik untuk mengirim nilai pilihan.
- **Options**: Daftar pilihan dipisahkan koma (contoh: `Low,Med,High` atau `Mode A,Mode B`).

## 8. Linear Gauge
Meteran gaya bar horizontal, cocok untuk termometer atau progress bar.

**Konfigurasi:**
- **Subscribe Topic**: Sumber data.
- **Min/Max Value**: Rentang skala.
- **Thresholds**: Indikator batas aman/bahaya.

## 9. Virtual Joystick
Kontrol analog X-Y axis untuk robot atau kamera PTZ.

**Konfigurasi:**
- **Publish Topic**: Mengirim koordinat JSON (contoh: `{"x": 0.5, "y": -1.0}`).
- **Color**: Warna stick.

## 10. Compass
Menampilkan arah mata angin (heading) 0-360 derajat.

**Konfigurasi:**
- **Subscribe Topic**: Data heading (0-360).
- **Visual**: Menampilkan jarum kompas dan label arah (N, E, S, W).

## 11. Keypad (PIN Input)
Input angka/PIN manual.

**Konfigurasi:**
- **Publish Topic**: Topik pengiriman kode PIN.
- **Fitur**: Tombol angka 0-9, Clear (C), dan OK (Kirim).

## 12. Icon Matrix
Grid status indikator biner untuk memantau banyak sensor sekaligus.

**Konfigurasi:**
- **Subscribe Topic**: Data integer (bitmask). 
  - Bit 0 = Indikator 1, Bit 1 = Indikator 2, dst.
- **Options**: Label untuk setiap indikator (dipisahkan koma, misal: `Pump 1,Pump 2,Valve A`).

## 13. Terminal Log
Menampilkan log data mentah dari MQTT dengan timestamp.

**Konfigurasi:**
- **Subscribe Topic**: Topik data stream.
- **Fitur**: Menampilkan waktu [HH:MM:SS] dan auto-scroll ke pesan terbaru.

## 14. Battery Level
Indikator visual level baterai.

**Konfigurasi:**
- **Subscribe Topic**: Data level baterai (0-100).
- **Visual**: Warna berubah otomatis (Hijau > 50%, Kuning > 20%, Merah < 20%).

## 15. Map Tracker
Melacak posisi GPS device.

**Konfigurasi:**
- **Subscribe Topic**: Data lat,long (csv).
- **Map Icon**: Pilihan ikon marker kendaraan.
