# Decisions on hidden commands and options

Decided 2026-10-08.

- **Flag.** `--help-include-hidden`, fixed name, always active, no setting. No help screen lists it.
- **Hidden options.** Declared as `option :name, hidden: true`. dry-cli 1.4.1 and the kigster fork both keep the key in `Option#options` and their parsers ignore it, so the gem adds no DSL.
- **Hidden commands.** dry-cli's own `register "name", Command, hidden: true`. The flag lists them at every level: top-level, group and a command's subcommands.
- **Marking.** A revealed command gets ` (hidden)` after its description. A revealed option gets `hidden` first in its notes: `(hidden; default: false)`.
- **Position.** The flag is removed before dry-cli parses, and `--help` goes at the end of the options part (before `--`), so `mycli --help-include-hidden deploy` shows `deploy`'s help. Anything after `--` is left to the command.
- **Hook.** The gem hooks the private `perform_command` and `perform_registry`, not `call`, because `call`'s keywords differ between dry-cli 1.4 and the fork, and overriding it hid the fork's parameters from callers that introspect it.
