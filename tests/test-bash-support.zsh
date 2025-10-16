#!/usr/bin/env zsh
# test-bash-support.zsh - Tests for bash script support functionality

# Source the test framework
source "${0:A:h}/test-framework.zsh"

# Source the plugin
source "${0:A:h}/../lazy-env.plugin.zsh"

# Create test directories and files
setup_bash_test_environment() {
	# Create test directories
	mkdir -p "/tmp/lazy-env-test/scripts"
	mkdir -p "/tmp/lazy-env-test/nested/scripts"

	# Create test bash scripts
	cat > "/tmp/lazy-env-test/scripts/deploy.sh" << 'EOF'
#!/bin/bash
echo "Deploy script running"
echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"
echo "DEPLOY_TOKEN: $DEPLOY_TOKEN"
EOF

	cat > "/tmp/lazy-env-test/scripts/test-script.sh" << 'EOF'
#!/bin/bash
echo "Test script running"
echo "TEST_VAR: $TEST_VAR"
echo "ANOTHER_VAR: $ANOTHER_VAR"
EOF

	cat > "/tmp/lazy-env-test/nested/scripts/nested-deploy.sh" << 'EOF'
#!/bin/bash
echo "Nested deploy script running"
echo "NESTED_TOKEN: $NESTED_TOKEN"
EOF

	# Make scripts executable
	chmod +x "/tmp/lazy-env-test/scripts/deploy.sh"
	chmod +x "/tmp/lazy-env-test/scripts/test-script.sh"
	chmod +x "/tmp/lazy-env-test/nested/scripts/nested-deploy.sh"
}

cleanup_bash_test_environment() {
	rm -rf "/tmp/lazy-env-test"
}

test_lazy_bash_script_registration() {
	test_start "lazy_bash_script registration"

	# Clear any existing registrations
	BASH_SCRIPT_VARS=()

	# Test basic registration
	lazy_bash_script "/tmp/lazy-env-test/scripts/deploy.sh" "AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY"

	local expected_vars="AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY"
	# Check both the original path and the normalized path (macOS /tmp -> /private/tmp)
	local actual_vars="${BASH_SCRIPT_VARS[/tmp/lazy-env-test/scripts/deploy.sh]}"
	local normalized_path="$(realpath "/tmp/lazy-env-test/scripts/deploy.sh" 2>/dev/null || echo "/tmp/lazy-env-test/scripts/deploy.sh")"
	if [[ -z "$actual_vars" ]]; then
		actual_vars="${BASH_SCRIPT_VARS[$normalized_path]}"
	fi

	if [[ "$actual_vars" == "$expected_vars" ]]; then
		test_pass "Basic bash script registration works"
	else
		test_fail "Basic bash script registration failed. Expected: $expected_vars, Got: $actual_vars"
	fi

	test_end
}

test_lazy_bash_script_pattern_registration() {
	test_start "lazy_bash_script pattern registration"

	# Clear any existing registrations
	BASH_SCRIPT_VARS=()

	# Test pattern registration
	lazy_bash_script "pattern:.*deploy.*\.sh" "DEPLOY_TOKEN"

	local expected_vars="DEPLOY_TOKEN"
	local actual_vars="${BASH_SCRIPT_VARS[pattern:.*deploy.*\.sh]}"

	if [[ "$actual_vars" == "$expected_vars" ]]; then
		test_pass "Pattern-based bash script registration works"
	else
		test_fail "Pattern-based bash script registration failed. Expected: $expected_vars, Got: $actual_vars"
	fi

	test_end
}

test_lazy_bash_script_tilde_expansion() {
	test_start "lazy_bash_script tilde expansion"

	# Clear any existing registrations
	BASH_SCRIPT_VARS=()

	# Test tilde expansion
	lazy_bash_script "~/test-script.sh" "HOME_VAR"

	local expected_path="$HOME/test-script.sh"
	local actual_vars="${BASH_SCRIPT_VARS[$expected_path]}"

	if [[ "$actual_vars" == "HOME_VAR" ]]; then
		test_pass "Tilde expansion in script path works"
	else
		test_fail "Tilde expansion failed. Expected path: $expected_path, Registered vars: $actual_vars"
	fi

	test_end
}

