# File Pattern Support Concept

## Overview

This document describes the concept and architecture for file-based variable loading in zsh-lazy-env. The goal is to enable automatic variable detection and loading from build files (Makefiles, justfiles, shell scripts, etc.) through a flexible, registrable pattern system.

## Core Concept

Instead of hardcoding support for specific build tools, we implement a generic pattern registration system that allows:

1. **File Pattern Registration**: Define regex patterns for detecting variables in specific file types
2. **Preset Definition**: Group related files into logical presets (e.g., "make" preset includes both "Makefile" and "makefile")
3. **Generic Execution**: Use a single `lazy-file` command that works with any registered preset
4. **User Extension**: Allow users to register their own patterns and presets

## Architecture

### Data Structures

The system uses two main associative arrays:

```bash
# Maps filename to variable detection regex
typeset -gA LAZY_FILE_PATTERNS
# Example: LAZY_FILE_PATTERNS["Makefile"] = '\$\([A-Z_][A-Z0-9_]*\)|\$\{[A-Z_][A-Z0-9_]*\}'

# Maps preset name to space-separated list of filenames
typeset -gA LAZY_PATTERN_PRESETS  
# Example: LAZY_PATTERN_PRESETS["make"] = "Makefile makefile"
```

### Registration Function

#### File Loader Registration
```bash
lazy_file_loader() {
    local preset_name="$1"    # e.g., "make", "just", "docker"
    local var_regex="$2"      # Regex for finding variables
    shift 2
    local filenames=("$@")    # Rest arguments: all relevant files
    
    # Store regex for each file
    for filename in $filenames; do
        LAZY_FILE_PATTERNS["$filename"]="$var_regex"
    done
    
    # Store preset mapping
    LAZY_PATTERN_PRESETS["$preset_name"]="${filenames[*]}"
}
```

### Generic Execution Command

```bash
lazy-file() {
    local preset_name="$1"
    # ... validate preset exists
    # ... detect variables from files in preset
    # ... load detected variables
    # ... execute original command
}
```

## Default Patterns and Presets

### Built-in File Patterns

The plugin will register these patterns by default:

```bash
# Make support (both Makefile and makefile)
lazy_file_loader "make" '\$\([A-Z_][A-Z0-9_]*\)|\$\{[A-Z_][A-Z0-9_]*\}' "Makefile" "makefile"

# Just support (both justfile and Justfile)
lazy_file_loader "just" '\$[A-Z_][A-Z0-9_]*|\$\{[A-Z_][A-Z0-9_]*\}|\{\{[A-Z_][A-Z0-9_]*\}\}' "justfile" "Justfile"

# Shell script support
lazy_file_loader "shell" '\$[A-Z_][A-Z0-9_]*|\$\{[A-Z_][A-Z0-9_]*\}' "*.sh" "*.bash"
```

## Usage Patterns

### Manual Usage

```bash
# Load variables from make files and execute make command
lazy-file make -- make deploy

# Load variables from just files and execute just command
lazy-file just -- just test
```

### Transparent Integration via Aliases

Users can add aliases to their `~/.zshrc` for transparent integration:

```bash
# Recommended aliases
alias make='lazy-file make -- make'
alias just='lazy-file just -- just'

# Now these work transparently:
make deploy    # Automatically loads variables from Makefile/makefile
just test      # Automatically loads variables from justfile/Justfile
```

### User Extensions

Users can register custom patterns and presets:

```bash
# Register custom file loader for Docker tools
lazy_file_loader "docker" '\$\{[A-Z_][A-Z0-9_]*\}|ARG\s+([A-Z_][A-Z0-9_]*)' "docker-compose.yml" "Dockerfile"

# Register Terraform support
lazy_file_loader "terraform" 'var\.([A-Z_][A-Z0-9_]*)|\$\{var\.([A-Z_][A-Z0-9_]*)\}' "*.tf" "terraform.tfvars"

# Use with aliases
alias docker-compose='lazy-file docker -- docker-compose'
alias terraform='lazy-file terraform -- terraform'
```

## Variable Detection Logic

### Detection Process

1. **Preset Lookup**: Find which files belong to the specified preset
2. **File Existence Check**: Only process files that exist in current directory
3. **Pattern Matching**: Apply registered regex to extract variable names
4. **Deduplication**: Remove duplicate variable names
5. **Loading**: Use existing `lazy_load` to load each detected variable
6. **Execution**: Run the original command

### Supported Variable Syntaxes

The system supports different variable syntaxes based on the file type:

- **Makefile**: `$(VAR)` and `${VAR}`
- **justfile**: `$VAR`, `${VAR}`, and `{{VAR}}`
- **Shell scripts**: `$VAR` and `${VAR}`

## Management and Introspection

### List Functions

```bash
# Show registered file loaders
lazy_list_file_loaders()

# Test what variables would be detected for a preset
lazy_test_file_loader <preset_name>
```

## Benefits

### For Users
- **Transparent**: Works with existing build files without modification
- **Flexible**: One system works for make, just, and any future tools
- **Extensible**: Users can add support for their own tools
- **Optional**: Zero impact if not used

### For Maintainers
- **Generic**: No tool-specific code to maintain
- **Data-driven**: New tools supported via configuration, not code
- **Consistent**: Follows existing lazy_var registration pattern  
- **Simple API**: One function to register everything
- **Testable**: Each component can be tested independently

## Implementation Notes

### Error Handling
- Invalid presets should show available options
- Missing files should be silently ignored
- Failed variable loading should not stop execution

### Performance Considerations
- File scanning only happens when `lazy-file` is called
- Variable detection is cached per command invocation
- Regex compilation should be optimized

### Compatibility
- Must work with existing lazy_var system
- Should not interfere with existing hooks
- Pattern registration should be idempotent

## Future Extensions

### Potential Enhancements
- **Glob Pattern Support**: Already supported via `lazy_file_loader "terraform" "..." "*.tf"`
- **Directory-Scoped Patterns**: Different patterns based on current directory
- **Conditional Loading**: Only load variables if they're actually used
- **Caching**: Cache variable detection results between runs
- **Pattern Inheritance**: Extend existing loaders with additional files

### Integration Opportunities
- **IDE Support**: Export detected variables for IDE environment
- **CI/CD Integration**: Use in build pipelines
- **Team Sharing**: Share pattern configurations across teams