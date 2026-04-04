#!/usr/bin/env bash

get_tmux_option() {
  local option="$1"
  local default_value="$2"
  local option_value="$(tmux show-option -gqv "$option" 2>/dev/null)"
  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

set_tmux_option() {
  local option="$1"
  local value="$2"
  tmux set-option -gq "${option}" "${value}"
}

# Load all tmux options in a single subprocess call.
# After calling this, use get_loaded_option instead of get_tmux_option.
_tmux_options_cache=""

load_all_tmux_options() {
  _tmux_options_cache="$(tmux show-options -g 2>/dev/null)"
}

get_loaded_option() {
  local key="$1" default="$2"
  local line
  while IFS= read -r line; do
    if [[ "$line" == "${key} "* ]]; then
      local val="${line#"${key} "}"
      # Strip surrounding quotes if present
      val="${val#\"}"
      val="${val%\"}"
      echo "$val"
      return
    fi
  done <<< "$_tmux_options_cache"
  echo "$default"
}

# Parse kubeconfig directly with awk instead of calling kubectl.
# Sets kube_context and kube_namespace variables.
parse_kubeconfig() {
  local kubeconfig="${KUBECONFIG%%:*}"
  kubeconfig="${kubeconfig:-$HOME/.kube/config}"
  [ -f "$kubeconfig" ] || return 1

  kube_context=$(awk '/^current-context:/ { sub(/^current-context: */, ""); print; exit }' "$kubeconfig")
  [ -z "$kube_context" ] && return 1

  kube_namespace=$(awk -v ctx="$kube_context" '
    /^contexts:/ { in_contexts=1; next }
    in_contexts && /^[^ -]/ {
      if (name == ctx) { print ns; found=1 }
      exit
    }
    in_contexts && /^- / {
      if (name == ctx) { print ns; found=1; exit }
      name=""; ns=""
    }
    in_contexts && /    namespace:/ { sub(/.*namespace: */, ""); ns=$0 }
    in_contexts && /  name:/ { sub(/.*name: */, ""); name=$0 }
    END { if (!found && name == ctx) print ns }
  ' "$kubeconfig")
}

