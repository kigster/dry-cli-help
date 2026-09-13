# frozen_string_literal: true

# Everything this gem reads from dry-cli is marked `@api private` there. None of
# it is a public contract, so this file states the contract instead: a dry-cli
# release that renames any of it fails here, naming what moved, rather than in
# a host's help screen.
RSpec.describe "The dry-cli internals this gem depends on" do
  it "prints command help from a private Dry::CLI#help(command, prog_name)" do
    original = Dry::CLI.instance_method(:help).super_method

    expect([original.owner, original.arity]).to eq([Dry::CLI, 2])
  end

  it "prints registry help from a private Dry::CLI#spell_checker(result, arguments)" do
    original = Dry::CLI.instance_method(:spell_checker).super_method

    expect([original.owner, original.arity]).to eq([Dry::CLI, 2])
  end

  it "exposes the readers the overrides call" do
    expect(%i[kommand registry out err].all? { Dry::CLI.private_method_defined?(it) }).to be(true)
  end

  it "exposes registry nodes and lookups through readers" do
    node_readers = %i[parent children aliases hidden command]

    expect(node_readers - Dry::CLI::CommandRegistry::Node.public_instance_methods).to be_empty
    expect(%i[names children] - Dry::CLI::CommandRegistry::LookupResult.public_instance_methods)
      .to be_empty
  end

  it "suggests a command through Dry::CLI::SpellChecker.call(result, arguments)" do
    expect(Dry::CLI::SpellChecker.method(:call).arity).to eq(2)
  end
end
