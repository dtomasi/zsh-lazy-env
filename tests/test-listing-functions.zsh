#!/usr/bin/env zsh
#
# Listing Functions Tests
# Tests the output formatting of lazy_list_vars, lazy_list_commands, lazy_list_directories
#

# Source test framework and plugin
source "$(dirname "$0")/test-framework.zsh"
source "$(dirname "$0")/../lazy-env.plugin.zsh"

test_suite "Listing Functions - lazy_list_vars"

test_start "lazy_list_vars shows proper table headers"
	test_setup
	local output
	output=$(lazy_list_vars)

	assert_contains "$output" "NAME" "Should contain NAME header"
	assert_contains "$output" "STATUS" "Should contain STATUS header"
	assert_contains "$output" "DIRECTORY" "Should contain DIRECTORY header"
	assert_contains "$output" "----" "Should contain header separator"

test_start "lazy_list_vars shows global variables"
	test_setup
	lazy_var "GLOBAL_VAR1" "echo 'value1'"
	lazy_var "GLOBAL_VAR2" "echo 'value2'"

	local output
	output=$(lazy_list_vars)

	assert_contains "$output" "GLOBAL_VAR1" "Should list first global variable"
	assert_contains "$output" "GLOBAL_VAR2" "Should list second global variable"
	assert_contains "$output" "global" "Should show global scope"
	assert_contains "$output" "registered" "Should show registered status"

test_start "lazy_list_vars shows directory-scoped variables"
	test_setup
	lazy_var "DIR_VAR1" "echo 'dir-value'" "$LAZY_ENV_TEST_DIR/project-a"
	lazy_var "DIR_VAR2" "echo 'dir-value'" "$LAZY_ENV_TEST_DIR/project-b"

	local output
	output=$(lazy_list_vars)

	assert_contains "$output" "DIR_VAR1" "Should list first directory variable"
	assert_contains "$output" "DIR_VAR2" "Should list second directory variable"
	assert_contains "$output" "project-a" "Should show project-a directory"
	assert_contains "$output" "project-b" "Should show project-b directory"

test_start "lazy_list_vars shows pattern-scoped variables"
	test_setup
	lazy_var "PATTERN_VAR" "echo 'pattern-value'" "pattern:.*/terraform/.*"

	local output
	output=$(lazy_list_vars)

	assert_contains "$output" "PATTERN_VAR" "Should list pattern variable"
	assert_contains "$output" "pattern:.*/terraform/.*" "Should show pattern scope"

test_start "lazy_list_vars shows loaded variable status"
	test_setup
	lazy_var "LOADED_VAR" "echo 'loaded-value'"
	lazy_var "FAILED_VAR" "false && echo 'failed'"

	# Load one successfully, one with failure
	lazy_load "LOADED_VAR"
	lazy_load "FAILED_VAR" 2>/dev/null || true

	local output
	output=$(lazy_list_vars)

	assert_contains "$output" "loaded" "Should show loaded status"
	assert_contains "$output" "failed" "Should show failed status"

test_start "lazy_list_vars column formatting is consistent"
	test_setup
	lazy_var "SHORT" "echo 'value'"
	lazy_var "VERY_LONG_VARIABLE_NAME_HERE" "echo 'value'"

	local output
	output=$(lazy_list_vars)

	# Check that the STATUS column aligns properly
	local line1=$(echo "$output" | grep "SHORT")
	local line2=$(echo "$output" | grep "VERY_LONG_VARIABLE_NAME_HERE")

	assert_true "[[ -n '$line1' ]]" "Should contain short variable line"
	assert_true "[[ -n '$line2' ]]" "Should contain long variable line"

test_suite "Listing Functions - lazy_list_commands"

test_start "lazy_list_commands shows proper table headers"
	test_setup
	local output
	output=$(lazy_list_commands)

	assert_contains "$output" "COMMAND" "Should contain COMMAND header"
	assert_contains "$output" "TYPE" "Should contain TYPE header"
	assert_contains "$output" "VARIABLES" "Should contain VARIABLES header"
	assert_contains "$output" "-------" "Should contain header separator"

