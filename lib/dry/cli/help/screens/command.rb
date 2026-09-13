# frozen_string_literal: true

module Dry
  class CLI
    module Help
      module Screens
        # The help printed for one command: `mycli deploy -h`.
        class Command < Base
          SECTIONS = %i[banner usage description subcommands arguments options examples epilogue].freeze

          # @param command [Class, Dry::CLI::Command]
          # @param prog_name [String] the program and command path, "mycli db migrate"
          # @param top_level [Boolean] true when the command is the whole CLI,
          #   as with `Dry::CLI.new(SomeCommand)`
          def initialize(command:, prog_name:, top_level: false, **)
            super(**)
            @command = command
            @prog_name = prog_name
            @top_level = top_level
          end

          private

          attr_reader :command, :prog_name

          def banner?
            @top_level || config.banner_on_subcommands
          end

          def epilogue?
            @top_level
          end

          def render_usage
            program = format.paint(prog_name, :command)
            lines = ["#{INDENT}#{program}#{usage_arguments} [OPTIONS]"]
            lines << "#{INDENT}#{program} COMMAND [OPTIONS]" if subcommand_rows.any?
            section(:usage, lines)
          end

          def render_description
            section(:description, format.paragraph(command.description, indent: INDENT))
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
          def render_examples
            rows = command.examples.map do |example|
              line, comment = example.split(" # ", 2)
              Row.new(term: "#{prog_name} #{line.strip}", text: comment&.strip, text_style: :comment)
            end
            section(:examples, format.definitions(rows, format.column_for(rows)))
          end

          def aligned_rows
            subcommand_rows + argument_rows + option_rows
          end

          def usage_arguments
            required = command.required_arguments.map { argument_name(it) }
            optional = command.optional_arguments.map { "[#{argument_name(it)}]" }
            names = [*required, *optional]
            " #{format.paint(names.join(' '), :argument)}" unless names.empty?
          end

          def subcommand_rows
            @subcommand_rows ||= visible(command.subcommands).map do |name, node|
              Row.new(term: name, text: describe_node(node))
            end
          end

          def argument_rows
            @argument_rows ||= command.arguments.map do |argument|
              Row.new(term: argument_name(argument), text: describe(argument), term_style: :argument)
            end
          end

          def option_rows
            @option_rows ||= command.options.map do |option|
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
            [param.options[:desc], ("(#{notes.join('; ')})" if notes.any?)].compact.join(" ")
          end
        end
      end
    end
  end
end
