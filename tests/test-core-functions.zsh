#!/usr/bin/env zsh
#
# Unit Tests for Core Functions
# Tests basic variable registration and command mapping functionality
#

# Source test framework and plugin
source "$(dirname "$0")/test-framework.zsh"
source "$(dirname "$0")/../lazy-env.plugin.zsh"

test_suite "Core Functions - Variable Registration"

# Test basic variable registration
test_start "lazy_var registers global variable"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'test-value-1'"

	assert_true "${LAZY_VARS[TEST_VAR_1]+set}" "Variable should be registered in LAZY_VARS"
	assert_equals "echo 'test-value-1'" "${LAZY_VARS[TEST_VAR_1]}" "Command should match"

test_start "lazy_var with directory scope"
	test_setup
	lazy_var "TEST_VAR_2" "echo 'test-value-2'" "/tmp/test-dir"

	assert_true "${DIR_SCOPED_VARS[/tmp/test-dir:TEST_VAR_2]+set}" "Variable should be registered in DIR_SCOPED_VARS"
	assert_equals "echo 'test-value-2'" "${DIR_SCOPED_VARS[/tmp/test-dir:TEST_VAR_2]}" "Command should match"

test_start "lazy_var with pattern scope"
	test_setup
	lazy_var "TEST_VAR_3" "echo 'test-value-3'" "pattern:.*/test/.*"

	assert_true "${DIR_PATTERN_SCOPED_VARS[.*/test/.*:TEST_VAR_3]+set}" "Variable should be registered in DIR_PATTERN_SCOPED_VARS"
	assert_equals "echo 'test-value-3'" "${DIR_PATTERN_SCOPED_VARS[.*/test/.*:TEST_VAR_3]}" "Command should match"

test_start "lazy_var handles empty command"
	test_setup
	lazy_var "EMPTY_VAR" ""

	assert_true "${LAZY_VARS[EMPTY_VAR]+set}" "Empty command should still register variable"
	assert_equals "" "${LAZY_VARS[EMPTY_VAR]}" "Empty command should be stored"

test_start "lazy_var overwrites existing variable"
	test_setup
	lazy_var "OVERWRITE_VAR" "echo 'first'"
	lazy_var "OVERWRITE_VAR" "echo 'second'"

	assert_equals "echo 'second'" "${LAZY_VARS[OVERWRITE_VAR]}" "Second command should overwrite first"

test_suite "Core Functions - Command Registration"

test_start "lazy_command registers exact command"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'test-value-1'"
	lazy_command "kubectl" "TEST_VAR_1"

	assert_equals "TEST_VAR_1" "${COMMAND_VARS[kubectl]}" "Command should map to variable"

test_start "lazy_command with multiple variables"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'test-value-1'"
	lazy_var "TEST_VAR_2" "echo 'test-value-2'"
	lazy_command "complex-cmd" "TEST_VAR_1,TEST_VAR_2"

	assert_equals "TEST_VAR_1,TEST_VAR_2" "${COMMAND_VARS[complex-cmd]}" "Command should map to both variables"

test_start "lazy_command with pattern registers pattern"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'test-value-1'"
	lazy_command "pattern:^git push.*github" "TEST_VAR_1"

	assert_equals "TEST_VAR_1" "${PATTERN_VARS[^git push.*github]}" "Pattern should map to variable"

test_start "lazy_command overwrites existing mapping"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'test-value-1'"
	lazy_var "TEST_VAR_2" "echo 'test-value-2'"
	lazy_command "overwrite-cmd" "TEST_VAR_1"
	lazy_command "overwrite-cmd" "TEST_VAR_2"

	assert_equals "TEST_VAR_2" "${COMMAND_VARS[overwrite-cmd]}" "Second mapping should overwrite first"

test_suite "Core Functions - Directory Registration"

test_start "lazy_directory registers directory mapping"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'test-value-1'"
	lazy_directory "/tmp/test-project" "TEST_VAR_1"

	assert_equals "TEST_VAR_1" "${DIRECTORY_VARS[/tmp/test-project]}" "Directory should map to variable"

test_start "lazy_directory with tilde expansion"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'test-value-1'"
	lazy_directory "~/test-project" "TEST_VAR_1"

	local expected_path="${HOME}/test-project"
	assert_equals "TEST_VAR_1" "${DIRECTORY_VARS[$expected_path]}" "Tilde should be expanded"

test_start "lazy_directory with pattern registers pattern"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'test-value-1'"
	lazy_directory "pattern:.*/terraform/.*" "TEST_VAR_1"

	assert_equals "TEST_VAR_1" "${DIR_PATTERN_VARS[.*/terraform/.*]}" "Pattern should map to variable"
	assert_contains "${DIR_PATTERN_KEYS[*]}" ".*/terraform/.*" "Pattern should be in keys array"

