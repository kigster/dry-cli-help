## [Unreleased]

- Every setting is made once, in `Dry::CLI::Help.configure`, which now also accepts a block without an argument and runs it against the configuration. The `help` block on registries is removed, along with `Help.config_for` and `Configuration#merge`: the gem adds nothing to dry-cli's registry or command DSL.
- A `styles` block declares every element's look in one place, replacing `style(element, *names)`. New elements `usage`, `example` and `example_comment`; `comment` is renamed `example_comment` and defaults to bold black.
- Heading case moves into the heading style: `styles { heading :bold, case: :Capitalize }`, one of `:UPPERCASE`, `:Capitalize`, `:lowercase` or `:as_is`. The `heading_case` setting is removed.
- `examples/` holds three single-file dry-cli tools that switch this gem on with `--with-dry-cli-help` or `-w`.

## [0.1.0] - 2026-09-12

- Initial release as `dry-cli-help`, converted from `dry-cli-autocomplete`. The shell completion generator is removed; that gem remains the place for it.
- Help screens with a title, description and epilogue, uppercase headings, aligned and wrapped descriptions, and ANSI colors through `pastel`.
- Settings through `Dry::CLI::Help.configure` for the whole process and a `help` block on any registry: `title`, `description`, `epilogue`, `color`, `wrap`, `width`, `margin`, `exit_code_without_arguments`, `banner_on_subcommands`, `heading_case`, `command_order`, `heading`, `style`, `group`, `sections` and `hide`.
- `-h` and `--help` at a registry level exit 0. Running with no command keeps dry-cli's exit status 1 unless configured otherwise.
- `Dry::CLI::Help::Colors`, a module exposing every foreground, background and text style as a method.
