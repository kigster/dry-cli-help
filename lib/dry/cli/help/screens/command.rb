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
          # @param long [Boolean] show the command's `long_desc` when it has one
          def initialize(command:, prog_name:, top_level: false, long: false, **)
            super(**)
            @command = command
            @prog_name = prog_name
            @top_level = top_level
            @long = long
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
            lines = ["#{prog_name}#{usage_arguments(command)} [OPTIONS]"]
            lines << "#{prog_name} COMMAND [OPTIONS]" if subcommand_rows.any?
            section(:usage, lines.map { INDENT + format.paint(it, :usage) })
          end

          def render_description
            section(:description, format.paragraph(description, indent: INDENT))
          end

          # The long description for `--help` where the command declares one
          # (`long_desc`, kigster/dry-cli), otherwise the one-line `desc`.
          def description
            long = command.long_description if @long && command.respond_to?(:long_description)
            long || command.description
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
          # An empty example is how a command says "run me with nothing at
          # all", and String#split answers [] for it, so `line` is nil and only
          # the program name is left to print.
          def render_examples
            rows = example_pairs.map do |line, comment|
              term = [prog_name, line&.strip].reject { it.nil? || it.empty? }.join(" ")
              Row.new(term: term, text: comment&.strip,
                      term_style: :example, text_style: :example_comment)
            end
            section(:examples, format.definitions(rows, format.column_for(rows)))
          end

          # Every example as `[args, comment]`. dry-cli 1.4 keeps one string per
          # example, "args # comment". The kigster fork keeps `[args, description]`
          # pairs, and a list handed to it in the 1.4 spelling arrives as one pair
          # holding the list and an empty description.
          def example_pairs
            command.examples.flat_map { pairs_of(it) }
          end

          def pairs_of(example)
            return [example.split(" # ", 2)] unless example.is_a?(Array)

            text, description = example
            return text.flat_map { pairs_of(it) } if text.is_a?(Array)
            return pairs_of(text) if description.nil? || description.empty?

            [[text, description]]
          end

          def aligned_rows
            subcommand_rows + argument_rows + option_rows
          end

          def subcommand_rows
            @subcommand_rows ||= visible(command.subcommands).map do |name, node|
              Row.new(term: command_term(name, node), text: describe_node(node))
            end
          end

          def argument_rows
            @argument_rows ||= command.arguments.map do |argument|
              Row.new(term: argument_name(argument), text: describe(argument), term_style: :argument)
            end
          end

          # An option declared `hidden: true` lists only when hidden ones are asked for.
          def option_rows
            @option_rows ||= command.options.filter_map do |option|
              hidden = option.options.fetch(:hidden, false)
              next if hidden && !include_hidden?

              Row.new(term: option_term(option), text: describe(option, hidden:), term_style: :option)
            end
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
          def describe(param, hidden: false)
            notes = []
            notes << "hidden" if hidden
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
