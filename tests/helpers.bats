#!/usr/bin/env bats

setup() {
  source "${BATS_TEST_DIRNAME}/../scripts/helpers.sh"
  TEST_TMPDIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# ============================================================
# parse_kubeconfig
# ============================================================

create_kubeconfig() {
  local ctx="${1:-my-context}"
  local ns="${2:-my-namespace}"
  local file="${TEST_TMPDIR}/kubeconfig_${ctx}"
  cat > "$file" <<EOF
apiVersion: v1
kind: Config
current-context: ${ctx}
contexts:
- context:
    cluster: my-cluster
    namespace: ${ns}
    user: my-user
  name: ${ctx}
EOF
  echo "$file"
}

@test "parse_kubeconfig: extracts context and namespace" {
  local f=$(create_kubeconfig "dev-cluster" "app-ns")
  export KUBECONFIG="$f"
  parse_kubeconfig
  [ "$kube_context" = "dev-cluster" ]
  [ "$kube_namespace" = "app-ns" ]
}

@test "parse_kubeconfig: handles missing namespace" {
  local file="${TEST_TMPDIR}/kubeconfig"
  cat > "$file" <<'EOF'
apiVersion: v1
kind: Config
current-context: no-ns-ctx
contexts:
- context:
    cluster: my-cluster
    user: my-user
  name: no-ns-ctx
EOF
  export KUBECONFIG="$file"
  parse_kubeconfig
  [ "$kube_context" = "no-ns-ctx" ]
  [ "$kube_namespace" = "" ]
}

@test "parse_kubeconfig: selects correct context from multiple" {
  local file="${TEST_TMPDIR}/kubeconfig"
  cat > "$file" <<'EOF'
apiVersion: v1
kind: Config
current-context: ctx-b
contexts:
- context:
    cluster: cluster-a
    namespace: ns-a
    user: user-a
  name: ctx-a
- context:
    cluster: cluster-b
    namespace: ns-b
    user: user-b
  name: ctx-b
- context:
    cluster: cluster-c
    namespace: ns-c
    user: user-c
  name: ctx-c
EOF
  export KUBECONFIG="$file"
  parse_kubeconfig
  [ "$kube_context" = "ctx-b" ]
  [ "$kube_namespace" = "ns-b" ]
}

@test "parse_kubeconfig: returns error when file does not exist" {
  export KUBECONFIG="${TEST_TMPDIR}/nonexistent"
  run parse_kubeconfig
  [ "$status" -eq 1 ]
}

@test "parse_kubeconfig: returns error when no current-context" {
  local file="${TEST_TMPDIR}/kubeconfig"
  cat > "$file" <<'EOF'
apiVersion: v1
kind: Config
contexts:
- context:
    cluster: my-cluster
  name: my-ctx
EOF
  export KUBECONFIG="$file"
  run parse_kubeconfig
  [ "$status" -eq 1 ]
}

@test "parse_kubeconfig: uses first file from colon-separated KUBECONFIG" {
  local f1=$(create_kubeconfig "first-ctx" "first-ns")
  local f2=$(create_kubeconfig "second-ctx" "second-ns")
  export KUBECONFIG="${f1}:${f2}"
  parse_kubeconfig
  [ "$kube_context" = "first-ctx" ]
  [ "$kube_namespace" = "first-ns" ]
}

@test "parse_kubeconfig: last context in file (no trailing section)" {
  local file="${TEST_TMPDIR}/kubeconfig"
  cat > "$file" <<'EOF'
apiVersion: v1
kind: Config
current-context: only-ctx
contexts:
- context:
    cluster: my-cluster
    namespace: my-ns
    user: my-user
  name: only-ctx
EOF
  export KUBECONFIG="$file"
  parse_kubeconfig
  [ "$kube_context" = "only-ctx" ]
  [ "$kube_namespace" = "my-ns" ]
}

# ============================================================
# get_loaded_option
# ============================================================

@test "get_loaded_option: returns value from cache" {
  _tmux_options_cache='@kube-status-icon-dev "★"'
  local result=$(get_loaded_option '@kube-status-icon-dev' 'default')
  [ "$result" = "★" ]
}

@test "get_loaded_option: returns default when key not found" {
  _tmux_options_cache='@kube-status-format-dev "#[fg=colour255]"'
  local result=$(get_loaded_option '@kube-status-nonexistent' 'fallback')
  [ "$result" = "fallback" ]
}

@test "get_loaded_option: returns default when cache is empty" {
  _tmux_options_cache=""
  local result=$(get_loaded_option '@kube-status-icon-dev' 'default-icon')
  [ "$result" = "default-icon" ]
}

@test "get_loaded_option: handles unquoted values" {
  _tmux_options_cache='@kube-status-context-max-length 25'
  local result=$(get_loaded_option '@kube-status-context-max-length' '20')
  [ "$result" = "25" ]
}

@test "get_loaded_option: does not match partial key names" {
  _tmux_options_cache='@kube-status-icon-dev-extra "wrong"
@kube-status-icon-dev "correct"'
  local result=$(get_loaded_option '@kube-status-icon-dev' 'default')
  [ "$result" = "correct" ]
}
