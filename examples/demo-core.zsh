#!/usr/bin/env zsh
#
# 🚀 zsh-lazy-env: Step-by-Step Demo
#
# This demo shows the core functionality of zsh-lazy-env with clear examples
# of how variables are loaded on-demand.
#

# Store the script directory
DEMO_DIR="${${(%):-%x}:A:h}"

# Check if we're in asciinema-friendly mode
ASCIINEMA_MODE="${ASCIINEMA_MODE:-false}"

# Icon definitions (asciinema-friendly alternatives)
if [[ "$ASCIINEMA_MODE" == "true" ]]; then
    ROCKET="[>]"
    CHECK="[+]"
    INFO="[i]"
    ARROW=">"
    PARTY="[!]"
else
    ROCKET="🚀"
    CHECK="✓"
    INFO="ℹ"
    ARROW="▶"
    PARTY="🎉"
fi

# Simple colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

demo_print() {
    echo -e "${BLUE}[DEMO]${NC} $1"
}

demo_step() {
    echo -e "\n\n${CYAN}${ARROW} $1${NC}"
}

demo_config() {
    echo -e "\n${GRAY}# Add to ~/.zshrc${NC}"
    echo -e "${MAGENTA}$1${NC}"
}

demo_command() {
    echo -e "\n${YELLOW}Command:${NC} $1"
    echo
}

demo_success() {
    echo -e "\n${GREEN}${CHECK}${NC} $1"
}

demo_info() {
    echo -e "\n${YELLOW}${INFO}${NC} $1"
}

wait_continue() {
    echo
    if [[ "${AUTOPLAY:-false}" == "true" ]]; then
        echo -e "${GRAY}────────────────────────────────────────────────${NC}"
        sleep 3
    else
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read
    fi
}

clear
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              ${ROCKET} zsh-lazy-env Demo              ║${NC}"
echo -e "${BLUE}║           On-demand variable loading           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"

demo_print "This demo shows how variables are loaded only when needed"
echo "We'll demonstrate lazy loading for:"
echo "• Simple variables (lazy_var)"
echo "• Command triggers (lazy_command)"
echo "• Directory triggers (lazy_directory)"

wait_continue

# Setup
demo_step "Loading zsh-lazy-env plugin"
source "${DEMO_DIR}/../lazy-env.plugin.zsh"
demo_success "Plugin loaded"

wait_continue

# =============================================================================
# PART 1: Basic Variables
# =============================================================================

demo_step "Part 1: Basic Variable Configuration"
echo "Let's configure 3 different variables:"
echo

demo_config "lazy_var 'API_TOKEN' 'echo \"secret-api-token-abc123\"'"
lazy_var 'API_TOKEN' 'echo "secret-api-token-abc123"'

demo_config "lazy_var 'DATABASE_URL' 'echo \"postgresql://localhost:5432/myapp\"'"
lazy_var 'DATABASE_URL' 'echo "postgresql://localhost:5432/myapp"'

demo_config "lazy_var 'AWS_SECRET' 'echo \"aws-secret-key-xyz789\"'"
lazy_var 'AWS_SECRET' 'echo "aws-secret-key-xyz789"'

demo_success "3 variables configured"

wait_continue

demo_step "Check current state - no variables loaded yet"
demo_command "lazy_list_vars"

lazy_list_vars

demo_info "Notice: All variables show 'registered' status"

wait_continue

demo_step "Now let's access API_TOKEN - this will trigger loading"
demo_command "echo \"API_TOKEN: \$API_TOKEN\""

# Simulate the preexec hook being triggered
_lazy_env_preexec "echo \"API_TOKEN: \$API_TOKEN\""
echo "API_TOKEN: $API_TOKEN"

demo_success "API_TOKEN loaded on first access!"

wait_continue

demo_step "Check state again - see what changed"
demo_command "lazy_list_vars"

lazy_list_vars

demo_info "Notice: Only API_TOKEN is now loaded, others remain registered"

wait_continue

demo_step "Let's access all variables to see them load"
demo_command "echo \"DATABASE_URL: \$DATABASE_URL\" && echo \"AWS_SECRET: \$AWS_SECRET\""

# Simulate preexec hook for both variables
_lazy_env_preexec "echo \"DATABASE_URL: \$DATABASE_URL\""
_lazy_env_preexec "echo \"AWS_SECRET: \$AWS_SECRET\""
echo "DATABASE_URL: $DATABASE_URL"
echo "AWS_SECRET: $AWS_SECRET"

wait_continue

demo_step "Final state check"
demo_command "lazy_list_vars"

lazy_list_vars

demo_info "Now all variables are loaded and show their values"

wait_continue

# =============================================================================
# PART 2: Command Triggers
# =============================================================================

demo_step "Part 2: Command-Triggered Loading"
echo "Variables can auto-load when specific commands are executed:"
echo

demo_config "lazy_var 'DOCKER_TOKEN' 'echo \"docker-registry-token-def456\"'"
lazy_var 'DOCKER_TOKEN' 'echo "docker-registry-token-def456"'

demo_config "lazy_var 'K8S_CONFIG' 'echo \"kubernetes-config-ghi789\"'"
lazy_var 'K8S_CONFIG' 'echo "kubernetes-config-ghi789"'

