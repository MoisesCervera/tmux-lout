# tmux-lout

Copy recent command transcripts from the current tmux pane to the system
clipboard.

`tmux-lout` reads text from tmux scrollback. It does not rerun commands, write
output logs, or use tmux paste buffers.

## Features

- Copies the previous N completed command blocks from the active pane.
- Preserves rendered text, physical wrapping, blank lines, stdout, and stderr.
- Includes or excludes prompts, typed commands, and output independently.
- Provides the `lout` command and a configurable tmux key binding.
- Supports Powerlevel10k without requiring it.
- Detects `pbcopy`, `wl-copy`, `xclip`, and `xsel`.
- Keeps only numeric command-boundary metadata for the lifetime of each pane.

## Requirements

- tmux 3.7 or newer
- zsh 5.8 or newer
- One supported clipboard command

## Installation

### TPM

Add the plugin before the TPM initialization line in `.tmux.conf`:

```tmux
set -g @plugin 'MoisesCervera/tmux-lout'

# TPM must remain last.
run '~/.tmux/plugins/tpm/tpm'
```

Install it with `Prefix + I`.

Add the shell integration near the end of `.zshrc`, after prompt and theme
initialization. With Powerlevel10k, it must appear after both the theme and
`.p10k.zsh` are sourced:

```zsh
if [[ -n ${TMUX:-} ]]; then
  lout_root=$(tmux show-options -gqv @lout-path)
  if [[ -r $lout_root/shell/lout.zsh ]]; then
    source "$lout_root/shell/lout.zsh"
  fi
  unset lout_root
fi
```

Restart existing shells with `exec zsh` after the initial installation.

### Manual installation

```sh
git clone https://github.com/MoisesCervera/tmux-lout \
  ~/.tmux/plugins/tmux-lout
```

Add the plugin entry point to `.tmux.conf`:

```tmux
run-shell '~/.tmux/plugins/tmux-lout/lout.tmux'
```

Add the shell integration to `.zshrc`:

```zsh
source ~/.tmux/plugins/tmux-lout/shell/lout.zsh
```

Reload tmux and restart zsh:

```sh
tmux source-file ~/.tmux.conf
exec zsh
```

## Usage

```sh
lout              # Copy the previous command block
lout 5            # Copy the previous five command blocks
lout 5 --print    # Write the selected transcript to stdout
```

The default binding is `Prefix + C-g`. It opens a tmux prompt for the number of
commands to copy; the initial value is `1`.

### Content selection

```sh
# Output only
lout 5 --no-prompt --no-command

# Typed commands and output, without prompts
lout 5 --no-prompt

# Typed commands only
lout 5 --no-prompt --no-output

# Prompts and typed commands, without output
lout 5 --no-output
```

Available command-line switches:

| Option | Effect |
| --- | --- |
| `--prompt` / `--no-prompt` | Include or exclude prompt text |
| `--command` / `--no-command` | Include or exclude typed commands |
| `--output` / `--no-output` | Include or exclude command output |
| `--print`, `-p` | Write to stdout instead of the clipboard |
| `--help`, `-h` | Show command help |

The active `lout` invocation is excluded. The tmux key binding does not enter a
command into the shell.

## Configuration

Set options before the plugin declaration in `.tmux.conf`.

| Option | Default | Description |
| --- | --- | --- |
| `@lout-key` | `C-g` | Key used after the tmux prefix; use `none` to disable |
| `@lout-default-count` | `1` | Initial count in the tmux command prompt |
| `@lout-include-prompt` | `on` | Include prompt text by default |
| `@lout-include-command` | `on` | Include typed commands by default |
| `@lout-include-output` | `on` | Include command output by default |
| `@lout-clipboard-command` | auto | Command that receives clipboard text on stdin |
| `@lout-status` | `on` | Show a tmux confirmation message after copying |
| `@lout-trailing-newline` | `on` | Append one newline to copied content |
| `@lout-metadata-limit` | `200` | Command-boundary records retained per pane |
| `@lout-force-key` | `off` | Replace an existing binding when set to `on` |

Example:

```tmux
set -g @lout-key 'C-g'
set -g @lout-default-count '3'
set -g @lout-include-prompt 'off'
set -g @lout-clipboard-command 'pbcopy'
set -g @plugin 'MoisesCervera/tmux-lout'
```

The plugin does not replace an occupied key unless `@lout-force-key` is `on`.
When a conflict is detected, the requested key is recorded in
`@lout-key-conflict`.

## How it works

The zsh integration emits OSC 133 semantic prompt markers. tmux 3.7 records
those markers in its pane grid, and `capture-pane -L -F` exposes prompt and
output boundaries. `lout` selects completed blocks and sends their rendered
plain text to the configured clipboard command.

tmux does not expose the prompt-to-command boundary as a grid marker. To support
independent prompt and command filtering, the shell integration stores the
character count of each command line in pane-scoped tmux options. It does not
store command text or command output.

Powerlevel10k redraws transient prompts through its own renderer. When
Powerlevel10k is present, `tmux-lout` enables its native OSC 133 integration at
runtime. Other zsh prompts use the generic integration included with this
project.

## Privacy

`tmux-lout` does not create a transcript database or log file. Captured text is
held in memory only long enough to write it to the clipboard command. Numeric
boundary metadata disappears when its tmux pane is destroyed.

The source text remains subject to the pane's configured tmux history limit.
Text already discarded by tmux cannot be recovered.

## Limitations

- Clipboard content is plain text; ANSI colors and terminal control sequences
  are not copied.
- Full-screen and alternate-screen applications contribute only text retained
  by tmux.
- Applications that clear or overwrite pane content remove it from the source
  available to `lout`.
- If command output and the following prompt occupy the same physical grid row,
  tmux cannot expose an exact column boundary between them.

## Development

Run the parser test suite:

```sh
./tests/run
```

Run static checks:

```sh
bash -n lout.tmux
zsh -n shell/lout.zsh scripts/lout scripts/parse-capture tests/run
shellcheck -x lout.tmux
```

## License

[MIT](LICENSE)
