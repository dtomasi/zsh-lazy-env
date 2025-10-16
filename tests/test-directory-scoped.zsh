#!/usr/bin/env zsh
# 
# Directory-Scoped Variable Tests
# Tests the core feature of directory-specific variable loading
#

# Source test framework and plugin
source "$(dirname "$0")/test-framework.zsh"
source "$(dirname "$0")/../lazy-env.plugin.zsh"

test_suite "Directory-Scoped Variables - Priority Resolution"

test_start "exact directory override beats global"
	test_setup
	lazy_var "API_KEY" "echo 'global-api-key'"
	lazy_var "API_KEY" "echo 'project-api-key'" "$LAZY_ENV_TEST_DIR/project-a"
	
	# Test global context
	lazy_load "API_KEY" "/tmp/other"
	assert_equals "global-api-key" "$API_KEY" "Should load global value outside project"
	
	# Test exact directory context
	lazy_load "API_KEY" "$LAZY_ENV_TEST_DIR/project-a"
	assert_equals "project-api-key" "$API_KEY" "Should load project-specific value in project directory"

test_start "pattern match beats global but loses to exact"
	test_setup
	lazy_var "API_KEY" "echo 'global-api-key'"
	lazy_var "API_KEY" "echo 'pattern-api-key'" "pattern:.*/terraform/.*"
	lazy_var "API_KEY" "echo 'exact-api-key'" "$LAZY_ENV_TEST_DIR/terraform/prod"
	
	# Test global context
	lazy_load "API_KEY" "/tmp/other"
	assert_equals "global-api-key" "$API_KEY" "Should load global value in non-matching directory"
	
	# Test pattern match
	lazy_load "API_KEY" "$LAZY_ENV_TEST_DIR/terraform/staging"
	assert_equals "pattern-api-key" "$API_KEY" "Should load pattern value in matching directory"
	
	# Test exact directory (should override pattern)
	lazy_load "API_KEY" "$LAZY_ENV_TEST_DIR/terraform/prod"
	assert_equals "exact-api-key" "$API_KEY" "Should load exact value over pattern value"

test_start "multiple patterns - first matching wins"
	test_setup
	lazy_var "TEST_VAR" "echo 'global-value'"
	lazy_var "TEST_VAR" "echo 'terraform-value'" "pattern:.*/terraform/.*"
	lazy_var "TEST_VAR" "echo 'prod-value'" "pattern:.*/prod.*"
	
	# Should match terraform pattern first
	lazy_load "TEST_VAR" "$LAZY_ENV_TEST_DIR/terraform/prod"
	assert_equals "terraform-value" "$TEST_VAR" "Should match first pattern (.*/terraform/.*)"

test_suite "Directory-Scoped Variables - Pattern Matching"

test_start "simple pattern matching"
	test_setup
	lazy_var "TERRAFORM_TOKEN" "echo 'tf-token'" "pattern:.*/terraform/.*"
	
	# Should match
	lazy_load "TERRAFORM_TOKEN" "$LAZY_ENV_TEST_DIR/terraform/prod"
	assert_equals "tf-token" "$TERRAFORM_TOKEN" "Should match terraform subdirectory"
	
	# Should not match
	lazy_load "TERRAFORM_TOKEN" "$LAZY_ENV_TEST_DIR/project-a"
	assert_var_unset "TERRAFORM_TOKEN" "Should not match non-terraform directory"

test_start "complex pattern with alternation"
	test_setup
	lazy_var "ENV_VAR" "echo 'env-specific'" "pattern:.*/terraform/(prod|staging)/.*"
	
	# Should match prod
	lazy_load "ENV_VAR" "$LAZY_ENV_TEST_DIR/terraform/prod"
	assert_equals "env-specific" "$ENV_VAR" "Should match prod environment"
	
	# Should match staging
	lazy_load "ENV_VAR" "$LAZY_ENV_TEST_DIR/terraform/staging"
	assert_equals "env-specific" "$ENV_VAR" "Should match staging environment"
	
	# Should not match other paths
	lazy_load "ENV_VAR" "$LAZY_ENV_TEST_DIR/terraform/dev"
	assert_var_unset "ENV_VAR" "Should not match dev environment"

