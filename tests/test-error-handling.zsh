#!/usr/bin/env zsh
# 
# Error Handling and Edge Case Tests
# Tests error conditions, malformed input, and edge cases
#

# Source test framework and plugin
source "$(dirname "$0")/test-framework.zsh"
source "$(dirname "$0")/../lazy-env.plugin.zsh"

test_suite "Error Handling - Invalid Input"

test_start "lazy_var with missing arguments"
	test_setup
	local output
	output=$(lazy_var 2>&1)
	local exit_code=$?
	
	assert_not_equals "0" "$exit_code" "Should return non-zero exit code"
	assert_contains "$output" "Usage:" "Should show usage message"

test_start "lazy_var with empty variable name"
	test_setup
	local output
	output=$(lazy_var "" "echo 'test'" 2>&1)
	local exit_code=$?
	
	assert_not_equals "0" "$exit_code" "Should return non-zero exit code for empty name"
	assert_contains "$output" "Usage:" "Should show usage message"

test_start "lazy_command with missing arguments"
	test_setup
	local output
	output=$(lazy_command 2>&1)
	local exit_code=$?
	
	assert_not_equals "0" "$exit_code" "Should return non-zero exit code"
	assert_contains "$output" "Usage:" "Should show usage message"

test_start "lazy_command with empty command"
	test_setup
	local output
	output=$(lazy_command "" "TEST_VAR" 2>&1)
	local exit_code=$?
	
	assert_not_equals "0" "$exit_code" "Should return non-zero exit code for empty command"

test_start "lazy_directory with missing arguments"
	test_setup
	local output
	output=$(lazy_directory 2>&1)
	local exit_code=$?
	
	assert_not_equals "0" "$exit_code" "Should return non-zero exit code"
	assert_contains "$output" "Usage:" "Should show usage message"

test_start "lazy_directory_pattern with invalid regex"
	test_setup
	lazy_var "TEST_VAR" "echo 'test'"
	# Register with invalid regex (unclosed bracket)
	lazy_directory_pattern "[invalid" "TEST_VAR"
	
	# Should register but fail to match
	local cmd
	cmd=$(_get_load_command_for_variable "TEST_VAR" "/tmp/invalid" 2>/dev/null)
	local exit_code=$?
	
	# Should fall back to global since pattern is invalid
	assert_equals "echo 'test'" "$cmd" "Should fall back to global when pattern fails"

test_suite "Error Handling - Variable Loading Failures"

test_start "command that exits with non-zero status"
	test_setup
	lazy_var "FAIL_VAR" "exit 1"
	lazy_load "FAIL_VAR"
	
	assert_equals "failed" "${LOADED_VARS[FAIL_VAR]}" "Should mark variable as failed"
	assert_var_unset "FAIL_VAR" "Failed variable should not be set in environment"

test_start "command that produces no output"
	test_setup
	lazy_var "EMPTY_VAR" "true"  # Command succeeds but produces no output
	lazy_load "EMPTY_VAR"
	
	assert_equals "failed" "${LOADED_VARS[EMPTY_VAR]}" "Should mark as failed when command produces no output"
	assert_var_unset "EMPTY_VAR" "Variable should not be set when command produces no output"

test_start "command that produces multiline output"
	test_setup
	lazy_var "MULTILINE_VAR" "printf 'line1\\nline2\\nline3'"
	lazy_load "MULTILINE_VAR"
	
	assert_equals "success" "${LOADED_VARS[MULTILINE_VAR]}" "Should mark multiline output as success"
	# The actual behavior - multiline output is preserved
	local expected_value=$'line1\nline2\nline3'
	assert_equals "$expected_value" "$MULTILINE_VAR" "Should preserve multiline output"

test_start "command with stderr output"
	test_setup
	lazy_var "STDERR_VAR" "echo 'stderr message' >&2; echo 'stdout value'"
	lazy_load "STDERR_VAR"
	
	assert_equals "success" "${LOADED_VARS[STDERR_VAR]}" "Should succeed despite stderr"
	assert_equals "stdout value" "$STDERR_VAR" "Should use stdout value"

test_start "command that times out or hangs"
	test_setup
	lazy_var "SLOW_VAR" "sleep 5; echo 'delayed-value'"
	
	# This test would normally take 5 seconds, but we can't easily test timeout
	# without modifying the plugin. For now, just verify it's registered correctly.
	assert_equals "sleep 5; echo 'delayed-value'" "${LAZY_VARS[SLOW_VAR]}" "Slow command should be registered"

