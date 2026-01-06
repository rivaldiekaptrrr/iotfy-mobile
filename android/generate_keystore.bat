@echo off
REM ===================================================
REM Script untuk Generate Keystore - Valiot Dashboard
REM ===================================================

echo.
echo ========================================
echo   GENERATE KEYSTORE FOR PLAY STORE
echo ========================================
echo.
echo PERINGATAN: Simpan password dengan AMAN!
echo Jika hilang, TIDAK BISA update app selamanya!
echo.
echo ========================================
echo.

REM Set lokasi output keystore
set KEYSTORE_FILE=upload-keystore.jks
set KEY_ALIAS=upload

echo File keystore akan dibuat: %KEYSTORE_FILE%
echo Key alias: %KEY_ALIAS%
echo Validity: 10000 hari (~27 tahun)
echo.

REM Check if keytool exists
set "KEYTOOL_CMD=keytool"
where keytool >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Keytool tidak ada di PATH, mengecek lokasi default Android Studio...
    
    if exist "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" (
        set "KEYTOOL_CMD=C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
        echo Keytool ditemukan di: Android Studio JBR
    ) else if exist "C:\Program Files\Android\Android Studio\jre\bin\keytool.exe" (
        set "KEYTOOL_CMD=C:\Program Files\Android\Android Studio\jre\bin\keytool.exe"
        echo Keytool ditemukan di: Android Studio JRE
    ) else (
        echo ERROR: keytool tidak ditemukan!
        echo.
        echo Pastikan Java JDK sudah terinstall dan ada di PATH.
        echo Atau install Android Studio.
        echo.
        pause
        exit /b 1
    )
)

echo Menggunakan Keytool: "%KEYTOOL_CMD%"
echo.
echo ========================================
echo   INFORMASI YANG AKAN DITANYAKAN:
echo ========================================
echo 1. Keystore password (WAJIB CATAT!)
echo 2. Nama lengkap / Nama perusahaan
echo 3. Organizational unit (bisa isi: Development)
echo 4. Organization (nama perusahaan)
echo 5. City (kota)
echo 6. State (provinsi)
echo 7. Country code (ketik: ID)
echo ========================================
echo.
pause

REM Generate keystore
"%KEYTOOL_CMD%" -genkey -v -keystore %KEYSTORE_FILE% -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias %KEY_ALIAS%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo   BERHASIL!

    echo ========================================
    echo.
    echo Keystore telah dibuat: %KEYSTORE_FILE%
    echo.
    echo LANGKAH SELANJUTNYA:
    echo 1. Catat semua password yang Anda buat
    echo 2. Backup file %KEYSTORE_FILE% ke tempat aman
    echo 3. Buat file key.properties dengan informasi keystore
    echo 4. Jangan commit keystore ke Git!
    echo.
    echo Baca panduan lengkap di: docs\KEYSTORE_GUIDE.md
    echo.
) else (
    echo.
    echo ========================================
    echo   GAGAL!
    echo ========================================
    echo.
    echo Terjadi error saat membuat keystore.
    echo Silakan coba lagi atau buat secara manual.
    echo.
)

pause
