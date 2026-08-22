# Contributing

Bug reports and focused pull requests are welcome.

## Development requirements

- tmux 3.7 or newer for integration testing
- zsh 5.8 or newer
- Bash and ShellCheck for static analysis

## Tests

Run all repository checks before submitting a change:

```sh
./tests/run
bash -n lout.tmux
zsh -n shell/lout.zsh scripts/lout scripts/parse-capture tests/run
shellcheck -x lout.tmux
```

Changes to parsing behavior should include a capture fixture and an assertion in
`tests/run`.
