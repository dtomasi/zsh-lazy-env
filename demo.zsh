#!/usr/bin/env zsh
# 
# 🚀 zsh-lazy-env Interactive Demo
# 
# This demo showcases the powerful directory-scoped variable loading feature
# Perfect for teams managing multiple projects with different credentials
#

# Store the script directory at the top level
DEMO_DIR="${${(%):-%x}:A:h}"

# Color definitions for fancy output (zsh format)
RED='%F{red}'
GREEN='%F{green}'
YELLOW='%F{yellow}'
BLUE='%F{blue}'
PURPLE='%F{magenta}'
CYAN='%F{cyan}'
WHITE='%F{white}'
BOLD='%B'
NC='%f%b' # No Color / Reset

# Helper function for fancy headers
print_header() {
	print ""
	print -P "${BLUE}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
	print -P "${BLUE}║${WHITE}${BOLD}  $1${NC}${BLUE}$(printf '%*s' $((84 - ${#1})) '')║${NC}"
	print -P "${BLUE}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
	print ""
}

# Helper function for step headers
print_step() {
	print ""
	print -P "${CYAN}▶${WHITE}${BOLD} $1${NC}"
	print -P "${CYAN}$(printf '─%.0s' {1..80})${NC}"
}

# Helper function for success messages
print_success() {
	print -P "${GREEN}✅ $1${NC}"
}

# Helper function for info messages
print_info() {
	print -P "${YELLOW}💡 $1${NC}"
}

# Helper function for waiting
wait_for_user() {
	print ""
	print -P "${PURPLE}Press Enter to continue...${NC}"
	read
}

