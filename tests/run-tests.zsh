#!/usr/bin/env zsh
# 
# Main Test Runner for zsh-lazy-env
# 
# Runs all test suites and provides CI/CD integration
#

# Set script directory
SCRIPT_DIR="$(dirname "$0")"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# Source test framework
source "$SCRIPT_DIR/test-framework.zsh"

# Test configuration
PARALLEL_TESTS=${PARALLEL_TESTS:-false}
VERBOSE=${VERBOSE:-false}
FILTER=${FILTER:-""}
SKIP_INTEGRATION=${SKIP_INTEGRATION:-false}

# Test files in execution order
TEST_FILES=(
	"$SCRIPT_DIR/test-core-functions.zsh"
	"$SCRIPT_DIR/test-directory-scoped.zsh"
	"$SCRIPT_DIR/test-listing-functions.zsh"
	"$SCRIPT_DIR/test-error-handling.zsh"
)

# Integration tests (optional, can be slow)
if [[ "$SKIP_INTEGRATION" != "true" ]]; then
	TEST_FILES+=("$SCRIPT_DIR/test-integration.zsh")
fi

# Global test state
TOTAL_SUITES=0
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
FAILED_SUITES=()

# Usage information
usage() {
	cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
  -h, --help         Show this help message
  -v, --verbose      Enable verbose output
  -f, --filter PATTERN   Run only tests matching pattern
  -s, --skip-integration Skip integration tests (faster)
  -p, --parallel     Run test suites in parallel (experimental)
  --ci               CI mode: non-interactive, structured output

ENVIRONMENT VARIABLES:
  VERBOSE=true       Enable verbose output
  FILTER="pattern"   Filter tests by pattern
  SKIP_INTEGRATION=true   Skip integration tests
  PARALLEL_TESTS=true     Enable parallel execution

EXAMPLES:
  $0                    # Run all tests
  $0 --verbose          # Run with verbose output
  $0 --filter "core"    # Run only core function tests
  $0 --skip-integration # Skip slow integration tests
  $0 --ci               # CI mode for automated environments

EXIT CODES:
  0    All tests passed
  1    Some tests failed
  2    Test framework error
  3    Usage error
EOF
}

# Parse command line arguments
parse_args() {
	while [[ $# -gt 0 ]]; do
		case $1 in
			-h|--help)
				usage
				exit 0
				;;
			-v|--verbose)
				VERBOSE=true
				shift
				;;
			-f|--filter)
				FILTER="$2"
				shift 2
				;;
			-s|--skip-integration)
				SKIP_INTEGRATION=true
				# Remove integration tests from array
				TEST_FILES=("${TEST_FILES[@]/*integration*/}")
				shift
				;;
			-p|--parallel)
				PARALLEL_TESTS=true
				shift
				;;
			--ci)
				VERBOSE=false
				CI_MODE=true
				shift
				;;
			*)
				echo "Unknown option: $1" >&2
				usage >&2
				exit 3
				;;
		esac
	done
}

# Run a single test file
run_test_file() {
	local test_file="$1"
	local test_name=$(basename "$test_file" .zsh)
	
	if [[ -n "$FILTER" && "$test_name" != *"$FILTER"* ]]; then
		if [[ "$VERBOSE" == "true" ]]; then
			echo "${COLORS[YELLOW]}⏭️  Skipping $test_name (doesn't match filter)${COLORS[NC]}"
		fi
		return 0
	fi
	
	if [[ ! -f "$test_file" ]]; then
		echo "${COLORS[RED]}❌ Test file not found: $test_file${COLORS[NC]}" >&2
		return 1
	fi
	
	if [[ "$VERBOSE" == "true" ]]; then
		echo "${COLORS[BLUE]}🔄 Running $test_name...${COLORS[NC]}"
	fi
	
	# Run test in a subshell to isolate state
	local output
	local exit_code
	
	if [[ "$VERBOSE" == "true" ]]; then
		# Show output in verbose mode
		(
			source "$test_file"
		)
		exit_code=$?
	else
		# Capture output in quiet mode
		output=$(
			source "$test_file" 2>&1
		)
		exit_code=$?
	fi
	
	# Parse results from the output
	if [[ $exit_code -eq 0 ]]; then
		if [[ "$VERBOSE" == "true" ]]; then
			echo "${COLORS[GREEN]}✅ $test_name completed successfully${COLORS[NC]}"
		fi
	else
		echo "${COLORS[RED]}❌ $test_name failed${COLORS[NC]}"
		FAILED_SUITES+=("$test_name")
		if [[ "$VERBOSE" != "true" && -n "$output" ]]; then
			echo "$output"
		fi
	fi
	
	return $exit_code
}

# Run all tests sequentially
run_tests_sequential() {
	local suite_count=0
	local suite_passed=0
	
	for test_file in "${TEST_FILES[@]}"; do
		if [[ -n "$test_file" ]]; then  # Skip empty entries from array filtering
			suite_count=$((suite_count + 1))
			if run_test_file "$test_file"; then
				suite_passed=$((suite_passed + 1))
			fi
		fi
	done
	
	TOTAL_SUITES=$suite_count
	# Note: Individual test counts would need to be extracted from test output
	# For now, we're tracking at the suite level
}

