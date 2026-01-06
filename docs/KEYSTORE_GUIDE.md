# 🔐 Panduan App Signing & Keystore - Valiot Dashboard

## alya@290701
## 📌 Apa itu Keystore?

Keystore adalah file yang berisi **private key** untuk menandatangani APK/App Bundle Anda. File ini adalah "identitas digital" app Anda dan **SANGAT PENTING** untuk disimpan dengan aman.

### ⚠️ PERINGATAN PENTING:
- ❌ **JANGAN PERNAH** kehilangan file keystore
- ❌ **JANGAN PERNAH** lupa password keystore
- ❌ **JANGAN PERNAH** commit keystore ke Git/public repository
- ✅ **WAJIB** backup keystore di tempat aman (cloud, USB, dll)

**Jika keystore hilang**: Anda tidak akan pernah bisa update app di Play Store!

---

## 🚀 Langkah 1: Generate Keystore File

### Opsi A: Menggunakan Command Line (Recommended)

Buka terminal/command prompt di folder `android/app/` dan jalankan:

```bash
# Untuk Windows (PowerShell/CMD)
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Untuk Mac/Linux
keytool -genkey -v -keystore ~/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Penjelasan Parameter:
- `-keystore upload-keystore.jks`: Nama file keystore yang akan dibuat
- `-keyalg RSA`: Algoritma enkripsi
- `-keysize 2048`: Ukuran key (2048 bit)
- `-validity 10000`: Masa berlaku 10000 hari (~27 tahun)
- `-alias upload`: Nama alias untuk key ini

### Pertanyaan yang Akan Ditanyakan:

Anda akan diminta mengisi informasi berikut:

```
Enter keystore password: [Buat password KUAT dan CATAT!]
Re-enter new password: [Ulangi password]
What is your first and last name? [Nama Anda atau Nama Perusahaan]
What is the name of your organizational unit? [Divisi/Unit, bisa diisi "Development"]
What is the name of your organization? [Nama Perusahaan]
What is the name of your City or Locality? [Kota]
What is the name of your State or Province? [Provinsi]
What is the two-letter country code for this unit? [ID untuk Indonesia]
Is CN=..., correct? [yes]
Enter key password for <upload>: [Tekan ENTER untuk pakai password yang sama]
```

### ✅ Hasil:
File `upload-keystore.jks` akan dibuat.

---

## 🔐 Langkah 2: Simpan Informasi Keystore dengan Aman

### 2.1. Buat File `key.properties`

Buat file baru di `android/key.properties` dengan isi:

```properties
storePassword=PASSWORD_KEYSTORE_ANDA
keyPassword=PASSWORD_KEY_ANDA
keyAlias=upload
storeFile=../upload-keystore.jks
```

**Ganti:**
- `PASSWORD_KEYSTORE_ANDA`: Password yang Anda buat tadi
- `PASSWORD_KEY_ANDA`: Password key (biasanya sama dengan storePassword)

### 2.2. Pindahkan Keystore ke Lokasi yang Aman

**Option 1: Di dalam project (NOT RECOMMENDED untuk production)**
```
valiotdashboard/
  android/
    upload-keystore.jks  ← Simpan di sini
    key.properties
```

**Option 2: Di luar project (RECOMMENDED)**
```
C:/AndroidKeys/
  valiotdashboard-upload-keystore.jks
```

Jika pilih Option 2, ubah `storeFile` di `key.properties`:
```properties
storeFile=C:/AndroidKeys/valiotdashboard-upload-keystore.jks
```

### 2.3. Update `.gitignore`

Pastikan `android/.gitignore` berisi:
```gitignore
upload-keystore.jks
key.properties
*.jks
*.keystore
```

Ini untuk memastikan keystore TIDAK ter-upload ke Git.

---

## ⚙️ Langkah 3: Konfigurasi Signing di `build.gradle.kts`

File `android/app/build.gradle.kts` perlu diupdate untuk menggunakan keystore saat build release.

### Update akan dilakukan pada:
1. Baca konfigurasi dari `key.properties`
2. Tambahkan `signingConfigs` untuk release
3. Gunakan signing config di `buildTypes.release`

**File akan diupdate secara otomatis** di langkah berikutnya.

---

## 📝 Langkah 4: Simpan Informasi Penting

### **CATATAN PENTING - SIMPAN DI TEMPAT AMAN!**

```
================================
KEYSTORE INFORMATION - VALIOT DASHBOARD
================================

File Location: [Path ke upload-keystore.jks]
Keystore Password: [Password Anda]
Key Alias: upload
Key Password: [Password Key Anda]

Generated Date: [Tanggal hari ini]
Validity: 10000 days (~27 years)
Algorithm: RSA 2048-bit

================================
ORGANIZATIONAL INFO
================================
Name: [First and Last Name]
Organizational Unit: [Unit]
Organization: [Company Name]
City: [City]
State: [Province]
Country: ID

================================
⚠️ SECURITY NOTES
================================
- Backup file ini dan keystore di 3 lokasi berbeda
- Jangan share password ke siapapun
- Jangan commit ke Git
- Jika hilang, TIDAK BISA update app di Play Store
================================
```

---

## 🧪 Langkah 5: Test Build Release

Setelah semua konfigurasi selesai, test dengan:

```bash
# Build App Bundle (untuk Play Store)
flutter build appbundle --release

# Build APK (untuk testing)
flutter build apk --release
```

Jika berhasil, file akan ada di:
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/apk/release/app-release.apk`

---

## 📦 Backup Checklist

- [ ] Backup `upload-keystore.jks` ke cloud (Google Drive, Dropbox, dll)
- [ ] Backup `upload-keystore.jks` ke USB/external drive
- [ ] Simpan password di password manager (LastPass, 1Password, dll)
- [ ] Print informasi keystore dan simpan di tempat aman
- [ ] Share backup ke team member yang dipercaya (jika ada)

---

## 🆘 Troubleshooting

### Error: "keytool: command not found"

**Solusi**: Tambahkan Java JDK ke PATH:
1. Cari lokasi Java JDK (biasanya di `C:\Program Files\Java\jdk-xx\bin`)
2. Tambahkan ke System Environment Variables → PATH

### Error: "Keystore was tampered with, or password was incorrect"

**Solusi**: Password salah, coba ingat lagi atau regenerate keystore baru.

### Error: "Cannot read key: Invalid keystore format"

**Solusi**: File keystore corrupt, gunakan backup atau regenerate.

---

## ✅ Checklist Akhir

Sebelum upload ke Play Store, pastikan:
- [ ] Keystore file sudah dibuat
- [ ] `key.properties` sudah dikonfigurasi
- [ ] `build.gradle.kts` sudah diupdate
- [ ] Keystore sudah di-backup minimal 2 tempat
- [ ] Test build release berhasil
- [ ] Keystore TIDAK ada di Git repository

---

**Created**: 2026-01-05
**Project**: Valiot Dashboard
**Purpose**: Play Store Release Preparation
