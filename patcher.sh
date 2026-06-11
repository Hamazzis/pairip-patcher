#!/system/bin/sh

# ============================================
#  Universal License Patcher
#  Detects & patches 6 types of Play Store /
#  license checks in decompiled APKs.
#  No root required.
# ============================================

VERSION="1.0"

# ─── Colors ────────────────────────────────
RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[1;33m'
BLU='\033[0;34m'
CYN='\033[0;36m'
NC='\033[0m' # No Color

# ─── Helpers ───────────────────────────────
detect_flag=0
patch_count=0
skip_count=0

print_banner() {
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║     🔧  Universal License Patcher  v${VERSION}             ║"
    echo "║                                                          ║"
    echo "║  Scans decompiled APKs for 6 types of license checks:    ║"
    echo "║                                                          ║"
    echo "║  1️⃣  PairiP SDK (installer + signature check)            ║"
    echo "║  2️⃣  Google LVL (License Verification Library)          ║"
    echo "║  3️⃣  Installer package check (getInstallingPackageName)  ║"
    echo "║  4️⃣  APK signature verification                          ║"
    echo "║  5️⃣  Google Play Integrity API                           ║"
    echo "║  6️⃣  Google Play Stamp (Standalone APK check)            ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
}

# ─── Patch function (generic: replace method body) ──
patch_method() {
    local FILE="$1"
    local METHOD_PATTERN="$2"  # grep pattern for the method
    local REPLACEMENT="$3"

    if [ ! -f "$FILE" ]; then
        return 2
    fi

    # Find method start line
    local START_LINE
    START_LINE=$(grep -n "^[[:space:]]*\.method .* ${METHOD_PATTERN}" "$FILE" | head -1 | cut -d: -f1)
    if [ -z "$START_LINE" ]; then
        START_LINE=$(grep -n "^\.method .* ${METHOD_PATTERN}" "$FILE" | head -1 | cut -d: -f1)
    fi
    if [ -z "$START_LINE" ]; then
        return 1
    fi

    # Find .end method after start
    local END_LINE
    END_LINE=$(sed -n "${START_LINE},\$p" "$FILE" | grep -n "^[[:space:]]*\.end method" | head -1 | cut -d: -f1)
    if [ -z "$END_LINE" ]; then
        return 1
    fi
    END_LINE=$((START_LINE + END_LINE - 1))

    # Read original header
    local ORIG_HEADER
    ORIG_HEADER=$(sed -n "${START_LINE}p" "$FILE")

    cp "$FILE" "${FILE}.bak" 2>/dev/null

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

# ─── Fast grep with timeout ───────────────
fast_grep() {
    local pattern="$1"
    local dir="$2"
    shift 2
    # Only search smali/ (main dex), skip classes2..8 to be fast
    # If not found there, fall back to broader search
    if [ -d "$dir/smali" ]; then
        timeout 15 grep -rlc "$pattern" "$dir/smali" --include="*.smali" 2>/dev/null | head -5
    else
        timeout 30 grep -rlc "$pattern" "$dir" --include="*.smali" 2>/dev/null | head -5
    fi
}

fast_grep_files() {
    local pattern="$1"
    local dir="$2"
    shift 2
    if [ -d "$dir/smali" ]; then
        timeout 15 grep -rl "$pattern" "$dir/smali" --include="*.smali" 2>/dev/null | head -5
    else
        timeout 30 grep -rl "$pattern" "$dir" --include="*.smali" 2>/dev/null | head -5
    fi
}

# ─── Scan mode (dry-run, only detect) ──────
scan_only() {
    echo ""
    echo "══════════════════════════════════════════════"
    echo "              🔍  SCAN RESULTS"
    echo "══════════════════════════════════════════════"
    echo ""

    # 1. PairiP
    if [ -f "$BASE/smali/com/pairip/SignatureCheck.smali" ]; then
        echo "  ${RED}⚠${NC}  1️⃣  PairiP SDK found!"
        detect_flag=1
    fi

    # 2. Google LVL
    LVL_COUNT=$(fast_grep "ILicensingService\|LicenseChecker" "$BASE")
    if [ -n "$LVL_COUNT" ] && [ "$LVL_COUNT" -gt 0 ] 2>/dev/null; then
        echo "  ${RED}⚠${NC}  2️⃣  Google LVL found!"
        detect_flag=1
    fi

    # 3. Installer check
    INSTALLER_FILES=$(fast_grep_files "getInstallerPackageName\|getInstallingPackageName" "$BASE")
    if [ -n "$INSTALLER_FILES" ]; then
        echo "  ${RED}⚠${NC}  3️⃣  Installer check found!"
        echo "       Files:"
        echo "$INSTALLER_FILES" | while read f; do echo "         ${f#$BASE/}"; done
        detect_flag=1
    fi

    # 4. Signature check (excluding AndroidX/system libs)
    SIG_FILES=$(fast_grep_files "getPackageInfo.*0x40\|PackageInfo;->signatures\[" "$BASE")
    # Filter out AndroidX and common libs
    for f in $SIG_FILES; do
        case "$f" in
            *"androidx/"*) continue ;;
            *"android/support/"*) continue ;;
            *)
                echo "  ${RED}⚠${NC}  4️⃣  APK signature check found!"
                echo "       $f"
                detect_flag=1
                ;;
        esac
    done

    # 5. Play Integrity (only check playcore directory quickly)
    if [ -d "$BASE/smali/com/google/android/play/core/integrity" ]; then
        echo "  ${RED}⚠${NC}  5️⃣  Google Play Integrity API found!"
        echo "       Files in smali/com/google/android/play/core/integrity/"
        detect_flag=1
    fi

    # 6. Play Stamp
    STAMP=$(grep "STAMP_TYPE_STANDALONE_APK" "$BASE/AndroidManifest.xml" 2>/dev/null | head -3)
    if [ -n "$STAMP" ]; then
        echo "  ${RED}⚠${NC}  6️⃣  Google Play Stamp detected in AndroidManifest!"
        echo "       $STAMP"
        detect_flag=1
    fi

    if [ "$detect_flag" -eq 0 ]; then
        echo "  ${GRN}✅${NC}  No common license checks detected."
        echo "       This APK may use a different protection method,"
        echo "       or may already be patched."
    fi

    echo ""
    echo "──────────────────────────────────────────"
}