# Run all tests in parallel (experimental)
run_tests_parallel() {
	local pids=()
	local results=()
	
	echo "${COLORS[YELLOW]}⚡ Running tests in parallel (experimental)...${COLORS[NC]}"
	
	# Start all test files in background
	for test_file in "${TEST_FILES[@]}"; do
		if [[ -n "$test_file" ]]; then
			(
				run_test_file "$test_file"
				echo $? > "/tmp/test-result-$$.$(basename "$test_file")"
			) &
			pids+=($!)
		fi
	done
	
	# Wait for all tests to complete
	for pid in "${pids[@]}"; do
		wait $pid
	done
	
	# Collect results
	local suite_count=0
	local suite_passed=0
	
	for test_file in "${TEST_FILES[@]}"; do
		if [[ -n "$test_file" ]]; then
			local result_file="/tmp/test-result-$$.$(basename "$test_file")"
			if [[ -f "$result_file" ]]; then
				suite_count=$((suite_count + 1))
				local result=$(cat "$result_file")
				if [[ "$result" == "0" ]]; then
					suite_passed=$((suite_passed + 1))
				fi
				rm -f "$result_file"
			fi
		fi
	done
	
	TOTAL_SUITES=$suite_count
}

# Check prerequisites
check_prerequisites() {
	if [[ ! -f "$PLUGIN_DIR/lazy-env.plugin.zsh" ]]; then
		echo "${COLORS[RED]}❌ Plugin file not found: $PLUGIN_DIR/lazy-env.plugin.zsh${COLORS[NC]}" >&2
		exit 2
	fi
	
	# Check for required commands
	for cmd in mkdir rm grep; do
		if ! command -v "$cmd" >/dev/null 2>&1; then
			echo "${COLORS[RED]}❌ Required command not found: $cmd${COLORS[NC]}" >&2
			exit 2
		fi
	done
}

# Main execution
main() {
	parse_args "$@"
	
	# Initialize test framework
	test_init
	
	echo "${COLORS[BLUE]}🚀 Starting zsh-lazy-env test suite${COLORS[NC]}"
	echo
	
	# Show configuration
	if [[ "$VERBOSE" == "true" ]]; then
		echo "${COLORS[CYAN]}Configuration:${COLORS[NC]}"
		echo "  Verbose: $VERBOSE"
		echo "  Filter: ${FILTER:-none}"
		echo "  Skip Integration: $SKIP_INTEGRATION"
		echo "  Parallel: $PARALLEL_TESTS"
		echo "  Test Files: ${#TEST_FILES[@]}"
		echo
	fi
	
	# Check prerequisites
	check_prerequisites
	
	# Record start time
	local start_time=$(date +%s)
	
	# Run tests
	if [[ "$PARALLEL_TESTS" == "true" ]]; then
		run_tests_parallel
	else
		run_tests_sequential
	fi
	
	# Calculate execution time
	local end_time=$(date +%s)
	local duration=$((end_time - start_time))
	
	# Show final results
	echo
	echo "${COLORS[CYAN]}$(printf '═%.0s' {1..80})${COLORS[NC]}"
	echo "${COLORS[BOLD]}📊 Final Test Results${COLORS[NC]}"
	echo "${COLORS[CYAN]}$(printf '═%.0s' {1..80})${COLORS[NC]}"
	echo
	
	echo "${COLORS[BLUE]}Test Suites:    ${COLORS[WHITE]}$TOTAL_SUITES${COLORS[NC]}"
	echo "${COLORS[GREEN]}Passed Suites:  ${COLORS[WHITE]}$(($TOTAL_SUITES - ${#FAILED_SUITES[@]}))${COLORS[NC]}"
	echo "${COLORS[RED]}Failed Suites:  ${COLORS[WHITE]}${#FAILED_SUITES[@]}${COLORS[NC]}"
	echo "${COLORS[YELLOW]}Duration:       ${COLORS[WHITE]}${duration}s${COLORS[NC]}"
	echo
	
	# Show failed suites if any
	if [[ ${#FAILED_SUITES[@]} -gt 0 ]]; then
		echo "${COLORS[RED]}${COLORS[BOLD]}❌ Failed Test Suites:${COLORS[NC]}"
		echo "${COLORS[RED]}$(printf '─%.0s' {1..50})${COLORS[NC]}"
		for failed_suite in "${FAILED_SUITES[@]}"; do
			echo "${COLORS[RED]}  • $failed_suite${COLORS[NC]}"
		done
		echo
	fi
	
	# Final status
	if [[ ${#FAILED_SUITES[@]} -eq 0 ]]; then
		echo "${COLORS[GREEN]}${COLORS[BOLD]}🎉 All test suites passed!${COLORS[NC]}"
		echo
		echo "${COLORS[GREEN]}✅ Test Coverage Summary:${COLORS[NC]}"
		echo "${COLORS[GREEN]}  • Core Functions: Variable registration, command mapping, loading${COLORS[NC]}"
		echo "${COLORS[GREEN]}  • Directory Scoping: Priority resolution, pattern matching${COLORS[NC]}"
		echo "${COLORS[GREEN]}  • Listing Functions: Output formatting, table structure${COLORS[NC]}"
		echo "${COLORS[GREEN]}  • Error Handling: Edge cases, malformed input, failures${COLORS[NC]}"
		if [[ "$SKIP_INTEGRATION" != "true" ]]; then
			echo "${COLORS[GREEN]}  • Integration: Real-world workflows, complex scenarios${COLORS[NC]}"
		fi
		exit 0
	else
		echo "${COLORS[RED]}${COLORS[BOLD]}💥 Some test suites failed.${COLORS[NC]}"
		echo
		echo "${COLORS[YELLOW]}💡 Troubleshooting Tips:${COLORS[NC]}"
		echo "${COLORS[YELLOW]}  • Run with --verbose for detailed output${COLORS[NC]}"
		echo "${COLORS[YELLOW]}  • Use --filter to run specific test suites${COLORS[NC]}"
		echo "${COLORS[YELLOW]}  • Check plugin file exists and is syntax-correct${COLORS[NC]}"
		exit 1
	fi
}

# Run main function with all arguments
main "$@"