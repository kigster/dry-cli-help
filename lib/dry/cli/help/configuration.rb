# frozen_string_literal: true

module Dry
  class CLI
    module Help
      # Help settings, readable and writable two ways:
      #
      #   help do
      #     title "Taxlibris"            # inside a registry's help block
      #   end
      #
      #   Dry::CLI::Help.configure do |config|
      #     config.title = "Taxlibris"   # on the yielded object
      #   end
      #
      # An instance stores only what was set on it. Everything else reads from
      # {DEFAULTS}, which is what lets a registry's settings sit over the
      # process-wide ones through {#merge} without either copying the other.
      class Configuration
        # Every section, in default order.
        SECTIONS = %i[
          banner usage description commands subcommands arguments options examples epilogue
        ].freeze

        # Default heading text. `banner` and `epilogue` print no heading.
        HEADINGS = {
          usage: "Usage",
          description: "Description",
          commands: "Commands",
          subcommands: "Subcommands",
          arguments: "Arguments",
          options: "Options",
          examples: "Examples"
        }.freeze

        # Default styles of every element a screen paints.
        STYLES = {
          title: %i[bold],
          heading: %i[bold yellow],
          command: %i[green],
          argument: %i[cyan],
          option: %i[cyan],
          comment: %i[bright_black]
        }.freeze

        HEADING_CASES = %i[upcase capitalize none].freeze
        COMMAND_ORDERS = %i[registration alphabetical].freeze

        # Narrowest column text wraps at, however small the terminal.
        MIN_WIDTH = 20

        BOOLEAN = ->(value) { [true, false].include?(value) }
        TEXT = ->(value) { value.nil? || value.is_a?(String) }

        # Single-value settings and what each accepts.
        SCALARS = {
          title: TEXT,
          description: TEXT,
          epilogue: TEXT,
          color: ->(value) { Colors::SETTINGS.include?(value) },
          wrap: BOOLEAN,
          width: ->(value) { value == :terminal || (value.is_a?(Integer) && value.positive?) },
          margin: ->(value) { value.is_a?(Integer) && !value.negative? },
          exit_code_without_arguments: ->(value) { value.is_a?(Integer) && value.between?(0, 255) },
          banner_on_subcommands: BOOLEAN,
          heading_case: ->(value) { HEADING_CASES.include?(value) },
          command_order: ->(value) { COMMAND_ORDERS.include?(value) }
        }.freeze

        DEFAULTS = {
          title: nil,
          description: nil,
          epilogue: nil,
          color: :auto,
          wrap: true,
          width: :terminal,
          margin: 0,
          exit_code_without_arguments: 1,
          banner_on_subcommands: false,
          heading_case: :upcase,
          command_order: :registration
        }.freeze

        # Marks a DSL call made without a value, which reads instead of writes.
        UNSET = Object.new.freeze
        private_constant :UNSET

        # @param values [Hash] settings made on this instance only
        def initialize(values = {})
          @values = values
        end

        SCALARS.each do |name, valid|
          define_method(:"#{name}=") do |value|
            raise ArgumentError, "#{name} cannot be #{value.inspect}" unless valid.call(value)

            @values[name] = value
          end

          define_method(name) do |value = UNSET|
            return @values.fetch(name) { DEFAULTS.fetch(name) } if UNSET.equal?(value)

            public_send(:"#{name}=", value)
          end
        end

        # Replace the text of one section's heading.
        #
        # @param section [Symbol] a key of {HEADINGS}
        # @param text [String]
        # @return [String]
        def heading(section, text)
          raise ArgumentError, "#{section.inspect} has no heading" unless HEADINGS.key?(section)
          raise ArgumentError, "a heading must be a String" unless text.is_a?(String)

          @values[:headings] = @values.fetch(:headings, {}).merge(section => text)
          text
        end

        # @return [Hash{Symbol => String}] every heading's text, before casing
        def headings
          HEADINGS.merge(@values.fetch(:headings, {}))
        end

        # Replace the styles of one element. No styles prints it plain.
        #
        # @param element [Symbol] a key of {STYLES}
        # @param names [Array<Symbol>] names from {Colors::STYLES}
        # @return [Array<Symbol>]
        def style(element, *names)
          raise ArgumentError, "#{element.inspect} is not a styled element" unless STYLES.key?(element)

          unknown = names - Colors::STYLES
          raise ArgumentError, "unknown styles: #{unknown.inspect}" unless unknown.empty?

          @values[:styles] = @values.fetch(:styles, {}).merge(element => names.freeze)
          names
        end

        # @return [Hash{Symbol => Array<Symbol>}] every element's styles
        def styles
          STYLES.merge(@values.fetch(:styles, {}))
        end

        # List commands under a heading of their own, in the order given.
        # Groups print in the order they are declared, after ungrouped commands.
        #
        # @param name [String] the heading
        # @param commands [Array<String>] command paths, such as "compile" or "db migrate"
        # @return [Array<Array(String, Array<String>)>] every group
        def group(name, *commands)
          commands = commands.flatten
          raise ArgumentError, "a group name must be a String" unless name.is_a?(String)
          raise ArgumentError, "group #{name.inspect} lists no commands" if commands.empty?

          @values[:groups] = groups + [[name, commands.map(&:to_s).freeze].freeze]
        end

        # @return [Array<Array(String, Array<String>)>]
        def groups
          @values.fetch(:groups, [])
        end

        # With names, set the order sections print in; a section left out is
        # hidden. Without, read the order.
        #
        # @param names [Array<Symbol>] names from {SECTIONS}
        # @return [Array<Symbol>]
        def sections(*names)
          return @values.fetch(:sections, SECTIONS) if names.empty?

          self.sections = names
        end

        # @param names [Array<Symbol>]
        def sections=(names)
          @values[:sections] = validate_sections(names.flatten)
        end

        # Hide sections without restating the order.
        #
        # @param names [Array<Symbol>] names from {SECTIONS}
        # @return [Array<Symbol>] every hidden section
        def hide(*names)
          @values[:hidden] = hidden | validate_sections(names.flatten)
        end

        # @return [Array<Symbol>]
        def hidden
          @values.fetch(:hidden, [])
        end

        # @return [Array<Symbol>] the sections that print, in order
        def visible_sections
          sections - hidden
        end

        # The column text wraps at, or nil when wrapping is off.
        #
        # @param terminal_width [Integer]
        # @return [Integer, nil]
        def wrap_width(terminal_width)
          return unless wrap

          columns = width == :terminal ? terminal_width - margin : width
          [columns, MIN_WIDTH].max
        end

        # These settings with another instance's laid over them. Headings and
        # styles merge key by key, hidden sections add up, and any other setting
        # the other instance made replaces this one's.
        #
        # @param other [Configuration]
        # @return [Configuration] a new instance
        def merge(other)
          combined = @values.merge(other.values) do |key, mine, theirs|
            case key
            when :headings, :styles then mine.merge(theirs)
            when :hidden then mine | theirs
            else theirs
            end
          end
          self.class.new(combined)
        end

        protected

        attr_reader :values

        private

        def validate_sections(names)
          unknown = names - SECTIONS
          raise ArgumentError, "unknown sections: #{unknown.inspect}" unless unknown.empty?

          names.freeze
        end
      end
    end
  end
end