# ─── Patch all detected issues ─────────────
patch_all() {
    echo ""
    echo "══════════════════════════════════════════════"
    echo "            🔧  PATCHING IN PROGRESS"
    echo "══════════════════════════════════════════════"
    echo ""

    # ── 1. PairiP ──────────────────────────
    echo -n "  [1/6]  PairiP SDK .......................... "

    LC="$BASE/smali/com/pairip/licensecheck/LicenseClient.smali"
    SC="$BASE/smali/com/pairip/SignatureCheck.smali"
    PAIRIP_OK=0

    if [ -f "$LC" ] && grep -q "getInstallSourceInfo\|getInstallingPackageName" "$LC" 2>/dev/null; then
        BODY='    .locals 1

    const/4 v0, 0x1

    return v0'
        patch_method "$LC" "performLocalInstallerCheck()Z" "$BODY" && PAIRIP_OK=1
    else
        PAIRIP_OK=2  # already patched or not found
    fi

    if [ -f "$SC" ] && ! grep -q "Signature check bypassed" "$SC" 2>/dev/null; then
        BODY='    .locals 2

    const-string v0, "SignatureCheck"

    const-string v1, "Signature check bypassed by patch"

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    return-void'
        patch_method "$SC" "verifyIntegrity(Landroid/content/Context;)V" "$BODY" && PAIRIP_OK=1
    fi

    case "$PAIRIP_OK" in
        0) echo "${CYN}not found${NC}" ;;
        1) echo "${GRN}patched${NC}"; patch_count=$((patch_count+1)) ;;
        2) echo "${YEL}already patched${NC}"; skip_count=$((skip_count+1)) ;;
    esac

    # ── 2. Google LVL ──────────────────────
    echo -n "  [2/6]  Google LVL ......................... "

    LVL_DIRS=$(find "$BASE/smali" -type d -name "licensing" 2>/dev/null)
    LVL_PATCHED=0

    for DIR in $LVL_DIRS; do
        CHECKER="$DIR/LicenseChecker.smali"
        if [ -f "$CHECKER" ] && grep -q "checkAccess\|checkLicense" "$CHECKER" 2>/dev/null; then
            BODY='    .locals 2

    const-string v0, "LicenseChecker"

    const-string v1, "License check bypassed by patch"

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    return-void'
            patch_method "$CHECKER" "checkAccess(Landroid/content/Context;)V" "$BODY" && LVL_PATCHED=1
        fi
    done

    case "$LVL_PATCHED" in
        0) echo "${CYN}not found${NC}" ;;
        1) echo "${GRN}patched${NC}"; patch_count=$((patch_count+1)) ;;
    esac

    # ── 3. Installer check ─────────────────
    echo -n "  [3/6]  Installer check .................... "

    INSTALLER_FILES=$(grep -rl "getInstallerPackageName\|getInstallingPackageName" "$BASE/smali" --include="*.smali" 2>/dev/null)
    INSTALLER_PATCHED=0

    if [ -z "$INSTALLER_FILES" ]; then
        echo "${CYN}not found${NC}"
    else
        echo ""
        for f in $INSTALLER_FILES; do
            echo -n "         $(echo $f | sed "s|$BASE/smali/||")... "
            # Try to find the method that contains this check and replace it
            # Strategy: find the enclosing method, replace compare-and-fail with always-true
            # This is complex, so mark it
            echo "${YEL}manual review needed${NC}"
        done
        echo "       ⚠️  Installer checks need manual patching - the logic varies"
    fi

    # ── 4. Signature check ─────────────────
    echo -n "  [4/6]  Signature verification ............. "

    SIG_FILES=$(grep -rl "getPackageInfo.*0x40\|PackageInfo;->signatures\[" "$BASE/smali" --include="*.smali" 2>/dev/null | grep -v "pairip" | head -5)
    SIG_PATCHED=0

    if [ -z "$SIG_FILES" ]; then
        echo "${CYN}not found${NC}"
    else
        echo ""
        for f in $SIG_FILES; do
            echo -n "         $(echo $f | sed "s|$BASE/smali/||")... "
            echo "${YEL}manual review needed${NC}"
        done
    fi

    # ── 5. Play Integrity ──────────────────
    echo -n "  [5/6]  Play Integrity API ................ "

    INTEGRITY_FILES=$(grep -rl "PlayIntegrity\|requestIntegrityToken" "$BASE/smali" --include="*.smali" 2>/dev/null | head -5)
    if [ -z "$INTEGRITY_FILES" ]; then
        echo "${CYN}not found${NC}"
    else
        echo "${YEL}detected - manual patching needed${NC}"
        for f in $INTEGRITY_FILES; do
            echo "         $(echo $f | sed "s|$BASE/smali/||")"
        done
    fi

    # ── 6. Play Stamp ──────────────────────
    echo -n "  [6/6]  Play Stamp (AndroidManifest) ...... "

    MANIFEST="$BASE/AndroidManifest.xml"
    if [ -f "$MANIFEST" ] && grep -q "STAMP_TYPE_STANDALONE_APK\|com.android.stamp" "$MANIFEST" 2>/dev/null; then
        cp "$MANIFEST" "${MANIFEST}.bak" 2>/dev/null
        sed -i '/com\.android\.stamp\.type/d; /STAMP_TYPE_STANDALONE_APK/d; /com\.android\.dynamic\.apk/d' "$MANIFEST" 2>/dev/null
        echo "${GRN}removed from manifest${NC}"
        patch_count=$((patch_count+1))
    else
        echo "${CYN}not found${NC}"
    fi

    echo ""
    echo "──────────────────────────────────────────"
}

