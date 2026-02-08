#!/bin/bash
###############################################################################
# 00_python_venv_setup.sh
# Creates Python virtual environment for AFDA backend services
# Location: ~/runtime_data/python_venvs/Agentic-Finance-Director-App_venv
# Python: 3.12 (preferred) → 3.13 → 3.11 (fallbacks)
# Run from: git repo root (Agentic-Finance-Director-App/)
###############################################################################
set -e

VENV_BASE="$HOME/runtime_data/python_venvs"
VENV_NAME="Intelligent-Mfg-Assistant-App_venv"
VENV_PATH="$VENV_BASE/$VENV_NAME"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   IMA — Python Virtual Environment Setup                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ═══════════════════════════════════════════════════════════════
# STEP 1: Find compatible Python (3.12 > 3.13 > 3.11)
# ═══════════════════════════════════════════════════════════════

PYTHON_CMD=""

# Search explicit version commands first
for cmd in python3.12 python3.13 python3.11; do
    if command -v "$cmd" &>/dev/null; then
        PYTHON_CMD="$cmd"
        break
    fi
done

# Fallback: check common install paths (macOS Homebrew, Framework, Linux)
if [ -z "$PYTHON_CMD" ]; then
    SEARCH_PATHS=(
        "/opt/homebrew/bin/python3.12"
        "/opt/homebrew/bin/python3.13"
        "/opt/homebrew/bin/python3.11"
        "/usr/local/bin/python3.12"
        "/usr/local/bin/python3.13"
        "/usr/local/bin/python3.11"
        "/Library/Frameworks/Python.framework/Versions/3.12/bin/python3.12"
        "/Library/Frameworks/Python.framework/Versions/3.13/bin/python3.13"
        "/Library/Frameworks/Python.framework/Versions/3.11/bin/python3.11"
    )
    for p in "${SEARCH_PATHS[@]}"; do
        if [ -x "$p" ]; then
            PYTHON_CMD="$p"
            break
        fi
    done
fi

# Last resort: check generic python3 but verify version
if [ -z "$PYTHON_CMD" ] && command -v python3 &>/dev/null; then
    PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.minor}')" 2>/dev/null)
    if [ "$PY_VER" -ge 11 ] && [ "$PY_VER" -le 13 ] 2>/dev/null; then
        PYTHON_CMD="python3"
    fi
fi

if [ -z "$PYTHON_CMD" ]; then
    echo "  ❌ No compatible Python found!"
    echo "  Need Python 3.11, 3.12, or 3.13 (3.14 is too new for pydantic/SQLAlchemy)"
    echo ""
    echo "  Install Python 3.12:"
    echo "  ───────────────────────────────────────────"
    echo "  macOS (Homebrew):  brew install python@3.12"
    echo "  macOS (Installer): https://www.python.org/downloads/release/python-3128/"
    echo "  Ubuntu/Debian:     sudo apt install python3.12 python3.12-venv"
    echo "  Fedora:            sudo dnf install python3.12"
    echo "  Windows:           https://www.python.org/downloads/"
    echo ""
    exit 1
fi

PY_FULL_VERSION=$("$PYTHON_CMD" --version 2>&1)
PY_PATH=$(command -v "$PYTHON_CMD" || echo "$PYTHON_CMD")
echo "  ✅ Using: $PY_FULL_VERSION"
echo "     Path:  $PY_PATH"

# Verify venv module is available
if ! "$PYTHON_CMD" -m venv --help &>/dev/null; then
    echo ""
    echo "  ❌ venv module not available for $PYTHON_CMD"
    echo "  Install it:"
    echo "    Ubuntu: sudo apt install python3.12-venv"
    echo "    Fedora: sudo dnf install python3.12"
    exit 1
fi

# ═══════════════════════════════════════════════════════════════
# STEP 2: Create or recreate venv
# ═══════════════════════════════════════════════════════════════

mkdir -p "$VENV_BASE"

if [ -d "$VENV_PATH" ]; then
    echo ""
    echo "  ⚠️  Existing venv found at:"
    echo "     $VENV_PATH"
    EXISTING_PY=$("$VENV_PATH/bin/python" --version 2>&1 || echo "unknown")
    echo "     Current: $EXISTING_PY"
    echo ""
    read -p "  Recreate with $PY_FULL_VERSION? (y/N): " CONFIRM
    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
        rm -rf "$VENV_PATH"
        echo "  🗑️  Removed old venv"
    else
        echo "  ↪️  Keeping existing venv"
        source "$VENV_PATH/bin/activate"
        echo "  ✅ Activated: $(python --version)"
        # Still install/update deps
        SKIP_CREATE=true
    fi
fi

