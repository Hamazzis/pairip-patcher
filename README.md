# 🔧 Universal License Patcher

> Remove Play Store license checks from decompiled Android APKs. No root required.

---

## ✨ Features

| # | Check Type | Detection | Auto-Patch |
|---|------------|-----------|------------|
| 1️⃣ | **PairiP SDK** (installer + signature) | ✅ | ✅ |
| 2️⃣ | **Google LVL** (License Verification) | ✅ | ✅ |
| 3️⃣ | **Installer package** (getInstallingPackageName) | ✅ | ⚠️ Manual |
| 4️⃣ | **APK signature verification** | ✅ | ⚠️ Manual |
| 5️⃣ | **Google Play Integrity API** | ✅ | ❌ Detection only |
| 6️⃣ | **Google Play Stamp** (Standalone APK) | ✅ | ✅ |

---

## 🚀 Usage

### Prerequisites
- Termux or any shell on Android
- Decompiled APK folder (use Apktool_M → Decompile)

### Commands

```sh
# Interactive mode (enter path manually)
sh patcher.sh

# Scan only (dry-run, no changes)
sh patcher.sh --scan /path/to/decompiled/apk

# Scan + auto-patch
sh patcher.sh /path/to/decompiled/apk
```

### Examples

```sh
sh patcher.sh --scan /storage/emulated/0/Apktool_M/MyApp_srcmn
sh patcher.sh /storage/emulated/0/MT2/apks/MyGame_src
```

---

## 🛠 What Gets Patched

### 1. PairiP — `performLocalInstallerCheck()`
Bypasses the "app not from Play Store" check by always returning `true`.

### 2. PairiP — `verifyIntegrity()`
Skips APK signature verification entirely.

### 3. Google LVL — `checkAccess()`
Mocks a successful license verification with Google Play.

### 4. Play Stamp
Removes `STAMP_TYPE_STANDALONE_APK` from `AndroidManifest.xml`.

---

## 🔄 After Patching (in Apktool_M)

1. **Build** (Собрать проект)
2. **Sign** (Подписать APK)
3. **Install**

---

## 💡 How It Works

The script scans decompiled smali code for known license check patterns and:
- Replaces method bodies with stubs that always succeed
- Removes metadata from AndroidManifest.xml
- Creates `.bak` backups of every modified file

Unlike Lucky Patcher (which is a black-box app), this script is fully transparent:
you see exactly what changes are made and can customize them.

---

## 📁 Repository Structure

```
.
├── patcher.sh              # Universal patcher (recommended)
├── patch_pairip.sh         # PairiP-only patcher
├── PATCH_DOCS.md           # Full documentation
├── AndroidManifest.xml     # Patched manifest (stamp removed)
└── smali/com/pairip/       # Patched PairiP smali files
    ├── licensecheck/       # License client (patched)
    ├── SignatureCheck.smali # Signature check (patched)
    └── ...
```

---

## ⚠️ Limitations

- **Play Integrity API** — detection only; server-side checks can't be patched locally
- **Custom protections** — apps with unique checks need manual smali analysis
- **Native (.so) checks** — not covered by this script
- **In-App Purchases** — not patched (use Lucky Patcher for that)

---

## 🔗 Related

- [Lucky Patcher](https://www.luckypatchers.com/) — GUI app with broader patch coverage
- [Apktool_M](https://apktool.mobi/) — APK decompilation tool for Android
- [lpdiff](https://github.com/S-trace/lpdiff) — LP custom patch generator

---

*For educational purposes only. Use at your own risk.*
