#!/system/bin/sh

# ============================================
#  PairiP License Check Patcher - Interactive
#  Auto-detects and patches licensing checks
#  Works on any APK version
# ============================================

set -e

clear

# ============================
# Welcome screen
# ============================
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║           🛠  PairiP License Check Patcher               ║
║                                                          ║
║  Removes Play Store redirect & license verification      ║
║  from APKs protected by PairiP anti-tamper SDK.          ║
║                                                          ║
║  What gets patched:                                      ║
║    ✔  Installer check (getInstallingPackageName)         ║
║    ✔  APK signature verification (SignatureCheck)        ║
║                                                          ║
║  Works on ALL versions — methods found by name,          ║
║  not by line number.                                     ║
║                                                          ║
║  No root required — only modifies .smali text files.     ║
╚══════════════════════════════════════════════════════════╝
EOF

echo ""
echo -n "   Press Enter to continue... "
read dummy

# ============================
# Get path
# ============================
clear
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Enter path to decompiled APK folder                    ║"
echo "║                                                          ║"
echo "║  Example:                                                ║"
echo "║    /storage/emulated/0/Apktool_M/v1.26.23.1_srcmn       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo -n "   Path: "
read BASE

BASE="${BASE%/}"

if [ ! -d "$BASE" ]; then
    echo ""
    echo "   ❌  ERROR: Folder not found: $BASE"
    echo ""
    exit 1
fi

if [ ! -d "$BASE/smali" ]; then
    echo ""
    echo "   ⚠️  '$BASE' doesn't look like a decompiled APK (no smali/ folder)"
    echo ""
    echo -n "   Continue anyway? (y/N): "
    read CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        echo "   Aborted."
        exit 1
    fi
fi

echo ""
echo "   ✅  Path accepted"
sleep 0.5

# ============================
# Patching function using grep + sed
# ============================
patch_method() {
    local FILE="$1"
    local METHOD_NAME="$2"
    local METHOD_ARGS="$3"
    local REPLACEMENT="$4"

    # Find the method line using grep with exact match
    local START_LINE
    START_LINE=$(grep -n "^[[:space:]]*\.method .* ${METHOD_NAME}${METHOD_ARGS}$" "$FILE" | head -1 | cut -d: -f1)

    if [ -z "$START_LINE" ]; then
        # Try without leading whitespace
        START_LINE=$(grep -n "^\.method .* ${METHOD_NAME}${METHOD_ARGS}$" "$FILE" | head -1 | cut -d: -f1)
    fi

    if [ -z "$START_LINE" ]; then
        return 1
    fi

    # Find the .end method after START_LINE
    local END_LINE
    END_LINE=$(sed -n "${START_LINE},\$p" "$FILE" | grep -n "^[[:space:]]*\.end method" | head -1 | cut -d: -f1)

    if [ -z "$END_LINE" ]; then
        return 1
    fi

    END_LINE=$((START_LINE + END_LINE - 1))

    # Read the original method header
    local ORIG_HEADER
    ORIG_HEADER=$(sed -n "${START_LINE}p" "$FILE")

    # Make a backup
    cp "$FILE" "${FILE}.bak" 2>/dev/null

    # Replace: delete lines START_LINE to END_LINE, insert new content
    {
        sed -n "1,$((START_LINE - 1))p" "$FILE"
        echo "$ORIG_HEADER"
        printf '%s\n' "$REPLACEMENT"
        echo ".end method"
        sed -n "$((END_LINE + 1)),\$p" "$FILE"
    } > "${FILE}.tmp"

    mv "${FILE}.tmp" "$FILE"
    return 0
}

# ============================
# Main patching logic
# ============================
clear
echo "╔══════════════════════════════════════════════════════════╗"
echo "║              🔍  Scanning & Patching...                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

PATCHED_LC=0
PATCHED_SC=0

# --- LicenseClient.smali ---
LC="$BASE/smali/com/pairip/licensecheck/LicenseClient.smali"

