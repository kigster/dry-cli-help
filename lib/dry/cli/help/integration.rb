# frozen_string_literal: true

module Dry
  class CLI
    module Help
      # The only code that touches dry-cli. Everything else renders.
      #
      # dry-cli builds a `Dry::CLI::Screen` whenever it prints help, and hands it to the renderer
      # set with `Dry::CLI.configure`. This is that renderer: it decides the exit status, and so
      # the stream, then renders the screen this gem draws for it.
      module Integration
        # The renderer this gem installs.
        module Renderer
          module_function

          # @param screen [Dry::CLI::Screen] a screen without text
          # @return [Dry::CLI::Screen] the screen with its status, streams and text
          def call(screen)
            config = Help.config
            # This gem decides color for itself, from the `color` setting, `NO_COLOR` and the
            # terminal, so it prints to the IO beneath dry-cli's streams, which would otherwise
            # take out color the gem was set to force.
            screen = screen.with(
              status: status(screen, config), stdout: screen.stdout.raw, stderr: screen.stderr.raw
            )
            text = screen.command? ? command(screen, config) : listing(screen, config)

            screen.with(text: [screen.suggestion, text].compact.join("\n\n"))
          end

          # `-h` and `--help` exit 0, a typo exits 1, and help shown because no command was given
          # exits with the configured status. A screen dry-cli prints without exiting stays so.
          #
          # @param screen [Dry::CLI::Screen]
          # @param config [Configuration]
          # @return [Integer, nil]
          def status(screen, config)
            return screen.status if screen.status.nil? || screen.command?

            case screen.reason
            when :help then 0
            when :no_command then config.exit_code_without_arguments
            else 1
            end
          end

          # @param screen [Dry::CLI::Screen]
          # @param config [Configuration]
          # @return [String]
          def command(screen, config)
            Screens::Command.new(
              node: screen.node, prog_name: screen.prog_name, top_level: screen.node.path.empty?,
              config:, io: screen.io
            ).render
          end

          # @param screen [Dry::CLI::Screen]
          # @param config [Configuration]
          # @return [String]
          def listing(screen, config)
            Screens::Listing.new(node: screen.node, prog_name: screen.prog_name, config:, io: screen.io).render
          end
        end

        # Makes {Renderer} the renderer of every CLI that reads dry-cli's process-wide settings.
        #
        # @return [void]
        def self.install
          Dry::CLI.configure { it.help.renderer = Renderer }
        end
      end
    end
  end
end