# Main demo function
run_demo() {
	clear
	
	print_header "🚀 zsh-lazy-env: Directory-Scoped Secret Management Demo"
	
	print -P "${WHITE}${BOLD}Welcome to the future of environment variable management!${NC}"
	print ""
	print -P "This demo shows how ${CYAN}zsh-lazy-env${NC} automatically loads different secrets"
	print -P "based on your current directory - perfect for multi-project workflows."
	print ""
	print -P "${GREEN}Key Features:${NC}"
	print -P "• 🎯 Directory-specific variable overrides"
	print -P "• 🔍 Pattern-based directory matching"
	print -P "• 🔄 Automatic reloading on directory changes"
	print -P "• 🔐 Seamless 1Password integration"
	print -P "• ⚡ Zero performance impact (lazy loading)"
	
	wait_for_user
	
	# Setup demo environment
	print_step "Setting up demo environment"
	
	# Source the plugin (with full path)
	source "${DEMO_DIR}/lazy-env.plugin.zsh"
	
	# Create demo directories
	mkdir -p /tmp/demo/{client-acme,client-globex,terraform/prod,terraform/staging,other}
	
	print_success "Demo directories created"
	
	# Setup global fallback
	print_step "🌍 Setting up global variable definitions (fallbacks)"
	
	print -P "${CYAN}lazy_var 'API_KEY' 'echo \"🔑 global-fallback-key\"'${NC}"
	lazy_var 'API_KEY' 'echo "🔑 global-fallback-key"'
	
	print -P "${CYAN}lazy_var 'DATABASE_URL' 'echo \"🗄️  postgresql://localhost:5432/default\"'${NC}"
	lazy_var 'DATABASE_URL' 'echo "🗄️  postgresql://localhost:5432/default"'
	
	print_success "Global variables registered"
	
	wait_for_user
	
	# Setup directory-specific overrides
	print_step "🎯 Setting up directory-specific overrides"
	
	print -P "${GREEN}# Client-specific API keys (same variable name, different secrets)${NC}"
	print -P "${CYAN}lazy_var 'API_KEY' 'echo \"🏢 acme-secret-api-key-xyz123\"' '/tmp/demo/client-acme'${NC}"
	lazy_var 'API_KEY' 'echo "🏢 acme-secret-api-key-xyz123"' '/tmp/demo/client-acme'
	
	print -P "${CYAN}lazy_var 'API_KEY' 'echo \"🌟 globex-premium-token-abc789\"' '/tmp/demo/client-globex'${NC}"
	lazy_var 'API_KEY' 'echo "🌟 globex-premium-token-abc789"' '/tmp/demo/client-globex'
	
	print ""
	print -P "${GREEN}# Environment-specific database URLs${NC}"
	print -P "${CYAN}lazy_var 'DATABASE_URL' 'echo \"🔴 postgresql://prod-db:5432/myapp\"' '/tmp/demo/terraform/prod'${NC}"
	lazy_var 'DATABASE_URL' 'echo "🔴 postgresql://prod-db:5432/myapp"' '/tmp/demo/terraform/prod'
	
	print -P "${CYAN}lazy_var 'DATABASE_URL' 'echo \"🟡 postgresql://staging-db:5432/myapp\"' '/tmp/demo/terraform/staging'${NC}"
	lazy_var 'DATABASE_URL' 'echo "🟡 postgresql://staging-db:5432/myapp"' '/tmp/demo/terraform/staging'
	
	print_success "Directory-specific overrides registered"
	
	wait_for_user
	
	# Setup pattern-based overrides
	print_step "🔍 Setting up pattern-based overrides"
	
	print -P "${GREEN}# Pattern matching for flexible directory structures${NC}"
	print -P "${CYAN}lazy_var 'TF_TOKEN' 'echo \"🏗️  terraform-cloud-token-def456\"' 'pattern:.*/terraform/.*'${NC}"
	lazy_var 'TF_TOKEN' 'echo "🏗️  terraform-cloud-token-def456"' 'pattern:.*/terraform/.*'
	
	print -P "${CYAN}lazy_var 'CLIENT_SECRET' 'echo \"🤝 universal-client-secret-789xyz\"' 'pattern:.*/client-.*'${NC}"
	lazy_var 'CLIENT_SECRET' 'echo "🤝 universal-client-secret-789xyz"' 'pattern:.*/client-.*'
	
	print_success "Pattern-based overrides registered"
	
	wait_for_user
	
	# Demonstrate command resolution
	print_step "🧪 Testing command resolution (priority system)"
	
	print -P "${WHITE}${BOLD}Priority: Exact Directory > Pattern Match > Global Fallback${NC}"
	print ""
	
	print -P "${GREEN}1. In client-acme directory (exact match):${NC}"
	cd /tmp/demo/client-acme
	lazy_load 'API_KEY'
	print -P "   📍 Directory: ${CYAN}$PWD${NC}"
	print -P "   🔑 API_KEY: ${WHITE}$API_KEY${NC}"
	print ""
	
	print -P "${GREEN}2. In client-acme directory - CLIENT_SECRET (pattern match):${NC}"
	unset CLIENT_SECRET
	lazy_load 'CLIENT_SECRET'
	print -P "   📍 Directory: ${CYAN}$PWD${NC}"
	print -P "   🔐 CLIENT_SECRET: ${WHITE}$CLIENT_SECRET${NC}"
	print ""
	
	print -P "${GREEN}3. In neutral directory (global fallback):${NC}"
	cd /tmp/demo/other
	unset API_KEY
	lazy_load 'API_KEY'
	print -P "   📍 Directory: ${CYAN}$PWD${NC}"
	print -P "   🔑 API_KEY: ${WHITE}$API_KEY${NC}"
	
	wait_for_user
	
	# Demonstrate automatic loading and switching
	print_step "🔄 Demonstrating automatic variable loading & switching"
	
	print -P "${WHITE}${BOLD}Watch how variables automatically change when switching directories!${NC}"
	print ""
	
	# Start in global context
	print -P "${GREEN}📁 Starting in neutral directory:${NC}"
	cd /tmp
	lazy_load 'API_KEY'
	print -P "   ${CYAN}API_KEY=${WHITE}$API_KEY${NC}"
	print ""
	
	# Switch to client-acme
	print -P "${GREEN}📁 Switching to client-acme directory:${NC}"
	cd /tmp/demo/client-acme
	lazy_load 'API_KEY'
	print -P "   ${CYAN}API_KEY=${WHITE}$API_KEY${NC}"
	print ""
	
	# Switch to client-globex
	print -P "${GREEN}📁 Switching to client-globex directory:${NC}"
	cd /tmp/demo/client-globex
	lazy_load 'API_KEY'
	print -P "   ${CYAN}API_KEY=${WHITE}$API_KEY${NC}"
	print ""
	
	# Load pattern-based variable
	print -P "${GREEN}📁 Moving to terraform/prod (loads TF_TOKEN via pattern):${NC}"
	cd /tmp/demo/terraform/prod
	lazy_load 'TF_TOKEN'
	lazy_load 'DATABASE_URL'
	print -P "   ${CYAN}TF_TOKEN=${WHITE}$TF_TOKEN${NC}"
	print -P "   ${CYAN}DATABASE_URL=${WHITE}$DATABASE_URL${NC}"
	
	wait_for_user
	
	# Show listing functionality
	print_step "📋 Directory-specific variable inspection"
	
	print -P "${GREEN}Listing variables for terraform/prod directory:${NC}"
	lazy_list_vars
	print ""
	
	print -P "${GREEN}Switching to client-acme directory:${NC}"
	cd /tmp/demo/client-acme
	lazy_list_vars
	
	wait_for_user
	
	# Real-world use case example
	print_step "🌟 Real-world use case: 1Password integration"
	
	print -P "${WHITE}${BOLD}In real scenarios, you'd use 1Password CLI:${NC}"
	print ""
	print -P "${GREEN}# Project-specific API keys from different vaults${NC}"
	print -P "${CYAN}lazy_var 'API_KEY' \\${NC}"
	print -P "${CYAN}    'op read \"op://acme-vault/api-key/password\"' \\${NC}"
	print -P "${CYAN}    '~/work/client-acme'${NC}"
	print ""
	print -P "${CYAN}lazy_var 'API_KEY' \\${NC}"
	print -P "${CYAN}    'op read \"op://globex-vault/api-key/password\"' \\${NC}"
	print -P "${CYAN}    '~/work/client-globex'${NC}"
	print ""
	print -P "${GREEN}# Environment-specific secrets${NC}"
	print -P "${CYAN}lazy_var 'DB_PASSWORD' \\${NC}"
	print -P "${CYAN}    'op read \"op://production/database/password\"' \\${NC}"
	print -P "${CYAN}    'pattern:.*/prod.*'${NC}"
	print ""
	print -P "${CYAN}lazy_var 'DB_PASSWORD' \\${NC}"
	print -P "${CYAN}    'op read \"op://staging/database/password\"' \\${NC}"
	print -P "${CYAN}    'pattern:.*/staging.*'${NC}"
	
	wait_for_user
	
	# Benefits summary
	print_step "🎯 Benefits for your team"
	
	print -P "${WHITE}${BOLD}Why this matters for multi-project teams:${NC}"
	print ""
	print -P "${GREEN}✅ Security:${NC} Different projects = different secrets, isolated automatically"
	print -P "${GREEN}✅ Simplicity:${NC} Same variable names across projects, no mental overhead"
	print -P "${GREEN}✅ Performance:${NC} Secrets only loaded when needed, zero startup penalty"
	print -P "${GREEN}✅ Flexibility:${NC} Pattern matching handles complex directory structures"
	print -P "${GREEN}✅ Integration:${NC} Works seamlessly with 1Password, AWS SSM, Keychain, etc."
	print -P "${GREEN}✅ Zero Config:${NC} Variables switch automatically, no manual intervention"
	print ""
	print -P "${YELLOW}💡 Perfect for:${NC}"
	print -P "   • DevOps teams managing multiple clients"
	print -P "   • Developers working across staging/prod environments"
	print -P "   • Teams using 1Password for secret management"
	print -P "   • Anyone tired of managing environment-specific .env files"
	
	wait_for_user
	
	# Installation and setup
	print_step "🚀 Getting started"
	
	print -P "${WHITE}${BOLD}Installation:${NC}"
	print ""
	print -P "${CYAN}# Add to ~/.zshrc${NC}"
	print -P "${GREEN}zinit load 'dtomasi/zsh-lazy-env'${NC}"
	print ""
	print -P "${WHITE}${BOLD}Basic setup:${NC}"
	print ""
	print -P "${GREEN}# Global fallback${NC}"
	print -P "${CYAN}lazy_var 'API_KEY' 'op read \"op://personal/api-key/password\"'${NC}"
	print ""
	print -P "${GREEN}# Project-specific overrides${NC}"
	print -P "${CYAN}lazy_var 'API_KEY' 'op read \"op://project-a/api-key/password\"' '~/work/project-a'${NC}"
	print -P "${CYAN}lazy_var 'API_KEY' 'op read \"op://project-b/api-key/password\"' '~/work/project-b'${NC}"
	print ""
	print -P "${GREEN}# Pattern-based environments${NC}"
	print -P "${CYAN}lazy_var 'DB_URL' 'op read \"op://prod/database/url\"' 'pattern:.*/prod.*'${NC}"
	
	wait_for_user
	
	# Cleanup
	print_step "🧹 Cleaning up demo environment"
	
	cd /tmp
	rm -rf /tmp/demo
	
	print_success "Demo directories cleaned up"
	
	# Final message
	print_header "🎉 Demo Complete!"
	
	print -P "${WHITE}${BOLD}Thanks for watching the zsh-lazy-env demo!${NC}"
	print ""
	print -P "${GREEN}Key takeaways:${NC}"
	echo "• Directory-scoped variables eliminate .env file management"
	echo "• Automatic switching means zero mental overhead"
	echo "• Priority system ensures predictable behavior"
	echo "• Perfect for teams with multiple projects/environments"
	print ""
	print -P "${CYAN}Questions? Check out the examples/config.zsh file for more inspiration!${NC}"
	print ""
	print -P "${PURPLE}Happy secret managing! 🔐✨${NC}"
}

# Run the demo
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%x}" == "${0}" ]]; then
	run_demo
fi