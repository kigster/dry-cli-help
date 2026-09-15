# frozen_string_literal: true

RSpec.describe Dry::CLI::Help do
  it "has a version" do
    expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  describe ".configure" do
    it "yields the process-wide configuration and returns it" do
      returned = described_class.configure { it.title = "MyCLI" }

      expect(returned).to be(described_class.config)
      expect(described_class.config.title).to eq("MyCLI")
    end

    it "runs a block without arguments against the configuration" do
      described_class.configure do
        title "Evaluated"
        styles { heading :underline }
      end

      expect([described_class.config.title, described_class.config.styles[:heading]])
        .to eq(["Evaluated", %i[underline]])
    end
  end

  describe ".reset!" do
    it "forgets every process-wide setting" do
      described_class.configure { it.width = 100 }
      described_class.reset!

      expect(described_class.config.width).to eq(:terminal)
    end
  end

  it "installs itself into dry-cli, and leaves dry-cli's registry DSL alone" do
    expect(Dry::CLI.ancestors).to include(described_class::Integration::CLIMethods)
    expect(Module.new.extend(Dry::CLI::Registry)).not_to respond_to(:help)
  end
end
