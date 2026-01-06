# ✅ Release Checklist - IoTify Platform

Quick checklist untuk memastikan semua sudah siap sebelum publish ke Play Store.

---

## 📋 Pre-Build Checklist

### Code & Configuration

- [ ] Application ID sudah diganti dari `com.example.*`
  - Current: `id.iotify.platform` ✅
- [ ] App name sudah sesuai dengan brand
  - pubspec.yaml: `iotify_platform` ✅
  - AndroidManifest.xml: `IoTify Platform` ✅
- [ ] Version number sudah benar di `pubspec.yaml`
  - Current: `1.0.0+1` ✅
- [ ] Semua TODO comments sudah dihapus atau diselesaikan
- [ ] Debug logs sudah dihapus atau di-comment
- [ ] Test code berjalan tanpa error
  ```bash
  flutter test
  ```

### Assets

- [ ] App icon sudah di-generate
  ```bash
  flutter pub run flutter_launcher_icons
  ```
- [ ] Logo final sudah ada di `assets/logo.png` ✅
- [ ] Semua assets yang dipakai sudah terdaftar di `pubspec.yaml`
- [ ] Tidak ada assets yang tidak terpakai (untuk mengecilkan ukuran app)

### Dependencies

- [ ] Semua dependencies sudah update (optional)
  ```bash
  flutter pub outdated
  ```
- [ ] Tidak ada unused dependencies
- [ ] Build dependencies (`dev_dependencies`) tidak masuk production build

---

## 🔐 Signing & Security

### Keystore

- [ ] Keystore file sudah dibuat ✅
  - Location: `android/upload-keystore.jks`
- [ ] `key.properties` sudah dikonfigurasi dengan benar ✅
- [ ] Password keystore sudah dicatat di tempat aman
- [ ] Keystore sudah di-backup ke minimum 2 lokasi berbeda:
  - [ ] Cloud storage (Google Drive, Dropbox, etc.)
  - [ ] External USB/HDD
  - [ ] Password manager
- [ ] Keystore **TIDAK** ter-commit ke Git
  - Check `.gitignore` includes `*.jks` and `key.properties` ✅

### Build Configuration

- [ ] `build.gradle.kts` signing config sudah correct ✅
- [ ] ProGuard rules sudah ditambahkan ✅
- [ ] R8 code shrinking enabled ✅
  ```kotlin
  isMinifyEnabled = true
  isShrinkResources = true
  ```

---

## 🏗️ Build Process

### Test Build

- [ ] Build debug berjalan tanpa error
  ```bash
  flutter build apk --debug
  ```
- [ ] Test di real device (bukan emulator)
- [ ] Test semua fitur utama:
  - [ ] MQTT connection
  - [ ] Widget creation & editing
  - [ ] Panel management
  - [ ] Data visualization
  - [ ] Notifications
  - [ ] GPS tracking (if applicable)

### Release Build

- [ ] Clean build directory
  ```bash
  flutter clean
  ```
- [ ] Get latest dependencies
  ```bash
  flutter pub get
  ```
- [ ] Build App Bundle (AAB) berhasil
  ```bash
  flutter build appbundle --release --no-tree-shake-icons
  ```
- [ ] Tidak ada error atau warning critical
- [ ] File AAB terbentuk di `build/app/outputs/bundle/release/app-release.aab` ✅
- [ ] Ukuran AAB masuk akal (<150MB for Play Store) ✅
  - Current: ~52.7 MB ✅

### Post-Build Testing

- [ ] Install APK release dan test di device
  ```bash
  flutter build apk --release --no-tree-shake-icons
  flutter install --release
  ```
- [ ] Test cold start (launch app setelah device restart)
- [ ] Test dengan internet mati (graceful error handling)
- [ ] Test dengan koneksi lambat
- [ ] Tidak ada crash yang terdeteksi
- [ ] Performance acceptable (tidak lag)

---

## 🎨 Play Store Assets

### Graphics Required

- [ ] **App Icon** (512 x 512 px)
  - [ ] File ready (PNG, 32-bit)
  - [ ] High quality, no pixelation
  - [ ] Transparent background atau white background
  - Source: `assets/logo.png` ✅

- [ ] **Feature Graphic** (1024 x 500 px)
  - [ ] File created (PNG or JPG)
  - [ ] Eye-catching design
  - [ ] Includes app name/logo
  - [ ] No text ratio >20%

- [ ] **Screenshots - Phone** (Minimum 2, Maximum 8)
  - [ ] Screenshot 1: Dashboard overview
  - [ ] Screenshot 2: Widget showcase
  - [ ] Screenshot 3: Connection setup (optional)
  - [ ] Screenshot 4: Real-time monitoring (optional)
  - [ ] All screenshots of correct size (min 320px shortest side)
  - [ ] Screenshots show actual app functionality
  - [ ] No emulator artifacts visible

- [ ] **Screenshots - Tablet** (Recommended)
  - [ ] 7-inch tablet screenshots (optional)
  - [ ] 10-inch tablet screenshots (optional)

### Store Listing Text

- [ ] **Short Description** prepared (max 80 chars) ✅
  - See: `docs/PLAY_STORE_LISTING.md`
  
- [ ] **Full Description** prepared (max 4000 chars) ✅
  - See: `docs/PLAY_STORE_LISTING.md`
  - [ ] Highlights key features
  - [ ] Includes use cases
  - [ ] Professional formatting
  - [ ] No grammar errors