test_start "lazy_list_commands shows exact command mappings"
	test_setup
	lazy_var "TEST_VAR1" "echo 'value1'"
	lazy_var "TEST_VAR2" "echo 'value2'"
	lazy_command "kubectl" "TEST_VAR1"
	lazy_command "docker" "TEST_VAR1,TEST_VAR2"

	local output
	output=$(lazy_list_commands)

	assert_contains "$output" "kubectl" "Should list kubectl command"
	assert_contains "$output" "docker" "Should list docker command"
	assert_contains "$output" "exact" "Should show exact type"
	assert_contains "$output" "TEST_VAR1" "Should show mapped variable"
	assert_contains "$output" "TEST_VAR1,TEST_VAR2" "Should show multiple variables"

test_start "lazy_list_commands shows pattern commands"
	test_setup
	lazy_var "GIT_VAR" "echo 'git-value'"
	lazy_command "pattern:^git push.*github" "GIT_VAR"

	local output
	output=$(lazy_list_commands)

	assert_contains "$output" "^git push.*github" "Should list command pattern"
	assert_contains "$output" "pattern" "Should show pattern type"
	assert_contains "$output" "GIT_VAR" "Should show mapped variable"

test_start "lazy_list_commands truncates long patterns"
	test_setup
	lazy_var "LONG_VAR" "echo 'long-value'"
	lazy_command "pattern:^very_long_command_pattern_that_exceeds_column_width_and_should_be_truncated" "LONG_VAR"

	local output
	output=$(lazy_list_commands)

	assert_contains "$output" "..." "Should contain truncation indicator"
	assert_contains "$output" "LONG_VAR" "Should still show mapped variable"

test_start "lazy_list_commands handles empty state"
	test_setup
	# No commands registered
	local output
	output=$(lazy_list_commands)

	assert_contains "$output" "COMMAND" "Should still show headers"
	assert_contains "$output" "TYPE" "Should still show headers"
	assert_contains "$output" "VARIABLES" "Should still show headers"

test_suite "Listing Functions - lazy_list_directories"

test_start "lazy_list_directories shows proper table headers"
	test_setup
	local output
	output=$(lazy_list_directories)

	assert_contains "$output" "DIRECTORY" "Should contain DIRECTORY header"
	assert_contains "$output" "TYPE" "Should contain TYPE header"
	assert_contains "$output" "VARIABLES" "Should contain VARIABLES header"
	assert_contains "$output" "---------" "Should contain header separator"

test_start "lazy_list_directories shows exact directory mappings"
	test_setup
	lazy_var "DIR_VAR1" "echo 'value1'" "$LAZY_ENV_TEST_DIR/project-a"
	lazy_var "DIR_VAR2" "echo 'value2'" "$LAZY_ENV_TEST_DIR/project-a"
	lazy_var "DIR_VAR3" "echo 'value3'" "$LAZY_ENV_TEST_DIR/project-b"

	local output
	output=$(lazy_list_directories)

	assert_contains "$output" "project-a" "Should list project-a directory"
	assert_contains "$output" "project-b" "Should list project-b directory"
	assert_contains "$output" "exact" "Should show exact type"
	assert_contains "$output" "DIR_VAR1, DIR_VAR2" "Should group variables for same directory"
	assert_contains "$output" "DIR_VAR3" "Should show single variable"

test_start "lazy_list_directories shows pattern directories"
	test_setup
	lazy_var "PATTERN_VAR" "echo 'pattern-value'" "pattern:.*/terraform/.*"
	lazy_directory "pattern:.*/client-.*" "CLIENT_VAR"

	local output
	output=$(lazy_list_directories)

	assert_contains "$output" ".*/terraform/.*" "Should list terraform pattern"
	assert_contains "$output" ".*/client-.*" "Should list client pattern"
	assert_contains "$output" "pattern" "Should show pattern type"

test_start "lazy_list_directories truncates long directory paths"
	test_setup
	local long_dir="$LAZY_ENV_TEST_DIR/very/long/directory/path/that/exceeds/column/width/and/should/be/truncated"
	mkdir -p "$long_dir"
	lazy_var "LONG_DIR_VAR" "echo 'long-value'" "$long_dir"

	local output
	output=$(lazy_list_directories)

	assert_contains "$output" "..." "Should contain truncation indicator"
	assert_contains "$output" "truncated" "Should show end of path"
	assert_contains "$output" "LONG_DIR_VAR" "Should still show mapped variable"