if [ "${SKIP_CREATE:-false}" = "false" ]; then
    echo ""
    echo "  🔧 Creating virtual environment..."
    "$PYTHON_CMD" -m venv "$VENV_PATH"
    echo "  ✅ Created: $VENV_PATH"
fi

# ═══════════════════════════════════════════════════════════════
# STEP 3: Activate and upgrade pip
# ═══════════════════════════════════════════════════════════════

source "$VENV_PATH/bin/activate"

echo ""
echo "  📦 Upgrading pip, setuptools, wheel..."
pip install --upgrade pip setuptools wheel --quiet 2>&1 | tail -1 || true
echo "  ✅ pip $(pip --version | awk '{print $2}')"

# ═══════════════════════════════════════════════════════════════
# STEP 4: Install backend dependencies
# ═══════════════════════════════════════════════════════════════

CRUD_REQ="Services/ima-crud-api/requirements.txt"
GW_REQ="Services/ima-agent-api/requirements.txt"

CRUD_OK=false
GW_OK=false

if [ -f "$CRUD_REQ" ]; then
    echo ""
    echo "  📦 Installing CRUD API dependencies..."
    pip install -r "$CRUD_REQ" --quiet 2>&1 | grep -i error || true
    CRUD_OK=true
    echo "  ✅ CRUD API deps installed"
else
    echo "  ⚠️  CRUD API requirements.txt not found"
    echo "     Run 'npm run backend:scaffold' first, then re-run this script"
fi

if [ -f "$GW_REQ" ]; then
    echo ""
    echo "  📦 Installing Agent Gateway dependencies..."
    pip install -r "$GW_REQ" --quiet 2>&1 | grep -i error || true
    GW_OK=true
    echo "  ✅ Agent Gateway deps installed"
else
    echo "  ⚠️  Agent Gateway requirements.txt not found"
    echo "     Run 'npm run backend:scaffold' first, then re-run this script"
fi

# ═══════════════════════════════════════════════════════════════
# STEP 5: Verify critical packages
# ═══════════════════════════════════════════════════════════════

echo ""
echo "  🔍 Verifying critical packages..."
VERIFY_FAIL=0
for pkg in fastapi uvicorn sqlalchemy pydantic motor redis alembic; do
    if python -c "import $pkg" 2>/dev/null; then
        VER=$(python -c "import $pkg; print(getattr($pkg, '__version__', '?'))" 2>/dev/null)
        printf "     ✅ %-15s %s\n" "$pkg" "$VER"
    else
        printf "     ❌ %-15s NOT INSTALLED\n" "$pkg"
        VERIFY_FAIL=$((VERIFY_FAIL + 1))
    fi
done

if [ $VERIFY_FAIL -gt 0 ]; then
    echo ""
    echo "  ⚠️  $VERIFY_FAIL packages failed to install"
    echo "     Try: pip install -r $CRUD_REQ"
fi

# ═══════════════════════════════════════════════════════════════
# STEP 6: Create helper files in project root
# ═══════════════════════════════════════════════════════════════

# Activation helper
cat > ".venv-activate.sh" << ACTIVATE_EOF
#!/bin/bash
# Activate AFDA Python virtual environment
# Usage: source .venv-activate.sh
AFDA_VENV="$VENV_PATH"
if [ ! -d "\$AFDA_VENV" ]; then
    echo "❌ Venv not found at \$AFDA_VENV"
    echo "   Run: npm run venv:setup"
    return 1 2>/dev/null || exit 1
fi
source "\$AFDA_VENV/bin/activate"
echo "✅ AFDA venv active — \$(python --version)"
ACTIVATE_EOF
chmod +x ".venv-activate.sh"

# Path file for npm scripts to read
echo "$VENV_PATH" > ".python-venv-path"

echo ""
echo "  📄 Created .venv-activate.sh (source this to activate)"
echo "  📄 Created .python-venv-path (used by npm scripts)"

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

TOTAL_PKGS=$(pip list --format=columns 2>/dev/null | tail -n +3 | wc -l | tr -d ' ')

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   ✅ PYTHON VENV READY                                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  Python:     $(python --version)"
echo "  Venv:       $VENV_PATH"
echo "  Packages:   $TOTAL_PKGS installed"
echo ""
echo "  ─────────────────────────────────────────────────────────"
echo "  Activate:"
echo "    source .venv-activate.sh        # from project root"
echo "    source $VENV_PATH/bin/activate  # full path"
echo ""
echo "  npm scripts auto-use venv:"
echo "    npm run dev:crud-api"
echo "    npm run dev:agent-gateway"
echo "    npm run dev:all"
echo "  ─────────────────────────────────────────────────────────"