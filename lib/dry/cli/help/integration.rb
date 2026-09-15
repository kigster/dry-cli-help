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

          # dry-cli calls this for `mycli deploy -h`.
          def help(command, prog_name)
            screen = Screens::Command.new(
              command:, prog_name:, top_level: !kommand.nil?,
              config: Help.config, io: out
            )
            out.puts screen.render
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
              list(result, config, status.zero? ? out : err, status)
            elsif HELP_FLAGS.include?(unmatched.first)
              list(result, config, out, 0)
            else
              suggestion = SpellChecker.call(result, arguments)
              err.puts "#{suggestion}\n\n" if suggestion
              list(result, config, err, 1)
            end
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
