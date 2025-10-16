# 🚀 zsh-lazy-env

> **Smart, directory-scoped environment variable management for zsh**

Automatically load the right environment variables and secrets based on your current directory. `zsh-lazy-env` provides directory-scoped variable management with lazy loading, pattern matching, and seamless integration with secret management tools like 1Password.

## ✨ What makes this special?

- 🎯 **Directory-scoped variables** - Different secrets for different projects, automatically
- ⚡ **Lazy loading** - Zero startup performance impact
- 🔄 **Automatic switching** - Variables reload when you `cd` between projects  
- 🔐 **1Password integration** - Seamless secret management
- 🔍 **Pattern matching** - Flexible directory structure support
- 🛡️ **Security first** - Secrets only loaded when needed
- 🚀 **Unified API** - Simple `lazy_var` function handles all three registration types

## 🎬 Live Demo

Want to see it in action? Run our interactive demo:

```bash
cd zsh-lazy-env
zsh demo.zsh
```

## 🚀 Quick Start

### Installation

```bash
# Add to your ~/.zshrc
zinit load "dtomasi/zsh-lazy-env"
```

### Basic Setup

```bash
# Global fallback (always available)
lazy_var "API_KEY" "op read 'op://personal/api-key/password'"

# Project-specific overrides (same variable name, different secrets!)
lazy_var "API_KEY" "op read 'op://acme-vault/api-key/password'" "~/work/client-acme"
lazy_var "API_KEY" "op read 'op://globex-vault/api-key/password'" "~/work/client-globex"

# Environment-specific database URLs  
lazy_var "DATABASE_URL" "op read 'op://prod/database/url'" "~/work/myapp/production"
lazy_var "DATABASE_URL" "op read 'op://staging/database/url'" "~/work/myapp/staging"
```

### Pattern-Based Matching

Perfect for complex directory structures:

```bash
# All terraform directories get the same token
lazy_var "TF_TOKEN" "op read 'op://terraform/cloud-token/password'" "pattern:.*/terraform/.*"

# Production environments get production secrets
lazy_var "DB_PASSWORD" "op read 'op://production/database/password'" "pattern:.*/prod.*"

# Kubernetes directories get cluster-specific configs
lazy_var "KUBE_CONFIG" "op read 'op://k8s-staging/config/file'" "pattern:.*/k8s/staging.*"
lazy_var "KUBE_CONFIG" "op read 'op://k8s-prod/config/file'" "pattern:.*/k8s/prod.*"
```

## 🎯 Real-World Example

Imagine you're a DevOps engineer working on multiple client projects:

```bash
# Setup once in ~/.zshrc
lazy_var "API_KEY" "op read 'op://acme/api-key/password'" "~/work/acme-corp"
lazy_var "API_KEY" "op read 'op://globex/api-key/password'" "~/work/globex-inc"
lazy_var "API_KEY" "op read 'op://initech/api-key/password'" "~/work/initech-ltd"
```

Then magic happens automatically:

```bash
$ cd ~/work/acme-corp
$ echo $API_KEY
acme-secret-key-xyz123

$ cd ~/work/globex-inc  
$ echo $API_KEY
globex-premium-token-abc789

$ cd ~/work/initech-ltd
$ echo $API_KEY
initech-corporate-key-def456
```

Variables automatically switch based on your current directory, eliminating the need for manual management or per-project `.env` files.

## 🛠️ All Functions

### Core Functions

| Function | Purpose |
|----------|---------|
| `lazy_var "VAR" "command"` | Register global variable (fallback) |
| `lazy_var "VAR" "command" "/path"` | Directory-specific override (exact path) |
| `lazy_var "VAR" "command" "pattern:regex"` | Pattern-based override |

### Management Functions

| Function | Purpose |
|----------|---------|
| `lazy_list_vars` | List all registered variables |
| `lazy_load "VAR" [path]` | Manually load/reload a variable |

### Testing & Debug Functions

| Function | Purpose |
|----------|---------|
| `lazy_test_var "VAR" [path]` | Test command resolution priority |
| `lazy_test_command "command"` | Test what variables a command would load |
| `lazy_test_directory "path"` | Test what variables a directory would load |

## 🔧 Advanced Configuration

### Organized Configuration with `lazy_load_configs`

For complex setups, organize your configurations into files:

```bash
# In ~/.zshrc - load all .sh files recursively
lazy_load_configs "$HOME/.config/env/**/*.sh"

# Or load specific directories
lazy_load_configs "$HOME/.config/env/global/*.sh" "$HOME/.config/env/prod/*.sh"

# Or use brace expansion
lazy_load_configs ~/.config/env/{global,tenants}/**/*.sh
```

Organize your files however you want - the directory structure is just for your convenience!

