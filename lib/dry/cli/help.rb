# frozen_string_literal: true

require "dry/cli"
require "pastel"

require_relative "help/version"
require_relative "help/colors"
require_relative "help/terminal"
require_relative "help/text"
require_relative "help/configuration"
require_relative "help/formatter"
require_relative "help/screens/base"
require_relative "help/screens/listing"
require_relative "help/screens/command"
require_relative "help/integration"

module Dry
  class CLI
    # Configurable, wrapped and colored help screens for dry-cli.
    #
    # Requiring this file changes the help every Dry::CLI in the process prints.
    # Every setting is made once, in {.configure}, so the way dry-cli declares
    # registries, commands and options stays exactly as dry-cli ships it.
    module Help
      class << self
        # Make every setting. A block taking an argument receives the
        # configuration; any other block runs against it.
        #
        # @example
        #   Dry::CLI::Help.configure do
        #     title "MyCLI"
        #     styles { heading :bold, :blue }
        #   end
        #
        # @return [Configuration]
        def configure(&block)
          block.arity == 1 ? yield(config) : config.instance_eval(&block)
          config
        end

        # @return [Configuration] the process-wide settings
        def config
          @config ||= Configuration.new
        end

        # Forget every process-wide setting.
        # @return [void]
        def reset!
          @config = nil
        end
      end
    end
  end
end

Dry::CLI.prepend(Dry::CLI::Help::Integration::CLIMethods)
