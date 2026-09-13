# frozen_string_literal: true

RSpec.describe Dry::CLI::Help do
  it "has a version" do
    expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  describe ".configure" do
    it "yields the process-wide configuration and returns it" do
      returned = described_class.configure { it.title = "Taxlibris" }

      expect(returned).to be(described_class.config)
      expect(described_class.config.title).to eq("Taxlibris")
    end
  end

  describe ".reset!" do
    it "forgets every process-wide setting" do
      described_class.configure { it.width = 100 }
      described_class.reset!

      expect(described_class.config.width).to eq(:terminal)
    end
  end

  describe ".config_for" do
    before { described_class.configure { it.width = 100 } }

    it "lays a registry's own settings over the process-wide ones" do
      cli = registry { help { title "Mine" } }
      config = described_class.config_for(cli)

      expect([config.title, config.width]).to eq(["Mine", 100])
    end

    it "uses the process-wide settings for a registry without a help block" do
      expect(described_class.config_for(registry)).to be(described_class.config)
    end

    it "uses the process-wide settings for a single command" do
      expect(described_class.config_for(command)).to be(described_class.config)
    end
  end

  it "installs itself into dry-cli" do
    expect(Dry::CLI.ancestors).to include(described_class::Integration::CLIMethods)
    expect(Dry::CLI::Registry.ancestors).to include(described_class::Integration::RegistryMethods)
  end
end
