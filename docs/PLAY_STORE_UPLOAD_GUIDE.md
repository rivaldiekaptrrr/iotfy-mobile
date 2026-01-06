# 🚀 Panduan Upload ke Google Play Store - IoTify Platform

## 📋 Prasyarat

Sebelum mulai upload, pastikan Anda sudah memiliki:

- [x] **Akun Google Play Developer** ($25 one-time fee)
- [x] **App Bundle (.aab)** sudah di-build
- [x] **Keystore file** sudah di-backup dengan aman
- [x] **Graphic assets** (icon, screenshots, feature graphic)
- [x] **Privacy Policy URL** (jika aplikasi mengumpulkan data)

---

## 🔑 Step 1: Persiapan Akun Developer

### Daftar Google Play Console

1. Kunjungi: https://play.google.com/console
2. Login dengan akun Google Anda
3. Bayar biaya registrasi developer ($25)
4. Lengkapi profil developer:
   - Nama developer (akan tampil di store)
   - Email kontak
   - Website (optional)

---

## 📱 Step 2: Buat Aplikasi Baru

### Di Google Play Console:

1. Klik **"Create App"** / **"Buat Aplikasi"**
2. Isi form:
   - **App name**: IoTify Platform
   - **Default language**: English (United States) atau Indonesian
   - **App or game**: App
   - **Free or paid**: Free
3. Centang declarations (kebijakan developer)
4. Klik **"Create app"**

---

## 🎨 Step 3: Store Listing

Navigasi ke **Store presence** → **Main store listing**

### 3.1 App Details

**App name**: `IoTify Platform` (max 50 chars)

**Short description**: (max 80 chars)
```
Smart IoT dashboard with real-time MQTT monitoring and control
```

**Full description**: (max 4000 chars)
```
[Copy dari PLAY_STORE_LISTING.md]
Lihat file PLAY_STORE_LISTING.md untuk deskripsi lengkap
```

### 3.2 Graphics

**App icon**: 
- Upload file 512 x 512 px dari `assets/logo.png`
- Pastikan resolusi tinggi dan background transparan

**Feature graphic**: 
- Upload file 1024 x 500 px
- Buat graphic menarik dengan logo + tagline

**Phone screenshots**: (WAJIB minimal 2)
- Upload 2-8 screenshots
- Format landscape atau portrait
- Tunjukkan fitur utama aplikasi

**Tablet screenshots**: (Optional tapi recommended)
- 7-inch tablet: Upload jika punya
- 10-inch tablet: Upload jika punya

### 3.3 Categorization

**App category**: 
- Primary: **Tools** atau **Productivity**
- Tags: IoT, MQTT, Dashboard, Monitoring, Smart Home

**Contact details**:
- Email: [Your support email]
- Website: [Optional]
- Phone: [Optional]

### 3.4 Privacy Policy (Jika diperlukan)

Jika aplikasi Anda:
- Mengumpulkan data user
- Menggunakan credentials yang disimpan
- Tracking lokasi

Maka WAJIB punya Privacy Policy URL.

**Template Privacy Policy**:
```
Our app stores MQTT broker credentials and panel configurations 
locally on your device. We do not collect, transmit, or share 
any personal information with third parties.
```

Simpan di website Anda atau gunakan GitHub Pages.

---

## 🎯 Step 4: App Content

### 4.1 Content Rating

Navigasi ke **Policy** → **App content** → **Content rating**

1. Klik **"Start questionnaire"**
2. Pilih rating board: **IARC**
3. Jawab pertanyaan:
   - Violence: **No**
   - Sexual content: **No**
   - Profanity: **No**
   - Drugs: **No**
   - Gambling: **No**
   - User interaction: **No**
   - Location sharing: **Yes** (jika pakai GPS tracking)
   - Personal info: **No**

**Expected Rating**: Everyone / All Ages

### 4.2 Target Audience

- **Target age group**: 18+ (untuk technical/professional app)
- **Appeals to children**: No

### 4.3 News Apps (Skip jika bukan news app)

- Select: **No, my app is not a news app**

### 4.4 COVID-19 Contact Tracing

- Select: **No**

### 4.5 Data Safety

Isi form data safety:

**Data collection**:
- Does your app collect user data?: **NO** (jika data disimpan lokal saja)
- Are all users required to provide this data?: N/A
- Do you share user data with third parties?: **NO**

**Security practices**:
- Is data encrypted in transit?: **YES** (MQTT TLS jika digunakan)
- Can users request data deletion?: N/A
- Committed to Play Families Policy?: **YES**

### 4.6 Government Apps

- Select: **No**

---

## 🏪 Step 5: Store Settings

### App Access

- **Is your app restricted to specific users?**: No
- **Special access instructions**: None (Unless perlu MQTT credentials demo)

### Ads

- **Does your app contain ads?**: No

---

## 📦 Step 6: Upload App Bundle

Navigasi ke **Release** → **Production** → **Create new release**

### 6.1 Upload AAB

1. Klik **"Upload"**
2. Pilih file: `build/app/outputs/bundle/release/app-release.aab`
3. Tunggu upload selesai (52.7 MB)
4. System akan scan APK - tunggu hingga selesai

### 6.2 Release Details

**Release name**: 
```
1.0.0 - Initial Release
```

**Release notes**: (Untuk setiap bahasa yang didukung)

**English (en-US)**:
```
🎉 Initial Release - IoTify Platform v1.0.0

Welcome to IoTify Platform! Your complete IoT dashboard solution.

✨ Features:
• Real-time MQTT monitoring with live widgets
• Multiple widget types: gauges, charts, tanks, compass
• Device control with toggles, buttons, and sliders
• GPS tracking with interactive maps
• Alarm and notification system
• Customizable layouts with drag-and-drop
• Secure MQTT connections with QoS support
• Local data storage for panels and configurations

🚀 Get started by configuring your MQTT broker and creating your first dashboard!

Thank you for choosing IoTify Platform!
```