**Example directory structure:**
```
~/.config/env/
├── global/
│   ├── github.sh
│   ├── docker.sh
│   └── ai.sh
└── tenants/
    ├── client-a/
    │   ├── aws.sh
    │   └── gitlab.sh
    └── client-b/
        └── api.sh
```

**Example global configuration** (`~/.config/env/global/github.sh`):
```bash
#!/usr/bin/env zsh
# GitHub configuration

# Global fallback
lazy_var "GITHUB_TOKEN" "op read 'op://Private/GitHub Token/credential'"

# Load token automatically when using gh CLI
lazy_command "gh" "GITHUB_TOKEN"
```

**Example scoped configuration** (`~/.config/env/tenants/client-a/aws.sh`):
```bash
#!/usr/bin/env zsh
# Client A AWS configuration

# These are only loaded when in directories matching the pattern
lazy_var "AWS_ACCESS_KEY_ID" \
    "op read 'op://ClientA/AWS/access-key'" \
    "pattern:.*/client-a/.*"

lazy_var "AWS_SECRET_ACCESS_KEY" \
    "op read 'op://ClientA/AWS/secret-key'" \
    "pattern:.*/client-a/.*"

# Or use exact directory paths
lazy_var "AWS_DEFAULT_REGION" \
    "echo us-east-1" \
    "$HOME/work/client-a"
```

**How it works:**
1. `lazy_setup_env` loads all `.sh` files from the config directory
2. Each file registers variables with `lazy_var` and their scoping rules
3. Variables are loaded on-demand based on the patterns you defined
4. Directory structure is purely organizational - define scoping in the files themselves

**Example behavior:**
```bash
$ cd ~/work/client-a/project1
$ echo $AWS_ACCESS_KEY_ID
# Automatically loads from 1Password when first accessed
xxx-client-a-access-key-xxx

$ cd ~/work/client-b/webapp
$ echo $AWS_ACCESS_KEY_ID
# Loads different credentials for client-b
xxx-client-b-access-key-xxx
```

**Benefits:**
- ✅ Organize files however makes sense to you
- ✅ Scoping logic defined in the files themselves (explicit & clear)
- ✅ Simple to understand - just `.sh` files with `lazy_var` calls
- ✅ Full power of pattern matching and exact paths available

### Command-Triggered Loading

Load variables automatically when certain commands are used:

```bash
# Load GitHub token when using gh CLI
lazy_command "gh" "GITHUB_TOKEN"

# Load Docker Hub token for push/pull
lazy_command_pattern "^docker (push|pull)" "DOCKER_HUB_TOKEN"

# Load Terraform token for any terraform command
lazy_command "terraform" "TF_TOKEN"
```

### Directory-Triggered Loading

Load variables automatically when entering directories:

```bash
# Load project variables when entering project directories
lazy_directory "~/work/project-a" "PROJECT_A_API_KEY,PROJECT_A_SECRET"

# Pattern-based directory triggers
lazy_directory_pattern ".*/terraform/.*" "TF_TOKEN,AWS_SECRET_ACCESS_KEY"
```

## 🎯 Priority System

Variables are resolved with clear priority:

1. **🎯 Exact Directory Match** - `lazy_var "VAR" "command" "/exact/path"`
2. **🔍 Pattern Directory Match** - `lazy_var "VAR" "command" "pattern:regex"`  
3. **🌍 Global Fallback** - `lazy_var "VAR" "command"`

```bash
# Setup hierarchy
lazy_var "API_KEY" "echo global-key"                                      # Priority 3
lazy_var "API_KEY" "echo pattern-key" "pattern:.*/work/.*"               # Priority 2  
lazy_var "API_KEY" "echo exact-key" "/Users/me/work/special"             # Priority 1

# Results:
# /Users/me/work/special     → exact-key    (priority 1)
# /Users/me/work/other       → pattern-key  (priority 2)
# /Users/me/home             → global-key   (priority 3)
```

## 🔐 Security Features

- **Secrets only loaded when needed** - No unnecessary exposure
- **Automatic cleanup** - Variables can be reloaded with new values
- **Isolation** - Project secrets never leak between directories
- **Audit trail** - All loading is logged and traceable

## 🤝 Team Benefits

### For DevOps Teams
- **Multi-client management** - Different secrets per client, zero mental overhead
- **Environment isolation** - Prod/staging secrets automatically separated
- **Consistent workflows** - Same commands work everywhere

### For Development Teams  
- **Zero configuration** - New team members get working setup immediately
- **No .env files** - No more committing secrets or missing .env.example
- **Cross-platform** - Works on any machine with zsh

### For Security Teams
- **Centralized secret management** - All secrets in 1Password/vault
- **Reduced exposure** - Secrets only loaded when actually needed
- **Audit compliance** - Clear trails of secret access

## 📋 Migration Guide

### From .env files

**Before:**
```bash
# project-a/.env
API_KEY=secret1
DATABASE_URL=postgres://...

# project-b/.env  
API_KEY=secret2
DATABASE_URL=postgres://...
```

