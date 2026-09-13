# Plan: convert dry-cli-autocomplete into dry-cli-help

Source of truth: `SPECIFICATION.md`.

## Steps

- [x] Remove the completion generator: `lib/dry/cli/autocomplete/**`, its specs, golden files, shell helpers, zsh CI steps
- [x] Rename to `dry-cli-help`: gemspec, entry files, `Dry::CLI::Help` namespace, version 0.1.0, `pastel` dependency, drop `dry-inflector`
- [x] `Colors`: 40 pastel styles as methods, process-wide enable switch
- [x] `Configuration`: defaults, validation, DSL and attribute access, merge of global and registry levels
- [x] `Terminal`: width from `COLUMNS`, console, fallback 80
- [x] `Text`: paragraph reflow and word wrap
- [x] `Formatter`: headings, paragraphs, aligned definition lists, styles
- [x] `Screens::Listing` (top-level and group help) and `Screens::Command` (command help)
- [x] `Integration`: prepend to `Dry::CLI`, `help` on `Dry::CLI::Registry`
- [x] Specs at 100% line and branch coverage, enforced by SimpleCov
- [x] justfile and lefthook: every recipe and job runs
- [x] README, CLAUDE.md, CHANGELOG, RBS signatures

## Open

- `origin` points at `kigster/dry-cli-autocomplete`. Nothing is pushed until a `dry-cli-help` remote exists.
