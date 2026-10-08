# frozen_string_literal: true

module Dry
  class CLI
    module Help
      # The only code that touches dry-cli. Everything else renders.
      module Integration
        # Prepended to Dry::CLI. Overrides the two private methods dry-cli
        # prints help from, and the two it dispatches through, and nothing else.
        #
        # All four are `@api private` in dry-cli, which is why the suite asserts
        # they exist: a dry-cli release that renames them fails this gem's specs
        # rather than a host's help screen.
        module CLIMethods
          HELP_FLAGS = %w[-h --help].freeze

          # Asks for help that also lists hidden commands and options. No help
          # screen lists the flag itself.
          INCLUDE_HIDDEN_FLAG = "--help-include-hidden"

          private

          # dry-cli's `call` hands the arguments to one of these two. They are
          # hooked rather than `call`, whose keywords differ between dry-cli 1.4
          # and the kigster fork.
          def perform_command(arguments)
            super(without_include_hidden_flag(arguments))
          end

          def perform_registry(arguments)
            super(without_include_hidden_flag(arguments))
          end

          # dry-cli would reject the flag as an unknown option, so it is taken
          # out of the arguments before dry-cli sees them. A `--help` goes last
          # in its place, unless one is there already, so the flag works before
          # the command's name as well as after it.
          #
          # Everything after `--` belongs to the command, flags included.
          def without_include_hidden_flag(arguments)
            @help_include_hidden = false
            options = arguments.take_while { it != "--" }
            index = options.index(INCLUDE_HIDDEN_FLAG)
            return arguments unless index

            @help_include_hidden = true
            rest = arguments.dup
            rest.delete_at(index)
            rest.insert(options.length - 1, "--help") unless options.intersect?(HELP_FLAGS)
            rest
          end

          # dry-cli calls this for `mycli deploy -h`, and the kigster fork also
          # for `--help`, with `long: true` so the long description is shown.
          def help(command, prog_name, long: false)
            screen = Screens::Command.new(
              command:, prog_name:, long:, top_level: !kommand.nil?,
              config: Help.config, io: help_out, include_hidden: help_include_hidden?
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
          # it writes to the IO underneath. The test is the class, not
          # `respond_to?(:raw)`: `io/console` gives every IO a `raw` of its own,
          # which puts a terminal into raw mode and raises ENOTTY on a pipe.
          def plain(io)
            defined?(Dry::CLI::Stream) && io.is_a?(Dry::CLI::Stream) ? io.raw : io
          end

          def help_include_hidden?
            @help_include_hidden
          end

          def list(result, config, io, status)
            io.puts Screens::Listing.new(result:, config:, io:, include_hidden: help_include_hidden?).render
            exit(status)
          end
        end
      end
    end
  end
end
