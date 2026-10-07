# frozen_string_literal: true

module Dry
  class CLI
    module Help
      # The only code that touches dry-cli. Everything else renders.
      module Integration
        # Prepended to Dry::CLI. Overrides the two private methods dry-cli
        # prints help from, and nothing else.
        #
        # Both are `@api private` in dry-cli, which is why the suite asserts they
        # exist: a dry-cli release that renames them fails this gem's specs
        # rather than a host's help screen.
        module CLIMethods
          HELP_FLAGS = %w[-h --help].freeze

          private

          # dry-cli calls this for `mycli deploy -h`, and the kigster fork also
          # for `--help`, with `long: true` so the long description is shown.
          def help(command, prog_name, long: false)
            screen = Screens::Command.new(
              command:, prog_name:, long:, top_level: !kommand.nil?,
              config: Help.config, io: help_out
            )
            help_out.puts screen.render
            exit(0)
          end

          # dry-cli calls this whenever the arguments name no command: none at
          # all, a group without a command of its own, `-h` or `--help` at a
          # registry level, or a typo.
          def spell_checker(result, arguments)
            config = Help.config
            unmatched = arguments.drop(result.names.length)

            if unmatched.empty?
              status = config.exit_code_without_arguments
              list(result, config, status.zero? ? help_out : help_err, status)
            elsif HELP_FLAGS.include?(unmatched.first)
              list(result, config, help_out, 0)
            else
              suggestion = SpellChecker.call(result, arguments)
              help_err.puts "#{suggestion}\n\n" if suggestion
              list(result, config, help_err, 1)
            end
          end

          # dry-cli 1.4 holds its streams as `out` and `err`; the kigster fork
          # renamed them `stdout` and `stderr`. Both are supported.
          def help_out
            plain(respond_to?(:stdout, true) ? stdout : out)
          end

          def help_err
            plain(respond_to?(:stderr, true) ? stderr : err)
          end

          # The fork wraps each stream in a `Dry::CLI::Stream` that strips ANSI
          # from anything written when it decides the stream has no color. The
          # help screen has already made that decision for the same stream, so
          # it writes to the IO underneath.
          def plain(io)
            io.respond_to?(:raw) ? io.raw : io
          end

          def list(result, config, io, status)
            io.puts Screens::Listing.new(result:, config:, io:).render
            exit(status)
          end
        end
      end
    end
  end
end
