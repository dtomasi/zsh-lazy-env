#!/usr/bin/env zsh
# lazy-env.plugin.zsh - Lazy loading of environment variables for secrets
#
# This plugin allows you to register environment variables that are only loaded
# when they are first accessed in a command or when entering specific directories.
# Perfect for secrets and API keys that should only be loaded when needed.

# Global arrays to store lazy and loaded variables
typeset -gA LAZY_VARS
typeset -gA LOADED_VARS

# Command mapping arrays for automatic loading
typeset -gA COMMAND_VARS
typeset -gA PATTERN_VARS
typeset -ga PATTERN_KEYS

# Directory mapping arrays for automatic loading on directory change
typeset -gA DIRECTORY_VARS
typeset -gA DIR_PATTERN_VARS
typeset -ga DIR_PATTERN_KEYS

# Directory-scoped variable definitions (overrides for specific directories)
typeset -gA DIR_SCOPED_VARS       # [directory:variable] = command
typeset -gA DIR_PATTERN_SCOPED_VARS # [pattern:variable] = command
typeset -ga DIR_SCOPED_PATTERN_KEYS

# Function to register a lazy-loaded environment variable
#
# Usage: lazy_var VARIABLE_NAME "command to load value" [path_or_pattern]
#
# Arguments:
#   $1 - Variable name (should be uppercase)
#   $2 - Command to execute to get the variable value
#   $3 - Optional path or pattern:
#        - If omitted: global variable (default)
#        - If starts with "/": exact directory path
#        - If starts with "pattern:": regex pattern for directory matching
#
# Examples:
#   lazy_var "API_KEY" "op read op://vault/api-key/password"                    # Global
#   lazy_var "API_KEY" "op read op://project/api/password" "/path/to/project"   # Directory-specific
#   lazy_var "API_KEY" "op read op://pattern/api/password" "pattern:.*/work/.*" # Pattern-based
lazy_var() {
	local var_name="$1"
	local load_command="$2"
	local path_or_pattern="$3"

	if [[ -z "$var_name" ]] || [[ -z "$load_command" ]]; then
		echo "Usage: lazy_var VARIABLE_NAME \"load command\" [path_or_pattern]" >&2
		echo "Examples:" >&2
		echo "  lazy_var \"API_KEY\" \"op read op://vault/api-key/password\"                    # Global" >&2
		echo "  lazy_var \"API_KEY\" \"op read op://project/api/password\" \"/path/to/project\"   # Directory-specific" >&2
		echo "  lazy_var \"API_KEY\" \"op read op://pattern/api/password\" \"pattern:.*/work/.*\" # Pattern-based" >&2
		return 1
	fi

	# Validate variable name (should be uppercase and valid shell variable name)
	if [[ ! "$var_name" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
		echo "Error: Variable name '$var_name' should be uppercase and a valid shell variable name" >&2
		return 1
	fi

	# Determine the type of registration based on the third parameter
	if [[ -z "$path_or_pattern" ]]; then
		# Global variable (original behavior)
		LAZY_VARS[$var_name]="$load_command"
	elif [[ "$path_or_pattern" =~ ^pattern: ]]; then
		# Pattern-based directory override
		local pattern="${path_or_pattern#pattern:}"
		DIR_PATTERN_SCOPED_VARS["${pattern}:${var_name}"]="$load_command"
		DIR_SCOPED_PATTERN_KEYS+=("$pattern")
	else
		# Exact directory override
		# Expand tilde if present
		local directory="${path_or_pattern/#\~/$HOME}"
		DIR_SCOPED_VARS["${directory}:${var_name}"]="$load_command"
	fi
}

# Function to register a command that should trigger variable loading
#
# Usage: lazy_command "command" "VARIABLE1,VARIABLE2"
#
# Arguments:
#   $1 - Command or subcommand (e.g., "gh", "docker push", "terraform plan")
#   $2 - Comma-separated list of variables to load
#
# Examples:
#   lazy_command "gh" "GITHUB_TOKEN"
#   lazy_command "docker push" "DOCKER_HUB_TOKEN"
#   lazy_command "terraform" "GITLAB_TOKEN,TF_VAR_gitlab_token"
lazy_command() {
	local command="$1"
	local variables="$2"

	if [[ -z "$command" ]] || [[ -z "$variables" ]]; then
		echo "Usage: lazy_command \"command\" \"VARIABLE1,VARIABLE2\"" >&2
		return 1
	fi

	COMMAND_VARS[$command]="$variables"
}

# Function to register a regex pattern that should trigger variable loading
#
# Usage: lazy_command_pattern "regex_pattern" "VARIABLE1,VARIABLE2"
#
# Arguments:
#   $1 - Regex pattern to match against full command
#   $2 - Comma-separated list of variables to load
#
# Examples:
#   lazy_command_pattern "^git (push|pull|clone)" "GITHUB_TOKEN"
#   lazy_command_pattern "^docker (push|pull|login).*" "DOCKER_HUB_TOKEN"
lazy_command_pattern() {
	local pattern="$1"
	local variables="$2"

	if [[ -z "$pattern" ]] || [[ -z "$variables" ]]; then
		echo "Usage: lazy_command_pattern \"regex_pattern\" \"VARIABLE1,VARIABLE2\"" >&2
		return 1
	fi

	PATTERN_VARS[$pattern]="$variables"
	PATTERN_KEYS+=("$pattern")
}

# Function to register a directory that should trigger variable loading
#
# Usage: lazy_directory "directory_path" "VARIABLE1,VARIABLE2"
#
# Arguments:
#   $1 - Directory path (exact match, can use ~ for home directory)
#   $2 - Comma-separated list of variables to load
#
# Examples:
#   lazy_directory "~/work/project1" "PROJECT1_API_KEY,PROJECT1_SECRET"
#   lazy_directory "$HOME/work/client-xyz" "CLIENT_XYZ_TOKEN"
lazy_directory() {
	local directory="$1"
	local variables="$2"

	if [[ -z "$directory" ]] || [[ -z "$variables" ]]; then
		echo "Usage: lazy_directory \"directory_path\" \"VARIABLE1,VARIABLE2\"" >&2
		return 1
	fi

	# Expand tilde if present
	directory="${directory/#\~/$HOME}"

	DIRECTORY_VARS[$directory]="$variables"
}

# Function to register a directory pattern that should trigger variable loading
#
# Usage: lazy_directory_pattern "regex_pattern" "VARIABLE1,VARIABLE2"
#
# Arguments:
#   $1 - Regex pattern to match against current directory path
#   $2 - Comma-separated list of variables to load
#
# Examples:
#   lazy_directory_pattern ".*/terraform/.*" "TF_VAR_gitlab_token,AWS_ACCESS_KEY"
#   lazy_directory_pattern ".*/k8s/.*" "KUBECONFIG_SECRET"
#   lazy_directory_pattern ".*/project-(dev|staging|prod)" "DEPLOY_KEY"
lazy_directory_pattern() {
	local pattern="$1"
	local variables="$2"

	if [[ -z "$pattern" ]] || [[ -z "$variables" ]]; then
		echo "Usage: lazy_directory_pattern \"regex_pattern\" \"VARIABLE1,VARIABLE2\"" >&2
		return 1
	fi

	DIR_PATTERN_VARS[$pattern]="$variables"
	DIR_PATTERN_KEYS+=("$pattern")
}





# Function to manually load a lazy variable
#
# Usage: lazy_load VARIABLE_NAME [directory_path]
#
# This can be useful if you want to preload a variable or force reload it.
# The optional directory_path allows testing what would be loaded in a different directory.
lazy_load() {
	local var_name="$1"
	local target_dir="${2:-$PWD}"

	if [[ -z "$var_name" ]]; then
		echo "Usage: lazy_load VARIABLE_NAME [directory_path]" >&2
		return 1
	fi

	# Check if we have any definition for this variable (global or directory-scoped)
	local load_cmd
	load_cmd="$(_get_load_command_for_variable "$var_name" "$target_dir")"
	local get_cmd_exit_code=$?

	if [[ $get_cmd_exit_code -ne 0 ]]; then
		echo "Error: No lazy variable registered with name '$var_name' (checked global and directory-scoped)" >&2
		return 1
	fi

	# Allow reloading even if previously loaded
	_lazy_load_variable "$var_name" "$target_dir"
}

# Function to list all registered lazy variables (unified view)
# Helper function to get variable status
_get_var_status() {
	local var_name="$1"
	if [[ -n "${LOADED_VARS[$var_name]}" ]]; then
		case "${LOADED_VARS[$var_name]}" in
			"success") echo "loaded" ;;
			"failed") echo "failed" ;;
			*) echo "pending" ;;
		esac
	else
		echo "pending"
	fi
}