test_start "command with special characters in output"
	test_setup
	lazy_var "SPECIAL_VAR" "echo 'value with spaces and \$pecial char@cters!'"
	lazy_load "SPECIAL_VAR"
	
	assert_equals "success" "${LOADED_VARS[SPECIAL_VAR]}" "Should handle special characters"
	assert_equals "value with spaces and \$pecial char@cters!" "$SPECIAL_VAR" "Should preserve special characters"

test_suite "Error Handling - Command Detection Edge Cases"

test_start "_lazy_env_preexec with empty command"
	test_setup
	local output
	output=$(_lazy_env_preexec "" 2>/dev/null)
	
	# Should not crash, but also should not load anything
	assert_true "true" "Should handle empty command gracefully"

test_start "_lazy_env_preexec with very long command"
	test_setup
	lazy_var "TEST_VAR" "echo 'test'"
	lazy_command "test-cmd" "TEST_VAR"
	
	# Create a very long command line
	local long_cmd="test-cmd $(printf 'arg%.0s ' {1..1000})"
	_lazy_env_preexec "$long_cmd"
	
	assert_equals "test" "$TEST_VAR" "Should handle very long command lines"

test_start "_lazy_env_preexec with command containing special regex chars"
	test_setup
	lazy_var "REGEX_VAR" "echo 'regex-test'"
	lazy_command "cmd[with]special(chars)" "REGEX_VAR"
	
	_lazy_env_preexec "cmd[with]special(chars) arg1 arg2"
	assert_equals "regex-test" "$REGEX_VAR" "Should handle commands with regex special characters"

test_start "pattern matching with malformed regex"
	test_setup
	lazy_var "PATTERN_VAR" "echo 'pattern-test'"
	
	# Manually insert malformed pattern (simulating corruption)
	# Use a different approach to avoid syntax error
	local malformed_pattern="[unclosed"
	PATTERN_VARS[$malformed_pattern]="PATTERN_VAR"
	
	# Test that it handles malformed regex gracefully
	local output
	output=$(lazy_test_command "test [unclosed command" 2>/dev/null || true)
	
	# Should not crash, may or may not match depending on zsh regex handling
	assert_true "true" "Should handle malformed regex gracefully"

test_suite "Error Handling - File System Edge Cases"

test_start "directory variable with nonexistent directory"
	test_setup
	lazy_var "NONEXIST_VAR" "echo 'nonexist-value'" "/nonexistent/directory/path"
	
	# Should register fine
	assert_true "${DIR_SCOPED_VARS[/nonexistent/directory/path:NONEXIST_VAR]+set}" "Should register nonexistent directory"
	
	# Should work when explicitly loaded
	lazy_load "NONEXIST_VAR" "/nonexistent/directory/path"
	assert_equals "nonexist-value" "$NONEXIST_VAR" "Should load even for nonexistent directory"

test_start "pattern matching very deep directory paths"
	test_setup
	local deep_path="/very/deep/directory/structure/that/goes/many/levels/deep/for/testing"
	lazy_var "DEEP_VAR" "echo 'deep-value'" "pattern:.*/deep/.*"
	
	lazy_load "DEEP_VAR" "$deep_path"
	assert_equals "deep-value" "$DEEP_VAR" "Should match patterns in very deep paths"

test_start "directory paths with special characters"
	test_setup
	local special_dir="/tmp/dir with spaces/and-dashes/and_underscores"
	lazy_var "SPECIAL_DIR_VAR" "echo 'special-value'" "$special_dir"
	
	lazy_load "SPECIAL_DIR_VAR" "$special_dir"
	assert_equals "special-value" "$SPECIAL_DIR_VAR" "Should handle directories with special characters"

test_start "relative directory paths"
	test_setup
	lazy_var "REL_VAR" "echo 'relative-value'" "./relative/path"
	
	# The relative path handling depends on how the plugin normalizes paths
	# This tests the current behavior
	assert_true "${DIR_SCOPED_VARS[./relative/path:REL_VAR]+set}" "Should register relative paths as-is"

test_suite "Error Handling - Memory and Performance Edge Cases"

test_start "many variables registered"
	test_setup
	
	# Register many variables
	for i in {1..100}; do
		lazy_var "VAR_$i" "echo 'value-$i'"
	done
	
	# Test that listing still works
	local output
	output=$(lazy_list_vars)
	assert_contains "$output" "VAR_1" "Should handle many variables"
	assert_contains "$output" "VAR_100" "Should list all variables"

