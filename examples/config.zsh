# Example configuration for zsh-lazy-env
# Add this to your .zshrc after loading the plugin

# Load the plugin with zinit
zinit load "dtomasi/zsh-lazy-env"

# Or with Git URL (for private repo access)
# zinit load "https://github.com/dtomasi/zsh-lazy-env.git"

# Manual installation alternative:
# git clone https://github.com/dtomasi/zsh-lazy-env.git ~/.local/share/zsh-lazy-env
# source ~/.local/share/zsh-lazy-env/lazy-env.plugin.zsh

# ============================================================================
# Global Variables (Fallback Definitions)
# ============================================================================
# These are used when no directory-specific override matches

# Version Control
lazy_var "GITHUB_TOKEN" "op read 'op://personal/github-token/credential'"
lazy_var "GITLAB_TOKEN" "op read 'op://personal/gitlab-token/credential'"

# Cloud Providers
lazy_var "AWS_ACCESS_KEY_ID" "op read 'op://personal/aws/access-key'"
lazy_var "AWS_SECRET_ACCESS_KEY" "op read 'op://personal/aws/secret-key'"
lazy_var "AWS_DEFAULT_REGION" "echo us-east-1"

# APIs & Services
lazy_var "OPENAI_API_KEY" "op read 'op://personal/openai/api-key'"
lazy_var "STRIPE_SECRET_KEY" "op read 'op://personal/stripe/secret-key'"
lazy_var "SENDGRID_API_KEY" "op read 'op://personal/sendgrid/api-key'"

# Databases
lazy_var "DATABASE_URL" "echo 'postgresql://localhost:5432/default'"
lazy_var "REDIS_URL" "echo 'redis://localhost:6379'"

# Container Registries
lazy_var "DOCKER_HUB_TOKEN" "op read 'op://personal/docker-hub/token'"

# ============================================================================
# Project-Specific Overrides
# ============================================================================
# Same variable names, different secrets per project

# Project A
lazy_var "API_KEY" "op read 'op://project-a/api-key/credential'" "$HOME/work/project-a"
lazy_var "DATABASE_URL" "op read 'op://project-a/database/url'" "$HOME/work/project-a"
lazy_var "STRIPE_SECRET_KEY" "op read 'op://project-a/stripe/secret'" "$HOME/work/project-a"

# Project B
lazy_var "API_KEY" "op read 'op://project-b/api-key/credential'" "$HOME/work/project-b"
lazy_var "DATABASE_URL" "op read 'op://project-b/database/url'" "$HOME/work/project-b"
lazy_var "STRIPE_SECRET_KEY" "op read 'op://project-b/stripe/secret'" "$HOME/work/project-b"

# ============================================================================
# Client-Specific Overrides
# ============================================================================

# Client X
lazy_var "AWS_ACCESS_KEY_ID" "op read 'op://client-x/aws/access-key'" "$HOME/work/client-x"
lazy_var "AWS_SECRET_ACCESS_KEY" "op read 'op://client-x/aws/secret-key'" "$HOME/work/client-x"
lazy_var "API_TOKEN" "op read 'op://client-x/api/token'" "$HOME/work/client-x"

# Client Y
lazy_var "AWS_ACCESS_KEY_ID" "op read 'op://client-y/aws/access-key'" "$HOME/work/client-y"
lazy_var "AWS_SECRET_ACCESS_KEY" "op read 'op://client-y/aws/secret-key'" "$HOME/work/client-y"
lazy_var "API_TOKEN" "op read 'op://client-y/api/token'" "$HOME/work/client-y"

# ============================================================================
# Environment-Specific Overrides (Production, Staging, Development)
# ============================================================================

# Production environment
lazy_var "DATABASE_URL" "op read 'op://production/database/url'" "$HOME/work/myapp/production"
lazy_var "REDIS_URL" "op read 'op://production/redis/url'" "$HOME/work/myapp/production"
lazy_var "API_SECRET" "op read 'op://production/api/secret'" "$HOME/work/myapp/production"

# Staging environment
lazy_var "DATABASE_URL" "op read 'op://staging/database/url'" "$HOME/work/myapp/staging"
lazy_var "REDIS_URL" "op read 'op://staging/redis/url'" "$HOME/work/myapp/staging"
lazy_var "API_SECRET" "op read 'op://staging/api/secret'" "$HOME/work/myapp/staging"

# Development environment (local)
lazy_var "DATABASE_URL" "echo 'postgresql://localhost:5432/myapp_dev'" "$HOME/work/myapp/development"
lazy_var "REDIS_URL" "echo 'redis://localhost:6379/0'" "$HOME/work/myapp/development"

# ============================================================================
# Pattern-Based Overrides
# ============================================================================
# Flexible directory matching using regex patterns

# All terraform directories get Terraform Cloud token
lazy_var "TF_TOKEN" "op read 'op://terraform/cloud-token/credential'" "pattern:.*/terraform/.*"