lazy_list_vars() {
	# Simple 3-column output: name, status, directory
	printf "%-30s %-10s %s\n" "NAME" "STATUS" "DIRECTORY"
	printf "%-30s %-10s %s\n" "----" "------" "---------"

	# Show global variables
	local sorted_vars=(${(ok)LAZY_VARS})
	for var_name in $sorted_vars; do
		local var_status=$(_get_var_status "$var_name")
		printf "%-30s %-10s %s\n" "$var_name" "$var_status" "global"
	done

	# Show directory-scoped variables
	for key in ${(k)DIR_SCOPED_VARS}; do
		local dir_part="${key%:*}"
		local var_part="${key#*:}"
		# Remove surrounding quotes if present
		dir_part="${dir_part#\"}"
		dir_part="${dir_part%\"}"
		var_part="${var_part#\"}"
		var_part="${var_part%\"}"
		local var_status=$(_get_var_status "$var_part")
		printf "%-30s %-10s %s\n" "$var_part" "$var_status" "$dir_part"
	done

	# Show pattern-scoped variables
	for key in ${(k)DIR_PATTERN_SCOPED_VARS}; do
		local pattern_part="${key%:*}"
		local var_part="${key#*:}"
		# Remove surrounding quotes if present
		pattern_part="${pattern_part#\"}"
		pattern_part="${pattern_part%\"}"
		var_part="${var_part#\"}"
		var_part="${var_part%\"}"
		local var_status=$(_get_var_status "$var_part")
		printf "%-30s %-10s %s\n" "$var_part" "$var_status" "pattern:$pattern_part"
	done
}

