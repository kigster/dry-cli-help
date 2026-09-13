# frozen_string_literal: true

require "io/console"

module Dry
  class CLI
    module Help
      # The width of the terminal help prints to.
      module Terminal
        FALLBACK_WIDTH = 80

        module_function

        # `COLUMNS` wins over the console, so a user or a test can pin the width.
        #
        # @param env [Hash, ENV]
        # @param console [IO, nil] the controlling terminal, nil without one
        # @return [Integer]
        def width(env: ENV, console: IO.console)
          from_env(env) || from_console(console) || FALLBACK_WIDTH
        end

        # @return [Integer, nil]
        def from_env(env)
          columns = Integer(env.fetch("COLUMNS", ""), exception: false)
          columns if columns&.positive?
        end

        # @return [Integer, nil]
        def from_console(console)
          columns = console&.winsize&.last
          columns if columns&.positive?
        rescue SystemCallError
          nil
        end
      end
    end
  end
end
