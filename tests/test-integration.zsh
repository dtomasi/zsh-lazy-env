#!/usr/bin/env zsh
#
# Integration Tests for Complex Scenarios
# Tests real-world usage patterns and complex interactions
#

# Source test framework and plugin
source "$(dirname "$0")/test-framework.zsh"
source "$(dirname "$0")/../lazy-env.plugin.zsh"

test_suite "Integration - Multi-Project Workflow"

test_start "complete client project setup"
	test_setup

	# Simulate real client project structure
	local client_a="$LAZY_ENV_TEST_DIR/clients/acme-corp"
	local client_b="$LAZY_ENV_TEST_DIR/clients/globex-inc"
	mkdir -p "$client_a" "$client_b"

	# Global fallback
	lazy_var "API_KEY" "echo 'global-api-fallback'"
	lazy_var "DATABASE_URL" "echo 'postgresql://localhost:5432/default'"

	# Client-specific overrides
	lazy_var "API_KEY" "echo 'acme-api-key-xyz123'" "$client_a"
	lazy_var "DATABASE_URL" "echo 'postgresql://acme-db:5432/acme'" "$client_a"

	lazy_var "API_KEY" "echo 'globex-api-key-abc789'" "$client_b"
	lazy_var "DATABASE_URL" "echo 'postgresql://globex-db:5432/globex'" "$client_b"

	# Pattern-based client secrets
	lazy_var "CLIENT_SECRET" "echo 'universal-client-secret'" "pattern:.*/clients/.*"

	# Test client A
	lazy_load "API_KEY" "$client_a"
	lazy_load "DATABASE_URL" "$client_a"
	lazy_load "CLIENT_SECRET" "$client_a"

	assert_equals "acme-api-key-xyz123" "$API_KEY" "Should load ACME API key"
	assert_equals "postgresql://acme-db:5432/acme" "$DATABASE_URL" "Should load ACME database URL"
	assert_equals "universal-client-secret" "$CLIENT_SECRET" "Should load universal client secret"

	# Test client B
	lazy_load "API_KEY" "$client_b"
	lazy_load "DATABASE_URL" "$client_b"
	lazy_load "CLIENT_SECRET" "$client_b"

	assert_equals "globex-api-key-abc789" "$API_KEY" "Should load Globex API key"
	assert_equals "postgresql://globex-db:5432/globex" "$DATABASE_URL" "Should load Globex database URL"
	assert_equals "universal-client-secret" "$CLIENT_SECRET" "Should load universal client secret"

	# Test outside clients (global fallback)
	lazy_load "API_KEY" "/tmp/other"
	lazy_load "DATABASE_URL" "/tmp/other"
	lazy_load "CLIENT_SECRET" "/tmp/other"

	assert_equals "global-api-fallback" "$API_KEY" "Should load global API fallback"
	assert_equals "postgresql://localhost:5432/default" "$DATABASE_URL" "Should load default database"
	assert_var_unset "CLIENT_SECRET" "Should not load client secret outside clients"

test_start "terraform multi-environment setup"
	test_setup

	# Environment directories
	local tf_prod="$LAZY_ENV_TEST_DIR/terraform/environments/production"
	local tf_staging="$LAZY_ENV_TEST_DIR/terraform/environments/staging"
	local tf_dev="$LAZY_ENV_TEST_DIR/terraform/environments/development"
	mkdir -p "$tf_prod" "$tf_staging" "$tf_dev"

	# Global terraform token
	lazy_var "TF_TOKEN" "echo 'terraform-cloud-token'"

	# Environment-specific variables
	lazy_var "AWS_PROFILE" "echo 'production'" "$tf_prod"
	lazy_var "DATABASE_PASSWORD" "echo 'prod-super-secret'" "$tf_prod"

	lazy_var "AWS_PROFILE" "echo 'staging'" "$tf_staging"
	lazy_var "DATABASE_PASSWORD" "echo 'staging-secret'" "$tf_staging"

	lazy_var "AWS_PROFILE" "echo 'development'" "$tf_dev"
	lazy_var "DATABASE_PASSWORD" "echo 'dev-password'" "$tf_dev"

	# Pattern-based terraform vars
	lazy_var "TF_LOG" "echo 'DEBUG'" "pattern:.*/terraform/.*"
	lazy_var "TF_PLUGIN_CACHE_DIR" "echo '/tmp/terraform-cache'" "pattern:.*/terraform/.*"

	# Test production environment
	lazy_load "TF_TOKEN" "$tf_prod"
	lazy_load "AWS_PROFILE" "$tf_prod"
	lazy_load "DATABASE_PASSWORD" "$tf_prod"
	lazy_load "TF_LOG" "$tf_prod"

	assert_equals "terraform-cloud-token" "$TF_TOKEN" "Should load global TF token"
	assert_equals "production" "$AWS_PROFILE" "Should load production AWS profile"
	assert_equals "prod-super-secret" "$DATABASE_PASSWORD" "Should load production DB password"
	assert_equals "DEBUG" "$TF_LOG" "Should load terraform debug logging"

	# Test staging environment
	lazy_load "AWS_PROFILE" "$tf_staging"
	lazy_load "DATABASE_PASSWORD" "$tf_staging"

	assert_equals "staging" "$AWS_PROFILE" "Should load staging AWS profile"
	assert_equals "staging-secret" "$DATABASE_PASSWORD" "Should load staging DB password"

