# CLAUDE.md

Guidance for Claude Code (claude.ai/code) working in this repository.

## What this is

A Ruby gem that changes the help screens every `Dry::CLI` prints: a title and description, an epilogue, command groups, section ordering and hiding, configurable headings, terminal-width wrapping and ANSI colors. It owns what a user reads before a command runs, and nothing after.

**Read `docs/SPECIFICATION.md` first.** It carries the settings, the section and layout rules, and why the integration hooks where it does. It specifies version 0.1.0, so where it and the code or `README.md` disagree, the code wins. This file covers how to work in the repository.

The repository began as a copy of `dry-cli-autocomplete`. The completion generator is gone; if you find a reference to emitters, bash or zsh scripts, it is stale.

## Environment

Ruby is managed by rbenv. Prefix every Ruby command:

```bash
eval "$(rbenv init -)" && bundle exec rspec
```

```bash
just install          # bin/setup, which runs bundle install
just test             # the suite; a full run fails below 100% line or branch coverage
just test-coverage    # measure coverage even for a partial run
just lint             # rubocop
just ci               # lint, then the suite with coverage
just format           # mdformat every Markdown file, then rubocop -a
just lefthook         # every pre-commit hook against every file
just doc              # YARD documentation
just build            # build the .gem into pkg/
bin/console           # IRB with the gem loaded
```

The gemspec sets `required_ruby_version >= 4.0` and `.rubocop.yml` sets `TargetRubyVersion: 4.0`. Keep the two in step.

## The trap that has already bitten this repository once

`bundle gem` generates `module Dry; module Cli`. **dry-cli declares `Dry::CLI`, and it is a class, not a module.** Reopening a class as a module raises `TypeError` the moment both are loaded. Nest every file under `lib/dry/cli/` as:

```ruby
module Dry
  class CLI
    module Help
```

`lib/dry/cli/help/version.rb` deliberately does **not** `require "dry/cli"`, because the gemspec loads it at build time when the dependency may not be installed.

Inside `module Dry`, an unqualified constant resolves there first: a bare `Struct` becomes `Dry::Struct` in any host that loads dry-struct. Write `::Data`, `::Pastel`, and so on.

## Architecture

| File                                  | Role                                                                               |
| ------------------------------------- | ---------------------------------------------------------------------------------- |
| `lib/dry/cli/help.rb`                 | Entry point: `configure`, `config`, `reset!`, and the line that installs the gem   |
| `lib/dry/cli/help/integration.rb`     | The only code that touches dry-cli: overrides `Dry::CLI#help` and `#spell_checker` |
| `lib/dry/cli/help/configuration.rb`   | Every setting, its validation, the DSL, and the `styles` block                     |
| `lib/dry/cli/help/screens/base.rb`    | What every screen shares: section order, banner, epilogue, the description column  |
| `lib/dry/cli/help/screens/listing.rb` | Top-level and group help: `mycli`, `mycli -h`, `mycli db`                          |
| `lib/dry/cli/help/screens/command.rb` | One command's help: `mycli deploy -h`                                              |
| `lib/dry/cli/help/formatter.rb`       | Headings, paragraphs, aligned definition lists, painting                           |
| `lib/dry/cli/help/text.rb`            | Paragraph reflow and word wrap                                                     |
| `lib/dry/cli/help/terminal.rb`        | Terminal width                                                                     |
| `lib/dry/cli/help/colors.rb`          | The public `Colors` module                                                         |
| `examples/`                           | `rbcheck`, `todo`, `deploy`: runnable CLIs, with the gem only under `-w`           |

Rules that hold this shape together:

- **Only `integration.rb` knows how dry-cli dispatches.** Screens receive a command or a lookup result and render; they never print or exit.
- **Wrap before painting.** Escape codes must never count toward a line's length.
- **Configuration happens once, in `Dry::CLI::Help.configure`.** The gem adds nothing to `Dry::CLI::Registry` or `Dry::CLI::Command`, so a host's command definitions stay plain dry-cli. Do not add a DSL method to either.
- **A `Configuration` stores only what was set on it.** Defaults live in constants.
- **Validate settings in `configure`, never while rendering.** A group with no commands raises there. A group naming commands a screen does not list prints no heading, and must not raise: the registry is unknown at configure time, and a typo must not break a user's help screen.

## Conventions

- **Read dry-cli through readers, not ivars.** Everything this gem reads is `@api private` in dry-cli 1.4.1. `spec/dry/cli/help/dry_cli_contract_spec.rb` lists all of it; add to that file whenever you read something new.
- **Every example resets global state.** `spec/spec_helper.rb` pins `COLUMNS=80`, clears `NO_COLOR`, sets `$PROGRAM_NAME` to `mycli`, and resets `Help.config` and `Colors.enabled` after each example. Build a registry per example with the `registry` helper, and make settings through `Dry::CLI::Help.configure` inside the example.
- **Test through `Dry::CLI#call`.** `run_cli` in `spec/support/cli_helpers.rb` captures stdout, stderr and the exit status. Expected screens are written out in full.
- **Test against registries this project did not write.** `spec/support/fixtures/` holds several shapes.
- **Commit messages**: imperative mood, 50-character subject, no full stop, no agent attribution.
- **Writing prose here**: no em dashes, active voice, plain words. Run `just format-markdown` after editing Markdown.
- **The README shows real output.** Its screens come from `examples/rbcheck` and a `my-cli` registry run at `COLUMNS=80`. When rendering or a setting changes, rerun them and update the README and `examples/README.md` to match.

## Releasing

- `just publish [OTP]` builds the gem and pushes it to RubyGems. `just release` tags `v<VERSION>` and creates the GitHub release.
- Bump `lib/dry/cli/help/version.rb`, then run `bundle install` so `Gemfile.lock` follows.
- The `dry-` prefix implies an affiliation with dry-rb that does not exist. The README says so; keep it that way.
