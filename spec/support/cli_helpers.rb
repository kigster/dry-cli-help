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
    kernel = ExitRecorder.new
    Dry::CLI.new(target).call(arguments:, stdout: out, stderr: err, kernel:)
    Run.new(status: kernel.status, out: out.string, err: err.string)
  end

  # Records the status the CLI exits with, in place of `Kernel`, so the example keeps running.
  class ExitRecorder
    # @return [Integer] the last status given to {#exit}, or 0 when there was none
    attr_reader :status

    def initialize
      @status = 0
    end

    # @param status [Integer]
    def exit(status)
      @status = status
    end
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
