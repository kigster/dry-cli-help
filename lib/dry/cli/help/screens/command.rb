# frozen_string_literal: true

module Dry
  class CLI
    module Help
      module Screens
        # The help printed for one command: `mycli deploy -h`.
        class Command < Base
          SECTIONS = %i[banner usage description subcommands arguments options examples epilogue].freeze

          # @param node [Dry::CLI::Tree::Node] the command
          # @param prog_name [String] the program and command path, "mycli db migrate"
          # @param top_level [Boolean] true when the command is the whole CLI,
          #   as with `Dry::CLI.new(SomeCommand)`
          def initialize(node:, prog_name:, top_level: false, **)
            super(**)
            @node = node
            @prog_name = prog_name
            @top_level = top_level
          end

          private

          attr_reader :node, :prog_name

          def banner?
            @top_level || config.banner_on_subcommands
          end

          def epilogue?
            @top_level
          end

          def render_usage
            lines = ["#{prog_name}#{usage_arguments} [OPTIONS]"]
            lines << "#{prog_name} COMMAND [OPTIONS]" if subcommand_rows.any?
            section(:usage, lines.map { INDENT + format.paint(it, :usage) })
          end

          def render_description
            section(:description, format.paragraph(node.description, indent: INDENT))
          end

          def render_subcommands
            section(:subcommands, definitions(subcommand_rows))
          end

          def render_arguments
            section(:arguments, definitions(argument_rows))
          end

          def render_options
            section(:options, definitions([*option_rows, HELP]))
          end

          # Examples align among themselves: a full command line is longer than
          # any option, and would push every other description off to the right.
          #
          # dry-cli gives each example as its arguments and a description. An
          # example declared the older way, as `"args # description"` with no
          # description of its own, is split at the " # ". An empty example is
          # how a command says "run me with nothing at all", so only the
          # program name is left to print.
          def render_examples
            rows = node.examples.map do |line, comment|
              line, comment = line.split(" # ", 2) if comment.to_s.empty?
              term = [prog_name, line&.strip].reject { it.nil? || it.empty? }.join(" ")
              Row.new(term: term, text: comment&.strip,
                      term_style: :example, text_style: :example_comment)
            end
            section(:examples, format.definitions(rows, format.column_for(rows)))
          end

          def aligned_rows
            subcommand_rows + argument_rows + option_rows
          end

          def usage_arguments
            required, optional = node.arguments.partition(&:required?)
            required = required.map { argument_name(it) }
            optional = optional.map { "[#{argument_name(it)}]" }
            names = [*required, *optional]
            " #{names.join(' ')}" unless names.empty?
          end

          def subcommand_rows
            @subcommand_rows ||= visible(node).map do |child|
              Row.new(term: child.name, text: describe_node(child))
            end
          end

          def argument_rows
            @argument_rows ||= node.arguments.map do |argument|
              Row.new(term: argument_name(argument), text: describe(argument), term_style: :argument)
            end
          end

          def option_rows
            @option_rows ||= node.options.map do |option|
              Row.new(term: option_term(option), text: describe(option), term_style: :option)
            end
          end

          def argument_name(argument)
            name = argument.name.to_s.upcase
            argument.array? ? "#{name}..." : name
          end

          # Short aliases, then the option, then long aliases: "-f, --[no-]force".
          def option_term(option)
            name = option.name.to_s.downcase.gsub(/[[:space:]]|_/, "-")
            main = if option.boolean? then "--[no-]#{name}"
                   elsif option.flag? then "--#{name}"
                   elsif option.array? then "--#{name}=VALUE1,VALUE2,.."
                   else "--#{name}=VALUE"
                   end
            aliases = option.aliases.map { it.sub(/\A-{1,2}/, "") }.uniq
            short, long = aliases.partition { it.length == 1 }
            [*short.map { "-#{it}" }, main, *long.map { "--#{it}" }].join(", ")
          end

          # The description, then what a reader needs to use the value.
          def describe(param)
            notes = []
            notes << "required" if param.required?
            notes << "one of: #{param.values.join(', ')}" if param.values
            notes << "default: #{param.default.inspect}" unless param.default.nil?
            [param.desc, ("(#{notes.join('; ')})" if notes.any?)].compact.join(" ")
          end
        end
      end
    end
  end
end
