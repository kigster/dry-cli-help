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
    # Settings come from {.configure} for the whole process, and from a
    # registry's `help` block for that registry.
    module Help
      class << self
        # @yieldparam config [Configuration] the process-wide settings
        # @return [Configuration]
        def configure
          yield config
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

        # The settings a registry renders with: its own `help` block over the
        # process-wide settings. A single command passed to Dry::CLI.new has no
        # `help` block, so it renders with the process-wide settings alone.
        #
        # @param registry [Module, Class, Dry::CLI::Command, nil]
        # @return [Configuration]
        def config_for(registry)
          own = registry.help_config if registry.respond_to?(:help_config)
          own ? config.merge(own) : config
        end
      end
    end
  end
end

Dry::CLI.prepend(Dry::CLI::Help::Integration::CLIMethods)
Dry::CLI::Registry.include(Dry::CLI::Help::Integration::RegistryMethods)