test_start "pattern matching with client prefix"
	test_setup
	lazy_var "CLIENT_SECRET" "echo 'client-secret'" "pattern:.*/client-.*"
	
	# Should match client-acme
	lazy_load "CLIENT_SECRET" "$LAZY_ENV_TEST_DIR/client-acme"
	assert_equals "client-secret" "$CLIENT_SECRET" "Should match client-acme"
	
	# Should match client-globex
	lazy_load "CLIENT_SECRET" "$LAZY_ENV_TEST_DIR/client-globex"
	assert_equals "client-secret" "$CLIENT_SECRET" "Should match client-globex"
	
	# Should not match project directories
	lazy_load "CLIENT_SECRET" "$LAZY_ENV_TEST_DIR/project-a"
	assert_var_unset "CLIENT_SECRET" "Should not match non-client directory"

test_start "pattern with special regex characters"
	test_setup
	lazy_var "SPECIAL_VAR" "echo 'special-value'" "pattern:.*\\.(js|ts)$"
	
	# Test with file-like paths
	lazy_load "SPECIAL_VAR" "/tmp/test.js"
	assert_equals "special-value" "$SPECIAL_VAR" "Should match .js extension"
	
	lazy_load "SPECIAL_VAR" "/tmp/test.ts"
	assert_equals "special-value" "$SPECIAL_VAR" "Should match .ts extension"
	
	lazy_load "SPECIAL_VAR" "/tmp/test.py"
	assert_var_unset "SPECIAL_VAR" "Should not match .py extension"

test_suite "Directory-Scoped Variables - Automatic Directory Detection"

test_start "_get_load_command_for_variable prioritizes correctly"
	test_setup
	lazy_var "TEST_VAR" "echo 'global'"
	lazy_var "TEST_VAR" "echo 'pattern'" "pattern:.*/terraform/.*"
	lazy_var "TEST_VAR" "echo 'exact'" "$LAZY_ENV_TEST_DIR/terraform/prod"
	
	# Test exact directory
	local cmd
	cmd=$(_get_load_command_for_variable "TEST_VAR" "$LAZY_ENV_TEST_DIR/terraform/prod")
	assert_equals "echo 'exact'" "$cmd" "Should return exact directory command"
	
	# Test pattern match
	cmd=$(_get_load_command_for_variable "TEST_VAR" "$LAZY_ENV_TEST_DIR/terraform/staging")
	assert_equals "echo 'pattern'" "$cmd" "Should return pattern command"
	
	# Test global fallback
	cmd=$(_get_load_command_for_variable "TEST_VAR" "/tmp/other")
	assert_equals "echo 'global'" "$cmd" "Should return global command"

test_start "_get_load_command_for_variable with nonexistent variable"
	test_setup
	local cmd
	local exit_code
	
	cmd=$(_get_load_command_for_variable "NONEXISTENT" "/tmp/any" 2>/dev/null)
	exit_code=$?
	
	assert_not_equals "0" "$exit_code" "Should return non-zero exit code for nonexistent variable"

test_suite "Directory-Scoped Variables - Variable Scope Isolation"

test_start "directory variables don't interfere with global"
	test_setup
	lazy_var "GLOBAL_VAR" "echo 'global-value'"
	lazy_var "PROJECT_VAR" "echo 'project-value'" "$LAZY_ENV_TEST_DIR/project-a"
	
	# Load global variable
	lazy_load "GLOBAL_VAR"
	assert_equals "global-value" "$GLOBAL_VAR" "Global variable should load correctly"
	
	# Project variable should not exist globally
	lazy_load "PROJECT_VAR" "/tmp/other" 2>/dev/null
	assert_var_unset "PROJECT_VAR" "Project variable should not load outside project"
	
	# Project variable should exist in project
	lazy_load "PROJECT_VAR" "$LAZY_ENV_TEST_DIR/project-a"
	assert_equals "project-value" "$PROJECT_VAR" "Project variable should load in project directory"