# Kubernetes directories get cluster-specific configs
lazy_var "KUBE_TOKEN" "op read 'op://k8s-prod/token/credential'" "pattern:.*/k8s/prod.*"
lazy_var "KUBE_TOKEN" "op read 'op://k8s-staging/token/credential'" "pattern:.*/k8s/staging.*"
lazy_var "KUBE_CONFIG" "op read 'op://k8s-prod/config/file'" "pattern:.*/k8s/prod.*"
lazy_var "KUBE_CONFIG" "op read 'op://k8s-staging/config/file'" "pattern:.*/k8s/staging.*"

# Docker-related directories
lazy_var "DOCKER_HUB_TOKEN" "op read 'op://docker/hub-token/credential'" "pattern:.*/docker/.*"

# Production pattern matching
lazy_var "DB_PASSWORD" "op read 'op://production/database/password'" "pattern:.*/(prod|production).*"

# Staging pattern matching
lazy_var "DB_PASSWORD" "op read 'op://staging/database/password'" "pattern:.*/(staging|stage).*"

# ============================================================================
# Command-Triggered Loading
# ============================================================================
# Load variables automatically when specific commands are used

# Version control
lazy_command "gh" "GITHUB_TOKEN"
lazy_command "gitlab" "GITLAB_TOKEN"
lazy_command_pattern "^git (push|pull)" "GITHUB_TOKEN"

# Infrastructure as Code
lazy_command "terraform" "TF_TOKEN,AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY"
lazy_command "pulumi" "PULUMI_ACCESS_TOKEN,AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY"

# Containers
lazy_command_pattern "^docker (push|pull)" "DOCKER_HUB_TOKEN"
lazy_command "kubectl" "KUBE_TOKEN,KUBE_CONFIG"

# Cloud CLIs
lazy_command "aws" "AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY"
lazy_command "gcloud" "GOOGLE_APPLICATION_CREDENTIALS"
lazy_command "az" "AZURE_CREDENTIALS"

# ============================================================================
# Directory-Triggered Loading
# ============================================================================
# Load variables automatically when entering specific directories

# Project directories
lazy_directory "$HOME/work/project-a" "API_KEY,DATABASE_URL"
lazy_directory "$HOME/work/project-b" "API_KEY,DATABASE_URL"

# Environment directories
lazy_directory "$HOME/work/myapp/production" "DATABASE_URL,REDIS_URL,API_SECRET"
lazy_directory "$HOME/work/myapp/staging" "DATABASE_URL,REDIS_URL,API_SECRET"

# Pattern-based directory triggers
lazy_directory_pattern ".*/terraform/.*" "TF_TOKEN,AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY"
lazy_directory_pattern ".*/k8s/.*" "KUBE_TOKEN,KUBE_CONFIG"
lazy_directory_pattern ".*/projects/.*" "API_KEY"

# ============================================================================
# Alternative Secret Sources
# ============================================================================
# Examples using different secret management tools

# macOS Keychain (instead of 1Password)
# lazy_var "GITHUB_TOKEN" "security find-generic-password -s github-token -w"
# lazy_var "OPENAI_API_KEY" "security find-generic-password -s openai-api-key -w"

# AWS Systems Manager Parameter Store
# lazy_var "DATABASE_URL" "aws ssm get-parameter --name /myapp/db-url --with-decryption --query Parameter.Value --output text"
# lazy_var "API_KEY" "aws ssm get-parameter --name /myapp/api-key --with-decryption --query Parameter.Value --output text"

# AWS Secrets Manager
# lazy_var "DB_PASSWORD" "aws secretsmanager get-secret-value --secret-id prod/db-password --query SecretString --output text"

# HashiCorp Vault
# lazy_var "API_KEY" "vault kv get -field=value secret/myapp/api-key"

# Environment variable files (less secure, for development)
# lazy_var "API_KEY" "grep API_KEY ~/.env.local | cut -d= -f2"

# ============================================================================
# Utility Functions
# ============================================================================

# List all variables for current directory
list_vars() {
	echo "=== Variables for current directory ==="
	lazy_list_vars
}

# List all command mappings
list_commands() {
	echo "=== Command mappings ==="
	lazy_list_commands
}

# List all directory mappings
list_directories() {
	echo "=== Directory mappings ==="
	lazy_list_directories
}

# Test variable resolution for current directory
test_var() {
	if [[ -z "$1" ]]; then
		echo "Usage: test_var VARIABLE_NAME"
		return 1
	fi
	lazy_test_var "$1"
}

# Connect to database using loaded credentials
db_connect() {
	if [[ -z "$DATABASE_URL" ]]; then
		lazy_load "DATABASE_URL"
	fi
	psql "$DATABASE_URL"
}

# Example function that uses multiple secrets
deploy_to_prod() {
	echo "Deploying to production..."
	lazy_load "DATABASE_URL"
	lazy_load "API_SECRET"
	lazy_load "STRIPE_SECRET_KEY"

	# Your deployment commands here
	echo "DATABASE_URL: ${DATABASE_URL:0:20}..."
	echo "API_SECRET: ${API_SECRET:0:10}..."
	echo "STRIPE_SECRET_KEY: ${STRIPE_SECRET_KEY:0:10}..."
}

# ============================================================================
# Aliases
# ============================================================================

# GitHub API
alias gh-api='curl -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com'

# Terraform shortcuts
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'

# kubectl shortcuts
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
