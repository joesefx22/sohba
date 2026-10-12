# =============================================================
#  rename_to_sohba.ps1
#  يغيّر اسم المشروع flutter_application_1 → sohba
#  ويحدّث كل ملفات المنصات + ينشئ assets/icons/
#
#  التشغيل (من جذر المشروع):
#    powershell -ExecutionPolicy Bypass -File .\scripts\rename_to_sohba.ps1
# =============================================================

$ErrorActionPreference = 'Stop'

# ─── الإعدادات ────────────────────────────────────────────────
$OLD_PKG   = "com.example.sohba"     # الحالي (من build.gradle)
$NEW_PKG   = "com.sohba.app"         # الهدف (مناسب للنشر)
$DISPLAY   = "صحبة"                  # الاسم المعروض
$BINARY    = "sohba"                 # اسم الملف التنفيذي

# ─── تأكد إننا في جذر المشروع ────────────────────────────────
if (-not (Test-Path "pubspec.yaml")) {
    throw "شغّل السكربت من جذر المشروع (pubspec.yaml مش موجود)."
}

Write-Host "`n🔧 إعادة تسمية المشروع → $DISPLAY ($BINARY)`n" -ForegroundColor Cyan

# ─── Helper: استبدال نصي في ملف (UTF-8 بدون BOM) ─────────────
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Replace-InFile {
    param([string]$Path, [string]$Find, [string]$Replace)
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "   ⏭  ملف غير موجود: $Path" -ForegroundColor DarkGray
        return
    }
    $full = (Get-Item -LiteralPath $Path).FullName
    $content = [System.IO.File]::ReadAllText($full, $utf8NoBom)
    if ($content.IndexOf($Find, [System.StringComparison]::Ordinal) -lt 0) {
        Write-Host "   ⏭  لا يوجد تطابق: $Path" -ForegroundColor DarkGray
        return
    }
    $content = $content.Replace($Find, $Replace)
    [System.IO.File]::WriteAllText($full, $content, $utf8NoBom)
    Write-Host "   ✅ تم التحديث: $Path" -ForegroundColor Green
}

