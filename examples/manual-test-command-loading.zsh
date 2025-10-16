#!/usr/bin/env zsh
# Test script for command-triggered loading

# Source the plugin
source "$(dirname "$0")/lazy-env.plugin.zsh"

echo "=== Testing Command-Triggered Lazy Loading ==="
echo

# Register test variables
echo "Registering test variables..."
lazy_var "TEST_GITHUB_TOKEN" "echo 'fake-github-token-12345'"
lazy_var "TEST_DOCKER_TOKEN" "echo 'fake-docker-token-67890'"
lazy_var "TEST_GITLAB_TOKEN" "echo 'fake-gitlab-token-abcde'"

# Register command mappings
echo "Registering command mappings..."
lazy_command "gh" "TEST_GITHUB_TOKEN"
lazy_command "docker push" "TEST_DOCKER_TOKEN"
lazy_command_pattern "^git push .*github\.com" "TEST_GITHUB_TOKEN"
lazy_command_pattern "^git push .*gitlab\.com" "TEST_GITLAB_TOKEN"

echo
echo "=== Initial Status ==="
lazy_list_vars
echo

echo "=== Command Mappings ==="
lazy_list_vars
echo

echo "=== Testing Command Detection ==="
echo "1. Testing 'gh repo list':"
lazy_test_command "gh repo list"
echo

echo "2. Testing 'docker push myimage:latest':"
lazy_test_command "docker push myimage:latest"
echo

echo "3. Testing 'git push https://github.com/user/repo.git':"
lazy_test_command "git push https://github.com/user/repo.git"
echo

echo "4. Testing variable reference 'echo \$TEST_DOCKER_TOKEN':"
lazy_test_command "echo \$TEST_DOCKER_TOKEN"
echo

echo "=== Testing Actual Loading ==="
echo "Simulating: gh repo list"
_lazy_env_preexec "gh repo list"
echo "Status after gh command:"
lazy_list_vars | grep TEST_GITHUB_TOKEN
echo

echo "Simulating: git push https://gitlab.com/user/repo.git"
_lazy_env_preexec "git push https://gitlab.com/user/repo.git"
echo "Status after git push to GitLab:"
lazy_list_vars | grep TEST_GITLAB_TOKEN
echo

echo "Simulating: echo \$TEST_DOCKER_TOKEN"
_lazy_env_preexec "echo \$TEST_DOCKER_TOKEN"
echo "Status after variable reference:"
lazy_list_vars | grep TEST_DOCKER_TOKEN
echo

echo "=== Final Status ==="
lazy_list_vars
echo

echo "=== Command Mappings ==="
lazy_list_vars
echo

echo "=== Testing Command Detection ==="
echo "1. Testing 'gh repo list':"
lazy_test_command "gh repo list"
echo

echo "2. Testing 'docker push myimage:latest':"
lazy_test_command "docker push myimage:latest"
echo

echo "3. Testing 'git push https://github.com/user/repo.git':"
lazy_test_command "git push https://github.com/user/repo.git"
echo

echo "4. Testing variable reference 'echo \$TEST_DOCKER_TOKEN':"
lazy_test_command "echo \$TEST_DOCKER_TOKEN"
echo

echo "=== Testing Actual Loading ==="
echo "Simulating: gh repo list"
_lazy_env_preexec "gh repo list"
echo "Status after gh command:"
lazy_list_vars | grep TEST_GITHUB_TOKEN
echo

echo "Simulating: git push https://gitlab.com/user/repo.git"
_lazy_env_preexec "git push https://gitlab.com/user/repo.git"
echo "Status after git push to GitLab:"
lazy_list_vars | grep TEST_GITLAB_TOKEN
echo

echo "Simulating: echo \$TEST_DOCKER_TOKEN"
_lazy_env_preexec "echo \$TEST_DOCKER_TOKEN"
echo "Status after variable reference:"
lazy_list_vars | grep TEST_DOCKER_TOKEN
echo

echo "=== Final Status ==="
lazy_list_vars
echo

echo "=== Testing Loaded Values ==="
echo "TEST_GITHUB_TOKEN = '$TEST_GITHUB_TOKEN'"
echo "TEST_GITLAB_TOKEN = '$TEST_GITLAB_TOKEN'"
echo "TEST_DOCKER_TOKEN = '$TEST_DOCKER_TOKEN'"
echo

echo "✅ All tests completed!"