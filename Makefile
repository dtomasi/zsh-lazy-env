# Makefile for zsh-lazy-env

.PHONY: test test-verbose test-parallel test-core test-integration test-all clean help lint demo install hermit-status

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
	@./bin/shellcheck lazy-env.plugin.zsh
	@echo "Running shellcheck on tests..."
	@for file in tests/*.zsh; do \
		echo "Checking $$file..."; \
		timeout 30s ./bin/shellcheck "$$file" || echo "Warning: shellcheck failed or timed out for $$file"; \
	done
	@echo "Shellcheck completed"

# Run interactive demo
demo:
	@echo "Starting interactive demo..."
	@zsh examples/demo-core.zsh



# Run demo in autoplay mode (for asciinema recordings)
demo-auto:
	@echo "Starting autoplay demo (3s delays)..."
	@AUTOPLAY=true zsh examples/demo-core.zsh

# Run demo in asciinema-friendly mode (ASCII icons)
demo-asciinema:
	@echo "Starting asciinema-friendly demo..."
	@ASCIINEMA_MODE=true AUTOPLAY=true zsh examples/demo-core.zsh


# Clean test artifacts
clean:
	@echo "Cleaning test artifacts..."
	@rm -rf test-results/
	@rm -rf coverage/
	@rm -f *.log
	@rm -f *.tmp

# Install plugin locally (for development)
install:
	@echo "Installing plugin to ~/.local/share/zsh-lazy-env/..."
	@mkdir -p ~/.local/share/zsh-lazy-env
	@cp lazy-env.plugin.zsh ~/.local/share/zsh-lazy-env/
	@cp -r examples ~/.local/share/zsh-lazy-env/
	@echo "Add this to your ~/.zshrc:"
	@echo "source ~/.local/share/zsh-lazy-env/lazy-env.plugin.zsh"

# Install from GitHub (production)
install-from-git:
	@echo "Cloning from GitHub..."
	@git clone https://github.com/dtomasi/zsh-lazy-env.git ~/.local/share/zsh-lazy-env
	@echo "Add this to your ~/.zshrc:"
	@echo "source ~/.local/share/zsh-lazy-env/lazy-env.plugin.zsh"
	@echo "Or with zinit: zinit load 'dtomasi/zsh-lazy-env'"

# Check plugin is working
check:
	@echo "Checking plugin functionality..."
	@./bin/activate-hermit && zsh -c "source lazy-env.plugin.zsh; lazy_var 'TEST' 'echo test-value'; lazy_load 'TEST'; echo 'Plugin check: \$$TEST = '\$$TEST"

# Show hermit tools
hermit-status:
	@echo "Hermit tools status:"
	@./bin/hermit status

# Show help
help:
	@echo "Available targets:"
	@echo "  test          - Run all tests"
	@echo "  test-verbose  - Run tests with verbose output"
	@echo "  test-parallel - Run tests in parallel"
	@echo "  test-core     - Run core functionality tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  test-all      - Run all test categories individually"
	@echo "  lint          - Run shellcheck linting (uses hermit)"
	@echo "  demo          - Run interactive demo"
	@echo "  demo-auto     - Run demo in autoplay mode (for recordings)"
	@echo "  clean         - Clean test artifacts"
	@echo "  install       - Install plugin locally for development"
	@echo "  install-from-git - Install from GitHub repository"
	@echo "  check         - Quick functionality check"
	@echo "  hermit-status - Show hermit tools status"
	@echo "  help          - Show this help message"
