# frozen_string_literal: true

module Dry
  class CLI
    module Help
      module Screens
        # The help printed for a registry level: `mycli`, `mycli -h`, and a group
        # such as `mycli db` whose node has no command of its own.
        class Listing < Base
          SECTIONS = %i[banner usage commands options epilogue].freeze

          # @param result [Dry::CLI::CommandRegistry::LookupResult] the level to list
          def initialize(result:, **)
            super(**)
            @result = result
          end

          private

          attr_reader :result

          def top_level?
            result.names.empty?
          end

          def banner?
            top_level? || config.banner_on_subcommands
          end

          def epilogue?
            top_level?
          end

          def render_usage
            usage = format.paint("#{ProgramName.call(result.names)} COMMAND [OPTIONS]", :usage)
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
            @command_rows ||= entries.each_with_object({}) do |(name, node, aliases), rows|
              next if name.start_with?("-")

              term = [name, *aliases.reject { it.start_with?("-") }].join(", ")
              rows[[*result.names, name].join(" ")] = Row.new(term:, text: describe_node(node))
            end
          end

          # A command reachable as `--version` or `-v` reads as an option, so it
          # lists under Options by its dashed names.
          def option_rows
            @option_rows ||= entries.filter_map do |name, node, aliases|
              dashed = [name, *aliases].select { it.start_with?("-") }
              next if dashed.empty?

              term = dashed.sort_by { [it.length, it] }.join(", ")
              Row.new(term:, text: describe_node(node), term_style: :option)
            end
          end

          def entries
            @entries ||= visible(result.children).map do |name, node|
              [name, node, aliases_of(node)]
            end
          end

          # dry-cli files an alias on the parent node, pointing at the child.
          def aliases_of(node)
            node.parent.aliases.filter_map { |name, target| name if target.equal?(node) }
          end
        end
      end
    end
  end
end