lazy_list_commands() {
	# Simple 3-column output: command, type, variables
	printf "%-30s %-10s %s\n" "COMMAND" "TYPE" "VARIABLES"
	printf "%-30s %-10s %s\n" "-------" "----" "---------"

	# Show exact command mappings
	for command in ${(ok)COMMAND_VARS}; do
		local variables="${COMMAND_VARS[$command]}"
		printf "%-30s %-10s %s\n" "$command" "exact" "$variables"
	done

	# Show pattern command mappings
	for pattern in ${(ok)PATTERN_VARS}; do
		local variables="${PATTERN_VARS[$pattern]}"
		# Truncate long patterns to fit in column
		local display_pattern="$pattern"
		if [[ ${#display_pattern} -gt 28 ]]; then
			display_pattern="${display_pattern:0:25}..."
		fi
		printf "%-30s %-10s %s\n" "$display_pattern" "pattern" "$variables"
	done
}

lazy_list_directories() {
	# Simple 3-column output: directory, type, variables
	printf "%-30s %-10s %s\n" "DIRECTORY" "TYPE" "VARIABLES"
	printf "%-30s %-10s %s\n" "---------" "----" "---------"

	# Show exact directory mappings from DIR_SCOPED_VARS
	# Group by directory from the "directory:variable" keys
	local -A dir_variables
	for key in ${(k)DIR_SCOPED_VARS}; do
		local dir_part="${key%:*}"
		local var_part="${key#*:}"
		# Remove surrounding quotes if present
		dir_part="${dir_part#\"}"
		dir_part="${dir_part%\"}"
		var_part="${var_part#\"}"
		var_part="${var_part%\"}"
		if [[ -z "${dir_variables[$dir_part]}" ]]; then
			dir_variables[$dir_part]="$var_part"
		else
			dir_variables[$dir_part]="${dir_variables[$dir_part]}, $var_part"
		fi
	done

	# Show grouped directories
	for dir in ${(ok)dir_variables}; do
		local variables="${dir_variables[$dir]}"
		# Truncate long directory paths to fit in column
		local display_dir="$dir"
		if [[ ${#display_dir} -gt 28 ]]; then
			display_dir="...${display_dir: -25}"
		fi
		printf "%-30s %-10s %s\n" "$display_dir" "exact" "$variables"
	done

	# Show pattern directory mappings
	for pattern in ${(ok)DIR_PATTERN_VARS}; do
		local variables="${DIR_PATTERN_VARS[$pattern]}"
		# Truncate long patterns to fit in column
		local display_pattern="$pattern"
		if [[ ${#display_pattern} -gt 28 ]]; then
			display_pattern="${display_pattern:0:25}..."
		fi
		printf "%-30s %-10s %s\n" "$display_pattern" "pattern" "$variables"
	done
}









# Function to test command detection (useful for debugging)
lazy_test_command() {
	local test_cmd="$1"

	if [[ -z "$test_cmd" ]]; then
		echo "Usage: lazy_test_command \"command to test\"" >&2
		echo "Example: lazy_test_command \"gh repo list\"" >&2
		return 1
	fi

	echo "Testing command detection for: $test_cmd"
	echo

	# Show what would be loaded
	local variables_to_load=()

	# Check for variable references
	echo "Variable references found:"
	for var_name in ${(k)LAZY_VARS}; do
		if [[ "$test_cmd" == *"\$${var_name}"* ]]; then
			echo "  \$${var_name} → would load $var_name"
			variables_to_load+=("$var_name")
		fi
	done
	if [[ ${#variables_to_load} -eq 0 ]]; then
		echo "  None"
	fi
	echo

	# Parse command to handle prefixed environment variables and pipes
	local clean_cmd="$test_cmd"
	clean_cmd=$(echo "$clean_cmd" | sed -E 's/^([A-Z_][A-Z0-9_]*=[^[:space:]]*[[:space:]]+)+//')

	if [[ "$clean_cmd" != "$test_cmd" ]]; then
		echo "Cleaned command (removed env prefixes): $clean_cmd"
		echo
	fi

	# Check each part of piped commands
	local cmd_parts=(${(@s:|:)clean_cmd})
	local part_num=1

	for part in $cmd_parts; do
		part=$(echo "$part" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
		local first_word="${part%% *}"
		local first_two_words="${part%% *} ${${part#* }%% *}"

		if [[ ${#cmd_parts} -gt 1 ]]; then
			echo "Pipe part $part_num: $part"
		fi

		# Check exact command matches
		if [[ -n "${COMMAND_VARS[$first_word]}" ]]; then
			echo "Exact command match: '$first_word'"
			echo "  Would load: ${COMMAND_VARS[$first_word]}"
			local cmd_vars="${COMMAND_VARS[$first_word]}"
			local var_list=(${(@s:,:)cmd_vars})
			variables_to_load+=($var_list)
		fi

		# Check subcommand matches
		if [[ -n "${COMMAND_VARS[$first_two_words]}" ]]; then
			echo "Subcommand match: '$first_two_words'"
			echo "  Would load: ${COMMAND_VARS[$first_two_words]}"
			local cmd_vars="${COMMAND_VARS[$first_two_words]}"
			local var_list=(${(@s:,:)cmd_vars})
			variables_to_load+=($var_list)
		fi

		# Check pattern matches
		local pattern_matched=false
		for pattern in $PATTERN_KEYS; do
			if [[ "$part" =~ $pattern ]]; then
				if [[ "$pattern_matched" == "false" ]]; then
					echo "Pattern matches:"
					pattern_matched=true
				fi
				echo "  /$pattern/ → ${PATTERN_VARS[$pattern]}"
				local pattern_vars="${PATTERN_VARS[$pattern]}"
				local var_list=(${(@s:,:)pattern_vars})
				variables_to_load+=($var_list)
			fi
		done

		if [[ ${#cmd_parts} -gt 1 ]]; then
			echo
		fi

		((part_num++))
	done

	if [[ ${#cmd_parts} -eq 1 ]] && [[ "$pattern_matched" == "false" ]]; then
		echo "Pattern matches: None"
	fi
	echo

	# Show summary
	if [[ ${#variables_to_load} -gt 0 ]]; then
		local unique_vars=($(printf '%s\n' "${variables_to_load[@]}" | sort -u))
		echo "Summary: Would load ${#unique_vars} variable(s): ${(j:, :)unique_vars}"
	else
		echo "Summary: No variables would be loaded"
	fi
}

# Function to test directory detection (useful for debugging)
lazy_test_directory() {
	local test_dir="$1"

	if [[ -z "$test_dir" ]]; then
		echo "Usage: lazy_test_directory \"directory_path\"" >&2
		echo "Example: lazy_test_directory \"$HOME/work/project1\"" >&2
		return 1
	fi

	# Expand tilde if present
	test_dir="${test_dir/#\~/$HOME}"

	echo "Testing directory detection for: $test_dir"
	echo

	# Show what would be loaded
	local variables_to_load=()

	# Check exact directory matches
	echo "Exact directory matches:"
	if [[ -n "${DIRECTORY_VARS[$test_dir]}" ]]; then
		echo "  '$test_dir' → ${DIRECTORY_VARS[$test_dir]}"
		local dir_vars="${DIRECTORY_VARS[$test_dir]}"
		local var_list=(${(@s:,:)dir_vars})
		variables_to_load+=($var_list)
	else
		echo "  None"
	fi
	echo

	# Check pattern matches
	echo "Pattern matches:"
	local pattern_matched=false
	for pattern in $DIR_PATTERN_KEYS; do
		if [[ "$test_dir" =~ $pattern ]]; then
			if [[ "$pattern_matched" == "false" ]]; then
				pattern_matched=true
			fi
			echo "  /$pattern/ → ${DIR_PATTERN_VARS[$pattern]}"
			local pattern_vars="${DIR_PATTERN_VARS[$pattern]}"
			local var_list=(${(@s:,:)pattern_vars})
			variables_to_load+=($var_list)
		fi
	done

	if [[ "$pattern_matched" == "false" ]]; then
		echo "  None"
	fi
	echo

	# Show summary
	if [[ ${#variables_to_load} -gt 0 ]]; then
		local unique_vars=($(printf '%s\n' "${variables_to_load[@]}" | sort -u))
		echo "Summary: Would load ${#unique_vars} variable(s): ${(j:, :)unique_vars}"
	else
		echo "Summary: No variables would be loaded"
	fi
}

# Function to unregister a lazy variable
lazy_unregister() {
	local var_name="$1"

	if [[ -z "$var_name" ]]; then
		echo "Usage: lazy_unregister VARIABLE_NAME" >&2
		return 1
	fi

	unset "LAZY_VARS[$var_name]"
	unset "LOADED_VARS[$var_name]"
	unset "$var_name"

	echo "Unregistered lazy variable: $var_name" >&2
}

# Internal function to get the appropriate load command for a variable
# Takes into account directory-scoped overrides with proper priority
_get_load_command_for_variable() {
	local var_name="$1"
	local current_dir="${2:-$PWD}"

	# Priority 1: Exact directory match
	local exact_key="${current_dir}:${var_name}"

	# Try direct lookup first
	if [[ -n "${DIR_SCOPED_VARS[$exact_key]}" ]]; then
		echo "${DIR_SCOPED_VARS[$exact_key]}"
		return 0
	fi

	# If direct lookup fails, try with quoted key
	local quoted_key="\"${exact_key}\""
	if [[ -n "${DIR_SCOPED_VARS[$quoted_key]}" ]]; then
		echo "${DIR_SCOPED_VARS[$quoted_key]}"
		return 0
	fi

	# Also try iterating through all keys to handle any quoting variations
	for key in ${(k)DIR_SCOPED_VARS}; do
		local clean_key="${key//\"/}"
		if [[ "$clean_key" == "$exact_key" ]]; then
			echo "${DIR_SCOPED_VARS[$key]}"
			return 0
		fi
	done

	# Priority 2: Directory pattern match (first match wins)
	for key in ${(k)DIR_PATTERN_SCOPED_VARS}; do
		# Remove quotes from key if present
		local clean_key="${key//\"/}"
		local pattern_part="${clean_key%:*}"
		local var_part="${clean_key#*:}"

		if [[ "$var_part" == "$var_name" ]] && [[ "$current_dir" =~ $pattern_part ]]; then
			echo "${DIR_PATTERN_SCOPED_VARS[$key]}"
			return 0
		fi
	done

	# Priority 3: Global definition
	if [[ -n "${LAZY_VARS[$var_name]}" ]]; then
		echo "${LAZY_VARS[$var_name]}"
		return 0
	fi

	# No definition found
	return 1
}

# Internal function to actually load a variable
_lazy_load_variable() {
	local var_name="$1"
	local current_dir="${2:-$PWD}"

	# Get the appropriate load command based on directory context
	local load_cmd
	load_cmd="$(_get_load_command_for_variable "$var_name" "$current_dir")"
	local get_cmd_exit_code=$?

	if [[ $get_cmd_exit_code -ne 0 ]]; then
		echo "❌ No load command found for variable $var_name" >&2
		LOADED_VARS[$var_name]="failed"
		return 1
	fi

	# Execute the load command and capture both output and exit code
	local value
	local exit_code
	value="$(eval "$load_cmd" 2>/dev/null)"
	exit_code=$?

	if [[ $exit_code -eq 0 ]] && [[ -n "$value" ]]; then
		# Successfully loaded
		export $var_name="$value"
		LOADED_VARS[$var_name]="success"

		# Special handling for GITLAB_TOKEN to set terraform variables
		if [[ "$var_name" == "GITLAB_TOKEN" ]]; then
			export TF_VAR_gitlab_token="$value"
		fi
	else
		# Failed to load
		LOADED_VARS[$var_name]="failed"
		echo "❌ Failed to load $var_name (exit code: $exit_code)" >&2
		return $exit_code
	fi
}

# chpwd hook function to detect and load lazy variables on directory change
_lazy_env_chpwd() {
	local current_dir="$PWD"
	local variables_to_load=()

	# 1. Check directory-triggered variable loading (existing functionality)
	# Check exact directory matches
	if [[ -n "${DIRECTORY_VARS[$current_dir]}" ]]; then
		local dir_vars="${DIRECTORY_VARS[$current_dir]}"
		local var_list=(${(@s:,:)dir_vars})
		for var in $var_list; do
			if [[ "${LOADED_VARS[$var]}" != "success" ]] && [[ -n "$(_get_load_command_for_variable "$var" "$current_dir")" ]]; then
				variables_to_load+=("$var")
			fi
		done
	fi

	# Check pattern matches for directory-triggered loading
	for pattern in $DIR_PATTERN_KEYS; do
		if [[ "$current_dir" =~ $pattern ]]; then
			local pattern_vars="${DIR_PATTERN_VARS[$pattern]}"
			local var_list=(${(@s:,:)pattern_vars})
			for var in $var_list; do
				if [[ "${LOADED_VARS[$var]}" != "success" ]] && [[ -n "$(_get_load_command_for_variable "$var" "$current_dir")" ]]; then
					variables_to_load+=("$var")
				fi
			done
		fi
	done

	# 2. Check for directory-scoped variable overrides that need reloading
	# Check all currently loaded variables to see if they have directory-specific overrides
	for var_name in ${(k)LOADED_VARS}; do
		if [[ "${LOADED_VARS[$var_name]}" == "success" ]]; then
			# Get the command that would be used in this directory
			local new_cmd="$(_get_load_command_for_variable "$var_name" "$current_dir" 2>/dev/null)"

			# If there's a different command available, we need to reload
			if [[ -n "$new_cmd" ]]; then
				# Check if this is a directory-scoped override (not global)
				local exact_key="${current_dir}:${var_name}"
				local has_dir_override=false

				# Check exact directory override
				local found_exact=false

				# Try direct lookup
				if [[ -n "${DIR_SCOPED_VARS[$exact_key]}" ]]; then
					found_exact=true
				fi

				# Try with quoted key
				if [[ "$found_exact" == "false" ]]; then
					local quoted_key="\"${exact_key}\""
					if [[ -n "${DIR_SCOPED_VARS[$quoted_key]}" ]]; then
						found_exact=true
					fi
				fi

				# Try iterating through all keys
				if [[ "$found_exact" == "false" ]]; then
					for key in ${(k)DIR_SCOPED_VARS}; do
						local clean_key="${key//\"/}"
						if [[ "$clean_key" == "$exact_key" ]]; then
							found_exact=true
							break
						fi
					done
				fi

				if [[ "$found_exact" == "true" ]]; then
					has_dir_override=true
				else
					# Check pattern override
					for pattern in $DIR_SCOPED_PATTERN_KEYS; do
						if [[ "$current_dir" =~ $pattern ]]; then
							# Try multiple key formats for pattern matching
							for key in ${(k)DIR_PATTERN_SCOPED_VARS}; do
								local clean_key="${key//\"/}"
								local pattern_part="${clean_key%:*}"
								local var_part="${clean_key#*:}"

								if [[ "$pattern_part" == "$pattern" ]] && [[ "$var_part" == "$var_name" ]]; then
									has_dir_override=true
									break 2  # Break out of both loops
								fi
							done
						fi
					done
				fi

				# If we have a directory override, reload the variable
				if [[ "$has_dir_override" == "true" ]]; then
					variables_to_load+=("$var_name")
				fi
			fi
		fi
	done

	# Load all variables (remove duplicates first)
	local unique_vars=($(printf '%s\n' "${variables_to_load[@]}" | sort -u))
	for var_name in $unique_vars; do
		_lazy_load_variable "$var_name" "$current_dir"
	done
}

# preexec hook function to detect and load lazy variables
_lazy_env_preexec() {
	local cmd="$1"
	local current_dir="$PWD"
	local variables_to_load=()

	# 1. Check each registered lazy variable to see if it appears in the command
	for var_name in ${(k)LAZY_VARS}; do
		# Check if this variable is referenced in the command and not yet successfully loaded
		if [[ "$cmd" == *"\$${var_name}"* ]] && [[ "${LOADED_VARS[$var_name]}" != "success" ]]; then
			variables_to_load+=("$var_name")
		fi
	done

	# Also check directory-scoped variables
	for key in ${(k)DIR_SCOPED_VARS}; do
		local var_name="${key#*:}"
		if [[ "$cmd" == *"\$${var_name}"* ]] && [[ "${LOADED_VARS[$var_name]}" != "success" ]]; then
			variables_to_load+=("$var_name")
		fi
	done

	for key in ${(k)DIR_PATTERN_SCOPED_VARS}; do
		local var_name="${key#*:}"
		if [[ "$cmd" == *"\$${var_name}"* ]] && [[ "${LOADED_VARS[$var_name]}" != "success" ]]; then
			variables_to_load+=("$var_name")
		fi
	done

	# 2. Parse command to handle prefixed environment variables and pipes
	local clean_cmd="$cmd"

	# Remove environment variable prefixes (FOO=bar BAZ=qux command -> command)
	# This regex removes VAR=value patterns from the beginning
	clean_cmd=$(echo "$clean_cmd" | sed -E 's/^([A-Z_][A-Z0-9_]*=[^[:space:]]*[[:space:]]+)+//')

	# For piped commands, check each part of the pipe
	local cmd_parts=(${(@s:|:)clean_cmd})
	for part in $cmd_parts; do
		# Trim whitespace and get first word
		part=$(echo "$part" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
		local first_word="${part%% *}"
		local first_two_words="${part%% *} ${${part#* }%% *}"

		# Check exact command matches
		if [[ -n "${COMMAND_VARS[$first_word]}" ]]; then
			local cmd_vars="${COMMAND_VARS[$first_word]}"
			local var_list=(${(@s:,:)cmd_vars})
			for var in $var_list; do
				if [[ "${LOADED_VARS[$var]}" != "success" ]] && [[ -n "$(_get_load_command_for_variable "$var" "$current_dir" 2>/dev/null)" ]]; then
					variables_to_load+=("$var")
				fi
			done
		fi

		# Check subcommand matches (e.g., "docker push")
		if [[ -n "${COMMAND_VARS[$first_two_words]}" ]]; then
			local cmd_vars="${COMMAND_VARS[$first_two_words]}"
			local var_list=(${(@s:,:)cmd_vars})
			for var in $var_list; do
				if [[ "${LOADED_VARS[$var]}" != "success" ]] && [[ -n "$(_get_load_command_for_variable "$var" "$current_dir" 2>/dev/null)" ]]; then
					variables_to_load+=("$var")
				fi
			done
		fi

		# Check regex patterns against the full part
		for pattern in $PATTERN_KEYS; do
			if [[ "$part" =~ $pattern ]]; then
				local pattern_vars="${PATTERN_VARS[$pattern]}"
				local var_list=(${(@s:,:)pattern_vars})
				for var in $var_list; do
					if [[ "${LOADED_VARS[$var]}" != "success" ]] && [[ -n "$(_get_load_command_for_variable "$var" "$current_dir" 2>/dev/null)" ]]; then
						variables_to_load+=("$var")
					fi
				done
			fi
		done
	done

	# 3. Load all variables (remove duplicates first)
	local unique_vars=($(printf '%s\n' "${variables_to_load[@]}" | sort -u))
	for var_name in $unique_vars; do
		_lazy_load_variable "$var_name" "$current_dir"
	done
}

# Function to manually test variable loading (useful for testing/debugging)
lazy_test_var() {
	local var_name="$1"
	local test_dir="${2:-$PWD}"

	if [[ -z "$var_name" ]]; then
		echo "Usage: lazy_test_var VARIABLE_NAME [directory_path]" >&2
		return 1
	fi

	echo "Testing lazy variable: $var_name"
	echo "Directory context: $test_dir"
	echo "Command simulation: echo \$${var_name}"

	# Save current directory
	local old_pwd="$PWD"

	# Change to test directory if specified
	if [[ "$test_dir" != "$PWD" ]]; then
		cd "$test_dir" 2>/dev/null || {
			echo "Error: Cannot access directory: $test_dir" >&2
			return 1
		}
	fi

	# Simulate preexec hook
	_lazy_env_preexec "echo \$${var_name}"

	# Show the result
	echo "Variable value: ${(P)var_name}"

	# Restore directory
	cd "$old_pwd"
}

# Load environment configuration files using glob patterns
# Usage: lazy_load_configs <pattern> [pattern2] ...
#
# Load configuration files matching the given glob patterns
# Each file should contain lazy_var registrations
#
# Examples:
#   lazy_load_configs "$HOME/.config/env/**/*.sh"
#   lazy_load_configs "$HOME/.config/env/global/*.sh" "$HOME/.config/env/prod/*.sh"
#   lazy_load_configs ~/.config/env/{global,prod}/*.sh
lazy_load_configs() {
	if [[ $# -eq 0 ]]; then
		echo "Usage: lazy_load_configs <glob_pattern> [pattern2] ..." >&2
		echo "Example: lazy_load_configs ~/.config/env/**/*.sh" >&2
		return 1
	fi

	local loaded_count=0

	# Process each pattern
	for pattern in "$@"; do
		# Expand glob pattern
		# shellcheck disable=SC2086,SC2035
		for config_file in ${~pattern}(N); do
			if [[ -r "$config_file" && -f "$config_file" ]]; then
				source "$config_file"
				((loaded_count++))
			fi
		done
	done

	if [[ $loaded_count -eq 0 ]]; then
		echo "Warning: No configuration files found matching patterns: $@" >&2
		return 1
	fi

	return 0
}

# Add our preexec and chpwd hooks
autoload -U add-zsh-hook
add-zsh-hook preexec _lazy_env_preexec
add-zsh-hook chpwd _lazy_env_chpwd

# Completion for lazy_var function
_lazy_var_completion() {
	_arguments \
		'1:variable name:()' \
		'2:load command:_command_names'
}

# Completion for load_lazy_var and unregister_lazy_var
_lazy_var_list_completion() {
	local lazy_vars=(${(k)LAZY_VARS})
	_describe 'lazy variables' lazy_vars
}

# Completion for lazy_test_directory
_lazy_test_directory_completion() {
	_arguments '1:directory path:_directories'
}






# Register completions (only if completion system is available)
if [[ -n "$_comps" ]]; then
	compdef _lazy_var_completion lazy_var
	compdef _lazy_var_list_completion lazy_load
	compdef _lazy_var_list_completion lazy_unregister
	compdef _lazy_var_list_completion lazy_test_var

	# Completion for lazy_test_command
	_lazy_test_command_completion() {
		_arguments '1:command to test:_command_names'
	}
	compdef _lazy_test_command_completion lazy_test_command

	# Completion for lazy_test_directory
	compdef _lazy_test_directory_completion lazy_test_directory

	# Completions for directory-scoped functions
fi