test_lazy_bash_script_error_handling() {
	test_start "lazy_bash_script error handling"

	# Test missing arguments
	local output
	output=$(lazy_bash_script 2>&1)
	local exit_code=$?

	if [[ $exit_code -ne 0 ]] && [[ "$output" == *"Usage: lazy_bash_script"* ]]; then
		test_pass "Error handling for missing arguments works"
	else
		test_fail "Error handling for missing arguments failed. Exit code: $exit_code, Output: $output"
	fi

	# Test missing second argument
	output=$(lazy_bash_script "/path/to/script.sh" 2>&1)
	exit_code=$?

	if [[ $exit_code -ne 0 ]] && [[ "$output" == *"Usage: lazy_bash_script"* ]]; then
		test_pass "Error handling for missing variables argument works"
	else
		test_fail "Error handling for missing variables argument failed. Exit code: $exit_code, Output: $output"
	fi

	test_end
}

test_load_variables_for_bash_script_exact_match() {
	test_start "_load_variables_for_bash_script exact match"

	# Setup
	BASH_SCRIPT_VARS=()
	LAZY_VARS=()
	LOADED_VARS=()

	# Register variables
	lazy_var "AWS_ACCESS_KEY_ID" "echo 'test-access-key'"
	lazy_var "AWS_SECRET_ACCESS_KEY" "echo 'test-secret-key'"
	lazy_bash_script "/tmp/lazy-env-test/scripts/deploy.sh" "AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY"

	# Test loading
	_load_variables_for_bash_script "/tmp/lazy-env-test/scripts/deploy.sh"

	# Check if variables were loaded
	if [[ "${LOADED_VARS[AWS_ACCESS_KEY_ID]}" == "success" ]] && [[ "${LOADED_VARS[AWS_SECRET_ACCESS_KEY]}" == "success" ]]; then
		test_pass "Variables loaded for exact script path match"
	else
		test_fail "Variables not loaded for exact script path match. AWS_ACCESS_KEY_ID: ${LOADED_VARS[AWS_ACCESS_KEY_ID]}, AWS_SECRET_ACCESS_KEY: ${LOADED_VARS[AWS_SECRET_ACCESS_KEY]}"
	fi

	# Check if variables have correct values
	if [[ "$AWS_ACCESS_KEY_ID" == "test-access-key" ]] && [[ "$AWS_SECRET_ACCESS_KEY" == "test-secret-key" ]]; then
		test_pass "Variables have correct values after loading"
	else
		test_fail "Variables have incorrect values. AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"
	fi

	test_end
}

test_load_variables_for_bash_script_pattern_match() {
	test_start "_load_variables_for_bash_script pattern match"

	# Setup
	BASH_SCRIPT_VARS=()
	LAZY_VARS=()
	LOADED_VARS=()

	# Register variables
	lazy_var "DEPLOY_TOKEN" "echo 'deploy-token-123'"
	lazy_bash_script "pattern:.*deploy.*\.sh" "DEPLOY_TOKEN"

	# Test loading for script that matches pattern
	_load_variables_for_bash_script "/tmp/lazy-env-test/scripts/deploy.sh"

	if [[ "${LOADED_VARS[DEPLOY_TOKEN]}" == "success" ]] && [[ "$DEPLOY_TOKEN" == "deploy-token-123" ]]; then
		test_pass "Variables loaded for pattern match"
	else
		test_fail "Variables not loaded for pattern match. DEPLOY_TOKEN status: ${LOADED_VARS[DEPLOY_TOKEN]}, value: $DEPLOY_TOKEN"
	fi

	# Test loading for nested script that also matches pattern
	_load_variables_for_bash_script "/tmp/lazy-env-test/nested/scripts/nested-deploy.sh"

	if [[ "${LOADED_VARS[DEPLOY_TOKEN]}" == "success" ]]; then
		test_pass "Variables loaded for nested script pattern match"
	else
		test_fail "Variables not loaded for nested script pattern match. DEPLOY_TOKEN status: ${LOADED_VARS[DEPLOY_TOKEN]}"
	fi

	test_end
}

