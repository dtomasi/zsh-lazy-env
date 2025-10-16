#!/usr/bin/env bash
#
# record-clean-demo.sh - Record demo with clean zsh session
#
# This script creates a completely clean zsh environment with only zinit
# and zsh-lazy-env loaded, then records the demo with asciinema.
#

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_FILE="$SCRIPT_DIR/demo-core.cast"

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    local missing=()

    if ! command -v asciinema &> /dev/null; then
        missing+=("asciinema")
    fi

    if ! command -v zsh &> /dev/null; then
        missing+=("zsh")
    fi

    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing dependencies: ${missing[*]}"
        echo "Please install them first:"
        echo "  brew install asciinema zsh git"
        echo "  # or"
        echo "  apt-get install asciinema zsh git"
        exit 1
    fi
}

setup_temp_env() {
    print_info "Setting up temporary environment..."

    # Create temporary directory for clean zsh setup
    TEMP_DIR=$(mktemp -d)
    ZINIT_HOME="$TEMP_DIR/zinit"

    print_info "Temporary directory: $TEMP_DIR"

    # Install zinit in temp directory
    print_info "Installing zinit..."
    git clone --quiet --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" || {
        print_error "Failed to clone zinit"
        exit 1
    }

    # Create clean zshrc
    cat > "$TEMP_DIR/.zshrc" << EOF
# Clean zshrc for demo recording
export ZINIT_HOME="$ZINIT_HOME"

# Load zinit
source "\$ZINIT_HOME/zinit.zsh"

# Load our plugin from local directory
zinit load "$PROJECT_ROOT"

# Simple, clean prompt
export PS1='%F{blue}demo%f %F{green}%1~%f %F{yellow}\$%f '

# Disable any startup messages
setopt NO_BEEP
setopt NO_HIST_BEEP
setopt NO_LIST_BEEP

# Set demo environment
export AUTOPLAY=true
export ASCIINEMA_MODE=true

# Clear screen and run demo
clear
echo "Starting zsh-lazy-env demo..."
echo

# Source and run the demo
source "$SCRIPT_DIR/demo-core.zsh"
EOF

    print_success "Clean environment prepared"
}

cleanup() {
    if [[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]]; then
        print_info "Cleaning up temporary directory..."
        rm -rf "$TEMP_DIR"
    fi
}

record_demo() {
    print_info "Starting asciinema recording..."
    print_warning "The demo will run automatically and stop when complete"
    echo

    # Set up cleanup trap
    trap cleanup EXIT

    # Start asciinema recording with clean zsh
    asciinema rec \
        --title "zsh-lazy-env: Directory-based Secret Management" \
        --command "zsh --rcs -c 'export ZDOTDIR=\"$TEMP_DIR\"; exec zsh'" \
        --overwrite \
        "$OUTPUT_FILE" || {
        print_error "Recording failed"
        exit 1
    }
}

main() {
    echo
    echo "🎬 Clean Demo Recording Script for zsh-lazy-env"
    echo "=============================================="
    echo

    print_info "Output file: $OUTPUT_FILE"
    echo

    # Check if output file exists
    if [[ -f "$OUTPUT_FILE" ]]; then
        print_warning "Output file already exists and will be overwritten"
        read -p "Continue? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Cancelled"
            exit 0
        fi
    fi

    # Check dependencies
    check_dependencies

    # Set up clean environment
    setup_temp_env

    # Record the demo
    record_demo

    # Success message
    echo
    print_success "Recording completed successfully!"
    print_info "Output: $OUTPUT_FILE"
    echo
    print_info "To play the recording:"
    echo "  asciinema play $OUTPUT_FILE"
    echo
    print_info "To upload to asciinema.org:"
    echo "  asciinema upload $OUTPUT_FILE"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [--help]"
        echo
        echo "Records a clean demo of zsh-lazy-env using asciinema."
        echo "Creates a temporary zsh environment with only zinit and zsh-lazy-env."
        echo
        echo "Output: $OUTPUT_FILE"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