- [ ] **Release Notes** prepared ✅
  - See: `docs/PLAY_STORE_UPLOAD_GUIDE.md`
  - [ ] Describes what's new
  - [ ] Lists main features (for v1.0.0)

---

## 📝 Legal & Compliance

### Required Documents

- [ ] **Privacy Policy** (if applicable)
  - [ ] URL ready and accessible
  - [ ] Covers data collection practices
  - [ ] Mentions MQTT credential storage
  - [ ] Uploaded to website or GitHub Pages

- [ ] **Terms of Service** (optional but recommended)
  - [ ] Describes acceptable use
  - [ ] Liability disclaimers

### Declarations

- [ ] App follows Google Play policies
- [ ] No copyright infringement
- [ ] No misleading content
- [ ] Age-appropriate content
- [ ] Data safety info accurate

---

## 🎯 Play Console Setup

### Developer Account

- [ ] Google Play Developer account created ($25 paid)
- [ ] Developer profile completed:
  - [ ] Developer name
  - [ ] Email address
  - [ ] Website (optional)

### App Creation

- [ ] App created in Play Console
- [ ] App name: "IoTify Platform"
- [ ] Default language set
- [ ] App type: App (not Game)
- [ ] Free or Paid: Free

### Store Listing

- [ ] Main store listing filled:
  - [ ] App name
  - [ ] Short description
  - [ ] Full description
  - [ ] App icon uploaded
  - [ ] Feature graphic uploaded
  - [ ] Screenshots uploaded
  - [ ] Category selected (Tools/Productivity)
  - [ ] Contact details filled

### App Content

- [ ] Content rating questionnaire completed
  - Expected: Everyone/All Ages
- [ ] Target audience defined (18+)
- [ ] Data safety form filled
  - [ ] Data collection: No (if storing locally only)
  - [ ] Data sharing: No
  - [ ] Security: Yes (if using TLS)
- [ ] News app: No
- [ ] COVID-19: No
- [ ] Government app: No

### Additional Info

- [ ] App access: All users
- [ ] Ads: No (or Yes if you have ads)
- [ ] Privacy policy URL added (if required)

---

## 🚀 Upload & Submission

### Production Release

- [ ] Navigated to Production track
- [ ] Created new release
- [ ] AAB file uploaded successfully
- [ ] Version details correct:
  - [ ] Version code: 1
  - [ ] Version name: 1.0.0
- [ ] Release name filled
- [ ] Release notes added (all languages)
- [ ] Reviewed all warnings (if any)

### Pre-Submission Review

- [ ] All sections show green checkmark ✅
- [ ] No critical warnings
- [ ] Publishing overview shows ready to publish
- [ ] Double-checked:
  - [ ] Package name: `id.iotify.platform`
  - [ ] Version: 1.0.0 (1)
  - [ ] File size: acceptable
  - [ ] Minimum SDK: correct

### Final Submit

- [ ] Clicked "Send for review" / "Publish to production"
- [ ] Received confirmation email from Google
- [ ] App status: "In review"

---

## 📊 Post-Launch Activities

### Immediate (First 24 hours)

- [ ] Monitor for urgent crash reports
- [ ] Check Play Console for any rejection notices
- [ ] Test download from Play Store once approved
- [ ] Verify app listing displays correctly
- [ ] Share Play Store link with team/stakeholders

### First Week

- [ ] Monitor reviews daily
- [ ] Respond to user feedback
- [ ] Track install metrics
- [ ] Check crash reports
- [ ] Note any common issues reported

### Ongoing

- [ ] Set up automated alerts for crashes
- [ ] Plan update schedule
- [ ] Collect feature requests
- [ ] Monitor competitors
- [ ] Optimize store listing based on performance

---

## 🐛 If Rejected

### Immediate Actions

- [ ] Read rejection email carefully
- [ ] Understand exact reason for rejection
- [ ] Check Google Play Policy violations (if mentioned)
- [ ] Make required changes

### Fix & Resubmit

- [ ] Fix all issues mentioned
- [ ] Increment version code (e.g., 1.0.0+2)
- [ ] Build new AAB
- [ ] Upload new version
- [ ] Submit for review again
- [ ] Add note explaining what was fixed

---

## 📈 Success Metrics to Track

After launch, monitor these in Play Console:

- [ ] **Installs**: Daily/weekly install numbers
- [ ] **Ratings**: Average rating (target 4.0+)
- [ ] **Reviews**: User feedback and sentiment
- [ ] **Crashes**: Crash rate (target <1%)
- [ ] **ANRs**: App not responding rate (target <0.5%)
- [ ] **Uninstalls**: Retention metrics
- [ ] **Countries**: Geographic distribution
- [ ] **Android versions**: Device compatibility

---

## 🔄 Next Release Planning

For future updates:

- [ ] Create changelog file
- [ ] Version increment strategy:
  - Patch (1.0.X): Bug fixes
  - Minor (1.X.0): New features
  - Major (X.0.0): Breaking changes
- [ ] Set up CI/CD pipeline (optional)
- [ ] Beta testing track for early access
- [ ] Staged rollouts (10% → 50% → 100%)

---

## 📞 Emergency Contacts

Keep these handy:

- **Google Play Console**: https://play.google.com/console
- **Play Console Support**: https://support.google.com/googleplay/android-developer
- **Keystore backup location**: [Document where you stored it]
- **Developer email**: [Your support email]
- **Team contacts**: [Key team members]

---

**Last Updated**: 2026-01-06
**App Version**: 1.0.0+1
**Package**: id.iotify.platform
**Status**: Ready for submission ✅
