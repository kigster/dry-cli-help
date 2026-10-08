# frozen_string_literal: true

module Dry
  class CLI
    module Help
      # One class per kind of help screen.
      module Screens
        # Renders the configured sections a screen supports, in configured
        # order, one blank line apart. A subclass lists the sections it
        # supports in `SECTIONS` and renders each in a private `render_<name>`
        # that returns lines, or nil when there is nothing to print.
        class Base
          Row = Formatter::Row
          INDENT = Formatter::INDENT
          HELP = Row.new(term: "-h, --help", text: "Show help", term_style: :option)

          # @param config [Configuration]
          # @param io [IO] where the screen prints
          # @param terminal_width [Integer]
          # @param include_hidden [Boolean] list hidden commands and options too,
          #   as `--help-include-hidden` asks
          def initialize(config:, io:, terminal_width: Terminal.width, include_hidden: false)
            @config = config
            @include_hidden = include_hidden
            @format = Formatter.new(config, io, terminal_width:)
          end

          # @return [String]
          def render
            config.visible_sections
                  .select { self.class::SECTIONS.include?(it) }
                  .filter_map { send(:"render_#{it}") }
                  .reject(&:empty?)
                  .map { it.join("\n") }
                  .join("\n\n")
          end

          private

          attr_reader :config, :format

          # A subclass answers `banner?` and `epilogue?`: whether the title and
          # description, and the epilogue, print on its screen.
          def render_banner
            return unless banner?

            lines = []
            lines << format.paint(config.title, :title) if config.title
            description = format.paragraph(config.description)
            lines << "" unless lines.empty? || description.empty?
            lines.concat(description)
          end

          def render_epilogue
            format.paragraph(config.epilogue) if epilogue?
          end

          def section(name, body)
            [format.heading(name), *body] unless body.empty?
          end

          # Every definition list on a screen shares one description column,
          # measured over the rows a subclass returns from `aligned_rows`.
          def column
            @column ||= format.column_for([HELP, *aligned_rows])
          end

          def definitions(rows)
            format.definitions(rows, column)
          end

          def include_hidden?
            @include_hidden
          end

          # The nodes of one registry level in the configured order, hidden
          # ones left out unless asked for.
          def visible(children)
            shown = children.to_a
            shown = shown.reject { |_, node| node.hidden } unless include_hidden?
            config.command_order == :alphabetical ? shown.sort_by(&:first) : shown
          end

          # A command's name as a listing prints it: followed by its arguments
          # when `command_arguments` is set, "deploy ENVIRONMENT".
          def command_term(name, node)
            return name unless config.command_arguments && node.command

            "#{name}#{usage_arguments(node.command)}"
          end

          # Required arguments bare, optional ones in brackets: " RULES [OUTPUT]".
          def usage_arguments(command)
            required = command.required_arguments.map { argument_name(it) }
            optional = command.optional_arguments.map { "[#{argument_name(it)}]" }
            names = [*required, *optional]
            " #{names.join(' ')}" unless names.empty?
          end

          def argument_name(argument)
            name = argument.name.to_s.upcase
            argument.array? ? "#{name}..." : name
          end

          # A hidden node, listed only when asked for, says so after its description.
          def describe_node(node)
            text = node_description(node)
            node.hidden ? [text, "(hidden)"].compact.join(" ") : text
          end

          # A group registered without a command has no description of its own,
          # so it describes itself by what it contains.
          def node_description(node)
            return node.command.description if node.command

            names = visible(node.children).map(&:first)
            "Subcommands: #{names.join(', ')}" unless names.empty?
          end
        end
      end
    end
  end
end
