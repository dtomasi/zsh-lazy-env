#!/usr/bin/env zsh
# 
# Test Framework for zsh-lazy-env
# 
# Simple but effective testing framework for zsh scripts
# Provides assertion functions, test isolation, and reporting
#

# Color codes for output
declare -A COLORS
COLORS[RED]='\033[0;31m'
COLORS[GREEN]='\033[0;32m'
COLORS[YELLOW]='\033[1;33m'
COLORS[BLUE]='\033[0;34m'
COLORS[PURPLE]='\033[0;35m'
COLORS[CYAN]='\033[0;36m'
COLORS[WHITE]='\033[1;37m'
COLORS[BOLD]='\033[1m'
COLORS[NC]='\033[0m' # No Color

# Test state tracking
TEST_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0
CURRENT_TEST=""
CURRENT_SUITE=""
TEST_OUTPUT=""

# Array to store failed tests for summary
typeset -a FAILED_TESTS

# Initialize test framework
test_init() {
	TEST_COUNT=0
	PASSED_COUNT=0
	FAILED_COUNT=0
	FAILED_TESTS=()
	TEST_OUTPUT=""
	
	echo "${COLORS[BLUE]}${COLORS[BOLD]}╔══════════════════════════════════════════════════════════════════════════════════════╗${COLORS[NC]}"
	echo "${COLORS[BLUE]}${COLORS[BOLD]}║${COLORS[WHITE]} zsh-lazy-env Test Suite${COLORS[NC]}${COLORS[BLUE]}$(printf '%*s' 57 '')║${COLORS[NC]}"
	echo "${COLORS[BLUE]}${COLORS[BOLD]}╚══════════════════════════════════════════════════════════════════════════════════════╝${COLORS[NC]}"
	echo
}

# Start a test suite
test_suite() {
	local suite_name="$1"
	CURRENT_SUITE="$suite_name"
	echo "${COLORS[CYAN]}${COLORS[BOLD]}📁 Test Suite: $suite_name${COLORS[NC]}"
	echo "${COLORS[CYAN]}$(printf '─%.0s' {1..80})${COLORS[NC]}"
}

# Start individual test
test_start() {
	local test_name="$1"
	CURRENT_TEST="$test_name"
	TEST_COUNT=$((TEST_COUNT + 1))
	printf "${COLORS[BLUE]}  ▶ %-60s" "$test_name"
}

# Test assertions
assert_equals() {
	local expected="$1"
	local actual="$2"
	local message="${3:-}"
	
	if [[ "$expected" == "$actual" ]]; then
		test_pass
	else
		test_fail "Expected: '$expected', Got: '$actual'${message:+ - $message}"
	fi
}

assert_not_equals() {
	local expected="$1"
	local actual="$2"
	local message="${3:-}"
	
	if [[ "$expected" != "$actual" ]]; then
		test_pass
	else
		test_fail "Expected NOT: '$expected', but got exactly that${message:+ - $message}"
	fi
}

assert_contains() {
	local haystack="$1"
	local needle="$2"
	local message="${3:-}"
	
	if [[ "$haystack" == *"$needle"* ]]; then
		test_pass
	else
		test_fail "Expected '$haystack' to contain '$needle'${message:+ - $message}"
	fi
}

assert_not_contains() {
	local haystack="$1"
	local needle="$2"
	local message="${3:-}"
	
	if [[ "$haystack" != *"$needle"* ]]; then
		test_pass
	else
		test_fail "Expected '$haystack' NOT to contain '$needle'${message:+ - $message}"
	fi
}

assert_matches() {
	local string="$1"
	local pattern="$2"
	local message="${3:-}"
	
	if [[ "$string" =~ $pattern ]]; then
		test_pass
	else
		test_fail "Expected '$string' to match pattern '$pattern'${message:+ - $message}"
	fi
}

assert_true() {
	local condition="$1"
	local message="${2:-}"
	
	if [[ "$condition" == "true" ]] || [[ "$condition" == "0" ]] || [[ -n "$condition" && "$condition" != "false" ]]; then
		test_pass
	else
		test_fail "Expected true condition, got: '$condition'${message:+ - $message}"
	fi
}

assert_false() {
	local condition="$1"
	local message="${2:-}"
	
	if [[ "$condition" == "false" ]] || [[ "$condition" == "1" ]] || [[ -z "$condition" ]]; then
		test_pass
	else
		test_fail "Expected false condition, got: '$condition'${message:+ - $message}"
	fi
}

assert_command_success() {
	local command="$1"
	local message="${2:-}"
	
	if eval "$command" >/dev/null 2>&1; then
		test_pass
	else
		test_fail "Command '$command' failed${message:+ - $message}"
	fi
}

assert_command_fails() {
	local command="$1"
	local message="${2:-}"
	
	if ! eval "$command" >/dev/null 2>&1; then
		test_pass
	else
		test_fail "Command '$command' should have failed${message:+ - $message}"
	fi
}

assert_var_set() {
	local var_name="$1"
	local message="${2:-}"
	
	if [[ -n "${(P)var_name}" ]]; then
		test_pass
	else
		test_fail "Variable '$var_name' should be set${message:+ - $message}"
	fi
}

