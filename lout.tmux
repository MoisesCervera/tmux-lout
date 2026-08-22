#!/usr/bin/env bash

set -u

LOUT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOUT_VERSION=0.1.1

set_default() {
  local option="$1"
  local value="$2"

  if [ -z "$(tmux show-options -gq "$option" 2>/dev/null)" ]; then
    tmux set-option -gq "$option" "$value"
  fi
}

tmux_version="$(tmux -V | awk '{print $2}')"
tmux_major="${tmux_version%%.*}"
tmux_minor="${tmux_version#*.}"
tmux_minor="$(printf '%s' "$tmux_minor" | sed 's/[^0-9].*$//')"

if [ "${tmux_major:-0}" -lt 3 ] || {
  [ "${tmux_major:-0}" -eq 3 ] && [ "${tmux_minor:-0}" -lt 7 ];
}; then
  tmux display-message "lout requires tmux 3.7 or newer (found ${tmux_version})"
  exit 1
fi

set_default @lout-key C-g
set_default @lout-default-count 1
set_default @lout-include-prompt on
set_default @lout-include-command on
set_default @lout-include-output on
set_default @lout-clipboard-command ''
set_default @lout-status on
set_default @lout-trailing-newline on
set_default @lout-metadata-limit 200
set_default @lout-force-key off

tmux set-option -gq @lout-path "$LOUT_DIR"
tmux set-option -gq @lout-version "$LOUT_VERSION"

lout_key="$(tmux show-options -gqv @lout-key)"
lout_force_key="$(tmux show-options -gqv @lout-force-key)"
lout_count="$(tmux show-options -gqv @lout-default-count)"

if [ -n "$lout_key" ] && [ "$lout_key" != none ] && [ "$lout_key" != off ]; then
  existing="$(
    tmux list-keys -T prefix 2>/dev/null |
      awk -v key="$lout_key" '
        {
          for (field = 1; field < NF; ++field) {
            if ($field == "prefix" && $(field + 1) == key) {
              print
              exit
            }
          }
        }
      '
  )"

  if [ -n "$existing" ] && [[ "$existing" != *"$LOUT_DIR/scripts/lout"* ]] && [ "$lout_force_key" != on ]; then
    tmux set-option -gq @lout-key-conflict "$lout_key"
    tmux display-message "lout: Prefix+$lout_key is already bound; set @lout-key or @lout-force-key on"
  else
    tmux set-option -gu @lout-key-conflict 2>/dev/null || true
    tmux bind-key -T prefix -N "Copy recent command blocks with lout" "$lout_key" \
      command-prompt -p "lout: commands" -I "$lout_count" \
      "run-shell -b '\"$LOUT_DIR/scripts/lout\" --pane \"#{pane_id}\" --count \"%%\"'"
  fi
fi