**After:**
```bash
# ~/.zshrc (setup once)
lazy_var "API_KEY" "op read 'op://project-a/api-key/password'" "~/work/project-a"
lazy_var "DATABASE_URL" "op read 'op://project-a/database/url'" "~/work/project-a"
lazy_var "API_KEY" "op read 'op://project-b/api-key/password'" "~/work/project-b"
lazy_var "DATABASE_URL" "op read 'op://project-b/database/url'" "~/work/project-b"
```

### From direnv

`zsh-lazy-env` provides similar functionality but with better performance and more features:

- ✅ **Faster** - No directory scanning overhead
- ✅ **More flexible** - Pattern matching and priority system
- ✅ **Better integration** - Works with 1Password, AWS SSM, etc.
- ✅ **Lazy loading** - Variables only loaded when actually used

## 🧪 Testing Your Setup

Use the built-in testing functions to verify your configuration:

```bash
# Test what command would be used for a variable in a specific directory
lazy_test_var "API_KEY" "~/work/project-a"

# List all variables for current directory
lazy_list_vars

# Test command detection
lazy_test_command "terraform plan"
```

## 🧪 Development & Testing

### Running the Test Suite

The plugin includes a comprehensive test framework with near 100% coverage:

```bash
# Run all tests
./tests/run-tests.zsh

# Run specific test suite
./tests/run-tests.zsh --filter core-functions

# Run with verbose output
./tests/run-tests.zsh --verbose

# Run tests in parallel (CI mode)
./tests/run-tests.zsh --parallel
```

### Test Coverage

The test suite covers:

- ✅ **Core Functions**: Variable registration, command mapping, loading
- ✅ **Directory Scoping**: Priority resolution, pattern matching  
- ✅ **Listing Functions**: Output formatting, table structure
- ✅ **Error Handling**: Edge cases, malformed input, failures
- ✅ **Integration**: Real-world workflows, complex scenarios

### CI/CD Integration

Automated testing is available for:

- **GitHub Actions**: `.github/workflows/test.yml`
- **GitLab CI**: `.gitlab-ci.yml`

The CI pipeline runs tests on:
- Multiple zsh versions (5.8, 5.9)
- Different operating systems (Ubuntu, macOS, Alpine)
- Various compatibility scenarios

### Contributing

1. Fork the repository
2. Make your changes
3. Run the test suite: `./tests/run-tests.zsh`
4. Ensure all tests pass
5. Submit a pull request

The automated CI will run additional compatibility tests across multiple environments.

## 🎯 Use Cases

**DevOps & Multi-Client Management**
- Manage different credentials for multiple client projects
- Automatic environment isolation (production, staging, development)
- Consistent workflows across all projects

**Development Teams**
- Simplified onboarding - new team members get working credentials immediately
- No `.env` file management or risk of committing secrets
- Cross-platform compatibility

**Security & Compliance**
- Centralized secret management with 1Password, AWS SSM, or HashiCorp Vault
- Secrets only loaded when needed, reducing exposure
- Clear audit trail of secret access

## 📚 Examples

Check out the [examples/config.zsh](examples/config.zsh) file for real-world configuration examples.

## 🤔 FAQ

**Q: Does this slow down my shell startup?**  
A: No. Variables are loaded lazily only when first accessed, resulting in zero startup performance impact.

**Q: What if I don't use 1Password?**  
A: The plugin works with any command-line tool. You can use AWS SSM, HashiCorp Vault, macOS Keychain, environment files, or any custom command that outputs a value.

**Q: Can I mix different secret sources?**  
A: Yes. Each variable can use a different source. For example, use 1Password for API keys, AWS SSM for production secrets, and local commands for development values.

**Q: What about Windows/PowerShell?**  
A: Currently zsh-only. The plugin relies on zsh-specific features like hooks and associative arrays.

**Q: How do I debug issues?**  
A: Use the built-in testing functions: `lazy_test_var`, `lazy_test_command`, and `lazy_test_directory` provide detailed information about variable resolution and command detection.

**Q: Is this production-ready?**  
A: Yes. The plugin includes comprehensive test coverage, CI/CD integration, and has been used in production environments. See `TESTING.md` for details about the test suite.

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

### Reporting Issues

- Check existing issues before creating a new one
- Include zsh version and OS information
- Provide a minimal reproduction example
- Describe expected vs actual behavior

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes with clear, descriptive commits
4. Add or update tests for your changes
5. Run the test suite: `./tests/run-tests.zsh`
6. Ensure all tests pass and code is well-documented
7. Submit a pull request with a clear description

### Development Guidelines

- Follow existing code style and conventions
- Add tests for new functionality
- Update documentation for user-facing changes
- Keep commits focused and atomic
- Write clear commit messages

### Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help maintain a welcoming community
- Report unacceptable behavior to project maintainers

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.