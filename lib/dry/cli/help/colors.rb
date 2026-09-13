# frozen_string_literal: true

module Dry
  class CLI
    module Help
      # Every pastel style as a method. Include it, or extend a module with it:
      #
      #   include Dry::CLI::Help::Colors
      #
      #   red("text")          # => decorated text
      #   red.bold("text")     # => chained styles
      #
      # Whether the methods decorate is one process-wide switch, {Colors.enabled=}.
      # Help screens do not read it: they follow the `color` setting instead.
      module Colors
        HUES = %i[black red green yellow blue magenta cyan white].freeze
        FOREGROUNDS = (HUES + HUES.map { :"bright_#{it}" }).freeze
        BACKGROUNDS = FOREGROUNDS.map { :"on_#{it}" }.freeze
        MODIFIERS = %i[clear bold dim italic underline inverse hidden strikethrough].freeze
        STYLES = (FOREGROUNDS + BACKGROUNDS + MODIFIERS).freeze

        # Values the color switch and the `color` setting accept.
        SETTINGS = [true, false, :auto].freeze

        @enabled = :auto

        class << self
          # @return [Boolean, Symbol] true, false or :auto
          attr_reader :enabled

          # @param value [Boolean, Symbol] true, false or :auto
          def enabled=(value)
            raise ArgumentError, "color must be one of #{SETTINGS.inspect}, got #{value.inspect}" \
              unless SETTINGS.include?(value)

            @enabled = value
            @pastel = nil
          end

          # @return [Pastel] shared by every includer, rebuilt when the switch changes
          def pastel
            @pastel ||= ::Pastel.new(enabled: enabled_for?(enabled, $stdout))
          end

          # `:auto` colors a terminal unless NO_COLOR is set to anything but
          # the empty string. https://no-color.org
          #
          # @param setting [Boolean, Symbol] true, false or :auto
          # @param io [IO, #tty?] where the text is going
          # @return [Boolean]
          def enabled_for?(setting, io)
            return setting unless setting == :auto

            io.respond_to?(:tty?) && io.tty? && ENV.fetch("NO_COLOR", "").empty?
          end
        end

        # @return [Pastel]
        def pastel
          Colors.pastel
        end

        STYLES.each do |style|
          define_method(style) do |*text|
            text.empty? ? pastel.public_send(style) : pastel.public_send(style, *text)
          end
        end
      end
    end
  end
end