test_suite "Core Functions - Variable Loading"

test_start "lazy_load loads global variable"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'global-test-value'"
	lazy_load "TEST_VAR_1"

	assert_equals "global-test-value" "$TEST_VAR_1" "Variable should be loaded with correct value"
	assert_equals "success" "${LOADED_VARS[TEST_VAR_1]}" "Variable should be marked as loaded"

test_start "lazy_load with directory context"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'global-value'"
	lazy_var "TEST_VAR_1" "echo 'directory-value'" "/tmp/test-dir"

	# Test global context
	lazy_load "TEST_VAR_1" "/tmp/other-dir"
	assert_equals "global-value" "$TEST_VAR_1" "Should load global value in other directory"

	# Test directory context
	lazy_load "TEST_VAR_1" "/tmp/test-dir"
	assert_equals "directory-value" "$TEST_VAR_1" "Should load directory-specific value"

test_start "lazy_load with pattern matching"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'global-value'"
	lazy_var "TEST_VAR_1" "echo 'pattern-value'" "pattern:.*/terraform/.*"

	# Test non-matching directory
	lazy_load "TEST_VAR_1" "/tmp/other-dir"
	assert_equals "global-value" "$TEST_VAR_1" "Should load global value for non-matching directory"

	# Test matching directory
	lazy_load "TEST_VAR_1" "/tmp/terraform/prod"
	assert_equals "pattern-value" "$TEST_VAR_1" "Should load pattern value for matching directory"

test_start "lazy_load handles failed commands"
	test_setup
	lazy_var "FAIL_VAR" "false && echo 'should-not-appear'"
	lazy_load "FAIL_VAR"

	assert_equals "failed" "${LOADED_VARS[FAIL_VAR]}" "Failed variable should be marked as failed"
	assert_var_unset "FAIL_VAR" "Failed variable should not be set in environment"

test_start "lazy_load with nonexistent variable"
	test_setup
	local output
	output=$(lazy_load "NONEXISTENT_VAR" 2>&1)

	assert_contains "$output" "No lazy variable registered" "Should show error for nonexistent variable"

test_suite "Core Functions - Command Testing"

test_start "lazy_test_command detects exact command match"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'test-value-1'"
	lazy_command "kubectl" "TEST_VAR_1"

	local output
	output=$(lazy_test_command "kubectl get pods")
	assert_contains "$output" "TEST_VAR_1" "Should detect variable for exact command match"

test_start "lazy_test_command detects pattern match"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'test-value-1'"
	lazy_command "pattern:^git push.*github" "TEST_VAR_1"

	local output
	output=$(lazy_test_command "git push origin main github.com")
	assert_contains "$output" "TEST_VAR_1" "Should detect variable for pattern match"

test_start "lazy_test_command detects variable reference"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'test-value-1'"

	local output
	output=$(lazy_test_command "echo \$TEST_VAR_1")
	assert_contains "$output" "TEST_VAR_1" "Should detect variable reference in command"

test_start "lazy_test_command with no matches"
	test_setup
	local output
	output=$(lazy_test_command "ls -la")
	assert_contains "$output" "No variables" "Should report no matches for unregistered command"

test_suite "Core Functions - Variable Testing"

test_start "lazy_test_var shows correct command for global variable"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'global-value'"

	local output
	output=$(lazy_test_var "TEST_VAR_1" "/tmp/any-dir")
	assert_contains "$output" "echo 'global-value'" "Should show global command"

test_start "lazy_test_var shows directory-specific command"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'global-value'"
	lazy_var "TEST_VAR_1" "echo 'directory-value'" "/tmp/test-dir"

	local output
	output=$(lazy_test_var "TEST_VAR_1" "/tmp/test-dir")
	assert_contains "$output" "echo 'directory-value'" "Should show directory-specific command"

test_start "lazy_test_var shows pattern command"
	test_setup
	lazy_var "TEST_VAR_1" "echo 'global-value'"
	lazy_var "TEST_VAR_1" "echo 'pattern-value'" "pattern:.*/terraform/.*"

	local output
	output=$(lazy_test_var "TEST_VAR_1" "/tmp/terraform/prod")
	assert_contains "$output" "echo 'pattern-value'" "Should show pattern command"

test_start "lazy_test_var with nonexistent variable"
	test_setup
	local output
	output=$(lazy_test_var "NONEXISTENT_VAR" "/tmp/any-dir" 2>&1)
	assert_contains "$output" "No lazy variable registered" "Should show error for nonexistent variable"

# Run the tests if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%x}" == "${0}" ]]; then
	test_init
	# Tests are automatically run when sourced due to the way zsh processes the file
	test_results
fi
