# 🔧 Universal License Patcher — Documentation

## Purpose

Automatically detects and patches Play Store / license verification checks
in decompiled APKs. No root required.

## Supported Protection Types

| # | Type | Detection | Auto-Patch |
|---|---|---|---|
| 1️⃣ | **PairiP SDK** | ✅ | ✅ installer + signature check |
| 2️⃣ | **Google LVL** (License Verification Library) | ✅ | ✅ Always returns LICENSED |
| 3️⃣ | **Installer check** (`getInstallingPackageName`) | ✅ | ⚠️ manual review |
| 4️⃣ | **APK signature verification** | ✅ | ⚠️ manual review |
| 5️⃣ | **Google Play Integrity API** | ✅ | ❌ detection only |
| 6️⃣ | **Google Play Stamp** (AndroidManifest.xml) | ✅ | ✅ Removes stamp metadata |

---

## How to Use

### Prerequisites
- Termux or any shell on Android
- Decompiled APK folder (use Apktool_M → Decompile)

### Commands

```sh
# Show help and enter path interactively
sh /storage/emulated/0/Apktool_M/universal_patcher.sh

# Scan only (dry-run, no changes)
sh /storage/emulated/0/Apktool_M/universal_patcher.sh --scan /path/to/decompiled/apk

# Scan + patch (asks for confirmation)
sh /storage/emulated/0/Apktool_M/universal_patcher.sh /path/to/decompiled/apk
```

### Examples

```sh
# Scan Minecraft
sh /storage/emulated/0/Apktool_M/universal_patcher.sh --scan \
  "/storage/emulated/0/Apktool_M/v1.26.23.1(972602301)_srcmn"

# Scan + patch Earn to Die 2
sh /storage/emulated/0/Apktool_M/universal_patcher.sh \
  "/storage/emulated/0/MT2/apks/Earn to Die 2_1.4.58_src"
```

---

## Files Modified

### 1. PairiP — LicenseClient.smali

**File:** `smali/com/pairip/licensecheck/LicenseClient.smali`
**Method:** `performLocalInstallerCheck()Z`

**Before:** Checks if app was installed from Google Play (`com.android.vending`)
using `getInstallingPackageName()`. Returns `false` for sideloaded apps.

**After:**
```smali
.method private performLocalInstallerCheck()Z
    .locals 1
    const/4 v0, 0x1
    return v0
.end method
```
Always returns `true` — installer check is bypassed.

### 2. PairiP — SignatureCheck.smali

**File:** `smali/com/pairip/SignatureCheck.smali`
**Method:** `verifyIntegrity(Landroid/content/Context;)V`

**Before:** Computes SHA-256 hash of APK signature and compares against
hardcoded values. Throws `SignatureTamperedException` on mismatch.

**After:**
```smali
.method public static verifyIntegrity(Landroid/content/Context;)V
    .locals 2
    const-string v0, "SignatureCheck"
    const-string v1, "Signature check bypassed by patch"
    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I
    return-void
.end method
```
Logs a message and returns — signature verification is skipped.

### 3. Google LVL — LicenseChecker.smali

**File:** `smali/.../licensing/LicenseChecker.smali` (varies by app)
**Method:** `checkAccess(Landroid/content/Context;)V`

**Before:** Binds to Google Play's `ILicensingService` and validates the
response. Returns `LICENSED` or `NOT_LICENSED`.

**After:** Same pattern as above — logs and returns void (mocks a successful check).

### 4. Google Play Stamp — AndroidManifest.xml

**Removed lines:**
```xml
<meta-data android:name="com.android.stamp.type" android:value="STAMP_TYPE_STANDALONE_APK" />
<meta-data android:name="com.android.dynamic.apk.fused.modules" android:value="base,install_pack" />
```

---

## Backups

Every modified file gets a `.bak` copy next to it before changes are applied:

| File | Backup |
|---|---|
| `LicenseClient.smali` | `LicenseClient.smali.bak` |
| `SignatureCheck.smali` | `SignatureCheck.smali.bak` |
| `AndroidManifest.xml` | `AndroidManifest.xml.bak` |

**How to revert:**
```sh
mv LicenseClient.smali.bak LicenseClient.smali
mv SignatureCheck.smali.bak SignatureCheck.smali
mv AndroidManifest.xml.bak AndroidManifest.xml
```

---

## How to Rebuild

After patching, rebuild the APK in **Apktool_M**:

1. Open Apktool_M
2. Tap **"Build Project"** (Собрать проект)
3. Select your decompiled folder
4. Wait for the build to finish
5. Tap **"Sign APK"** (Подписать APK)
6. Install the resulting APK

---

## How It Compares to Lucky Patcher

| Feature | Lucky Patcher | Universal Patcher |
|---|---|---|
| PairiP bypass | ✅ Built-in | ✅ Script-based |
| LVL bypass | ✅ Proxy + smali | ✅ smali patch |
| Installer check | ✅ | ⚠️ Manual |
| Signature check | ✅ | ⚠️ Manual |
| Play Integrity | ⚠️ Limited | ❌ Detection only |
| Play Stamp | ✅ | ✅ |
| In-App Purchases | ✅ Proxy | ❌ |
| Native .so patching | ✅ | ❌ |
| GUI | ✅ App | ❌ Shell script |
| Custom patches | ✅ Database | ❌ Custom per-app |
| Transparency | ❌ Black box | ✅ Shows everything |
| Works without install | ❌ Needs LP app | ✅ Standalone script |

---

## Script Location

```
/storage/emulated/0/Apktool_M/universal_patcher.sh
```

---

## Safety Notes

- Always make backups — the script creates `.bak` files automatically
- Test the patched APK before distributing
- Some apps have additional server-side checks (Play Integrity, custom servers)
  that cannot be bypassed by smali patching alone