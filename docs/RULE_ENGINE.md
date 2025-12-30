# Rule Engine - Panduan Lengkap

Sistem Rule Engine memungkinkan Anda membuat otomasi berdasarkan data sensor yang masuk. Fitur ini akan secara otomatis memantau nilai dari widget dan menjalankan aksi tertentu ketika kondisi terpenuhi.

---

## 📋 Cara Mengakses Rule Engine

1. Buka **Dashboard** Anda
2. Klik ikon **⚙️ Rule** di AppBar (pojok kanan atas)
3. Anda akan dibawa ke layar **Rule Manager**

---

## ✨ Membuat Rule Baru

### Langkah-langkah:

1. **Klik tombol `[+ Add Rule]`** di Rule Manager
2. **Dialog Konfigurasi Rule** akan muncul dengan form berikut:

### Form Konfigurasi:

#### **1. Rule Name**
- Nama untuk rule Anda (contoh: "High Temperature Alert")
- Nama ini akan muncul di daftar rule dan notifikasi

#### **2. Kondisi (Condition)**

**a. Source Widget:**
- Pilih widget yang ingin dimonitor
- Hanya widget dengan data numerik yang muncul (Gauge, Slider, atau widget ber-subscribe MQTT)
- Contoh: "Suhu Mesin"

**b. Operator:**
Pilih operator perbandingan:
- `>` (Greater than) - Lebih besar dari
- `<` (Less than) - Lebih kecil dari
- `>=` (Greater or equal) - Lebih besar atau sama dengan
- `<=` (Less or equal) - Lebih kecil atau sama dengan
- `==` (Equals) - Sama dengan
- `!=` (Not equals) - Tidak sama dengan

**c. Threshold Value:**
- Nilai batas/ambang
- Contoh: `80` (untuk suhu 80°C)

#### **3. Aksi (Actions)**

Anda bisa mengaktifkan **satu atau lebih** aksi:

**✅ Show Notification** *(Recommended)*
- Menampilkan notifikasi sistem (Windows toast / Android notification)
- **Title:** Judul notifikasi custom (opsional)
- Notifikasi akan muncul meskipun aplikasi di-minimize

**📤 Publish MQTT Message**
- Mengirim perintah MQTT ke device lain
- **MQTT Topic:** Topik tujuan (contoh: `fan/control`)
- **MQTT Payload:** Pesan yang dikirim (contoh: `ON`, `1`, `{"speed": 100}`)

---

## 💡 Contoh Use Case

### **Contoh 1: Kontrol Otomatis Kipas**
```
Rule Name: "Auto Fan Control"

Kondisi:
  IF suhu_mesin > 80

Aksi:
  ✅ Show Notification
     Title: "⚠️ Suhu Kritis!"
  
  ✅ Publish MQTT
     Topic: fan/control
     Payload: ON
```
**Hasil:** Ketika suhu mesin melebihi 80°C, sistem akan:
1. Menampilkan notifikasi peringatan
2. Menyalakan kipas secara otomatis

---

### **Contoh 2: Alert Kelembaban Rendah**
```
Rule Name: "Low Humidity Warning"

Kondisi:
  IF humidity < 30

Aksi:
  ✅ Show Notification
     Title: "💧 Kelembaban Rendah"
```
**Hasil:** Notifikasi muncul saat kelembaban di bawah 30%

---

### **Contoh 3: Monitoring Batas Atas & Bawah**
Buat **2 rule terpisah** untuk monitoring dual-threshold:

**Rule 1: Over Limit**
```
IF temperature > 90
THEN notify "🔴 Suhu Terlalu Tinggi!"
```

**Rule 2: Under Limit**
```
IF temperature < 10
THEN notify "🔵 Suhu Terlalu Rendah!"
```

---

## ⚙️ Mengelola Rule

### **Toggle ON/OFF**
- Setiap rule memiliki **Switch** di sebelah kanan
- Rule yang **AKTIF** (hijau ✅) akan berjalan otomatis
- Rule yang **NONAKTIF** (abu ⚪) tidak akan berjalan

### **Edit Rule**
1. Klik tombol **[Edit]** pada card rule
2. Ubah konfigurasi sesuai kebutuhan
3. Klik **[Save]**

### **Delete Rule**
1. Klik tombol **[Delete]** (merah)
2. Konfirmasi penghapusan

