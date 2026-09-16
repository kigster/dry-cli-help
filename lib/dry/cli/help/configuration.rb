# frozen_string_literal: true

module Dry
  class CLI
    module Help
      # Every help setting, made once for the whole process, two ways:
      #
      #   Dry::CLI::Help.configure do
      #     title "MyCLI"            # as a DSL
      #   end
      #
      #   Dry::CLI::Help.configure do |config|
      #     config.title = "MyCLI"   # on the yielded object
      #   end
      #
      # Every element's look is declared in one {#styles} block. Anything not
      # set reads from {DEFAULTS}, {HEADINGS} or {STYLES}.
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
          usage: %i[green],
          command: %i[green],
          argument: %i[cyan],
          option: %i[cyan],
          example: %i[green],
          example_comment: %i[bold black]
        }.freeze

        # How headings can be cased; each name is written the way it cases.
        # `:Capitalize` raises only the first letter.
        HEADING_CASES = %i[UPPERCASE Capitalize lowercase as_is].freeze
        DEFAULT_HEADING_CASE = :UPPERCASE
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

        # Declare how elements look, all in one place. Each line names an
        # element from {STYLES} and its styles from {Colors::STYLES}; no styles
        # prints it plain. Elements left out keep their defaults. `heading` also
        # takes `case:`, one of {HEADING_CASES}. A block taking an argument
        # receives the declarations instead.
        #
        # @example
        #   styles do
        #     heading :bold, :blue, case: :Capitalize
        #     example_comment              # plain
        #   end
        #
        # @return [Hash{Symbol => Array<Symbol>}] every element's styles
        def styles(&block)
          if block
            sheet = StyleSheet.new
            block.arity == 1 ? yield(sheet) : sheet.instance_eval(&block)
            @values[:styles] = @values.fetch(:styles, {}).merge(sheet.styles)
            @values[:heading_case] = sheet.heading_case if sheet.heading_case
          end
          STYLES.merge(@values.fetch(:styles, {}))
        end

        # How every heading is cased, set by `heading ..., case:` in {#styles}.
        #
        # @return [Symbol] one of {HEADING_CASES}
        def heading_case
          @values.fetch(:heading_case, DEFAULT_HEADING_CASE)
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

        private

        def validate_sections(names)
          unknown = names - SECTIONS
          raise ArgumentError, "unknown sections: #{unknown.inspect}" unless unknown.empty?

          names.freeze
        end

        # What a {Configuration#styles} block runs against: one method per
        # element, each validating what it is given.
        class StyleSheet
          # @return [Hash{Symbol => Array<Symbol>}] the elements declared
          attr_reader :styles

          # @return [Symbol, nil] the heading case, when declared
          attr_reader :heading_case

          def initialize
            @styles = {}
          end

          STYLES.each_key do |element|
            define_method(element) do |*names, **options|
              declare(element, names.flatten, options)
            end
          end

          private

          def declare(element, names, options)
            unknown = names - Colors::STYLES
            raise ArgumentError, "unknown styles for #{element}: #{unknown.inspect}" unless unknown.empty?

            @heading_case = letter_case(element, options) unless options.empty?
            # `heading case: :as_is` alone changes the case and keeps the styles.
            @styles[element] = names.freeze unless names.empty? && !options.empty?
          end

          def letter_case(element, options)
            unless element == :heading && options.keys == [:case]
              raise ArgumentError, "#{element} takes no #{options.keys.map { "#{it}:" }.join(', ')}"
            end

            value = options.fetch(:case)
            return value if HEADING_CASES.include?(value)

            raise ArgumentError, "case cannot be #{value.inspect}; use one of #{HEADING_CASES.inspect}"
          end
        end
      end
    end
  end
end
