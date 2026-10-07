# frozen_string_literal: true

# dry-cli 1.4 holds its streams as `out`/`err`; the kigster fork as `stdout`/
# `stderr`, each wrapped in a Stream that offers the IO underneath as `raw`.
# The integration must find the stream under either name and print past the
# wrapper, whichever dry-cli is loaded.
RSpec.describe Dry::CLI::Help::Integration::CLIMethods do
  let(:cli) { Dry::CLI.new(registry) }
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  # The fork's wrapper, or a stand-in with the same shape where dry-cli 1.4 is loaded.
  def wrapped(io)
    stub_const("Dry::CLI::Stream", Struct.new(:raw)) unless defined?(Dry::CLI::Stream)
    Dry::CLI::Stream.new(io)
  end

  it "reads the fork's stdout and stderr, and writes past its Stream wrapper" do
    fork_out = wrapped(out)
    fork_err = wrapped(err)
    cli.define_singleton_method(:stdout) { fork_out }
    cli.define_singleton_method(:stderr) { fork_err }

    expect(cli.send(:help_out)).to be(out)
    expect(cli.send(:help_err)).to be(err)
  end

  it "reads dry-cli 1.4's out and err as they are" do
    singleton = cli.singleton_class
    singleton.undef_method(:stdout) if singleton.private_method_defined?(:stdout, false)
    allow(cli).to receive(:respond_to?).and_call_original
    allow(cli).to receive(:respond_to?).with(:stdout, true).and_return(false)
    allow(cli).to receive(:respond_to?).with(:stderr, true).and_return(false)
    legacy_out = out
    legacy_err = err
    cli.define_singleton_method(:out) { legacy_out }
    cli.define_singleton_method(:err) { legacy_err }

    expect(cli.send(:help_out)).to be(out)
    expect(cli.send(:help_err)).to be(err)
  end

  # `io/console` defines IO#raw, which switches a terminal to raw mode and
  # raises ENOTTY on a pipe. It must never be mistaken for the wrapper's `raw`.
  it "leaves a plain IO alone even though io/console gives it a raw method" do
    require "io/console"
    pipe_read, pipe_write = IO.pipe
    cli.define_singleton_method(:stdout) { pipe_write }
    cli.define_singleton_method(:stderr) { pipe_write }

    expect(cli.send(:help_out)).to be(pipe_write)
    expect(cli.send(:help_err)).to be(pipe_write)
  ensure
    pipe_read&.close
    pipe_write&.close
  end
end