**Indonesian (id-ID)** (Optional):
```
🎉 Rilis Pertama - IoTify Platform v1.0.0

Selamat datang di IoTify Platform! Solusi dashboard IoT lengkap Anda.

✨ Fitur:
• Monitoring MQTT real-time dengan widget live
• Berbagai jenis widget: gauge, chart, tangki, kompas
• Kontrol perangkat dengan toggle, button, dan slider
• Pelacakan GPS dengan peta interaktif
• Sistem alarm dan notifikasi
• Layout yang dapat disesuaikan dengan drag-and-drop
• Koneksi MQTT aman dengan dukungan QoS
• Penyimpanan data lokal untuk panel dan konfigurasi

🚀 Mulai dengan mengkonfigurasi MQTT broker dan buat dashboard pertama Anda!

Terima kasih telah memilih IoTify Platform!
```

### 6.3 Review Release

Periksa summary:
- ✅ Version code: 1
- ✅ Version name: 1.0.0
- ✅ Package name: id.iotify.platform
- ✅ Minimum SDK: Android 5.0 (API 21)
- ✅ Target SDK: Latest
- ✅ File size: ~52.7 MB

Klik **"Save"**

---

## 🧪 Step 7: Testing (Optional but Recommended)

### Internal Testing Track

Sebelum publish ke production, disarankan test dulu:

1. Navigasi ke **Release** → **Testing** → **Internal testing**
2. Create release dengan AAB yang sama
3. Tambahkan email tester (max 100)
4. Share link testing ke tester
5. Kumpulkan feedback
6. Fix bugs jika ada
7. Upload versi baru jika perlu (increment version code)

### Closed Testing Track

Untuk testing lebih luas (up to 1000 users):
1. Gunakan **Closed testing** track
2. Buat email list tester
3. Bagikan link opt-in

---

## ✅ Step 8: Submit for Review

### Pre-Submit Checklist

Pastikan semua sudah lengkap:

- [x] Store listing completed
- [x] Graphics uploaded (icon, feature, screenshots)
- [x] Content rating completed
- [x] Privacy policy added (if required)
- [x] App access configured
- [x] Data safety completed
- [x] AAB uploaded
- [x] Release notes written

### Submit

1. Klik **"Send X items for review"** di dashboard
2. atau navigasi ke **Publishing overview**
3. Review semua section (harus semua ✅)
4. Klik **"Send for review"** / **"Publish"**

---

## ⏱️ Review Process Timeline

### What to Expect:

**Initial Review**: 
- Biasanya 1-3 hari kerja
- Bisa lebih cepat (beberapa jam) atau lebih lama (sampai 7 hari)

**Status yang akan Anda lihat**:
1. ⏳ **In review** - Google sedang review
2. ✅ **Published** - Aplikasi sudah live!
3. ❌ **Rejected** - Ada masalah (akan dapat email penjelasan)

### Jika Ditolak:

1. Baca email rejection dengan teliti
2. Perbaiki masalah yang disebutkan
3. Upload versi baru (increment version code)
4. Submit ulang

**Alasan rejection umum**:
- Icon tidak sesuai quality standard
- Description menyesatkan
- Privacy policy missing (jika required)
- App crash saat testing
- Tidak sesuai dengan screenshot

---

## 🎉 After Publishing

### Your App is Live!

Setelah approved, aplikasi akan muncul di Play Store dalam beberapa jam.

**Store URL**: 
```
https://play.google.com/store/apps/details?id=id.iotify.platform
```

### Next Steps:

1. **Monitor Reviews**: 
   - Balas review user dengan cepat
   - Tangani komplain dan bug reports

2. **Track Downloads**:
   - Lihat statistics di Play Console
   - Monitor crash reports

3. **Plan Updates**:
   - Fix bugs yang dilaporkan
   - Tambahkan fitur baru
   - Release update secara berkala

### Update Release Process:

Untuk update selanjutnya:
1. Increment version di `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # version name + version code
   ```
2. Build AAB baru
3. Upload di **Production** → **Create new release**
4. Tulis release notes (What's new)
5. Submit for review

---

## 🆘 Troubleshooting

### Common Issues:

**Upload Error: "Version code already exists"**
- Solution: Increment version code di `pubspec.yaml`

**Rejection: "Icon quality"**
- Solution: Use high-res 512x512 PNG with transparent background

**Rejection: "Privacy policy required"**
- Solution: Add privacy policy URL if app handles user data

**AAB too large (>150MB)**
- Solution: Enable R8 optimization (already done in your project)
- Check for unused assets

**Crash during Google's automated testing**
- Solution: Test thoroughly before upload
- Check ProGuard rules
- Test on multiple devices/Android versions

---

## 📞 Support

**Google Play Console Help**:
- Help Center: https://support.google.com/googleplay/android-developer
- Community Forum: https://support.google.com/googleplay/android-developer/community

**Your Support Channels**:
- Email: [Your email]
- Documentation: `docs/` folder in this project

---

## 🎯 Success Metrics

Track these in Play Console:

- **Downloads**: User acquisition
- **Ratings**: User satisfaction (target 4.0+)
- **Crashes**: Stability (target <1%)
- **ANRs**: Performance (target <0.5%)
- **Retention**: D1, D7, D30 retention rates

---

**Good luck with your Play Store submission!** 🚀

**Created**: 2026-01-06
**App**: IoTify Platform v1.0.0
**Package**: id.iotify.platform
