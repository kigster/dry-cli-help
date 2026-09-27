# frozen_string_literal: true

module Dry
  class CLI
    module Help
      module Screens
        # The help printed for a registry level: `mycli`, `mycli -h`, and a group
        # such as `mycli db` whose node has no command of its own.
        class Listing < Base
          SECTIONS = %i[banner usage commands options epilogue].freeze

          # @param node [Dry::CLI::Tree::Node] the level to list
          # @param prog_name [String] the program and the names leading to the level, "mycli db"
          def initialize(node:, prog_name:, **)
            super(**)
            @node = node
            @prog_name = prog_name
          end

          private

          attr_reader :node, :prog_name

          def top_level?
            node.path.empty?
          end

          def banner?
            top_level? || config.banner_on_subcommands
          end

          def epilogue?
            top_level?
          end

          def render_usage
            usage = format.paint("#{prog_name} COMMAND [OPTIONS]", :usage)
            section(:usage, ["#{INDENT}#{usage}"])
          end

          def render_commands
            blocks = []
            ungrouped = command_rows.except(*grouped).values
            blocks << section(:commands, definitions(ungrouped)) if ungrouped.any?

            config.groups.each do |name, paths|
              rows = paths.filter_map { command_rows[it] }
              blocks << [format.title(name), *definitions(rows)] if rows.any?
            end

            blocks.inject { |above, below| above + [""] + below }
          end

          def render_options
            section(:options, definitions([HELP, *option_rows]))
          end

          def aligned_rows
            command_rows.values + option_rows
          end

          def grouped
            @grouped ||= config.groups.flat_map(&:last)
          end

          # Commands keyed by full path, so a group can name "db migrate".
          def command_rows
            @command_rows ||= visible(node).each_with_object({}) do |child, rows|
              next if child.name.start_with?("-")

              term = [child.name, *child.aliases.reject { it.start_with?("-") }].join(", ")
              rows[child.path.join(" ")] = Row.new(term:, text: describe_node(child))
            end
          end

          # A command reachable as `--version` or `-v` reads as an option, so it
          # lists under Options by its dashed names.
          def option_rows
            @option_rows ||= visible(node).filter_map do |child|
              dashed = [child.name, *child.aliases].select { it.start_with?("-") }
              next if dashed.empty?

              term = dashed.sort_by { [it.length, it] }.join(", ")
              Row.new(term:, text: describe_node(child), term_style: :option)
            end
          end
        end
      end
    end
  end
end
