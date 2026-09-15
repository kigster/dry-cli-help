# Examples

Three single-file command line tools built on dry-cli. Each one loads and configures `dry-cli-help` only when you pass `--with-dry-cli-help`, or `-w` for short, anywhere on the command line, so the same command shows dry-cli's own help and this gem's side by side:

```bash
./examples/todo -h                      # dry-cli's own help
./examples/todo -h --with-dry-cli-help  # the same help, through dry-cli-help
./examples/todo -h -w                   # the same help, through dry-cli-help, shorter flag
```

Run them from the repository root after `just install`. Each script points Bundler at the repository's `Gemfile`, so it loads this checkout of the gem.

| Script    | Commands                                                  | What its configuration block shows                                                                                                       |
| --------- | --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `rbcheck` | `version`, `check-ruby-syntax [DIR]`                      | The defaults, plus a title, description and epilogue. `check-ruby-syntax` really runs: it parses every Ruby file under `DIR` with Prism. |
| `todo`    | `add`, `list`, `done`, `tag add`, `tag remove`, `version` | Custom heading text, a `styles` block with `case: :Capitalize`, aliases, an array argument, option values, and a group with no command   |
| `deploy`  | `ship ENVIRONMENT`, `status`, `db migrate`, `db rollback` | A fixed width of 72, the banner above command help, reordered sections, alphabetical commands, and help without a command exiting 0      |

Screens worth comparing:

```bash
cd examples
./rbcheck check-ruby-syntax -h -w   # wrapping, defaults, aligned examples
./todo tag -h -w                    # a group without a command of its own
./deploy ship -h -w                 # banner, argument values, a narrow width
./deploy -h -w; echo $?             # help on stdout, exit 0; dry-cli exits 1
```

Nothing in a registry or a command changes between the two modes. The flag only decides whether the `configure` block at the top of the file runs.