test_suite "Integration - Command-Driven Workflows"

test_start "devops tool chain integration"
	test_setup

	# Set up tools and their required variables
	lazy_var "KUBERNETES_TOKEN" "echo 'k8s-cluster-token'"
	lazy_var "DOCKER_HUB_TOKEN" "echo 'docker-hub-secret'"
	lazy_var "GITHUB_TOKEN" "echo 'github-personal-token'"
	lazy_var "GITLAB_TOKEN" "echo 'gitlab-deploy-token'"

	# Command mappings
	lazy_command "kubectl" "KUBERNETES_TOKEN"
	lazy_command "docker push" "DOCKER_HUB_TOKEN"
	lazy_command "pattern:^git push.*github\.com" "GITHUB_TOKEN"
	lazy_command "pattern:^git push.*gitlab\.com" "GITLAB_TOKEN"

	# Test kubernetes workflow
	_lazy_env_preexec "kubectl get pods -n production"
	assert_equals "k8s-cluster-token" "$KUBERNETES_TOKEN" "Should load k8s token for kubectl"

	# Test docker workflow
	_lazy_env_preexec "docker push myregistry/myapp:latest"
	assert_equals "docker-hub-secret" "$DOCKER_HUB_TOKEN" "Should load docker token for push"

	# Test git workflows
	_lazy_env_preexec "git push origin main https://github.com/user/repo.git"
	assert_equals "github-personal-token" "$GITHUB_TOKEN" "Should load GitHub token for git push"

	_lazy_env_preexec "git push origin develop https://gitlab.com/group/project.git"
	assert_equals "gitlab-deploy-token" "$GITLAB_TOKEN" "Should load GitLab token for git push"

test_start "ci/cd pipeline simulation"
	test_setup

	# Pipeline stages need different secrets
	lazy_var "BUILD_TOKEN" "echo 'build-stage-token'"
	lazy_var "TEST_DATABASE_URL" "echo 'postgresql://test-db:5432/test'"
	lazy_var "DEPLOY_TOKEN" "echo 'deploy-stage-token'"
	lazy_var "MONITORING_TOKEN" "echo 'monitoring-api-token'"

	# Command mappings for pipeline stages
	lazy_command "npm run build" "BUILD_TOKEN"
	lazy_command "npm test" "TEST_DATABASE_URL"
	lazy_command "npm run test:e2e" "TEST_DATABASE_URL"
	lazy_command "pattern:^terraform apply" "DEPLOY_TOKEN"
	lazy_command "pattern:^kubectl apply" "DEPLOY_TOKEN"
	lazy_command "datadog-ci" "MONITORING_TOKEN"

	# Simulate pipeline execution
	_lazy_env_preexec "npm run build"
	assert_equals "build-stage-token" "$BUILD_TOKEN" "Should load build token"

	_lazy_env_preexec "npm test"
	assert_equals "postgresql://test-db:5432/test" "$TEST_DATABASE_URL" "Should load test database"

	_lazy_env_preexec "terraform apply -auto-approve"
	assert_equals "deploy-stage-token" "$DEPLOY_TOKEN" "Should load deploy token for terraform"

	_lazy_env_preexec "kubectl apply -f k8s/production.yaml"
	assert_equals "deploy-stage-token" "$DEPLOY_TOKEN" "Should load deploy token for kubectl"

	_lazy_env_preexec "datadog-ci metric send --metric-name deployment.success"
	assert_equals "monitoring-api-token" "$MONITORING_TOKEN" "Should load monitoring token"

