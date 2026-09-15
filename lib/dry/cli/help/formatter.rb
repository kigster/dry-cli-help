# frozen_string_literal: true

module Dry
  class CLI
    module Help
      # The pieces every help screen is made of: headings, paragraphs and
      # definition lists, wrapped to one width and painted with one palette.
      #
      # Text wraps before it is painted, so escape codes never count toward a
      # line's length.
      class Formatter
        INDENT = "  "
        GAP = 2

        # One line of a definition list: a term, and the text that describes it.
        Row = ::Data.define(:term, :text, :term_style, :text_style) do
          def initialize(term:, text: nil, term_style: :command, text_style: nil)
            super
          end
        end

        # @return [Configuration]
        attr_reader :config

        # @return [Integer, nil] the column text wraps at, nil when it does not
        attr_reader :width

        # @param config [Configuration]
        # @param io [IO] where the screen prints, which decides `color :auto`
        # @param terminal_width [Integer]
        def initialize(config, io, terminal_width: Terminal.width)
          @config = config
          @width = config.wrap_width(terminal_width)
          @pastel = ::Pastel.new(enabled: Colors.enabled_for?(config.color, io))
        end

        # @param text [String]
        # @param element [Symbol, nil] a key of {Configuration::STYLES}; nil paints nothing
        # @return [String]
        def paint(text, element)
          return text if element.nil?

          @pastel.decorate(text, *config.styles.fetch(element))
        end

        # @param section [Symbol]
        # @return [String]
        def heading(section)
          title(config.headings.fetch(section))
        end

        # A heading in the configured case and style, for any text.
        #
        # @param text [String]
        # @return [String]
        def title(text)
          cased = case config.heading_case
                  when :UPPERCASE then text.upcase
                  when :lowercase then text.downcase
                  when :Capitalize then text.sub(/\A\p{Ll}/, &:upcase)
                  else text
                  end
          paint(cased, :heading)
        end

        # @param text [String, nil]
        # @param indent [String]
        # @return [Array<String>] wrapped lines; blank lines carry no indent
        def paragraph(text, indent: "")
          Text.lines(text, width && (width - indent.length)).map do |line|
            line.empty? ? line : indent + line
          end
        end

        # The description column for a set of rows: the longest term that has
        # a description, but never more than half the wrap width. A term with
        # nothing beside it has nothing to align.
        #
        # @param rows [Array<Row>]
        # @return [Integer]
        def column_for(rows)
          longest = rows.reject { it.text.to_s.empty? }.map { it.term.length }.max || 0
          width ? [longest, width / 2].min : longest
        end

        # @param rows [Array<Row>]
        # @param column [Integer] from {#column_for}
        # @return [Array<String>]
        def definitions(rows, column)
          rows.flat_map { definition(it, column) }
        end

        private

        def definition(row, column)
          term = INDENT + paint(row.term, row.term_style)
          offset = INDENT.length + column + GAP
          lines = Text.lines(row.text, width && [width - offset, Configuration::MIN_WIDTH].max)
          return [term] if lines.empty?

          body = lines.map { it.empty? ? it : paint(it, row.text_style) }
          hanging = body.map { it.empty? ? it : (" " * offset) + it }
          return [term, *hanging] if row.term.length > column

          [term + (" " * (column + GAP - row.term.length)) + body.first, *hanging.drop(1)]
        end
      end
    end
  end
end
