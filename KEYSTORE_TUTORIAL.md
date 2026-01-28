# Tutorial: Generate Keystore Baru untuk Flutter APK Release

## Masalah
Keystore `upload-keystore.jks` corrupt dan menyebabkan build APK gagal dengan error:
```
Failed to read key upload from store "D:\Project\valiotdashboard\android\upload-keystore.jks": 
DerInputStream.getLength(): lengthTag=63, too big.
```

## Solusi: Generate Keystore Baru

### Step 1: Hapus Keystore Lama yang Corrupt

1. Buka **File Explorer**
2. Navigate ke: `D:\Project\valiotdashboard\android\`
3. Hapus file `upload-keystore.jks` (klik kanan → Delete)
4. Hapus juga file `key.properties` (jika ada)

### Step 2: Generate Keystore Baru

Buka **Command Prompt** atau **PowerShell**, lalu jalankan:

```powershell
keytool -genkey -v -keystore D:\Project\valiotdashboard\android\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Anda akan ditanya beberapa pertanyaan. Isi seperti contoh berikut:**

```
Enter keystore password: [ketik password, contoh: valiot123]
Re-enter new password: [ketik password yang sama]

What is your first and last name?
  [Unknown]:  Rivaldi Sinkoprima
What is the name of your organizational unit?
  [Unknown]:  Development
What is the name of your organization?
  [Unknown]:  Rivaldi
What is the name of your City or Locality?
  [Unknown]:  Jakarta
What is the name of your State or Province?
  [Unknown]:  DKI Jakarta
What is the two-letter country code for this unit?
  [Unknown]:  ID
Is CN=Rivaldi Sinkoprima, OU=Development, O=Rivaldi, L=Jakarta, ST=DKI Jakarta, C=ID correct?
  [no]:  yes

Enter key password for <upload>
    (RETURN if same as keystore password): [tekan ENTER]
```

✅ **PENTING: Simpan password yang Anda gunakan! Anda akan membutuhkannya di step berikutnya.**

---

### Step 3: Buat File `key.properties`

Buat file baru di `D:\Project\valiotdashboard\android\key.properties` dengan isi:

```properties
storePassword=valiot123
keyPassword=valiot123
keyAlias=upload
storeFile=upload-keystore.jks
```

**⚠️ Ganti `valiot123` dengan password yang Anda gunakan di Step 2!**

---

### Step 4: Verifikasi Konfigurasi Gradle

File `android/app/build.gradle.kts` seharusnya sudah dikonfigurasi. Pastikan ada bagian ini:

```kotlin
// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ...
    
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

---

### Step 5: Build APK Release

Setelah semua selesai, jalankan:

```powershell
flutter clean
flutter build apk
```

APK akan tersimpan di: `build\app\outputs\flutter-apk\app-release.apk`

---

## Troubleshooting

### ❌ Error: `keytool: command not found`
**Solusi:** Tambahkan Java ke PATH atau gunakan full path:
```powershell
"C:\Program Files\Java\jdk-XX.X.X\bin\keytool.exe" -genkey -v ...
```

### ❌ Error: `keystore passwords must be at least 6 characters`
**Solusi:** Gunakan password minimal 6 karakter.

### ❌ Build masih gagal setelah generate keystore baru
**Solusi:** 
1. Pastikan `key.properties` ada dan isinya benar
2. Periksa `android/app/build.gradle.kts` sudah load `key.properties`
3. Jalankan `flutter clean` lalu build lagi

---

## Catatan Penting

⚠️ **JANGAN commit file-file berikut ke Git (untuk keamanan):**
- `android/upload-keystore.jks`
- `android/key.properties`

Pastikan file `.gitignore` sudah berisi:
```
**/android/upload-keystore.jks
**/android/key.properties
```

📝 **Simpan password dan keystore di tempat aman!** 
Jika kehilangan keystore, Anda TIDAK BISA update aplikasi yang sudah dipublish di Google Play Store!