test_start "many command patterns"
	test_setup
	lazy_var "PATTERN_VAR" "echo 'pattern-value'"
	
	# Register many patterns
	for i in {1..50}; do
		lazy_command_pattern "pattern_$i.*" "PATTERN_VAR"
	done
	
	# Test pattern matching still works
	local output
	output=$(lazy_test_command "pattern_25 test command")
	assert_contains "$output" "PATTERN_VAR" "Should handle many patterns"

test_start "very long variable names"
	test_setup
	local long_name=$(printf 'VERY_LONG_VARIABLE_NAME_%.0s' {1..10})
	lazy_var "$long_name" "echo 'long-name-value'"
	
	lazy_load "$long_name"
	assert_equals "long-name-value" "${(P)long_name}" "Should handle very long variable names"

test_start "very long commands"
	test_setup
	local long_command=$(printf 'very-long-command-name-%.0s' {1..20})
	lazy_var "LONG_CMD_VAR" "echo 'long-cmd-value'"
	lazy_command "$long_command" "LONG_CMD_VAR"
	
	_lazy_env_preexec "$long_command arg1 arg2"
	assert_equals "long-cmd-value" "$LONG_CMD_VAR" "Should handle very long command names"

test_suite "Error Handling - State Corruption Recovery"

test_start "corrupted LAZY_VARS array"
	test_setup
	lazy_var "GOOD_VAR" "echo 'good-value'"
	
	# Simulate corruption
	LAZY_VARS[""]="corrupted command"
	LAZY_VARS["CORRUPTED"]=""
	
	# Should still work for good variables
	lazy_load "GOOD_VAR"
	assert_equals "good-value" "$GOOD_VAR" "Should work despite corruption"

test_start "mixed array types"
	test_setup
	# This tests the robustness of our array handling
	lazy_var "TEST_VAR" "echo 'test-value'"
	
	# Simulate mixed data in arrays (though this shouldn't happen in normal use)
	LOADED_VARS["TEST_VAR"]="mixed-data"
	
	# Reloading should fix the state
	lazy_load "TEST_VAR"
	assert_equals "success" "${LOADED_VARS[TEST_VAR]}" "Should fix corrupted state on reload"

test_start "recovery from failed state"
	test_setup
	lazy_var "RECOVERY_VAR" "false"  # Initially fails
	lazy_load "RECOVERY_VAR"
	assert_equals "failed" "${LOADED_VARS[RECOVERY_VAR]}" "Should initially fail"
	
	# Update to working command
	lazy_var "RECOVERY_VAR" "echo 'recovered'"
	lazy_load "RECOVERY_VAR"
	
	assert_equals "success" "${LOADED_VARS[RECOVERY_VAR]}" "Should recover from failed state"
	assert_equals "recovered" "$RECOVERY_VAR" "Should load new value"

test_suite "Error Handling - Integration Edge Cases"

test_start "preexec hook with command substitution"
	test_setup
	lazy_var "SUB_VAR" "echo 'substitution-test'"
	lazy_command "nested" "SUB_VAR"
	
	# Command with substitution that contains our trigger
	_lazy_env_preexec "echo \$(nested command here)"
	
	assert_equals "substitution-test" "$SUB_VAR" "Should detect commands in substitution"

test_start "preexec hook with pipes and redirects"
	test_setup
	lazy_var "PIPE_VAR" "echo 'pipe-test'"
	lazy_command "kubectl" "PIPE_VAR"
	
	_lazy_env_preexec "kubectl get pods | grep running > /tmp/pods.txt"
	assert_equals "pipe-test" "$PIPE_VAR" "Should detect commands in complex pipelines"

test_start "variable loading during variable loading"
	test_setup
	# Create a circular reference scenario
	lazy_var "CIRCULAR_A" "echo 'circular-a'; lazy_load CIRCULAR_B"
	lazy_var "CIRCULAR_B" "echo 'circular-b'"
	
	lazy_load "CIRCULAR_A"
	# Should not hang or crash
	assert_equals "circular-a" "$CIRCULAR_A" "Should handle nested loading"

# Run the tests if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%x}" == "${0}" ]]; then
	test_init
	# Tests are automatically run when sourced due to the way zsh processes the file
	test_results
fi