test_suite "Integration - Directory Switching Scenarios"

test_start "developer daily workflow simulation"
	test_setup

	# Create realistic project structure
	local work_dir="$LAZY_ENV_TEST_DIR/work"
	local project1="$work_dir/microservice-auth"
	local project2="$work_dir/microservice-payment"
	local infra="$work_dir/infrastructure/terraform"
	mkdir -p "$project1" "$project2" "$infra"

	# Global development tools
	lazy_var "EDITOR_TOKEN" "echo 'editor-integration-token'"

	# Project-specific configurations
	lazy_var "DATABASE_URL" "echo 'postgresql://auth-db:5432/auth'" "$project1"
	lazy_var "REDIS_URL" "echo 'redis://auth-redis:6379/0'" "$project1"
	lazy_var "SERVICE_PORT" "echo '3001'" "$project1"

	lazy_var "DATABASE_URL" "echo 'postgresql://payment-db:5432/payment'" "$project2"
	lazy_var "REDIS_URL" "echo 'redis://payment-redis:6379/1'" "$project2"
	lazy_var "SERVICE_PORT" "echo '3002'" "$project2"

	# Infrastructure secrets
	lazy_var "AWS_ACCESS_KEY" "echo 'infra-aws-key'" "$infra"
	lazy_var "TF_VAR_db_password" "echo 'terraform-db-secret'" "$infra"

	# Pattern-based variables
	lazy_var "NODE_ENV" "echo 'development'" "pattern:.*/microservice-.*"
	lazy_var "LOG_LEVEL" "echo 'debug'" "pattern:.*/microservice-.*"

	# Test switching between projects

	# Work on auth service
	lazy_load "DATABASE_URL" "$project1"
	lazy_load "SERVICE_PORT" "$project1"
	lazy_load "NODE_ENV" "$project1"

	assert_equals "postgresql://auth-db:5432/auth" "$DATABASE_URL" "Should load auth database"
	assert_equals "3001" "$SERVICE_PORT" "Should load auth service port"
	assert_equals "development" "$NODE_ENV" "Should load development environment"

	# Switch to payment service
	lazy_load "DATABASE_URL" "$project2"
	lazy_load "SERVICE_PORT" "$project2"
	lazy_load "NODE_ENV" "$project2"

	assert_equals "postgresql://payment-db:5432/payment" "$DATABASE_URL" "Should load payment database"
	assert_equals "3002" "$SERVICE_PORT" "Should load payment service port"
	assert_equals "development" "$NODE_ENV" "Should still be development"

	# Switch to infrastructure work
	lazy_load "AWS_ACCESS_KEY" "$infra"
	lazy_load "TF_VAR_db_password" "$infra"
	lazy_load "NODE_ENV" "$infra"

	assert_equals "infra-aws-key" "$AWS_ACCESS_KEY" "Should load AWS key for infrastructure"
	assert_equals "terraform-db-secret" "$TF_VAR_db_password" "Should load terraform variable"
	assert_var_unset "NODE_ENV" "Should not load Node.js env for infrastructure"

