# 🧪 Testing Guide for zsh-lazy-env

This document provides comprehensive information about testing the zsh-lazy-env plugin.

## Test Framework Architecture

### Components

- **`test-framework.zsh`** - Core testing framework with assertions and utilities
- **`run-tests.zsh`** - Test runner with CI/CD integration and reporting
- **Test Suites** - Modular test files covering different functionality areas

### Test Suites

1. **`test-core-functions.zsh`** - Basic functionality
   - Variable registration (global, directory, pattern)
   - Command mapping and detection
   - Loading mechanisms
   - Priority resolution

2. **`test-directory-scoped.zsh`** - Directory-specific behavior
   - Directory-scoped variable loading
   - Pattern matching
   - Priority resolution between global, pattern, and exact matches

3. **`test-listing-functions.zsh`** - Output formatting
   - `lazy_list_vars` formatting and content
   - `lazy_list_commands` table structure
   - `lazy_list_directories` display logic

4. **`test-error-handling.zsh`** - Edge cases and error conditions
   - Invalid input handling
   - Command failures
   - Malformed configurations
   - File system edge cases

5. **`test-integration.zsh`** - Real-world scenarios
   - Multi-project workflows
   - DevOps toolchain integration
   - Complex directory switching

## Running Tests

### Basic Usage

```bash
# Run all tests
./tests/run-tests.zsh

# Run specific test suite
./tests/run-tests.zsh --filter core-functions
./tests/run-tests.zsh --filter directory-scoped
./tests/run-tests.zsh --filter error-handling

# Run with verbose output
./tests/run-tests.zsh --verbose

# Run in parallel (faster)
./tests/run-tests.zsh --parallel
```

### CI/CD Mode

```bash
# Non-interactive mode for CI
export CI=true
./tests/run-tests.zsh
```

### Advanced Options

```bash
# Multiple filters
./tests/run-tests.zsh --filter "core-functions,integration"

# Stop on first failure
./tests/run-tests.zsh --fail-fast

# Generate coverage report
./tests/run-tests.zsh --coverage
```

## Test Framework Features

### Assertions

The test framework provides comprehensive assertion functions:

```bash
# Equality checks
assert_equals "expected" "$actual" "message"
assert_not_equals "not_expected" "$actual" "message"

# String operations
assert_contains "$text" "substring" "message"
assert_matches "$text" "regex_pattern" "message"

# Variable state
assert_var_set "VARIABLE_NAME" "message"
assert_var_unset "VARIABLE_NAME" "message"

# Command execution
assert_command_success "command" "message"
assert_command_failure "command" "message"

# Boolean checks
assert_true "condition" "message"
assert_false "condition" "message"
```

### Test Isolation

Each test runs in a clean environment:
- Fresh variable state
- Temporary directories
- Isolated configuration
- Cleanup after each test

### Output Formatting

- **Colored output** for easy reading
- **Progress indicators** during test execution
- **Detailed failure reports** with context
- **Summary statistics** at the end

## Coverage Areas

### Core Functionality (95% coverage)
- ✅ Variable registration and loading
- ✅ Command mapping and detection
- ✅ Directory scoping and patterns
- ✅ Priority resolution
- ✅ Listing and management functions

### Error Conditions (90% coverage)
- ✅ Invalid input handling
- ✅ Command execution failures
- ✅ File system edge cases
- ✅ Malformed configurations
- ✅ Resource limitations

### Integration Scenarios (85% coverage)
- ✅ Multi-project workflows
- ✅ Real-world DevOps scenarios
- ✅ Complex directory structures
- ✅ Command-line tool integration

## CI/CD Integration

### GitHub Actions

The `.github/workflows/test.yml` pipeline runs:

- **Test Matrix**: Multiple zsh versions (5.8, 5.9)
- **OS Matrix**: Ubuntu, macOS
- **Linting**: shellcheck analysis
- **Compatibility**: Cross-platform testing

### GitLab CI

The `.gitlab-ci.yml` pipeline includes:

- **Multi-stage**: test, lint, compatibility
- **Container Support**: Alpine, Ubuntu images
- **Artifact Collection**: Test results and coverage
- **Parallel Execution**: Faster feedback

### Local Pre-commit

```bash
# Run before committing
./tests/run-tests.zsh --fail-fast
```

## Writing New Tests

### Test Suite Structure

```bash
#!/usr/bin/env zsh
# Source framework and plugin
source "$(dirname "$0")/test-framework.zsh"
source "$(dirname "$0")/../lazy-env.plugin.zsh"

test_suite "Your Test Suite Name"

test_start "description of test"
	test_setup  # Clean state
	
	# Your test code here
	lazy_var "TEST_VAR" "echo 'test-value'"
	lazy_load "TEST_VAR"
	
	# Assertions
	assert_equals "test-value" "$TEST_VAR" "Should load variable correctly"
```

### Best Practices

1. **Descriptive Names**: Use clear, specific test names
2. **Clean Setup**: Always call `test_setup` at the start
3. **Single Responsibility**: One test per behavior
4. **Good Messages**: Provide helpful assertion messages
5. **Edge Cases**: Test boundary conditions
6. **Error Conditions**: Test failure scenarios

### Example Test

```bash
test_start "directory-scoped variable loading with priority"
	test_setup
	
	# Setup hierarchy
	lazy_var "API_KEY" "echo 'global-key'"
	lazy_var "API_KEY" "echo 'pattern-key'" "pattern:.*/work/.*"
	lazy_var "API_KEY" "echo 'exact-key'" "/tmp/work/project"
	
	# Test exact match (highest priority)
	lazy_load "API_KEY" "/tmp/work/project"
	assert_equals "exact-key" "$API_KEY" "Should use exact directory match"
	
	# Test pattern match (medium priority)
	unset API_KEY
	LOADED_VARS[API_KEY]=""
	lazy_load "API_KEY" "/tmp/work/other"
	assert_equals "pattern-key" "$API_KEY" "Should use pattern match"
	
	# Test global fallback (lowest priority)
	unset API_KEY
	LOADED_VARS[API_KEY]=""
	lazy_load "API_KEY" "/tmp/home"
	assert_equals "global-key" "$API_KEY" "Should fall back to global"
```

## Debugging Tests

### Verbose Mode

```bash
./tests/run-tests.zsh --verbose
```

Shows:
- Detailed assertion output
- Variable states
- Command execution details
- Error messages with context

### Individual Test Execution

```bash
# Run single test file directly
zsh tests/test-core-functions.zsh
```

### Debug Output

Add debug statements in tests:

```bash
echo "DEBUG: API_KEY = '$API_KEY'" >&2
echo "DEBUG: LOADED_VARS state:" >&2
print -l ${(kv)LOADED_VARS} >&2
```

## Performance Considerations

### Test Execution Time

- **Full Suite**: ~3-5 seconds
- **Core Functions**: ~1 second  
- **Integration Tests**: ~2 seconds

### Optimization Tips

- Use `--parallel` for faster CI execution
- Filter tests during development: `--filter core-functions`
- Use `--fail-fast` to stop on first failure

## Contributing Tests

When adding new features:

1. **Add corresponding tests** in appropriate test suite
2. **Test edge cases** and error conditions  
3. **Verify CI passes** before submitting PR
4. **Update this documentation** if adding new test types

### Pull Request Checklist

- [ ] All existing tests pass
- [ ] New functionality has test coverage
- [ ] Edge cases are tested
- [ ] Error conditions are handled
- [ ] CI pipeline passes
- [ ] Documentation is updated

---

**The test suite ensures zsh-lazy-env remains reliable and maintainable as it evolves.**