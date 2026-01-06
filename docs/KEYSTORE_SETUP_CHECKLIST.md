# ✅ KEYSTORE SETUP CHECKLIST

## 📋 Langkah-Langkah Setup (Ikuti Berurutan)

### **STEP 1: Generate Keystore** 🔑

**Opsi A: Menggunakan Script (Mudah)**
```bash
cd android
.\generate_keystore.bat
```

**Opsi B: Manual (Advanced)**
```bash
cd android
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Checklist:**
- [ ] File `upload-keystore.jks` sudah dibuat
- [ ] Sudah catat semua informasi yang ditanyakan
- [ ] Sudah catat password keystore
- [ ] Sudah catat password key

---

### **STEP 2: Buat File key.properties** ⚙️

1. Copy template:
   ```bash
   cd android
   copy key.properties.template key.properties
   ```

2. Edit `android/key.properties`:
   - Ganti `YOUR_KEYSTORE_PASSWORD_HERE` dengan password Anda
   - Ganti `YOUR_KEY_PASSWORD_HERE` dengan password key Anda
   - Sesuaikan `storeFile` jika keystore di tempat lain

**Checklist:**
- [ ] File `key.properties` sudah dibuat
- [ ] Password sudah diisi dengan benar
- [ ] Path keystore sudah benar

---

### **STEP 3: Simpan Informasi dengan Aman** 💾

1. Isi template `docs/KEYSTORE_INFO_TEMPLATE.md`
2. Simpan di tempat aman (JANGAN di Git!)
3. Backup keystore ke minimal 2 lokasi:
   - Cloud storage (Google Drive, Dropbox)
   - External storage (USB, hard drive)

**Checklist:**
- [ ] Informasi keystore sudah dicatat lengkap
- [ ] Password disimpan di password manager
- [ ] Keystore sudah di-backup ke cloud
- [ ] Keystore sudah di-backup ke external storage

---

### **STEP 4: Verifikasi Konfigurasi** ✓

File-file berikut sudah otomatis dikonfigurasi:
- ✅ `android/app/build.gradle.kts` - Signing configuration
- ✅ `android/app/proguard-rules.pro` - Code obfuscation rules
- ✅ `android/.gitignore` - Ignore keystore files

**Checklist:**
- [ ] `build.gradle.kts` sudah memiliki signingConfigs
- [ ] ProGuard rules sudah ada
- [ ] `.gitignore` sudah ignore `*.jks` dan `key.properties`

---

### **STEP 5: Test Build Release** 🧪

```bash
# Test build App Bundle (untuk Play Store)
flutter build appbundle --release

# Atau test build APK
flutter build apk --release
```

**Checklist:**
- [ ] Build berhasil tanpa error
- [ ] File AAB/APK sudah ter-generate
- [ ] Sudah test install APK di device (jika perlu)

---

## 📂 File Structure Setelah Setup

```
valiotdashboard/
├── android/
│   ├── app/
│   │   ├── build.gradle.kts          ✅ Sudah dikonfigurasi
│   │   └── proguard-rules.pro        ✅ Sudah dibuat
│   ├── upload-keystore.jks           🔐 File keystore (JANGAN commit!)
│   ├── key.properties                🔐 Credentials (JANGAN commit!)
│   ├── key.properties.template       📝 Template saja
│   └── generate_keystore.bat         🛠️ Helper script
├── docs/
│   ├── KEYSTORE_GUIDE.md             📚 Panduan lengkap
│   └── KEYSTORE_INFO_TEMPLATE.md     📝 Template info
└── .gitignore                         ✅ Sudah ignore keystore
```

---

## 🚨 SECURITY CHECKLIST

**SEBELUM commit ke Git, pastikan:**
- [ ] `upload-keystore.jks` TIDAK ter-commit
- [ ] `key.properties` TIDAK ter-commit
- [ ] Password TIDAK ada di code atau file lain
- [ ] File `.gitignore` sudah configured
- [ ] Keystore sudah di-backup aman

**Verifikasi dengan:**
```bash
git status
# Pastikan upload-keystore.jks dan key.properties tidak muncul
```

---

## 📱 Build Commands Reference

### Build untuk Play Store (Recommended)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build APK untuk Testing
```bash
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

### Build APK dengan Split per ABI (Ukuran lebih kecil)
```bash
flutter build apk --split-per-abi --release
# Output: app-armeabi-v7a-release.apk, app-arm64-v8a-release.apk, app-x86_64-release.apk
```

### Analyze App Bundle Size
```bash
flutter build appbundle --release --analyze-size
```

---

## 🆘 Troubleshooting

### Error: "Keystore file does not exist"
**Solusi:** Path di `key.properties` salah atau keystore belum dibuat.

### Error: "Keystore was tampered with, or password was incorrect"
**Solusi:** Password di `key.properties` salah.

### Error: "minifyEnabled requires dependencies"
**Solusi:** ProGuard rules sudah dibuat, should work. Jika masih error, set `isMinifyEnabled = false` sementara.

### Build berhasil tapi tidak bisa install di device
**Solusi:** Pastikan signing configuration sudah benar. Coba uninstall versi lama dulu.

---

## 📞 Support

Jika ada masalah:
1. Baca `docs/KEYSTORE_GUIDE.md` untuk detail lengkap
2. Check troubleshooting section
3. Pastikan semua checklist sudah ✅

---

**Last Updated:** 2026-01-05
**Project:** Valiot Dashboard
**Status:** Ready for Play Store Build ✅
