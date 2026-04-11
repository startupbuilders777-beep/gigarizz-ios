#!/bin/bash
# ============================================================
# GigaRizz Dev Startup Script
# Usage: ./dev.sh [backend|frontend|all|setup|test]
# ============================================================
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"
VENV_DIR="$BACKEND_DIR/.venv"
BACKEND_PORT=8000

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_banner() {
    echo -e "${PURPLE}"
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║        🔥 GigaRizz Dev Environment 🔥        ║"
    echo "  ║     AI Dating Photo Generation Platform       ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${BLUE}[→]${NC} $1"; }

# ─── CHECK PREREQUISITES ────────────────────────────────────
check_prereqs() {
    info "Checking prerequisites..."
    local missing=0

    command -v python3 &>/dev/null || { err "python3 not found"; missing=1; }
    command -v xcodegen &>/dev/null || { warn "xcodegen not found — install with: brew install xcodegen"; }
    command -v xcodebuild &>/dev/null || { err "xcodebuild not found — install Xcode"; missing=1; }

    if [[ $missing -eq 1 ]]; then
        err "Missing prerequisites. Install them and retry."
        exit 1
    fi
    log "Prerequisites OK"
}

# ─── SETUP BACKEND ──────────────────────────────────────────
setup_backend() {
    info "Setting up backend..."

    # Create virtualenv if it doesn't exist
    if [[ ! -d "$VENV_DIR" ]]; then
        info "Creating Python virtual environment..."
        python3 -m venv "$VENV_DIR"
    fi

    # Activate and install deps
    source "$VENV_DIR/bin/activate"
    info "Installing Python dependencies..."
    pip install --quiet --upgrade pip
    pip install --quiet -r "$BACKEND_DIR/requirements.txt"

    # Setup .env if missing
    if [[ ! -f "$BACKEND_DIR/.env" ]]; then
        warn "No .env file found — copying from .env.example"
        cp "$BACKEND_DIR/.env.example" "$BACKEND_DIR/.env"
        warn "Edit $BACKEND_DIR/.env with your API keys before running!"
    fi

    log "Backend setup complete"
}

# ─── SETUP FRONTEND ─────────────────────────────────────────
setup_frontend() {
    info "Setting up iOS frontend..."
    cd "$PROJECT_DIR"

    if command -v xcodegen &>/dev/null; then
        info "Running xcodegen..."
        xcodegen generate
        log "Xcode project generated"
    else
        warn "xcodegen not installed — using existing .xcodeproj"
    fi

    log "Frontend setup complete"
    info "Open GigaRizz.xcodeproj in Xcode, or use: open GigaRizz.xcodeproj"
}

# ─── START BACKEND ───────────────────────────────────────────
start_backend() {
    info "Starting backend on port $BACKEND_PORT..."
    cd "$BACKEND_DIR"

    if [[ ! -d "$VENV_DIR" ]]; then
        setup_backend
    fi

    source "$VENV_DIR/bin/activate"

    # Check .env exists
    if [[ ! -f ".env" ]]; then
        err "No .env file. Run: ./dev.sh setup"
        exit 1
    fi

    echo -e "${GREEN}"
    echo "  Backend starting at http://localhost:$BACKEND_PORT"
    echo "  API docs at http://localhost:$BACKEND_PORT/docs"
    echo "  Health check at http://localhost:$BACKEND_PORT/api/v1/health"
    echo -e "${NC}"

    uvicorn app.main:app \
        --host 0.0.0.0 \
        --port "$BACKEND_PORT" \
        --reload \
        --log-level info
}

# ─── START FRONTEND ──────────────────────────────────────────
start_frontend() {
    info "Opening iOS project in Xcode..."
    cd "$PROJECT_DIR"

    # Regenerate project if xcodegen available
    if command -v xcodegen &>/dev/null; then
        xcodegen generate 2>/dev/null
    fi

    open GigaRizz.xcodeproj
    log "Xcode opened. Press ⌘+R to build and run on simulator."
    echo ""
    info "Make sure the backend is running (./dev.sh backend) for full functionality."
    info "Set your backend URL in AppConstants.swift if needed."
}

