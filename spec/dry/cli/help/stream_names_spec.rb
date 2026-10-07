# frozen_string_literal: true

# dry-cli 1.4 holds its streams as `out`/`err`; the kigster fork as `stdout`/
# `stderr`, each wrapped in a Stream that offers the IO underneath as `raw`.
# The integration must find the stream under either name and print past the
# wrapper, whichever dry-cli is loaded.
RSpec.describe Dry::CLI::Help::Integration::CLIMethods do
  let(:cli) { Dry::CLI.new(registry) }
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  def wrapped(io)
    Struct.new(:raw).new(io)
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
end
