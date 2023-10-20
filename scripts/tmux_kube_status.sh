#!/usr/bin/env bash

script_dir=$(dirname "$0")
source ${script_dir}/helpers.sh

format_default=$(get_tmux_option '@kube-status-format-default' '#[fg=colour255,bg=colour27]')
format_dev=$(get_tmux_option '@kube-status-format-dev' '#[fg=colour255,bg=colour27]')
format_test=$(get_tmux_option '@kube-status-format-test' '#[fg=colour255,bg=colour28]')
format_stg=$(get_tmux_option '@kube-status-format-stage' '#[fg=colour255,bg=colour136]')
format_prod=$(get_tmux_option '@kube-status-format-prod' '#[fg=colour255,bg=colour200]')

icon_default=$(get_tmux_option '@kube-status-icon-default' '⎈')
icon_dev=$(get_tmux_option '@kube-status-icon-dev' '⎈')
icon_test=$(get_tmux_option '@kube-status-icon-test' '⎈')
icon_stg=$(get_tmux_option '@kube-status-icon-stage' '⎈')
icon_prod=$(get_tmux_option '@kube-status-icon-prod' '⎈')

context_max_length=$(get_tmux_option '@kube-status-context-max-length' '20')
namespace_max_length=$(get_tmux_option '@kube-status-namespace-max-length' '20')
empty_context_string=$(get_tmux_option '@kube-status-empty-context-string' '-')

kube_context=""
kube_namespace=""

debug_print() {
  # show the 256 colors
  if [ "${1}" == "1" ]; then
    for num in {0..255}; do printf "%s\033[38;5;${num}mcolour${num}\033[0m \t"; [ $(expr $((num+1)) % 8) -eq 0 ] && printf "\n"; done
  fi

  printf "$(get_output "dev" "dev-env" "namespace")\n"
  printf "$(get_output "test" "test-env" "namespace")\n"
  printf "$(get_output "stg" "stg-env" "namespace")\n"
  printf "$(get_output "prod" "prod-env" "namespace")\n"
  printf "$(get_output "default" "default-env" "namespace")\n"

  printf "$(get_output "dev" "" "")\n"
  printf "$(get_output "dev" "context-only" "")\n"
  printf "$(get_output "dev" "long-context-name-abcdefghijklmnopqrstuvwxyz0123456789" "dev")\n"
  printf "$(get_output "dev" "context" "long-namespace-abcdefghijklmnopqrstuvwxyz0123456789")\n"
  printf "$(get_output "dev" "long-context-name-abcdefghijklmnopqrstuvwxyz0123456789" "long-namespace-abcdefghijklmnopqrstuvwxyz0123456789")\n"

  printf "$(get_output $(get_context_env) $(get_kube_context) $(get_kube_namespace))"
}

get_kube_context() {
  if [ -n "${kube_context}" ]; then
    echo ${kube_context}
  else
    [ -x "$(command -v kubectl)" ] || return 0
    kube_context=$(kubectl config current-context)
    echo ${kube_context}
  fi
}

get_kube_namespace() {
  if [ -n "${kube_namespace}" ]; then
    echo ${kube_namespace}
  else
    [ -x "$(command -v kubectl)" ] || return 0
    kube_namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    echo ${kube_namespace}
  fi
}

get_context_env() {
  local kube_context=$(get_kube_context)
  local prod_pattern=$(get_tmux_option '@kube-status-prod-pattern' '.*prod.*')
  local stg_pattern=$(get_tmux_option '@kube-status-stg-pattern' '.*stg.*|.*stage.*')
  local test_pattern=$(get_tmux_option '@kube-status-test-pattern' '.*test.*')
  local dev_pattern=$(get_tmux_option '@kube-status-dev-pattern' '.*dev.*')

  if [[ $kube_context =~ $prod_pattern ]]; then
    echo "prod"
  elif [[ $kube_context =~ $stg_pattern ]]; then
    echo "stg"
  elif [[ $kube_context =~ $test_pattern ]]; then
    echo "test"
  elif [[ $kube_context =~ $test_pattern ]]; then
    echo "dev"
  else
    echo "default"
  fi
}

get_cutoff_string() {
  local max_length=${1}
  local original=${2:-"${empty_context_string}"}

  if [ -z "${max_length}" ] || ! [[ "${max_length}" =~ ^[0-9]+$ ]]; then
    echo "max_length needs to be an integer."
    return
  fi
  if [ ${max_length} -eq 0 ]; then
    echo $original
    return
  fi

  local cut_string="${original:0:$max_length}"
  [ "${#cut_string}" -eq "${max_length}" ] && [ "${cut_string}" != "${original}" ] && cut_string+="…"

  echo ${cut_string}
}

get_output() {
  local env=${1}
  local context=$(get_cutoff_string ${context_max_length} ${2})
  local namespace=$(get_cutoff_string ${namespace_max_length} ${3})
  if [[ "${namespace}" == "${empty_context_string}" ]]; then
    namespace=""
  else
    namespace=":$namespace"
  fi
  local format_variable="format_${env}"
  local icon_variable="icon_${env}"
  echo "${!format_variable} ${!icon_variable} ${context}${namespace} #[default]"
}

for arg in "$@"; do
  case "$arg" in
    --debug)
      debug_print
      exit 0
      ;;
    --debug-with-color-code)
      debug_print 1
      exit 0
      ;;
  esac
done

echo -e $(get_output $(get_context_env) $(get_kube_context) $(get_kube_namespace))