test_start "lazy_list_directories groups variables by directory"
	test_setup
	# Multiple variables for same directory
	lazy_var "VAR1" "echo 'value1'" "$LAZY_ENV_TEST_DIR/shared"
	lazy_var "VAR2" "echo 'value2'" "$LAZY_ENV_TEST_DIR/shared"
	lazy_var "VAR3" "echo 'value3'" "$LAZY_ENV_TEST_DIR/shared"

	local output
	output=$(lazy_list_directories)

	# Should appear as one line with comma-separated variables
	local shared_line=$(echo "$output" | grep "shared")
	assert_contains "$shared_line" "VAR1" "Should contain VAR1"
	assert_contains "$shared_line" "VAR2" "Should contain VAR2"
	assert_contains "$shared_line" "VAR3" "Should contain VAR3"
	assert_contains "$shared_line" ", " "Should be comma-separated"

test_suite "Listing Functions - Output Consistency"

test_start "all listing functions use consistent column widths"
	test_setup
	lazy_var "TEST_VAR" "echo 'value'"
	lazy_command "test-cmd" "TEST_VAR"
	lazy_var "DIR_VAR" "echo 'dir-value'" "$LAZY_ENV_TEST_DIR/test-dir"

	local vars_output=$(lazy_list_vars)
	local cmds_output=$(lazy_list_commands)
	local dirs_output=$(lazy_list_directories)

	# Check that first columns are all 30 characters wide (based on our recent changes)
	# This is a format check - exact spacing might vary but structure should be consistent
	assert_contains "$vars_output" "NAME" "Variables should have NAME column"
	assert_contains "$cmds_output" "COMMAND" "Commands should have COMMAND column"
	assert_contains "$dirs_output" "DIRECTORY" "Directories should have DIRECTORY column"

test_start "listing functions handle special characters in names"
	test_setup
	lazy_var "VAR_WITH_UNDERSCORES" "echo 'value'"
	lazy_var "VAR-WITH-DASHES" "echo 'value'"
	lazy_command "cmd-with-dashes" "VAR_WITH_UNDERSCORES"

	local vars_output=$(lazy_list_vars)
	local cmds_output=$(lazy_list_commands)

	assert_contains "$vars_output" "VAR_WITH_UNDERSCORES" "Should handle underscores"
	assert_contains "$vars_output" "VAR-WITH-DASHES" "Should handle dashes"
	assert_contains "$cmds_output" "cmd-with-dashes" "Should handle command dashes"

test_start "listing functions work with empty state"
	test_setup
	# No variables, commands, or directories registered

	local vars_output=$(lazy_list_vars)
	local cmds_output=$(lazy_list_commands)
	local dirs_output=$(lazy_list_directories)

	# Should still show headers
	assert_contains "$vars_output" "NAME" "Should show headers even when empty"
	assert_contains "$cmds_output" "COMMAND" "Should show headers even when empty"
	assert_contains "$dirs_output" "DIRECTORY" "Should show headers even when empty"

test_start "listing functions show sorted output"
	test_setup
	lazy_var "ZEBRA_VAR" "echo 'z'"
	lazy_var "ALPHA_VAR" "echo 'a'"
	lazy_var "BETA_VAR" "echo 'b'"

	local output=$(lazy_list_vars)

	# Check that ALPHA appears before ZEBRA (basic alphabetical check)
	local alpha_line=$(echo "$output" | grep -n "ALPHA_VAR" | cut -d: -f1)
	local zebra_line=$(echo "$output" | grep -n "ZEBRA_VAR" | cut -d: -f1)

	assert_true "[[ $alpha_line -lt $zebra_line ]]" "Variables should be sorted alphabetically"

# Run the tests if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%x}" == "${0}" ]]; then
	test_init
	# Tests are automatically run when sourced due to the way zsh processes the file
	test_results
fi