assert_var_unset() {
	local var_name="$1"
	local message="${2:-}"
	
	if [[ -z "${(P)var_name}" ]]; then
		test_pass
	else
		test_fail "Variable '$var_name' should be unset, but has value: '${(P)var_name}'${message:+ - $message}"
	fi
}

# Mark test as passed
test_pass() {
	PASSED_COUNT=$((PASSED_COUNT + 1))
	echo "${COLORS[GREEN]}✅ PASS${COLORS[NC]}"
}

# Mark test as failed
test_fail() {
	local reason="$1"
	FAILED_COUNT=$((FAILED_COUNT + 1))
	FAILED_TESTS+=("[$CURRENT_SUITE] $CURRENT_TEST: $reason")
	echo "${COLORS[RED]}❌ FAIL${COLORS[NC]}"
	echo "${COLORS[RED]}     $reason${COLORS[NC]}"
}

# Skip test
test_skip() {
	local reason="${1:-No reason given}"
	echo "${COLORS[YELLOW]}⏭️  SKIP${COLORS[NC]}"
	echo "${COLORS[YELLOW]}     $reason${COLORS[NC]}"
}

# Clean up test environment
test_cleanup() {
	# Reset all lazy-env state
	unset LAZY_VARS
	unset LOADED_VARS
	unset COMMAND_VARS
	unset PATTERN_VARS
	unset DIR_SCOPED_VARS
	unset DIR_PATTERN_SCOPED_VARS
	unset DIR_PATTERN_VARS
	unset DIR_PATTERN_KEYS
	unset DIRECTORY_VARS
	
	# Declare associative arrays again
	typeset -gA LAZY_VARS
	typeset -gA LOADED_VARS
	typeset -gA COMMAND_VARS
	typeset -gA PATTERN_VARS
	typeset -gA DIR_SCOPED_VARS
	typeset -gA DIR_PATTERN_SCOPED_VARS
	typeset -gA DIR_PATTERN_VARS
	typeset -ga DIR_PATTERN_KEYS
	typeset -gA DIRECTORY_VARS
	
	# Clean up test variables
	unset TEST_VAR_1 TEST_VAR_2 TEST_VAR_3
	unset API_KEY DATABASE_URL TF_TOKEN CLIENT_SECRET
	
	# Reset PWD to safe location
	cd /tmp 2>/dev/null || true
}

# Setup isolated test environment
test_setup() {
	test_cleanup
	
	# Create temporary test directory structure
	local test_dir="/tmp/lazy-env-test-$$"
	mkdir -p "$test_dir"/{project-a,project-b,terraform/{prod,staging},client-{acme,globex}}
	
	# Export for tests to use
	export LAZY_ENV_TEST_DIR="$test_dir"
}

# Print final test results
test_results() {
	echo
	echo "${COLORS[CYAN]}$(printf '─%.0s' {1..80})${COLORS[NC]}"
	echo "${COLORS[BOLD]}📊 Test Results Summary${COLORS[NC]}"
	echo "${COLORS[CYAN]}$(printf '─%.0s' {1..80})${COLORS[NC]}"
	echo
	
	local total_tests=$TEST_COUNT
	local success_rate=0
	
	if [[ $total_tests -gt 0 ]]; then
		success_rate=$((PASSED_COUNT * 100 / total_tests))
	fi
	
	echo "${COLORS[BLUE]}Total Tests:    ${COLORS[WHITE]}$total_tests${COLORS[NC]}"
	echo "${COLORS[GREEN]}Passed:         ${COLORS[WHITE]}$PASSED_COUNT${COLORS[NC]}"
	echo "${COLORS[RED]}Failed:         ${COLORS[WHITE]}$FAILED_COUNT${COLORS[NC]}"
	echo "${COLORS[YELLOW]}Success Rate:   ${COLORS[WHITE]}$success_rate%${COLORS[NC]}"
	echo
	
	# Show failed tests if any
	if [[ $FAILED_COUNT -gt 0 ]]; then
		echo "${COLORS[RED]}${COLORS[BOLD]}❌ Failed Tests:${COLORS[NC]}"
		echo "${COLORS[RED]}$(printf '─%.0s' {1..50})${COLORS[NC]}"
		for failed_test in "${FAILED_TESTS[@]}"; do
			echo "${COLORS[RED]}  • $failed_test${COLORS[NC]}"
		done
		echo
	fi
	
	# Final status
	if [[ $FAILED_COUNT -eq 0 ]]; then
		echo "${COLORS[GREEN]}${COLORS[BOLD]}🎉 All tests passed!${COLORS[NC]}"
		return 0
	else
		echo "${COLORS[RED]}${COLORS[BOLD]}💥 Some tests failed.${COLORS[NC]}"
		return 1
	fi
}

# Cleanup on exit
test_teardown() {
	# Remove test directories
	if [[ -n "$LAZY_ENV_TEST_DIR" && -d "$LAZY_ENV_TEST_DIR" ]]; then
		rm -rf "$LAZY_ENV_TEST_DIR"
	fi
	
	test_cleanup
}

# Trap to ensure cleanup
trap test_teardown EXIT