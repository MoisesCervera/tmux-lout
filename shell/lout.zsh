# tmux-lout shell integration for zsh.
# Source this near the end of .zshrc, after prompt/theme initialization.

if (( ${+_LOUT_SHELL_INTEGRATION_LOADED} )); then
  return 0
fi

typeset -g _LOUT_SHELL_INTEGRATION_LOADED=1
typeset -g _LOUT_PLUGIN_DIR=${${(%):-%x}:A:h:h}
typeset -gi _LOUT_COMMAND_ACTIVE=0
typeset -gi _LOUT_SEQ=0
typeset -gi _LOUT_OWNS_MARKERS=1
typeset -gr _LOUT_PROMPT_MARK=$'%{\e]133;A\e\\%}'

if [[ -n ${TMUX_PANE:-} ]]; then
  _LOUT_SEQ=$(tmux show-options -pqv -t "$TMUX_PANE" @lout_seq 2>/dev/null)
  [[ $_LOUT_SEQ == <-> ]] || _LOUT_SEQ=0
fi

# Powerlevel10k can redraw old prompts without using PROMPT. When it is
# already loaded, enable its public OSC 133 integration so those redraws keep
# tmux's semantic marks. This is an optional compatibility path; lout does not
# require Powerlevel10k.
if (( ${+functions[p10k]} )); then
  typeset -g POWERLEVEL9K_TERM_SHELL_INTEGRATION=true
  if p10k reload >/dev/null 2>&1; then
    _LOUT_OWNS_MARKERS=0
  fi
fi

_lout_command_line_lengths() {
  emulate -L zsh

  local command=$1
  local -a command_lines lengths
  local line

  command_lines=("${(@f)command}")
  (( ${#command_lines} )) || command_lines=('')

  for line in "${command_lines[@]}"; do
    lengths+=("${#line}")
  done

  print -rn -- "${(j:,:)lengths}"
}

_lout_record_command_geometry() {
  emulate -L zsh

  [[ -n ${TMUX_PANE:-} ]] || return 0

  local command=$1
  local lengths limit old_seq

  lengths=$(_lout_command_line_lengths "$command")
  (( ++_LOUT_SEQ ))

  tmux set-option -pq -t "$TMUX_PANE" "@lout_lens_${_LOUT_SEQ}" "$lengths" 2>/dev/null || return 0
  tmux set-option -pq -t "$TMUX_PANE" @lout_seq "$_LOUT_SEQ" 2>/dev/null || return 0

  limit=$(tmux show-options -gqv @lout-metadata-limit 2>/dev/null)
  [[ $limit == <-> ]] || limit=200
  (( limit < 10 )) && limit=10
  old_seq=$(( _LOUT_SEQ - limit ))
  if (( old_seq > 0 )); then
    tmux set-option -pqu -t "$TMUX_PANE" "@lout_lens_${old_seq}" 2>/dev/null || true
  fi
}

_lout_preexec() {
  emulate -L zsh

  _lout_record_command_geometry "$1"
  if (( _LOUT_OWNS_MARKERS )); then
    print -rn -- $'\e]133;C\e\\'
    _LOUT_COMMAND_ACTIVE=1
  fi
}

_lout_precmd() {
  local command_status=$?
  emulate -L zsh

  if (( _LOUT_OWNS_MARKERS && _LOUT_COMMAND_ACTIVE )); then
    print -rn -- $'\e]133;D;'"$command_status"$'\e\\'
    _LOUT_COMMAND_ACTIVE=0
  fi

  if (( _LOUT_OWNS_MARKERS )); then
    # Keep the mark inside PROMPT so zsh redisplays it after clearing a line.
    # Remove our previous prefix first because precmd runs before every prompt.
    PROMPT=${PROMPT#$_LOUT_PROMPT_MARK}
    PROMPT=$_LOUT_PROMPT_MARK$PROMPT
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _lout_precmd
add-zsh-hook preexec _lout_preexec

lout() {
  "$_LOUT_PLUGIN_DIR/scripts/lout" "$@"
}