test_start "monorepo with mixed technologies"
	test_setup

	# Monorepo structure
	local monorepo="$LAZY_ENV_TEST_DIR/monorepo"
	local frontend="$monorepo/packages/frontend"
	local backend="$monorepo/packages/backend"
	local mobile="$monorepo/packages/mobile"
	local shared="$monorepo/packages/shared"
	mkdir -p "$frontend" "$backend" "$mobile" "$shared"

	# Global monorepo settings
	lazy_var "WORKSPACE_ROOT" "echo '$monorepo'"

	# Technology-specific variables
	lazy_var "NODE_ENV" "echo 'development'" "pattern:.*/packages/(frontend|backend)/.*"
	lazy_var "API_BASE_URL" "echo 'http://localhost:3000'" "pattern:.*/packages/frontend.*"
	lazy_var "DATABASE_URL" "echo 'postgresql://mono-db:5432/app'" "pattern:.*/packages/backend.*"
	lazy_var "REACT_NATIVE_PACKAGER_HOSTNAME" "echo '192.168.1.100'" "pattern:.*/packages/mobile.*"

	# Package-specific overrides
	lazy_var "PORT" "echo '3000'" "$backend"
	lazy_var "REACT_APP_API_URL" "echo 'http://localhost:3000/api'" "$frontend"
	lazy_var "METRO_PORT" "echo '8081'" "$mobile"

	# Test each package environment

	# Frontend development
	lazy_load "NODE_ENV" "$frontend"
	lazy_load "API_BASE_URL" "$frontend"
	lazy_load "REACT_APP_API_URL" "$frontend"

	assert_equals "development" "$NODE_ENV" "Should set Node environment for frontend"
	assert_equals "http://localhost:3000" "$API_BASE_URL" "Should set API base URL"
	assert_equals "http://localhost:3000/api" "$REACT_APP_API_URL" "Should set React app API URL"

	# Backend development
	lazy_load "NODE_ENV" "$backend"
	lazy_load "DATABASE_URL" "$backend"
	lazy_load "PORT" "$backend"

	assert_equals "development" "$NODE_ENV" "Should set Node environment for backend"
	assert_equals "postgresql://mono-db:5432/app" "$DATABASE_URL" "Should set database URL"
	assert_equals "3000" "$PORT" "Should set backend port"

	# Mobile development
	lazy_load "REACT_NATIVE_PACKAGER_HOSTNAME" "$mobile"
	lazy_load "METRO_PORT" "$mobile"
	lazy_load "NODE_ENV" "$mobile"

	assert_equals "192.168.1.100" "$REACT_NATIVE_PACKAGER_HOSTNAME" "Should set packager hostname"
	assert_equals "8081" "$METRO_PORT" "Should set Metro port"
	assert_var_unset "NODE_ENV" "Should not set Node environment for mobile"

test_suite "Integration - Real-World Command Patterns"

test_start "1password integration simulation"
	test_setup

	# Simulate 1Password CLI integration
	lazy_var "GITHUB_TOKEN" "echo 'op://Personal/GitHub/credential'"
	lazy_var "AWS_ACCESS_KEY" "echo 'op://Work/AWS/access-key'"
	lazy_var "DATABASE_PASSWORD" "echo 'op://Project/Database/password'"

	# Different vaults for different projects
	lazy_var "GITHUB_TOKEN" "echo 'op://ClientA/GitHub/token'" "$LAZY_ENV_TEST_DIR/client-a"
	lazy_var "AWS_ACCESS_KEY" "echo 'op://ClientA/AWS/key'" "$LAZY_ENV_TEST_DIR/client-a"

	# Command patterns that trigger loading
	lazy_command "pattern:^git (push|pull|fetch).*" "GITHUB_TOKEN"
	lazy_command "pattern:^aws .*" "AWS_ACCESS_KEY"
	lazy_command "psql" "DATABASE_PASSWORD"

	# Test global context
	_lazy_env_preexec "git push origin main"
	assert_equals "op://Personal/GitHub/credential" "$GITHUB_TOKEN" "Should load personal GitHub token"

	_lazy_env_preexec "aws s3 ls"
	assert_equals "op://Work/AWS/access-key" "$AWS_ACCESS_KEY" "Should load work AWS key"

	# Test client context
	_lazy_env_preexec "git push origin feature-branch" "$LAZY_ENV_TEST_DIR/client-a"
	_lazy_load_variable "GITHUB_TOKEN" "$LAZY_ENV_TEST_DIR/client-a"
	assert_equals "op://ClientA/GitHub/token" "$GITHUB_TOKEN" "Should load client-specific GitHub token"

