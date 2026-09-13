# frozen_string_literal: true

# Runs a CLI the way a shell would, and captures what it printed and how it exited.
module CLIHelpers
  Run = Data.define(:status, :out, :err)

  # @param target [Module, Class] a registry or a single command
  # @param arguments [Array<String>]
  # @return [Run]
  def run_cli(target, *arguments)
    out = StringIO.new
    err = StringIO.new
    status = 0
    begin
      Dry::CLI.new(target).call(arguments:, out:, err:)
    rescue SystemExit => e
      status = e.status
    end
    Run.new(status:, out: out.string, err: err.string)
  end

  # A registry built for one example, so its help block cannot leak into another.
  # @return [Module]
  def registry(&block)
    Module.new do
      extend Dry::CLI::Registry

      module_eval(&block) if block
    end
  end

  # @return [Class] a command class carrying whatever the block declares
  def command(&block)
    Class.new(Dry::CLI::Command) do
      class_eval(&block) if block

      def call(**); end
    end
  end

  # A StringIO that claims to be a terminal.
  def tty_io
    StringIO.new.tap { |io| io.define_singleton_method(:tty?) { true } }
  end
end