test_load_variables_for_bash_script_multiple_patterns() {
	test_start "_load_variables_for_bash_script multiple patterns"

	# Setup
	BASH_SCRIPT_VARS=()
	LAZY_VARS=()
	LOADED_VARS=()

	# Register variables with multiple patterns - use more specific patterns
	lazy_var "DEPLOY_TOKEN" "echo 'deploy-token'"
	lazy_var "SCRIPT_TOKEN" "echo 'script-token'"
	lazy_bash_script "pattern:.*deploy\.sh$" "DEPLOY_TOKEN"
	lazy_bash_script "pattern:.*test-script\.sh$" "SCRIPT_TOKEN"

	# Test script that matches first pattern
	_load_variables_for_bash_script "/tmp/lazy-env-test/scripts/deploy.sh"

	if [[ "${LOADED_VARS[DEPLOY_TOKEN]}" == "success" ]] && [[ -z "${LOADED_VARS[SCRIPT_TOKEN]}" || "${LOADED_VARS[SCRIPT_TOKEN]}" != "success" ]]; then
		test_pass "Only matching pattern variables loaded (deploy script)"
	else
		test_fail "Incorrect pattern matching for deploy script. DEPLOY_TOKEN: ${LOADED_VARS[DEPLOY_TOKEN]}, SCRIPT_TOKEN: ${LOADED_VARS[SCRIPT_TOKEN]}"
	fi

	# Reset and test script that matches second pattern
	LOADED_VARS=()
	unset DEPLOY_TOKEN SCRIPT_TOKEN

	_load_variables_for_bash_script "/tmp/lazy-env-test/scripts/test-script.sh"

	if [[ "${LOADED_VARS[SCRIPT_TOKEN]}" == "success" ]] && [[ -z "${LOADED_VARS[DEPLOY_TOKEN]}" || "${LOADED_VARS[DEPLOY_TOKEN]}" != "success" ]]; then
		test_pass "Only matching pattern variables loaded (test script)"
	else
		test_fail "Incorrect pattern matching for test script. DEPLOY_TOKEN: ${LOADED_VARS[DEPLOY_TOKEN]}, SCRIPT_TOKEN: ${LOADED_VARS[SCRIPT_TOKEN]}"
	fi

	test_end
}

test_bash_wrapper_function() {
	test_start "bash wrapper function"

	# Setup
	BASH_SCRIPT_VARS=()
	LAZY_VARS=()
	LOADED_VARS=()

	# Enable bash support
	LAZY_ENV_BASH_SUPPORT="true"

	# Register variables
	lazy_var "TEST_VAR" "echo 'test-value'"
	lazy_bash_script "/tmp/lazy-env-test/scripts/test-script.sh" "TEST_VAR"

	# Test bash wrapper - execute script and capture output
	local output
	output=$(bash "/tmp/lazy-env-test/scripts/test-script.sh" 2>&1)

	if [[ "$output" == *"TEST_VAR: test-value"* ]]; then
		test_pass "Bash wrapper loads variables before script execution"
	else
		test_fail "Bash wrapper failed to load variables. Output: $output"
	fi

	test_end
}

test_bash_wrapper_disabled() {
	test_start "bash wrapper when disabled"

	# Setup
	BASH_SCRIPT_VARS=()
	LAZY_VARS=()
	LOADED_VARS=()

	# Disable bash support
	LAZY_ENV_BASH_SUPPORT="false"

	# Register variables
	lazy_var "TEST_VAR" "echo 'test-value'"
	lazy_bash_script "/tmp/lazy-env-test/scripts/test-script.sh" "TEST_VAR"

	# Test bash wrapper - execute script and capture output
	local output
	output=$(bash "/tmp/lazy-env-test/scripts/test-script.sh" 2>&1)

	# Variable should be empty since bash support is disabled
	if [[ "$output" == *"TEST_VAR:"* ]] && [[ "$output" != *"TEST_VAR: test-value"* ]]; then
		test_pass "Bash wrapper respects disabled setting"
	else
		test_fail "Bash wrapper ignored disabled setting. Output: $output"
	fi

	# Re-enable for other tests
	LAZY_ENV_BASH_SUPPORT="true"

	test_end
}

test_bash_wrapper_non_script_files() {
	test_start "bash wrapper with non-script files"

	# Setup
	BASH_SCRIPT_VARS=()
	LAZY_VARS=()
	LOADED_VARS=()

	LAZY_ENV_BASH_SUPPORT="true"

	# Register variables
	lazy_var "TEST_VAR" "echo 'test-value'"

	# Test with non-.sh file (should not trigger variable loading)
	echo "echo 'TEST_VAR: \$TEST_VAR'" > "/tmp/lazy-env-test/not-a-script.txt"

	local output
	output=$(bash "/tmp/lazy-env-test/not-a-script.txt" 2>&1)

	# Should not load variables for non-.sh files
	if [[ "${LOADED_VARS[TEST_VAR]}" != "success" ]]; then
		test_pass "Bash wrapper ignores non-.sh files"
	else
		test_fail "Bash wrapper incorrectly processed non-.sh file"
	fi

	test_end
}

