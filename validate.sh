#!/bin/bash
# ============================================================
# Tails Hermes — Pre-Build Validation Script
# Run this before attempting a full ISO build.
# Checks all config files, scripts, and dependencies.
# ============================================================

# Collect all results — don't exit on first failure
set +e

PASS=0
FAIL=0
WARN=0

check() {
    local desc="$1"
    local result="$2"
    if [ "$result" = "0" ]; then
        echo "  ✅ $desc"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $desc"
        FAIL=$((FAIL + 1))
    fi
}

warn() {
    echo "  ⚠️  $1"
    WARN=$((WARN + 1))
}

cd "$(dirname "$0")"

# Clean up any __pycache__ that may have been created by Python imports
find config/chroot_local-includes -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

echo "============================================"
echo "  Tails Hermes — Pre-Build Validation"
echo "============================================"
echo ""

# --- 1. Hook scripts ---
echo "[1/8] Hook scripts..."
for f in config/chroot_local-hooks/*.chroot; do
    [ -f "$f" ] || continue
    bash -n "$f" 2>/dev/null
    check "$(basename $f) syntax" $?
done

# --- 2. Bash scripts ---
echo ""
echo "[2/8] Bash scripts..."
for f in config/chroot_local-includes/usr/local/bin/hermes-*; do
    [ -f "$f" ] || continue
    bash -n "$f" 2>/dev/null
    check "$(basename $f) syntax" $?
done

# --- 3. Python files ---
echo ""
echo "[3/8] Python files..."
python3 -c "
import py_compile, glob, sys
files = glob.glob('config/chroot_local-includes/opt/hermes/**/*.py', recursive=True)
failed = 0
for f in files:
    if '__pycache__' in f:
        continue
    try:
        py_compile.compile(f, doraise=True)
        print(f'  ✅ {f}')
    except py_compile.PyCompileError as e:
        print(f'  ❌ {f}: {e}')
        failed += 1
sys.exit(failed)
" || FAIL=$((FAIL + 1))

# --- 4. Systemd service ---
echo ""
echo "[4/8] Systemd service..."
if command -v systemd-analyze >/dev/null 2>&1; then
    # Expected to fail in dev env (no Tor service, no llama-server binary)
    # but syntax should be valid
    output=$(systemd-analyze verify config/chroot_local-includes/etc/systemd/system/llama-cpp.service 2>&1) || true
    if echo "$output" | grep -q "syntax error\|invalid\|Unknown"; then
        check "llama-cpp.service syntax" 1
    else
        check "llama-cpp.service syntax (expected env warnings OK)" 0
    fi
else
    warn "systemd-analyze not available — skipping"
fi

# --- 5. Desktop entry ---
echo ""
echo "[5/8] Desktop entry..."
if command -v desktop-file-validate >/dev/null 2>&1; then
    desktop-file-validate config/chroot_local-includes/usr/share/applications/hermes-ai.desktop 2>/dev/null
    check "hermes-ai.desktop" $?
else
    warn "desktop-file-validate not available — skipping"
fi

# --- 6. SVG icon ---
echo ""
echo "[6/8] SVG icon..."
if command -v xmllint >/dev/null 2>&1; then
    xmllint --noout config/chroot_local-includes/usr/share/icons/hicolor/scalable/apps/hermes-ai.svg 2>/dev/null
    check "hermes-ai.svg" $?
else
    warn "xmllint not available — skipping"
fi

# --- 7. Security checks ---
echo ""
echo "[7/8] Security checks..."

# No ollama references in canonical paths
OLLAMA_REFS=$(grep -r "ollama" \
    config/chroot_local-includes/opt/ \
    config/chroot_local-includes/usr/local/bin/ \
    config/chroot_local-includes/etc/ \
    config/chroot_local-hooks/ \
    2>/dev/null | grep -v ".git" | grep -v "__pycache__" | wc -l)
[ "$OLLAMA_REFS" = "0" ]
check "No ollama references in canonical paths" $?

# No __pycache__ in ISO (clean first, then check)
find config/chroot_local-includes -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
[ ! -d "config/chroot_local-includes/opt/hermes/gui/__pycache__" ]
check "No __pycache__ in ISO" $?

# No empty opt/ollama directory
[ ! -d "config/chroot_local-includes/opt/ollama" ]
check "No stale opt/ollama directory" $?

# hermes user in ferm.conf
grep -q "uid-owner hermes" config/chroot_local-includes/etc/ferm/ferm.conf
check "hermes user in ferm.conf" $?

# IPv6 block for hermes
grep -q "hermes jump log_reject" config/chroot_local-includes/etc/ferm/ferm.conf
check "IPv6 block for hermes in ferm.conf" $?

# SHA256 in download script
grep -q "EXPECTED_SHA256" config/chroot_local-includes/usr/local/bin/hermes-download-model
check "SHA256 verification in download script" $?

# No Tor exit IP in scripts (check for actual IP display, not comments)
grep -q "exit IP:" config/chroot_local-includes/usr/local/bin/hermes-start 2>/dev/null && RC=1 || RC=0
check "No Tor exit IP in hermes-start" $RC

grep -q "exit IP:" config/chroot_local-includes/usr/local/bin/hermes-download-model 2>/dev/null && RC=1 || RC=0
check "No Tor exit IP in download script" $RC

# --- 8. File inventory ---
echo ""
echo "[8/8] File inventory..."
EXPECTED_FILES=(
    "config/chroot_local-hooks/13-install-hermes.hook.chroot"
    "config/chroot_local-hooks/13-hermes-persistence.hook.chroot"
    "config/chroot_local-includes/etc/ferm/ferm.conf"
    "config/chroot_local-includes/etc/systemd/system/llama-cpp.service"
    "config/chroot_local-includes/etc/tor/torsocks-hermes.conf"
    "config/chroot_local-includes/opt/hermes/gui/hermes_app.py"
    "config/chroot_local-includes/usr/local/bin/hermes-download-model"
    "config/chroot_local-includes/usr/local/bin/hermes-start"
    "config/chroot_local-includes/usr/share/applications/hermes-ai.desktop"
    "config/chroot_local-includes/usr/share/icons/hicolor/scalable/apps/hermes-ai.svg"
    "config/chroot_local-packageslists/tails-hermes.list"
)

for f in "${EXPECTED_FILES[@]}"; do
    [ -f "$f" ]
    check "$f exists" $?
done

# --- Summary ---
echo ""
echo "============================================"
echo "  Results: ${PASS} passed, ${FAIL} failed, ${WARN} warnings"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "  ❌ Fix failures before building!"
    exit 1
else
    echo ""
    echo "  ✅ All checks passed. Ready to build."
    echo ""
    echo "  To build the full ISO, run on a Debian Trixie system with"
    echo "  Vagrant + libvirt + 17GB RAM:"
    echo ""
    echo "    rake build"
    echo ""
    echo "  Or with live-build directly (after installing deps):"
    echo "    sudo lb config --cache false"
    echo "    sudo lb build"
    exit 0
fi
