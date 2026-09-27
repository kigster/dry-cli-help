# frozen_string_literal: true

# Everything this gem reads from dry-cli, stated as a contract: a dry-cli release
# that renames any of it fails here, naming what moved, rather than in a host's
# help screen. All of it is dry-cli's public API.
RSpec.describe "The dry-cli API this gem depends on" do
  it "takes a help renderer through Dry::CLI.configure" do
    expect(Dry::CLI.config.help).to respond_to(:renderer=)
  end

  it "hands the renderer a Dry::CLI::Screen" do
    expect(Dry::CLI::Screen.members).to include(
      :kind, :reason, :node, :prog_name, :suggestion, :text, :status, :stdout, :stderr
    )
    expect(Dry::CLI::Screen.public_instance_methods).to include(:command?, :io, :with)
  end

  it "describes commands through Dry::CLI::Tree::Node" do
    readers = %i[name path aliases hidden? command description examples arguments options children]

    expect(readers - Dry::CLI::Tree::Node.public_instance_methods).to be_empty
  end

  it "describes options and arguments through Dry::CLI::Tree::Param" do
    readers = %i[name desc required? default values aliases boolean? flag? array?]

    expect(readers - Dry::CLI::Tree::Param.public_instance_methods).to be_empty
  end

  it "reaches the IO beneath a stream through Dry::CLI::Stream#raw" do
    expect(Dry::CLI::Stream.public_instance_methods).to include(:raw)
  end

  it "exits through the kernel Dry::CLI#call is given" do
    expect(Dry::CLI.instance_method(:call).parameters).to include([:key, :kernel])
  end
end