# ══════════════════════════════════════════
#                   MAIN
# ══════════════════════════════════════════

# Parse args
MODE="auto"

if [ "$1" = "--scan" ] || [ "$1" = "-s" ]; then
    MODE="scan"
    shift
fi

# Get path
if [ -n "$1" ]; then
    BASE="${1%/}"
else
    print_banner
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  Enter path to decompiled APK folder                    ║"
    echo "║                                                          ║"
    echo "║  Usage: sh patch_pairip.sh [--scan] <path>              ║"
    echo "║    --scan   : only detect, don't patch                  ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo -n "   Path: "
    read BASE
    BASE="${BASE%/}"
fi

if [ ! -d "$BASE" ] || [ ! -d "$BASE/smali" ]; then
    echo ""
    echo "   ${RED}❌${NC}  Invalid folder: $BASE"
    echo "       Must be a decompiled APK with smali/ directory"
    exit 1
fi

print_banner
echo "   📁  $BASE"
echo ""

if [ "$MODE" = "scan" ]; then
    scan_only
else
    scan_only
    echo ""
    echo -n "   Patch all detected issues? (Y/n): "
    read CONFIRM
    if [ -z "$CONFIRM" ] || [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
        patch_all
        echo ""
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║                    📋  SUMMARY                          ║"
        echo "╠══════════════════════════════════════════════════════════╣"
        echo "║  ${GRN}✔${NC}  Patched:  $patch_count                                  ║"
        echo "║  ${YEL}⏩${NC}  Skipped: $skip_count (already patched)               ║"
        echo "║                                                          ║"
        echo "║  ${YEL}⚠${NC}  Items marked 'manual review needed':                    ║"
        echo "║       Some checks vary by app and need custom            ║"
        echo "║       smali patching. See PATCH_DOCS.md for guidance.    ║"
        echo "║                                                          ║"
        echo "║  ${BLU}🔄${NC}  Rebuild in Apktool_M: Build → Sign → Install       ║"
        echo "╚══════════════════════════════════════════════════════════╝"
    else
        echo "   ${YEL}Skipped patching${NC}"
    fi
fi

echo ""
echo -n "   Press Enter to exit... "
read dummy
clear