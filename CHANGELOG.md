## [Unreleased]

- The gem sets dry-cli's help renderer through `Dry::CLI.configure`, and reads commands through `Dry::CLI::Tree`, instead of prepending a module that overrode two private `Dry::CLI` methods. Help output is unchanged. The override had already broken against dry-cli's `main`, whose `#help` takes `long:` and whose streams are `stdout` and `stderr`.
- A CLI given settings of its own, `Dry.CLI(registry, config:)`, renders the help those settings name.
- A group run without a subcommand, such as `mycli db` where `db` is a namespace, now lists its commands through this gem too.
- Examples follow dry-cli's `example "args", "description"`. One string written the older way, `"args # description"`, is still split at the `#`.
- Needs dry-cli with the help hooks; the Gemfile takes it from kigster/dry-cli until they are released.

## [0.5.1] - 2026-09-21

- An empty example, `example [""]`, no longer raises `NoMethodError` and takes the whole help screen with it. It prints the program name on its own, which is what a command that runs with no arguments means by it.

## [0.5.0] - Unreleased

- The `dry-cli` dependency no longer pins a version range; any release satisfies it.
- `SPECIFICATION.md` moves to `docs/SPECIFICATION.md`, marked as the specification for 0.1.0, and stays out of the YARD documentation.
- The README documents which sections each screen prints, how groups and nested commands list, the description column and minimum wrap width, `Help.config`, `Help.reset!`, and the `ArgumentError` a bad setting raises.

## [0.2.1] - 2026-09-15

- Every setting is made once, in `Dry::CLI::Help.configure`, which now also accepts a block without an argument and runs it against the configuration. The `help` block on registries is removed, along with `Help.config_for` and `Configuration#merge`: the gem adds nothing to dry-cli's registry or command DSL.
- A `styles` block declares every element's look in one place, replacing `style(element, *names)`. New elements `usage`, `example` and `example_comment`; `comment` is renamed `example_comment` and defaults to bold black.
- Heading case moves into the heading style: `styles { heading :bold, case: :Capitalize }`, one of `:UPPERCASE`, `:Capitalize`, `:lowercase` or `:as_is`. The `heading_case` setting is removed.
- `examples/` holds three single-file dry-cli tools that switch this gem on with `--with-dry-cli-help` or `-w`.

## [0.2.0] - 2026-09-14

- Documentation, justfile, lefthook and packaging fixes after the conversion. No change to behavior.

## [0.1.0] - 2026-09-12

- Initial release as `dry-cli-help`, converted from `dry-cli-autocomplete`. The shell completion generator is removed; that gem remains the place for it.
- Help screens with a title, description and epilogue, uppercase headings, aligned and wrapped descriptions, and ANSI colors through `pastel`.
- Settings through `Dry::CLI::Help.configure` for the whole process and a `help` block on any registry: `title`, `description`, `epilogue`, `color`, `wrap`, `width`, `margin`, `exit_code_without_arguments`, `banner_on_subcommands`, `heading_case`, `command_order`, `heading`, `style`, `group`, `sections` and `hide`.
- `-h` and `--help` at a registry level exit 0. Running with no command keeps dry-cli's exit status 1 unless configured otherwise.
- `Dry::CLI::Help::Colors`, a module exposing every foreground, background and text style as a method.