test_start "same variable name different scopes"
	test_setup
	lazy_var "CONFIG_PATH" "echo '/global/config'"
	lazy_var "CONFIG_PATH" "echo '/project-a/config'" "$LAZY_ENV_TEST_DIR/project-a"
	lazy_var "CONFIG_PATH" "echo '/project-b/config'" "$LAZY_ENV_TEST_DIR/project-b"
	
	# Test each scope
	lazy_load "CONFIG_PATH" "/tmp/other"
	assert_equals "/global/config" "$CONFIG_PATH" "Should load global config path"
	
	lazy_load "CONFIG_PATH" "$LAZY_ENV_TEST_DIR/project-a"
	assert_equals "/project-a/config" "$CONFIG_PATH" "Should load project-a config path"
	
	lazy_load "CONFIG_PATH" "$LAZY_ENV_TEST_DIR/project-b"
	assert_equals "/project-b/config" "$CONFIG_PATH" "Should load project-b config path"

test_suite "Directory-Scoped Variables - Edge Cases"

test_start "directory path normalization"
	test_setup
	local test_dir="$LAZY_ENV_TEST_DIR/project-a"
	lazy_var "TEST_VAR" "echo 'normalized'" "$test_dir"
	
	# Test with trailing slash
	lazy_load "TEST_VAR" "$test_dir/"
	assert_equals "normalized" "$TEST_VAR" "Should work with trailing slash"
	
	# Test with double slashes
	lazy_load "TEST_VAR" "$test_dir//."
	assert_equals "normalized" "$TEST_VAR" "Should work with path normalization"

test_start "nested directory inheritance"
	test_setup
	# Only global and specific nested directory
	lazy_var "NESTED_VAR" "echo 'global'"
	lazy_var "NESTED_VAR" "echo 'nested'" "$LAZY_ENV_TEST_DIR/terraform/prod"
	
	# Parent directory should use global
	lazy_load "NESTED_VAR" "$LAZY_ENV_TEST_DIR/terraform"
	assert_equals "global" "$NESTED_VAR" "Parent directory should use global"
	
	# Exact nested directory should use specific
	lazy_load "NESTED_VAR" "$LAZY_ENV_TEST_DIR/terraform/prod"
	assert_equals "nested" "$NESTED_VAR" "Nested directory should use specific value"

test_start "pattern with special directory names"
	test_setup
	# Create directory with special characters
	local special_dir="$LAZY_ENV_TEST_DIR/project-with-dashes"
	mkdir -p "$special_dir"
	
	lazy_var "SPECIAL_VAR" "echo 'special'" "pattern:.*project-with-dashes.*"
	
	lazy_load "SPECIAL_VAR" "$special_dir"
	assert_equals "special" "$SPECIAL_VAR" "Should match directory with special characters"

test_start "relative vs absolute paths"
	test_setup
	# Register with relative path
	lazy_var "REL_VAR" "echo 'relative'" "./relative-dir"
	
	# Should work when PWD makes it valid
	mkdir -p "$LAZY_ENV_TEST_DIR/relative-dir"
	cd "$LAZY_ENV_TEST_DIR"
	lazy_load "REL_VAR" "$PWD/relative-dir"
	assert_equals "relative" "$REL_VAR" "Should work with relative paths when resolved"

test_start "variable loading order independence"
	test_setup
	# Register in different order
	lazy_var "ORDER_VAR" "echo 'exact'" "$LAZY_ENV_TEST_DIR/terraform/prod"
	lazy_var "ORDER_VAR" "echo 'pattern'" "pattern:.*/terraform/.*"
	lazy_var "ORDER_VAR" "echo 'global'"
	
	# Exact should still win regardless of registration order
	lazy_load "ORDER_VAR" "$LAZY_ENV_TEST_DIR/terraform/prod"
	assert_equals "exact" "$ORDER_VAR" "Exact directory should win regardless of order"

# Run the tests if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%x}" == "${0}" ]]; then
	test_init
	# Tests are automatically run when sourced due to the way zsh processes the file
	test_results
fi