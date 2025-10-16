# Makefile for zsh-lazy-env

.PHONY: test test-verbose test-parallel test-core test-integration test-all clean help lint demo install

# Default target
all: test

# Run all tests
test:
	@echo "Running test suite..."
	@./tests/run-tests.zsh

# Run tests with verbose output
test-verbose:
	@echo "Running test suite (verbose)..."
	@./tests/run-tests.zsh --verbose

# Run tests in parallel
test-parallel:
	@echo "Running test suite (parallel)..."
	@./tests/run-tests.zsh --parallel

# Run core functionality tests only
test-core:
	@echo "Running core functionality tests..."
	@./tests/run-tests.zsh --filter core-functions

# Run integration tests only
test-integration:
	@echo "Running integration tests..."
	@./tests/run-tests.zsh --filter integration

# Run all test categories individually
test-all:
	@echo "Running all test categories..."
	@./tests/run-tests.zsh --filter core-functions
	@./tests/run-tests.zsh --filter directory-scoped
	@./tests/run-tests.zsh --filter listing-functions
	@./tests/run-tests.zsh --filter error-handling
	@./tests/run-tests.zsh --filter integration

# Run linting
lint:
	@echo "Running shellcheck on plugin..."
	@shellcheck -s bash -e SC1091,SC2034,SC2154 lazy-env.plugin.zsh || true
	@echo "Running shellcheck on tests..."
	@find tests/ -name "*.zsh" -exec shellcheck -s bash -e SC1091,SC2034,SC2154 {} \; || true

# Run interactive demo
demo:
	@echo "Starting interactive demo..."
	@zsh demo.zsh

# Run manual command loading test
test-manual:
	@echo "Running manual command loading test..."
	@zsh examples/manual-test-command-loading.zsh

# Clean test artifacts
clean:
	@echo "Cleaning test artifacts..."
	@rm -rf test-results/
	@rm -rf coverage/
	@rm -f *.log
	@rm -f *.tmp

# Install plugin locally (for development)
install:
	@echo "Installing plugin to ~/.config/zsh/plugins/zsh-lazy-env/..."
	@mkdir -p ~/.config/zsh/plugins/zsh-lazy-env
	@cp lazy-env.plugin.zsh ~/.config/zsh/plugins/zsh-lazy-env/
	@cp -r examples ~/.config/zsh/plugins/zsh-lazy-env/
	@echo "Add this to your ~/.zshrc:"
	@echo "source ~/.config/zsh/plugins/zsh-lazy-env/lazy-env.plugin.zsh"

# Check plugin is working
check:
	@echo "Checking plugin functionality..."
	@zsh -c "source lazy-env.plugin.zsh; lazy_var 'TEST' 'echo test-value'; lazy_load 'TEST'; echo 'Plugin check: \$$TEST = '\$$TEST"

# Show help
help:
	@echo "Available targets:"
	@echo "  test          - Run all tests"
	@echo "  test-verbose  - Run tests with verbose output"
	@echo "  test-parallel - Run tests in parallel"
	@echo "  test-core     - Run core functionality tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  test-all      - Run all test categories individually"
	@echo "  test-manual   - Run manual command loading test"
	@echo "  lint          - Run shellcheck linting"
	@echo "  demo          - Run interactive demo"
	@echo "  clean         - Clean test artifacts"
	@echo "  install       - Install plugin locally for development"
	@echo "  check         - Quick functionality check"
	@echo "  help          - Show this help message"
