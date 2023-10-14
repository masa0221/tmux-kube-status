#!/usr/bin/env bash

script_dir=$(dirname "$0")
source ${script_dir}/helpers.sh

format_dev=$(get_tmux_option '@kube-status-format-dev' '#[fg=colour255,bg=colour27]')
format_test=$(get_tmux_option '@kube-status-format-test' '#[fg=colour255,bg=colour28]')
format_stg=$(get_tmux_option '@kube-status-format-stage' '#[fg=colour255,bg=colour136]')
format_prod=$(get_tmux_option '@kube-status-format-prod' '#[fg=colour255,bg=colour200]')

context_cutoff_length=$(get_tmux_option '@kube-status-context-cutoff-length' '20')
empty_context_string=$(get_tmux_option '@kube-status-empty-context-string' '-')

kube_context=""

debug_print() {
  # show the 256 colors
  if [ "${1}" == "1" ]; then
    for num in {0..255}; do printf "%s\033[38;5;${num}mcolour${num}\033[0m \t"; [ $(expr $((num+1)) % 8) -eq 0 ] && printf "\n"; done
  fi

  printf "$(get_output "dev-env" "dev")\n"
  printf "$(get_output "test-env" "test")\n"
  printf "$(get_output "stg-env" "stg")\n"
  printf "$(get_output "prod-env" "prod")\n"

  printf "$(get_output "" "dev")\n"
  printf "$(get_output "long-context-name-abcdefghijklmnopqrstuvwxyz0123456789" "dev")\n"
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

get_context_env() {
  local kube_context=$(get_kube_context)
  local prod_pattern=$(get_tmux_option '@kube-status-prod-pattern' '.*prod.*')
  local stg_pattern=$(get_tmux_option '@kube-status-stg-pattern' '.*stg.*|.*stage.*')
  local test_pattern=$(get_tmux_option '@kube-status-test-pattern' '.*test.*')

  if [[ $kube_context =~ $prod_pattern ]]; then
    echo "prod"
  elif [[ $kube_context =~ $stg_pattern ]]; then
    echo "stg"
  elif [[ $kube_context =~ $test_pattern ]]; then
    echo "test"
  else
    echo "dev"
  fi
}

get_output_context_string() {
  local original=${1:-"${empty_context_string}"}

  if [ -z "${context_cutoff_length}" ] || ! [[ "${context_cutoff_length}" =~ ^[0-9]+$ ]]; then
    echo "context_cutoff_length needs to be an integer."
    return
  fi
  if [ ${context_cutoff_length} -eq 0 ]; then
    echo $original
    return
  fi

  local cut_string="${original:0:$context_cutoff_length}"
  [ "${#cut_string}" -eq "${context_cutoff_length}" ] && [ "${cut_string}" != "${original}" ] && cut_string+="..."

  echo ${cut_string}
}

get_output() {
  local context=$(get_output_context_string ${1})
  local env=${2}
  local format_variable="format_${env}"
  echo "${!format_variable} ⎈ ${context} #[default]"
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

echo -e $(get_output $(get_kube_context) $(get_context_env))

