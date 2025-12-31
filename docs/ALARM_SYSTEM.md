# Alarm System - Dokumentasi Lengkap

Sistem Alarm di VALIoT Dashboard adalah fitur monitoring otomatis yang memberikan peringatan real-time berdasarkan kondisi sensor yang telah ditentukan.

---

## 📋 Daftar Isi

1. [Pengenalan](#pengenalan)
2. [Konsep Dasar](#konsep-dasar)
3. [Severity Levels](#severity-levels)
4. [Status Alarm](#status-alarm)
5. [Cara Membuat Alarm](#cara-membuat-alarm)
6. [Alarm Widget](#alarm-widget)
7. [Acknowledge & Clear](#acknowledge--clear)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

---

## 🎯 Pengenalan

Alarm System bekerja bersama dengan **Rule Engine** untuk:
- ✅ Monitoring sensor secara real-time
- ✅ Deteksi kondisi abnormal otomatis
- ✅ Notifikasi ke sistem operasi
- ✅ Tracking alarm history dengan timestamp
- ✅ Acknowledge mechanism untuk operator

**Perbedaan dengan Rule Engine:**
- **Rule Engine**: Eksekusi aksi (publish MQTT, notification, dll)
- **Alarm System**: Tracking event + lifecycle management

---

## 🧩 Konsep Dasar

### **Alarm Lifecycle:**

```
┌─────────────────────────────────────────────┐
│  Sensor Data → Rule Evaluation              │
└──────────────┬──────────────────────────────┘
               │
               ▼
      ┌────────────────┐
      │ Condition Met? │
      └────┬───────────┘
           │ YES
           ▼
   ┌───────────────────┐
   │ CREATE Alarm      │◄─── startTime = now()
   │ Status: ACTIVE    │
   └───────┬───────────┘
           │
           ├──► User: ACKNOWLEDGE ──► Status: ACKNOWLEDGED
           │
           ├──► Condition Normal ───► Status: CLEARED
           │                          endTime = now()
           │
           └──► Duration = endTime - startTime
```

### **Komponen Utama:**

1. **AlarmEvent**: Object yang menyimpan data alarm
   - ID, Rule ID, Sensor Name
   - Severity, Status
   - Start Time, End Time, Duration
   - Trigger Value, Threshold

2. **AlarmPanel Widget**: Display 3 alarm terbaru di dashboard

3. **AlarmDetailScreen**: List 10 alarm + acknowledge button

4. **RuleEvaluatorService**: Background service yang mengelola lifecycle

---

## ⚠️ Severity Levels

Severity ditentukan **saat membuat rule** (bukan auto-detect).

### **1. 🔴 CRITICAL**

**Karakteristik:**
- Icon: ❌ Error
- Color: Merah
- Notifikasi: High priority

**Use Case:**
- Sistem shutdown/offline
- Suhu ekstrem (kebakaran)
- Pressure over limit (ledakan)
- Security breach

**Contoh:**
```
Rule: "Critical Temperature"
IF suhu_mesin > 90°C
Severity: CRITICAL
Action: Notification + Emergency Shutdown
```

---

### **2. 🟠 MAJOR**

**Karakteristik:**
- Icon: ⚠️ Warning
- Color: Orange
- Notifikasi: Medium priority

**Use Case:**
- Performance degradation
- Resource usage tinggi
- Koneksi tidak stabil
- Maintenance needed

**Contoh:**
```
Rule: "High CPU Usage"
IF cpu_usage > 80%
Severity: MAJOR
Action: Notification + Log
```

---

### **3. 🟡 MINOR**

**Karakteristik:**
- Icon: ℹ️ Info
- Color: Kuning
- Notifikasi: Low priority

**Use Case:**
- Informasi penting
- Kondisi tidak ideal tapi tidak urgent
- Warning preventif

**Contoh:**
```
Rule: "Low Battery"
IF battery < 20%
Severity: MINOR
Action: Notification
```

---

## 📊 Status Alarm

### **1. 🟢 ACTIVE (Aktif)**

**Deskripsi:** Alarm baru dibuat, kondisi masih terpenuhi, belum di-acknowledge.

**Karakteristik:**
- Border berwarna sesuai severity
- Duration terus bertambah
- Bisa di-acknowledge

**Behavior:**
- ✅ Auto-clear saat kondisi normal
- ✅ Bisa di-acknowledge
- ✅ Tampil di top list

---

### **2. 🔵 ACKNOWLEDGED (Sudah Dikonfirmasi)**

**Deskripsi:** Operator sudah aware, tapi kondisi masih abnormal.

**Karakteristik:**
- Badge "ACK" biru
- Background semi-transparent
- Duration masih berjalan

**Behavior:**
- ❌ TIDAK auto-clear (manual intervention)
- ⏸️ Duration stop saat endTime di-set manual
- 📌 Tetap di list untuk tracking

**Cara Acknowledge:**
1. Buka Alarm Panel → Details
2. Klik tombol "ACK" di alarm yang diinginkan
3. Status berubah menjadi ACKNOWLEDGED

---

### **3. ✅ CLEARED (Selesai)**

**Deskripsi:** Kondisi sudah normal kembali, alarm resolved.

**Karakteristik:**
- Badge "CLEARED" hijau
- endTime sudah ter-set
- Duration final

**Behavior:**
- 📝 Masih tampil di history (10 alarms)
- ⏹️ Tidak muncul di panel (hanya active)
- 🕒 Duration = endTime - startTime

**Cara Clear:**
- **Otomatis**: Saat sensor kembali normal (untuk status ACTIVE)
- **Manual**: Acknowledged alarm harus di-clear manual (future feature)

---

## 🔧 Cara Membuat Alarm

### **Step-by-Step:**

#### **1. Buat Rule dengan Severity**

```
Dashboard → Klik ⚙️ Rule (top bar) → [+ Add Rule]
```

**Form Konfigurasi:**

**A. Rule Name**
```
Contoh: "Overheat Protection"
```

**B. Condition (IF)**
```
Source Widget: [Pilih sensor yang ingin dimonitor]
Operator: [>, <, >=, <=, ==, !=]
Threshold: [Nilai batas, contoh: 80]
```

**C. Severity** ⭐ **PENTING!**
```
Dropdown: [Critical / Major / Minor]
```

**D. Actions (THEN)**
```
☑ Show Notification
  Title: "⚠️ Overheating Detected!"

☑ Publish MQTT (optional)
  Topic: cooling/fan/control
  Payload: ON
```

**E. Save**
```
Klik [Save] → Rule aktif otomatis
```

---

#### **2. Tambah Alarm Widget ke Dashboard**

```
Dashboard → Edit Mode (✏️) → [+ Add Widget]
```

**Pilih Widget Type:**
```
Scroll ke bawah → Pilih "Alarm Panel"
```

**Konfigurasi:**
```
Title: "Recent Alarms"
(Tidak perlu topic, data otomatis dari rule engine)
```

**Posisi & Size:**
```
Default: 8x6 grid cells
Bisa di-resize sesukanya
```

---

### **Contoh Lengkap:**

**Skenario: Monitoring Suhu Ruang Server**

**Rule 1: Critical Overheat**
```yaml
Name: "Server Room Critical"
Condition:
  Source: Temperature Sensor
  Operator: >
  Threshold: 35
Severity: CRITICAL
Actions:
  - Notification: "🔴 CRITICAL: Server room > 35°C!"
  - MQTT: cooling/emergency → "ON"
```

**Rule 2: Warning High Temp**
```yaml
Name: "Server Room Warning"
Condition:
  Source: Temperature Sensor
  Operator: >
  Threshold: 30
Severity: MAJOR
Actions:
  - Notification: "🟠 WARNING: Server room > 30°C"
```

**Rule 3: Info Low Temp**
```yaml
Name: "Server Room Cold"
Condition:
  Source: Temperature Sensor
  Operator: <
  Threshold: 18
Severity: MINOR
Actions:
  - Notification: "🔵 INFO: Server room < 18°C"
```

**Hasil:**
- 3 level monitoring dengan severity berbeda
- Automatic hierarchy (Critical > Major > Minor)
- Comprehensive coverage (terlalu panas, normal, terlalu dingin)

---

## 📱 Alarm Widget

### **Alarm Panel (Dashboard Widget)**

**Tampilan:**
```
┌─────────────────────────────────────┐
│ 🔔 Recent Alarms          [Details] │
├─────────────────────────────────────┤
│ 🔴 CRITICAL              10:30 AM   │
│ Temperature Sensor                  │
│ Duration: 5m 30s                    │
├─────────────────────────────────────┤
│ 🟠 MAJOR                 10:25 AM   │
│ Humidity Sensor          [ACK]      │
│ Duration: 10m 15s                   │
├─────────────────────────────────────┤
│ 🟡 MINOR                 09:50 AM   │
│ Pressure Sensor                     │
│ Duration: 45m 20s                   │
└─────────────────────────────────────┘
```

**Features:**
- ✅ Tampil 3 alarm ACTIVE terbaru
- ✅ Auto-scroll jika lebih dari 3
- ✅ Color-coded borders
- ✅ Real-time duration update
- ✅ Quick acknowledge
- ✅ Details button untuk full list

---

### **Alarm Detail Screen**

**Cara Akses:**
```
Alarm Panel → Klik [Details]
```

**Tampilan:**
```
┌─────────────────────────────────────┐
│ ← Alarm Details                     │
├─────────────────────────────────────┤
│ 🔴 CRITICAL              [ACK]      │
│ Server Temperature                  │
│ ├─ Start: 31/12/2025 10:30:15      │
│ ├─ Duration: 5m 30s                │
│ ├─ Condition: > 35°C               │
│ └─ Value: 37.5°C                   │
├─────────────────────────────────────┤
│ 🟠 MAJOR          [ACKNOWLEDGED]    │
│ Network Latency                     │
│ ├─ Start: 31/12/2025 10:25:00      │
│ ├─ Duration: 10m 15s               │
│ ├─ Condition: > 200ms              │
│ └─ Value: 250ms                    │
├─────────────────────────────────────┤
│ ... (8 more alarms)                │
└─────────────────────────────────────┘
```

**Features:**
- ✅ List 10 alarms (active + cleared)
- ✅ Full alarm info (start, end, duration, values)
- ✅ Acknowledge button per alarm
- ✅ Status badges (ACK / CLEARED)
- ✅ Scroll untuk history lebih jauh

---

## ✅ Acknowledge & Clear

### **Acknowledge Workflow:**

```
User melihat alarm → Investigasi → Klik ACK
      ↓
Status: ACTIVE → ACKNOWLEDGED
      ↓
- Badge "ACK" muncul
- Background jadi semi-transparent
- TIDAK auto-clear (butuh manual intervention)
- Duration tetap berjalan sampai endTime di-set
```

**Kapan Acknowledge?**
- ✅ Operator sudah aware masalah
- ✅ Sedang dalam proses perbaikan
- ✅ Ingin prevent alarm hilang otomatis
- ✅ Tracking manual resolution

---

### **Auto-Clear Mechanism:**

**Kondisi Auto-Clear:**
```
IF alarm.status == ACTIVE
   AND condition_not_met (sensor normal)
THEN
   alarm.status = CLEARED
   alarm.endTime = now()
```

**Kondisi TIDAK Auto-Clear:**
```
IF alarm.status == ACKNOWLEDGED
THEN
   Tetap di list sampai manual clear (future update)
```

**Example:**
```
Rule: Temperature > 80°C

Timeline:
10:00 - Suhu 85°C → Alarm ACTIVE dibuat
10:05 - User ACK → Status: ACKNOWLEDGED
10:10 - Suhu turun 75°C → Alarm TETAP ACKNOWLEDGED (tidak auto-clear)
10:15 - User resolve issue → Manual clear (future feature)
```

---

## 💡 Best Practices

### **1. Severity Assignment**

**DO ✅**
- Critical: Hanya untuk kondisi darurat (downtime, safety)
- Major: Untuk masalah yang perlu segera ditangani
- Minor: Untuk warning preventif

**DON'T ❌**
- Semua alarm Critical (jadi tidak prioritas)
- Tidak ada Minor (kehilangan early warning)

---

### **2. Rule Threshold**

**DO ✅**
- Beri margin dari nilai normal:
  ```
  Normal: 70°C
  Major: > 80°C (margin 10°C)
  Critical: > 90°C (margin 20°C)
  ```
- Multiple rules untuk berbagai level

**DON'T ❌**
- Threshold terlalu sensitif (alarm noise)
- Satu threshold untuk semua severity

---

### **3. Acknowledge Discipline**

**DO ✅**
- ACK setelah investigate
- ACK hanya untuk alarm yang ditangani
- Review acknowledged alarms secara berkala

**DON'T ❌**
- ACK semua alarm tanpa cek
- Biarkan acknowledged alarms menumpuk
- Ignore alarm karena sering muncul

---

### **4. Alarm Widget Placement**

**DO ✅**
- Taruh di posisi visible (top-right dashboard)
- Ukuran cukup besar untuk 3 alarms
- Grouping dengan widget terkait

**DON'T ❌**
- Tersembunyi di scroll bawah
- Terlalu kecil (text terpotong)
- Mixed dengan widget tidak related

---

## 🐛 Troubleshooting

### **Alarm Tidak Muncul**

**Problem:** Rule trigger tapi alarm tidak dibuat

**Checklist:**
- [ ] Rule status ACTIVE (hijau)
- [ ] Sensor mengirim data valid (cek System Logs)
- [ ] MQTT connected
- [ ] Threshold sudah terlewati
- [ ] Debounce 30 detik sudah lewat

**Solution:**
```
1. Cek Rule Manager → Rule masih ON?
2. Buka System Logs → Ada incoming data?
3. Test manual: publish data via MQTT client
4. Restart rule: Toggle OFF → ON
```

---

###**Alarm Tidak Auto-Clear**

**Problem:** Sensor sudah normal tapi alarm tetap ACTIVE

**Possible Causes:**
1. Alarm sudah ACKNOWLEDGED
2. Sensor belum kirim data terbaru
3. Threshold masih terlewati (nilai borderline)

**Solution:**
```
IF status == ACKNOWLEDGED:
   - Normal behavior, butuh manual clear
   
IF sensor tidak kirim data:
   - Cek MQTT topic subscription
   - Restart broker connection
   
IF nilai borderline:
   - Adjust threshold dengan margin lebih besar
```

---

### **Duplicate Alarms**

**Problem:** Satu kondisi create multiple alarms

**Cause:**
- Debounce tidak cukup (30 detik)
- Multiple rules dengan source sama

**Solution:**
```
1. Check: Apakah ada >1 rule untuk sensor yang sama?
2. Merge rules atau adjust threshold
3. Increase debounce (edit code jika perlu)
```

---

### **Performance Issues**

**Problem:** Dashboard lag saat banyak alarm

**Cause:**
- Alarm history terlalu banyak (>100)

**Solution:**
```
1. Manual clear old alarms (future: auto-purge)
2. Filter alarm di detail screen
3. Archive alarm > 7 hari
```

---

## 📊 Alarm Statistics (Future Enhancement)

Fitur yang bisa ditambahkan di masa depan:

- [ ] Alarm count per severity (dashboard widget)
- [ ] Alarm frequency chart (trend analysis)
- [ ] MTBF (Mean Time Between Failures)
- [ ] MTTR (Mean Time To Resolution)
- [ ] Export alarm history (CSV/PDF)
- [ ] Email/SMS notification
- [ ] Alarm sound/ringtone
- [ ] Snooze alarm function
- [ ] Alarm escalation (auto-promote severity)

---

## 🔗 Related Documentation

- **[RULE_ENGINE.md](./RULE_ENGINE.md)** - Rule Engine documentation
- **[WIDGET_USAGE.md](./WIDGET_USAGE.md)** - Widget configuration guide

---

**Last Updated:** 31 Desember 2025  
**Version:** 1.0.0