---

## 📊 Statistik Rule

Setiap rule menampilkan informasi:
- **Last Triggered:** Waktu terakhir rule dipicu
- **Trigger Count:** Berapa kali rule sudah dipicu

---

## ⚠️ Penting untuk Diketahui

### **1. Rule Berjalan di Background**
- Rule akan **terus berjalan** selama aplikasi dibuka (bahkan saat di-minimize)
- Rule **TIDAK AKAN** berjalan jika aplikasi ditutup sepenuhnya

### **2. De bounce Protection**
- Rule memiliki **cooldown 30 detik** untuk menghindari spam notifikasi
- Artinya: Rule yang sama tidak akan terpicu berkali-kali dalam waktu 30 detik

### **3. Syarat Rule Berjalan**
- Dashboard harus aktif
- Widget sumber harus menerima data MQTT
- Koneksi MQTT harus stabil

### **4. Format Data**
- Data MQTT harus berupa **angka** (integer/float)
- Data string tidak akan dievaluasi

---

## 🔧 Troubleshooting

### **Rule tidak terpicu meskipun kondisi terpenuhi?**

**Cek:**
1. ✅ Rule dalam status **ACTIVE** (switch hijau)
2. ✅ Widget sumber menerima data dengan benar
3. ✅ MQTT broker terkoneksi (status "Online" di header)
4. ✅ Topic MQTT widget sama dengan yang dikirim device
5. ✅ Nilai threshold benar (tidak ada typo)

### **Notifikasi tidak muncul?**

**Solusi:**
- **Windows:** Pastikan notifikasi aplikasi tidak di-block di Settings
- **Android:** Berikan permission notifikasi ke aplikasi

### **MQTT Publish tidak jalan?**

**Cek:**
1. Topic dan Payload tidak boleh kosong
2. Broker MQTT dalam status connected
3. Device/topic tujuan valid

---

## 🎯 Tips & Best Practices

1. **Gunakan nama rule yang jelas**
   - ❌ "Rule 1", "Test"
   - ✅ "High Temp Alert", "Auto Light OFF"

2. **Set threshold dengan margin**
   - Hindari nilai threshold yang terlalu sensitif
   - Contoh: Jika normal 70, set threshold 75 (bukan 71)

3. **Kombinasikan multiple actions**
   - Bisa aktifkan notifikasi + MQTT control sekaligus
   - Berguna untuk automation kompleks

4. **Manfaatkan statistik**
   - Cek "Trigger Count" untuk monitoring seberapa sering rule aktif
   - Bisa jadi indikator jika ada masalah sensor

---

## 📱 Notifikasi Sistem

Notifikasi akan muncul di:
- **Windows:** Toast notification (pojok kanan bawah layar)
- **Android:** Notification bar/tray
- **Linux/macOS:** System notification native

Format notifikasi:
```
┌────────────────────────────┐
│ 🔔 [Nama Rule]             │
├────────────────────────────┤
│ Widget: nilai unit         │
│ Condition: operator nilai  │
└────────────────────────────┘
```

---

## 🚀 Fitur Lanjutan (Coming Soon)

- [ ] Multi-condition rules (IF A AND B THEN...)
- [ ] Time-based triggers (Hanya aktif jam 08:00-17:00)
- [ ] Rule history log viewer
- [ ] Export/Import rule configuration
- [ ] Email/Telegram notification

---

## 💬 Contoh Skenario Lengkap

### **Smart Home Temperature Control**

**Equipment:**
- Sensor Suhu (publish ke `home/temp`)
- AC/Heater (subscribe ke `home/ac/control`)

**Rules yang Dibuat:**

1. **"AC Auto ON"**
   ```
   IF home/temp > 28
   THEN publish "ON" to home/ac/control
   ```

2. **"AC Auto OFF"**
   ```
   IF home/temp < 24
   THEN publish "OFF" to home/ac/control
   ```

3. **"Extreme Heat Warning"**
   ```
   IF home/temp > 35
   THEN notify "🔥 Suhu Sangat Tinggi! Segera Cek"
   ```

**Hasil:** Sistem akan otomatis menyalakan/mematikan AC dan memberi warning jika suhu ekstrem.

---

Jika ada pertanyaan, silakan buka menu Help (ℹ️) di Rule Manager screen.