demo_config "lazy_command 'docker' 'DOCKER_TOKEN'"
lazy_command 'docker' 'DOCKER_TOKEN'

demo_config "lazy_command 'pattern:kubectl.*' 'K8S_CONFIG'"
lazy_command 'pattern:kubectl.*' 'K8S_CONFIG'

demo_success "Command triggers configured"

wait_continue

demo_step "Check state - new variables are not loaded"
demo_command "lazy_list_vars"

lazy_list_vars

demo_info "DOCKER_TOKEN and K8S_CONFIG show 'registered'"

wait_continue

demo_step "Execute 'docker' command - this will auto-load DOCKER_TOKEN"
demo_command "docker --version || echo \"Docker command executed\""

# Simulate preexec hook triggering for docker command
_lazy_env_preexec "docker --version"
docker --version 2>/dev/null || echo "Docker command executed"
echo "DOCKER_TOKEN is now loaded: $DOCKER_TOKEN"

wait_continue

demo_step "Execute 'kubectl' command - this will auto-load K8S_CONFIG"
demo_command "kubectl version || echo \"Kubectl command executed\""

# Simulate preexec hook triggering for kubectl command
_lazy_env_preexec "kubectl version"
kubectl version 2>/dev/null || echo "Kubectl command executed"
echo "K8S_CONFIG is now loaded: $K8S_CONFIG"

wait_continue

demo_step "Check final state"
demo_command "lazy_list_vars"

lazy_list_vars

demo_info "Both command-triggered variables are now loaded"

wait_continue

# =============================================================================
# PART 3: Directory Triggers
# =============================================================================

demo_step "Part 3: Directory-Triggered Loading"
echo "Variables can auto-load when entering specific directories:"
echo

# Create demo directories
mkdir -p /tmp/demo-{project-a,project-b,staging}

demo_config "lazy_var 'PROJECT_A_KEY' 'echo \"project-a-secret-jkl012\"'"
lazy_var 'PROJECT_A_KEY' 'echo "project-a-secret-jkl012"'

demo_config "lazy_var 'PROJECT_B_KEY' 'echo \"project-b-secret-mno345\"'"
lazy_var 'PROJECT_B_KEY' 'echo "project-b-secret-mno345"'

demo_config "lazy_var 'STAGING_DB' 'echo \"staging-database-url-pqr678\"'"
lazy_var 'STAGING_DB' 'echo "staging-database-url-pqr678"'

echo

demo_config "lazy_directory '/tmp/demo-project-a' 'PROJECT_A_KEY'"
lazy_directory '/tmp/demo-project-a' 'PROJECT_A_KEY'

demo_config "lazy_directory '/tmp/demo-project-b' 'PROJECT_B_KEY'"
lazy_directory '/tmp/demo-project-b' 'PROJECT_B_KEY'

demo_config "lazy_directory 'pattern:.*staging.*' 'STAGING_DB'"
lazy_directory 'pattern:.*staging.*' 'STAGING_DB'

demo_success "Directory triggers configured"

wait_continue

demo_step "Check state - directory variables not loaded"
demo_command "lazy_list_vars"

lazy_list_vars

demo_info "PROJECT_A_KEY, PROJECT_B_KEY, and STAGING_DB show 'registered'"

wait_continue

demo_step "Change to /tmp/demo-project-a - this will auto-load PROJECT_A_KEY"
demo_command "cd /tmp/demo-project-a"

cd /tmp/demo-project-a
# Simulate chpwd hook triggering after directory change
_lazy_env_chpwd_internal "/tmp/demo-project-a"
demo_info "Current directory: $(pwd)"
echo "PROJECT_A_KEY is now auto-loaded: $PROJECT_A_KEY"

wait_continue

demo_step "Check state after directory change"
demo_command "lazy_list_vars"

lazy_list_vars

demo_info "PROJECT_A_KEY is now loaded due to directory trigger"

wait_continue

demo_step "Change to /tmp/demo-staging - this will trigger pattern match"
demo_command "cd /tmp/demo-staging"

cd /tmp/demo-staging
# Simulate chpwd hook triggering after directory change
_lazy_env_chpwd_internal "/tmp/demo-staging"
demo_info "Current directory: $(pwd)"
echo "STAGING_DB is now loaded via pattern: $STAGING_DB"

wait_continue

demo_step "Check final state"
demo_command "lazy_list_vars"

lazy_list_vars

demo_info "STAGING_DB is now loaded due to directory pattern match"

wait_continue

# Cleanup
demo_step "Cleaning up demo directories"
cd /tmp
rm -rf /tmp/demo-{project-a,project-b,staging}
demo_success "Demo directories removed"

wait_continue

demo_step "Summary"
echo "zsh-lazy-env provides three loading mechanisms:"
echo
echo "${CHECK} lazy_var: Define variables that load on first access"
echo "${CHECK} lazy_command: Auto-load when specific commands run"
echo "${CHECK} lazy_directory: Auto-load when entering directories"
echo
demo_info "Variables only load when needed - saving time and resources"

wait_continue

echo
echo -e "${GREEN}${PARTY} Demo complete! Thanks for trying zsh-lazy-env!${NC}"
echo -e "${CYAN}Visit github.com/dtomasi/zsh-lazy-env for more information${NC}"