test_export_loaded_variables() {
	test_start "_export_loaded_variables function"

	# Setup
	LOADED_VARS=()
	unset TEST_EXPORT_VAR ANOTHER_EXPORT_VAR

	# Set up some loaded variables
	TEST_EXPORT_VAR="test-value"
	ANOTHER_EXPORT_VAR="another-value"
	LOADED_VARS[TEST_EXPORT_VAR]="success"
	LOADED_VARS[ANOTHER_EXPORT_VAR]="success"

	# Test export function
	_export_loaded_variables

	# Check if variables are exported (we can't directly test export status in zsh easily,
	# but we can test that the function runs without error)
	if _export_loaded_variables; then
		test_pass "Export function runs without error"
	else
		test_fail "Export function failed"
	fi

	test_end
}

test_bash_support_integration() {
	test_start "Full bash support integration test"

	# Setup
	BASH_SCRIPT_VARS=()
	LAZY_VARS=()
	LOADED_VARS=()
	LAZY_ENV_BASH_SUPPORT="true"

	# Register multiple variables with different methods
	lazy_var "INTEGRATION_VAR1" "echo 'integration-value-1'"
	lazy_var "INTEGRATION_VAR2" "echo 'integration-value-2'"
	lazy_var "PATTERN_VAR" "echo 'pattern-value'"

	# Register exact script
	lazy_bash_script "/tmp/lazy-env-test/scripts/deploy.sh" "INTEGRATION_VAR1,INTEGRATION_VAR2"

	# Register pattern
	lazy_bash_script "pattern:.*test.*\.sh" "PATTERN_VAR"

	# Create integration test script
	cat > "/tmp/lazy-env-test/scripts/integration-test.sh" << 'EOF'
#!/bin/bash
echo "INTEGRATION_VAR1: $INTEGRATION_VAR1"
echo "INTEGRATION_VAR2: $INTEGRATION_VAR2"
echo "PATTERN_VAR: $PATTERN_VAR"
EOF
	chmod +x "/tmp/lazy-env-test/scripts/integration-test.sh"

	# Test execution
	local output
	output=$(bash "/tmp/lazy-env-test/scripts/integration-test.sh" 2>&1)

	# Should only load PATTERN_VAR (matches pattern), not INTEGRATION_VAR1/2 (exact path doesn't match)
	if [[ "$output" == *"PATTERN_VAR: pattern-value"* ]] &&
	   [[ "$output" == *"INTEGRATION_VAR1:"* ]] &&
	   [[ "$output" != *"INTEGRATION_VAR1: integration-value-1"* ]]; then
		test_pass "Integration test: pattern matching works correctly"
	else
		test_fail "Integration test failed. Output: $output"
	fi

	# Reset loaded variables for fresh test
	LOADED_VARS=()
	unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY DEPLOY_TOKEN

	# Re-register variables for exact script test
	lazy_var "AWS_ACCESS_KEY_ID" "echo 'test-access-key'"
	lazy_var "AWS_SECRET_ACCESS_KEY" "echo 'test-secret-key'"
	lazy_bash_script "/tmp/lazy-env-test/scripts/deploy.sh" "AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY"

	# Test the exact script
	output=$(bash "/tmp/lazy-env-test/scripts/deploy.sh" 2>&1)

	if [[ "$output" == *"AWS_ACCESS_KEY_ID: test-access-key"* ]] &&
	   [[ "$output" == *"AWS_SECRET_ACCESS_KEY: test-secret-key"* ]]; then
		test_pass "Integration test: exact script matching works correctly"
	else
		test_fail "Integration test for exact script failed. Output: $output"
	fi

	test_end
}

# Initialize test environment
test_init

# Set up test environment
setup_bash_test_environment

# Run all tests
test_lazy_bash_script_registration
test_lazy_bash_script_pattern_registration
test_lazy_bash_script_tilde_expansion
test_lazy_bash_script_error_handling
test_load_variables_for_bash_script_exact_match
test_load_variables_for_bash_script_pattern_match
test_load_variables_for_bash_script_multiple_patterns
test_bash_wrapper_function
test_bash_wrapper_disabled
test_bash_wrapper_non_script_files
test_export_loaded_variables
test_bash_support_integration

# Clean up test environment
cleanup_bash_test_environment

# Show results
test_results

# Auto-run tests when script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%x}" == "${0}" ]]; then
	test_init
	# Tests are automatically run when sourced due to the way zsh processes the file
	test_results
fi