echo "   [1/2]  LicenseClient.smali"
echo "   --------------------------------------------------"

if [ -f "$LC" ]; then
    # Check if already patched (no installer check calls)
    if grep -q "getInstallSourceInfo\|getInstallingPackageName" "$LC" 2>/dev/null; then
        echo -n "   → Patching performLocalInstallerCheck()... "

        BODY='    .locals 1

    const/4 v0, 0x1

    return v0'

        if patch_method "$LC" "performLocalInstallerCheck" "()Z" "$BODY"; then
            if grep -q "const/4 v0, 0x1" "$LC" 2>/dev/null; then
                echo "✅  done"
                PATCHED_LC=1
            else
                echo "⚠️  failed"
            fi
        else
            echo "⚠️  method 'performLocalInstallerCheck' not found"
        fi
    else
        echo "   ⏩  Already patched"
        PATCHED_LC=1
    fi
else
    echo "   ⏩  File not found (no PairiP protection)"
fi

# --- SignatureCheck.smali ---
SC="$BASE/smali/com/pairip/SignatureCheck.smali"

echo ""
echo "   [2/2]  SignatureCheck.smali"
echo "   --------------------------------------------------"

if [ -f "$SC" ]; then
    # Check if already patched
    if grep -q "Signature check bypassed" "$SC" 2>/dev/null; then
        echo "   ⏩  Already patched"
        PATCHED_SC=1
    else

        echo -n "   → Patching verifyIntegrity()... "

        BODY='    .locals 2

    const-string v0, "SignatureCheck"

    const-string v1, "Signature check bypassed by patch"

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    return-void'

        if patch_method "$SC" "verifyIntegrity" "(Landroid/content/Context;)V" "$BODY"; then
            if grep -q "Signature check bypassed" "$SC" 2>/dev/null; then
                echo "✅  done"
                PATCHED_SC=1
            else
                echo "⚠️  failed"
            fi
        else
            echo "⚠️  method 'verifyIntegrity' not found"
        fi
    fi
else
    echo "   ⏩  File not found (no PairiP protection)"
fi

# ============================
# Summary
# ============================
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    📋  RESULTS                          ║"
echo "╠══════════════════════════════════════════════════════════╣"

if [ "$PATCHED_LC" -eq 0 ] && [ "$PATCHED_SC" -eq 0 ] && [ ! -f "$LC" ] && [ ! -f "$SC" ]; then
    echo "║                                                          ║"
    echo "║  ⚠️  No PairiP files found in this APK.                  ║"
    echo "║                                                          ║"
    echo "║  This APK may not use PairiP protection.                 ║"
    echo "║  The patcher only targets PairiP SDK.                    ║"
    echo "╚══════════════════════════════════════════════════════════╝"
else
    if [ "$PATCHED_LC" -eq 1 ]; then
        echo "║  ✅  LicenseClient  — performLocalInstallerCheck()       ║"
        echo "║        → always returns true (installer check removed)  ║"
    else
        echo "║  ❌  LicenseClient  — NOT patched                         ║"
    fi

    if [ "$PATCHED_SC" -eq 1 ]; then
        echo "║  ✅  SignatureCheck — verifyIntegrity()                   ║"
        echo "║        → signature verification bypassed                  ║"
    else
        echo "║  ❌  SignatureCheck — NOT patched                         ║"
    fi

    echo "║                                                          ║"
    if [ "$PATCHED_LC" -eq 1 ] || [ "$PATCHED_SC" -eq 1 ]; then
        echo "║  🔄  Rebuild your APK in Apktool_M:                      ║"
        echo "║       1. Build (Собрать проект)                          ║"
        echo "║       2. Sign (Подписать APK)                            ║"
        echo "║       3. Install                                        ║"
    fi
    echo "╚══════════════════════════════════════════════════════════╝"
fi

echo ""
echo -n "   Press Enter to exit... "
read dummy
clear