test_start "docker and kubernetes workflow"
	test_setup

	# Different registries and clusters
	lazy_var "DOCKER_REGISTRY_TOKEN" "echo 'docker-hub-token'"
	lazy_var "KUBERNETES_CONFIG" "echo '~/.kube/config'"
	lazy_var "HELM_REPOSITORY_PASSWORD" "echo 'helm-repo-secret'"

	# Environment-specific overrides
	local k8s_prod="$LAZY_ENV_TEST_DIR/k8s/production"
	local k8s_staging="$LAZY_ENV_TEST_DIR/k8s/staging"
	mkdir -p "$k8s_prod" "$k8s_staging"

	lazy_var "KUBERNETES_CONFIG" "echo '~/.kube/prod-config'" "$k8s_prod"
	lazy_var "HELM_NAMESPACE" "echo 'production'" "$k8s_prod"

	lazy_var "KUBERNETES_CONFIG" "echo '~/.kube/staging-config'" "$k8s_staging"
	lazy_var "HELM_NAMESPACE" "echo 'staging'" "$k8s_staging"

	# Command mappings
	lazy_command "docker login" "DOCKER_REGISTRY_TOKEN"
	lazy_command "docker push" "DOCKER_REGISTRY_TOKEN"
	lazy_command "pattern:^kubectl .*" "KUBERNETES_CONFIG"
	lazy_command "pattern:^helm .*" "HELM_REPOSITORY_PASSWORD,HELM_NAMESPACE"

	# Test docker workflow
	_lazy_env_preexec "docker login"
	assert_equals "docker-hub-token" "$DOCKER_REGISTRY_TOKEN" "Should load docker registry token"

	# Test kubernetes production
	_lazy_env_preexec "kubectl get pods -n production" "$k8s_prod"
	_lazy_load_variable "KUBERNETES_CONFIG" "$k8s_prod"
	_lazy_load_variable "HELM_NAMESPACE" "$k8s_prod"

	assert_equals "~/.kube/prod-config" "$KUBERNETES_CONFIG" "Should load production k8s config"
	assert_equals "production" "$HELM_NAMESPACE" "Should set production namespace"

	# Test helm in staging
	_lazy_env_preexec "helm upgrade myapp ./chart" "$k8s_staging"
	_lazy_load_variable "KUBERNETES_CONFIG" "$k8s_staging"
	_lazy_load_variable "HELM_NAMESPACE" "$k8s_staging"

	assert_equals "~/.kube/staging-config" "$KUBERNETES_CONFIG" "Should load staging k8s config"
	assert_equals "staging" "$HELM_NAMESPACE" "Should set staging namespace"

test_suite "Integration - Performance and Reliability"

test_start "high-frequency command execution"
	test_setup

	lazy_var "FREQUENT_VAR" "echo 'frequently-used-value'"
	lazy_command "ls" "FREQUENT_VAR"

	# Simulate many command executions
	for i in {1..20}; do
		_lazy_env_preexec "ls -la /tmp"
	done

	# Should only load once
	assert_equals "frequently-used-value" "$FREQUENT_VAR" "Should load variable"
	assert_equals "success" "${LOADED_VARS[FREQUENT_VAR]}" "Should be marked as loaded"

test_start "complex pattern matching performance"
	test_setup

	# Set up many patterns
	for i in {1..10}; do
		lazy_var "PATTERN_VAR_$i" "echo 'pattern-$i-value'"
		lazy_command "pattern:pattern_$i.*complex.*regex.*test" "PATTERN_VAR_$i"
	done

	# Test that the last pattern still works
	_lazy_env_preexec "pattern_10_with_complex_regex_test_command"
	assert_equals "pattern-10-value" "$PATTERN_VAR_10" "Should match complex patterns efficiently"

test_start "memory usage with many variables"
	test_setup

	# Create many scoped variables
	for i in {1..50}; do
		local test_dir="$LAZY_ENV_TEST_DIR/test-$i"
		mkdir -p "$test_dir"
		lazy_var "TEST_VAR_$i" "echo 'test-value-$i'" "$test_dir"
	done

	# Test that listing still works efficiently
	local output
	output=$(lazy_list_vars)
	assert_contains "$output" "TEST_VAR_1" "Should handle many variables efficiently"
	assert_contains "$output" "TEST_VAR_50" "Should list all variables"

# Run the tests if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "${(%):-%x}" == "${0}" ]]; then
	test_init
	# Tests are automatically run when sourced due to the way zsh processes the file
	test_results
fi