# ─── START ALL ───────────────────────────────────────────────
start_all() {
    info "Starting backend in background + opening Xcode..."

    # Start backend in background
    cd "$BACKEND_DIR"
    if [[ ! -d "$VENV_DIR" ]]; then
        setup_backend
    fi
    source "$VENV_DIR/bin/activate"

    if [[ ! -f ".env" ]]; then
        err "No .env file. Run: ./dev.sh setup"
        exit 1
    fi

    echo -e "${GREEN}"
    echo "  Backend: http://localhost:$BACKEND_PORT"
    echo "  API docs: http://localhost:$BACKEND_PORT/docs"
    echo -e "${NC}"

    uvicorn app.main:app \
        --host 0.0.0.0 \
        --port "$BACKEND_PORT" \
        --reload \
        --log-level info &
    BACKEND_PID=$!
    log "Backend started (PID: $BACKEND_PID)"

    # Wait for backend to be ready
    info "Waiting for backend to start..."
    for i in {1..15}; do
        if curl -s "http://localhost:$BACKEND_PORT/api/v1/health" >/dev/null 2>&1; then
            log "Backend is ready!"
            break
        fi
        sleep 1
    done

    # Open Xcode
    cd "$PROJECT_DIR"
    if command -v xcodegen &>/dev/null; then
        xcodegen generate 2>/dev/null
    fi
    open GigaRizz.xcodeproj
    log "Xcode opened"

    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}✅ GigaRizz is running!${NC}"
    echo -e "  Backend: ${BLUE}http://localhost:$BACKEND_PORT/docs${NC}"
    echo -e "  Press ${YELLOW}Ctrl+C${NC} to stop the backend"
    echo -e "${PURPLE}═══════════════════════════════════════════════════${NC}"
    echo ""

    # Wait for backend process (Ctrl+C will stop it)
    trap "kill $BACKEND_PID 2>/dev/null; echo -e '\n${RED}Backend stopped.${NC}'" EXIT INT TERM
    wait $BACKEND_PID
}

# ─── RUN TESTS ───────────────────────────────────────────────
run_tests() {
    info "Running all tests..."

    # Backend tests
    cd "$BACKEND_DIR"
    if [[ ! -d "$VENV_DIR" ]]; then
        setup_backend
    fi
    source "$VENV_DIR/bin/activate"

    echo -e "\n${BLUE}── Backend Tests ──${NC}"
    python -m pytest tests/ -v --tb=short
    BACKEND_RESULT=$?

    # iOS build test
    echo -e "\n${BLUE}── iOS Build Test ──${NC}"
    cd "$PROJECT_DIR"
    if command -v xcodegen &>/dev/null; then
        xcodegen generate 2>/dev/null
    fi

    # Find available simulator
    SIM_NAME=$(xcrun simctl list devices available | grep "iPhone" | head -1 | sed 's/.*\(iPhone[^(]*\).*/\1/' | xargs)
    if [[ -z "$SIM_NAME" ]]; then
        SIM_NAME="iPhone 17"
    fi

    xcodebuild -project GigaRizz.xcodeproj \
        -scheme GigaRizz \
        -destination "platform=iOS Simulator,name=$SIM_NAME" \
        build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED"
    IOS_RESULT=$?

    echo ""
    echo -e "${PURPLE}═══ Test Results ═══${NC}"
    [[ $BACKEND_RESULT -eq 0 ]] && log "Backend tests: PASSED" || err "Backend tests: FAILED"
    [[ $IOS_RESULT -eq 0 ]] && log "iOS build: PASSED" || err "iOS build: FAILED"

    exit $((BACKEND_RESULT + IOS_RESULT))
}

# ─── MAIN ────────────────────────────────────────────────────
print_banner

case "${1:-all}" in
    setup)
        check_prereqs
        setup_backend
        setup_frontend
        echo ""
        log "Setup complete! Run ./dev.sh to start everything."
        ;;
    backend)
        start_backend
        ;;
    frontend)
        start_frontend
        ;;
    all)
        check_prereqs
        start_all
        ;;
    test)
        run_tests
        ;;
    *)
        echo "Usage: ./dev.sh [setup|backend|frontend|all|test]"
        echo ""
        echo "  setup     — Install dependencies and configure"
        echo "  backend   — Start FastAPI backend with hot reload"
        echo "  frontend  — Open Xcode project"
        echo "  all       — Start backend + open Xcode (default)"
        echo "  test      — Run backend tests + iOS build"
        ;;
esac
