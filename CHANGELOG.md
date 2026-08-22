# Changelog

All notable changes to this project are documented in this file.

## 0.1.1 - 2026-08-22

### Fixed

- Ignore prompt-only spans created by Powerlevel10k transient prompt redraws,
  preventing duplicated command lines and incorrect command counts.
- Clarify that the shell integration must load after Powerlevel10k.

## 0.1.0 - 2026-08-22

### Added

- `lout N` command for copying completed command blocks from the current pane.
- `Prefix + C-g` binding with an interactive command count.
- Independent prompt, typed-command, and output filters.
- OSC 133 integration for generic zsh prompts and Powerlevel10k.
- Automatic clipboard command detection on macOS, Wayland, and X11.
- Pane-scoped, length-only command-boundary metadata.
- Binding conflict detection and configurable plugin options.
- Parser tests for transcripts, filtering, wrapped commands, Unicode prompts,
  and active-command exclusion.
