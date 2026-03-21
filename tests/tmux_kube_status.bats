#!/usr/bin/env bats

setup() {
  source "${BATS_TEST_DIRNAME}/../scripts/helpers.sh"
  # Source functions from tmux_kube_status.sh (main guard prevents execution)
  source "${BATS_TEST_DIRNAME}/../scripts/tmux_kube_status.sh"

  # Set defaults that the main block normally sets
  _tmux_options_cache=""
  empty_context_string="-"
  context_max_length="20"
  namespace_max_length="20"

  prod_pattern='.*prod.*'
  stg_pattern='.*stg.*|.*stage.*'
  test_pattern='.*test.*'
  dev_pattern='.*dev.*'

  format_default='#[fg=colour255,bg=colour27]'
  format_dev='#[fg=colour255,bg=colour27]'
  format_test='#[fg=colour255,bg=colour28]'
  format_stg='#[fg=colour255,bg=colour136]'
  format_prod='#[fg=colour255,bg=colour200]'
  icon_default='⎈'
  icon_dev='⎈'
  icon_test='⎈'
  icon_stg='⎈'
  icon_prod='⎈'

  TEST_TMPDIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# ============================================================
# get_cutoff_string
# ============================================================

@test "get_cutoff_string: returns original when shorter than max" {
  local result=$(get_cutoff_string 20 "short")
  [ "$result" = "short" ]
}

@test "get_cutoff_string: truncates and adds ellipsis" {
  local result=$(get_cutoff_string 5 "abcdefghij")
  [ "$result" = "abcde…" ]
}

@test "get_cutoff_string: returns original when exact length" {
  local result=$(get_cutoff_string 5 "abcde")
  [ "$result" = "abcde" ]
}

@test "get_cutoff_string: max_length 0 returns full string" {
  local result=$(get_cutoff_string 0 "anything")
  [ "$result" = "anything" ]
}

@test "get_cutoff_string: returns default when no value given" {
  local result=$(get_cutoff_string 20)
  [ "$result" = "-" ]
}

@test "get_cutoff_string: rejects non-integer max_length" {
  local result=$(get_cutoff_string "abc" "test")
  [ "$result" = "max_length needs to be an integer." ]
}

# ============================================================
# get_context_env
# ============================================================

@test "get_context_env: detects prod" {
  kube_context="my-prod-cluster"
  local result=$(get_context_env)
  [ "$result" = "prod" ]
}

@test "get_context_env: detects stg" {
  kube_context="my-stg-cluster"
  local result=$(get_context_env)
  [ "$result" = "stg" ]
}

@test "get_context_env: detects stage" {
  kube_context="my-stage-cluster"
  local result=$(get_context_env)
  [ "$result" = "stg" ]
}

@test "get_context_env: detects test" {
  kube_context="my-test-cluster"
  local result=$(get_context_env)
  [ "$result" = "test" ]
}

@test "get_context_env: detects dev" {
  kube_context="my-dev-cluster"
  local result=$(get_context_env)
  [ "$result" = "dev" ]
}

@test "get_context_env: returns default for unknown" {
  kube_context="my-cluster"
  local result=$(get_context_env)
  [ "$result" = "default" ]
}

@test "get_context_env: prod takes priority over dev" {
  kube_context="dev-prod-cluster"
  local result=$(get_context_env)
  [ "$result" = "prod" ]
}

# ============================================================
# get_output
# ============================================================

@test "get_output: formats context and namespace" {
  local result=$(get_output "dev" "my-ctx" "my-ns")
  [[ "$result" == *"⎈ my-ctx:my-ns"* ]]
}

@test "get_output: hides namespace section when empty (shows default marker)" {
  local result=$(get_output "dev" "my-ctx" "")
  # When namespace is empty, get_cutoff_string returns the empty_context_string "-"
  # which get_output detects and hides the namespace section entirely
  [[ "$result" == *"⎈ my-ctx "* ]]
  [[ "$result" != *":"* ]]
}

@test "get_output: uses correct format for each env" {
  local result=$(get_output "prod" "ctx" "ns")
  [[ "$result" == "#[fg=colour255,bg=colour200]"* ]]
}
