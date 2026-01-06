# 🔐 App Signing & Keystore - Quick Start

## 🚀 Setup dalam 3 Langkah

### 1️⃣ Generate Keystore
```bash
cd android
.\generate_keystore.bat
```
Ikuti instruksi dan **CATAT SEMUA PASSWORD!**

### 2️⃣ Buat key.properties
```bash
copy key.properties.template key.properties
```
Edit `key.properties` dan ganti placeholder dengan password Anda.

### 3️⃣ Verifikasi Setup
```bash
.\verify_keystore_setup.bat
```
Pastikan semua ✓ (checklist hijau).

---

## 🏗️ Build untuk Play Store

```bash
# Kembali ke root project
cd ..

# Build App Bundle
flutter build appbundle --release
```

File output: `build/app/outputs/bundle/release/app-release.aab`

---

## 📚 Dokumentasi Lengkap

- **Panduan Detail**: [docs/KEYSTORE_GUIDE.md](../docs/KEYSTORE_GUIDE.md)
- **Checklist Setup**: [docs/KEYSTORE_SETUP_CHECKLIST.md](../docs/KEYSTORE_SETUP_CHECKLIST.md)
- **Template Info**: [docs/KEYSTORE_INFO_TEMPLATE.md](../docs/KEYSTORE_INFO_TEMPLATE.md)

---

## ⚠️ PENTING!

1. **Backup keystore** ke minimal 2 tempat aman
2. **Simpan password** di password manager
3. **JANGAN commit** keystore/key.properties ke Git
4. **Jika hilang** = TIDAK BISA update app selamanya!

---

## 📁 Files Created

```
android/
├── upload-keystore.jks           🔐 Keystore file (BACKUP!)
├── key.properties                🔐 Credentials (PRIVATE!)
├── key.properties.template       📝 Template
├── generate_keystore.bat         🛠️ Generator script
├── verify_keystore_setup.bat     ✅ Verification script
└── app/
    ├── build.gradle.kts          ⚙️ Auto-configured
    └── proguard-rules.pro        🛡️ Security rules
```

---

**Status**: ✅ Ready to use  
**Last Updated**: 2026-01-05  
**Project**: Valiot Dashboard
