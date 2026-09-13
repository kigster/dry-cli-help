# CLAUDE.md

Guidance for Claude Code (claude.ai/code) working in this repository.

## What this is

A Ruby gem that changes the help screens every `Dry::CLI` prints: a title and description, an epilogue, command groups, section ordering and hiding, configurable headings, terminal-width wrapping and ANSI colors. It owns what a user reads before a command runs, and nothing after.

**Read `SPECIFICATION.md` first.** It carries the settings, the section and layout rules, and why the integration hooks where it does. This file covers how to work in the repository.

The repository began as a copy of `dry-cli-autocomplete`. The completion generator is gone; if you find a reference to emitters, bash or zsh scripts, it is stale.

## Environment

Ruby is managed by rbenv. Prefix every Ruby command:

```bash
eval "$(rbenv init -)" && bundle exec rspec
```

```bash
just install     # bundle install
just test        # the suite; a full run fails below 100% line or branch coverage
just lint        # rubocop
just ci          # both
just lefthook    # every pre-commit hook against every file
bin/console      # IRB with the gem loaded
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

| File                                  | Role                                                                                                          |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `lib/dry/cli/help.rb`                 | Entry point: `configure`, `config`, `config_for`, and the two lines that install the gem                      |
| `lib/dry/cli/help/integration.rb`     | The only code that touches dry-cli: overrides `Dry::CLI#help` and `#spell_checker`, adds `help` to registries |
| `lib/dry/cli/help/configuration.rb`   | Every setting, its validation, the DSL, and `merge` of process-wide and registry settings                     |
| `lib/dry/cli/help/screens/listing.rb` | Top-level and group help: `mycli`, `mycli -h`, `mycli db`                                                     |
| `lib/dry/cli/help/screens/command.rb` | One command's help: `mycli deploy -h`                                                                         |
| `lib/dry/cli/help/formatter.rb`       | Headings, paragraphs, aligned definition lists, painting                                                      |
| `lib/dry/cli/help/text.rb`            | Paragraph reflow and word wrap                                                                                |
| `lib/dry/cli/help/terminal.rb`        | Terminal width                                                                                                |
| `lib/dry/cli/help/colors.rb`          | The public `Colors` module                                                                                    |

Rules that hold this shape together:

- **Only `integration.rb` knows how dry-cli dispatches.** Screens receive a command or a lookup result and render; they never print or exit.
- **Wrap before painting.** Escape codes must never count toward a line's length.
- **A `Configuration` stores only what was set on it.** Defaults live in constants, which is what lets `merge` lay a registry over the process-wide settings.

## Conventions

- **Read dry-cli through readers, not ivars.** Everything this gem reads is `@api private` in dry-cli 1.4.1. `spec/dry/cli/help/dry_cli_contract_spec.rb` lists all of it; add to that file whenever you read something new.
- **Every example resets global state.** `spec/spec_helper.rb` pins `COLUMNS=80`, clears `NO_COLOR`, sets `$PROGRAM_NAME` to `mycli`, and resets `Help.config` and `Colors.enabled` after each example. Build a registry per example with the `registry` helper rather than calling `help` on a shared fixture.
- **Test through `Dry::CLI#call`.** `run_cli` in `spec/support/cli_helpers.rb` captures stdout, stderr and the exit status. Expected screens are written out in full.
- **Test against registries this project did not write.** `spec/support/fixtures/` holds several shapes.
- **Commit messages**: imperative mood, 50-character subject, no full stop, no agent attribution.
- **Writing prose here**: no em dashes, active voice, plain words. Run `just format-markdown` after editing Markdown.

## Before the first release

- `origin` still points at `kigster/dry-cli-autocomplete`. Point it at a `dry-cli-help` repository before pushing anything.
- The `dry-` prefix implies an affiliation with dry-rb that does not exist. The README says so.