# ─── Helper: مسار باكدج → مسار مجلد ──────────────────────────
function PkgToPath {
    param([string]$Pkg)
    return ($Pkg -replace '\.', '\')
}

# =============================================================
# 1. Android
# =============================================================
Write-Host "`n📱 Android" -ForegroundColor Yellow

# 1a. نقل مجلد Kotlin
$kotlinRoot = "android\app\src\main\kotlin"
$oldKotlin  = Join-Path $kotlinRoot (PkgToPath $OLD_PKG)
$newKotlin  = Join-Path $kotlinRoot (PkgToPath $NEW_PKG)

# محاولة كشف المجلد القديم الفعلي
if (-not (Test-Path -LiteralPath $oldKotlin)) {
    $candidates = @(
        (Join-Path $kotlinRoot "com\example\flutter_application_1"),
        (Join-Path $kotlinRoot "com\example\sohba")
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { $oldKotlin = $c; break }
    }
}

if ((Test-Path -LiteralPath $oldKotlin) -and ($oldKotlin -ne $newKotlin)) {
    $newParent = Split-Path $newKotlin -Parent
    if (-not (Test-Path -LiteralPath $newParent)) {
        New-Item -ItemType Directory -Path $newParent -Force | Out-Null
    }
    if (Test-Path -LiteralPath $newKotlin) {
        Remove-Item -LiteralPath $newKotlin -Recurse -Force
    }
    Move-Item -LiteralPath $oldKotlin -Destination $newKotlin -Force
    Write-Host "   ✅ نقل المجلد: $oldKotlin → $newKotlin" -ForegroundColor Green
} else {
    Write-Host "   ⏭  مجلد Kotlin مش موجود: $oldKotlin" -ForegroundColor DarkGray
}

# 1b. تحديث اسم الباكدج داخل MainActivity.kt
$mainActivity = Join-Path $newKotlin "MainActivity.kt"
if (-not (Test-Path -LiteralPath $mainActivity)) {
    # جرّب أي MainActivity.kt في المشروع
    $mainActivity = (Get-ChildItem -Path $kotlinRoot -Recurse -Filter "MainActivity.kt" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
}
if ($mainActivity -and (Test-Path -LiteralPath $mainActivity)) {
    $content = [System.IO.File]::ReadAllText($mainActivity, $utf8NoBom)
    $content = [regex]::Replace($content, 'package\s+[A-Za-z0-9_.]+', "package $NEW_PKG")
    [System.IO.File]::WriteAllText($mainActivity, $content, $utf8NoBom)
    Write-Host "   ✅ تحديث الباكدج في: $mainActivity" -ForegroundColor Green
}

# 1c. تنظيف مجلدات example الفاضية
foreach ($p in @("$kotlinRoot\com\example\sohba", "$kotlinRoot\com\example")) {
    if ((Test-Path -LiteralPath $p)) {
        $files = Get-ChildItem -LiteralPath $p -Recurse -File -ErrorAction SilentlyContinue
        if (-not $files) {
            Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "   🧹 حذف مجلد فاضي: $p" -ForegroundColor DarkGray
        }
    }
}

# 1d. build.gradle(.kts)
foreach ($g in @("android\app\build.gradle","android\app\build.gradle.kts")) {
    Replace-InFile -Path $g -Find $OLD_PKG -Replace $NEW_PKG
}

# 1e. AndroidManifest — label
$manifest = "android\app\src\main\AndroidManifest.xml"
Replace-InFile -Path $manifest -Find 'android:label="flutter_application_1"' -Replace ('android:label="' + $DISPLAY + '"')
Replace-InFile -Path $manifest -Find 'android:label="sohba"'                -Replace ('android:label="' + $DISPLAY + '"')

# =============================================================
# 2. iOS
# =============================================================
Write-Host "`n🍎 iOS" -ForegroundColor Yellow
$iosInfo = "ios\Runner\Info.plist"
Replace-InFile -Path $iosInfo -Find "<string>Flutter Application 1</string>" -Replace "<string>$DISPLAY</string>"
Replace-InFile -Path $iosInfo -Find "<string>flutter_application_1</string>" -Replace "<string>$BINARY</string>"

# =============================================================
# 3. macOS
# =============================================================
Write-Host "`n🖥  macOS" -ForegroundColor Yellow
$macInfo = "macos\Runner\Configs\AppInfo.xcconfig"
Replace-InFile -Path $macInfo -Find "PRODUCT_NAME = flutter_application_1"                -Replace "PRODUCT_NAME = $BINARY"
Replace-InFile -Path $macInfo -Find "PRODUCT_BUNDLE_IDENTIFIER = com.example.flutterApplication1" -Replace "PRODUCT_BUNDLE_IDENTIFIER = $NEW_PKG"

# =============================================================
# 4. Windows
# =============================================================
Write-Host "`n🪟 Windows" -ForegroundColor Yellow

Replace-InFile -Path "windows\CMakeLists.txt" `
               -Find 'project(flutter_application_1 LANGUAGES CXX)' `
               -Replace 'project(sohba LANGUAGES CXX)'
Replace-InFile -Path "windows\CMakeLists.txt" `
               -Find 'set(BINARY_NAME "flutter_application_1")' `
               -Replace ('set(BINARY_NAME "' + $BINARY + '")')

Replace-InFile -Path "windows\runner\main.cpp" `
               -Find 'L"flutter_application_1"' `
               -Replace ('L"' + $BINARY + '"')

# Runner.rc — استبدال شامل للقيم
$rc = "windows\runner\Runner.rc"
if (Test-Path -LiteralPath $rc) {
    $c = [System.IO.File]::ReadAllText($rc, $utf8NoBom)
    $c = [regex]::Replace($c, 'VALUE\s+"CompanyName",\s+"[^"]*"',           ('VALUE "CompanyName", "' + $NEW_PKG + '"'))
    $c = [regex]::Replace($c, 'VALUE\s+"FileDescription",\s+"[^"]*"',       ('VALUE "FileDescription", "' + $DISPLAY + '"'))
    $c = [regex]::Replace($c, 'VALUE\s+"InternalName",\s+"[^"]*"',          ('VALUE "InternalName", "' + $BINARY + '"'))
    $c = [regex]::Replace($c, 'VALUE\s+"LegalCopyright",\s+"[^"]*"',        ('VALUE "LegalCopyright", "Copyright (C) 2025 Sohba. All rights reserved."'))
    $c = [regex]::Replace($c, 'VALUE\s+"OriginalFilename",\s+"[^"]*"',      ('VALUE "OriginalFilename", "' + $BINARY + '.exe"'))
    $c = [regex]::Replace($c, 'VALUE\s+"ProductName",\s+"[^"]*"',           ('VALUE "ProductName", "' + $DISPLAY + '"'))
    [System.IO.File]::WriteAllText($rc, $c, $utf8NoBom)
    Write-Host "   ✅ تحديث: $rc (version info)" -ForegroundColor Green
}

# =============================================================
# 5. Linux
# =============================================================
Write-Host "`n🐧 Linux" -ForegroundColor Yellow
Replace-InFile -Path "linux\CMakeLists.txt" `
               -Find 'set(BINARY_NAME "flutter_application_1")' `
               -Replace ('set(BINARY_NAME "' + $BINARY + '")')
Replace-InFile -Path "linux\CMakeLists.txt" `
               -Find 'set(APPLICATION_ID "com.example.flutter_application_1")' `
               -Replace ('set(APPLICATION_ID "' + $NEW_PKG + '")')
Replace-InFile -Path "linux\my_application.cc" `
               -Find '"flutter_application_1"' `
               -Replace ('"' + $DISPLAY + '"')

# =============================================================
# 6. Web
# =============================================================
Write-Host "`n🌐 Web" -ForegroundColor Yellow
Replace-InFile -Path "web\index.html" `
               -Find 'content="flutter_application_1"' `
               -Replace ('content="' + $BINARY + '"')
Replace-InFile -Path "web\index.html" `
               -Find '<title>flutter_application_1</title>' `
               -Replace ('<title>' + $DISPLAY + ' — Sohba</title>')
Replace-InFile -Path "web\manifest.json" `
               -Find '"flutter_application_1"' `
               -Replace ('"' + $BINARY + '"')

# =============================================================
# 7. assets/icons/ — مكان صورة التطبيق
# =============================================================
Write-Host "`n🎨 Assets" -ForegroundColor Yellow

$iconsDir = "assets\icons"
if (-not (Test-Path -LiteralPath $iconsDir)) {
    New-Item -ItemType Directory -Path $iconsDir -Force | Out-Null
    Write-Host "   ✅ تم إنشاء: $iconsDir" -ForegroundColor Green
}

$readme = Join-Path $iconsDir "README.md"
if (-not (Test-Path -LiteralPath $readme)) {
    $readmeBody = @'
# App Icon Assets

## ضع هنا أيقونة التطبيق

- `app_icon.png` — 1024×1024 PNG، بدون شفافية، بدون زوايا مدورة.
  يستخدمها `flutter_launcher_icons` لتوليد:
    - Android mipmaps (mdpi → xxxhdpi) + adaptive icons
    - iOS AppIcon.appiconset (19 حجم)
    - Web PWA icons (192, 512, maskable)

## الإعداد

أضف لـ `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.1

flutter_launcher_icons:
  android: true
  ios: true
  web:
    generate: true
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_background: "#071612"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
  remove_alpha_ios: true