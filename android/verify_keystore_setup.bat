@echo off
REM ===================================================
REM Script Verifikasi Setup Keystore - Valiot Dashboard
REM ===================================================

echo.
echo ========================================
echo   VERIFIKASI KEYSTORE SETUP
echo ========================================
echo.

set FAILED=0

REM Check 1: Keystore file exists
echo [1/5] Checking keystore file...
if exist "upload-keystore.jks" (
    echo     ✓ upload-keystore.jks ditemukan
) else (
    echo     ✗ upload-keystore.jks TIDAK ditemukan!
    echo       Jalankan: generate_keystore.bat
    set FAILED=1
)

REM Check 2: key.properties exists
echo [2/5] Checking key.properties...
if exist "key.properties" (
    echo     ✓ key.properties ditemukan
    
    REM Check if still has placeholder
    findstr /C:"YOUR_KEYSTORE_PASSWORD_HERE" key.properties >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo     ✗ key.properties masih berisi placeholder!
        echo       Edit file dan ganti dengan password sesungguhnya
        set FAILED=1
    ) else (
        echo     ✓ key.properties sudah dikonfigurasi
    )
) else (
    echo     ✗ key.properties TIDAK ditemukan!
    echo       Copy dari key.properties.template dan edit
    set FAILED=1
)

REM Check 3: build.gradle.kts configured
echo [3/5] Checking build.gradle.kts...
if exist "app\build.gradle.kts" (
    findstr /C:"signingConfigs" app\build.gradle.kts >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo     ✓ build.gradle.kts sudah dikonfigurasi
    ) else (
        echo     ✗ build.gradle.kts belum dikonfigurasi!
        set FAILED=1
    )
) else (
    echo     ✗ build.gradle.kts tidak ditemukan!
    set FAILED=1
)

REM Check 4: ProGuard rules
echo [4/5] Checking ProGuard rules...
if exist "app\proguard-rules.pro" (
    echo     ✓ proguard-rules.pro ditemukan
) else (
    echo     ! proguard-rules.pro tidak ditemukan (optional)
)

REM Check 5: .gitignore configured
echo [5/5] Checking .gitignore...
if exist ".gitignore" (
    findstr /C:"*.jks" .gitignore >nul 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo     ✓ .gitignore sudah configured
    ) else (
        echo     ! .gitignore mungkin belum configured
    )
) else (
    echo     ! .gitignore tidak ditemukan
)

echo.
echo ========================================

if %FAILED% EQU 0 (
    echo   STATUS: ✅ SEMUA VERIFIKASI LULUS!
    echo ========================================
    echo.
    echo Keystore setup sudah lengkap.
    echo Anda bisa build release dengan:
    echo   flutter build appbundle --release
    echo.
    echo JANGAN LUPA:
    echo - Backup keystore ke tempat aman
    echo - Catat semua password
    echo - Jangan commit keystore ke Git
    echo.
) else (
    echo   STATUS: ❌ ADA MASALAH!
    echo ========================================
    echo.
    echo Ada beberapa item yang perlu diperbaiki.
    echo Silakan cek output di atas dan perbaiki.
    echo.
    echo Baca panduan lengkap di:
    echo   docs\KEYSTORE_GUIDE.md
    echo   docs\KEYSTORE_SETUP_CHECKLIST.md
    echo.
)

pause
