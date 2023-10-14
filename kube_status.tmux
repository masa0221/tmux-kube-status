#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "$0" )" && pwd )"

source "${CURRENT_DIR}/scripts/helpers.sh"

kube_status="#(${CURRENT_DIR}/scripts/tmux_kube_status.sh)"
kube_status_interpolation_string="\#{kube_status}"

do_interpolation() {
  local string="$1"
  local interpolated="${string/${kube_status_interpolation_string}/${kube_status}}"

  echo "$interpolated"
}

update_tmux_option() {
  local option="$1"
  local option_value="$(get_tmux_option "${option}")"
  local new_option_value="$(do_interpolation "${option_value}")"

  set_tmux_option "${option}" "${new_option_value}"
}

update_tmux_option "status-right"
update_tmux_option "status-left"

