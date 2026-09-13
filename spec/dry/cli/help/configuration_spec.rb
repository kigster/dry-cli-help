# frozen_string_literal: true

RSpec.describe Dry::CLI::Help::Configuration do
  subject(:config) { described_class.new }

  describe "defaults" do
    it "reads the default of every single-value setting" do
      expect(described_class::SCALARS.keys.to_h { [it, config.public_send(it)] })
        .to eq(described_class::DEFAULTS)
    end

    it "has every heading, style and section, no groups and nothing hidden" do
      expect(config.headings).to eq(described_class::HEADINGS)
      expect(config.styles).to eq(described_class::STYLES)
      expect(config.sections).to eq(described_class::SECTIONS)
      expect([config.groups, config.hidden]).to eq([[], []])
    end
  end

  describe "single-value settings" do
    valid = {
      title: "Taxlibris",
      description: "Compile tax rules.",
      epilogue: "See the manual.",
      color: false,
      wrap: false,
      width: 100,
      margin: 4,
      exit_code_without_arguments: 0,
      banner_on_subcommands: true,
      heading_case: :capitalize,
      command_order: :alphabetical
    }

    invalid = {
      title: 1,
      description: :text,
      epilogue: [],
      color: "yes",
      wrap: nil,
      width: 0,
      margin: -1,
      exit_code_without_arguments: 256,
      banner_on_subcommands: "no",
      heading_case: :shout,
      command_order: :random
    }

    valid.each do |name, value|
      it "sets #{name} through the DSL and through a writer" do
        dsl = described_class.new
        dsl.public_send(name, value)
        config.public_send(:"#{name}=", value)

        expect([dsl.public_send(name), config.public_send(name)]).to eq([value, value])
      end
    end

    invalid.each do |name, value|
      it "rejects #{value.inspect} for #{name}" do
        expect { config.public_send(name, value) }.to raise_error(ArgumentError, /#{name}/)
      end
    end

    it "accepts every documented value" do
      expect { config.color(:auto) }.not_to raise_error
      expect { config.width(:terminal) }.not_to raise_error
      expect { config.heading_case(:none) }.not_to raise_error
      expect { config.title(nil) }.not_to raise_error
    end
  end

  describe "#heading" do
    it "replaces one heading's text and keeps the others" do
      config.heading(:commands, "Available commands")

      expect(config.headings).to include(commands: "Available commands", usage: "Usage")
    end

    it "rejects a section without a heading" do
      expect { config.heading(:banner, "Banner") }.to raise_error(ArgumentError, /:banner/)
    end

    it "rejects text that is not a String" do
      expect { config.heading(:usage, :synopsis) }.to raise_error(ArgumentError, /String/)
    end
  end

  describe "#style" do
    it "replaces one element's styles and keeps the others" do
      config.style(:heading, :underline, :blue)

      expect(config.styles).to include(heading: %i[underline blue], title: %i[bold])
    end

    it "prints an element plain when given no styles" do
      config.style(:comment)

      expect(config.styles[:comment]).to eq([])
    end

    it "rejects an unknown element" do
      expect { config.style(:banner, :bold) }.to raise_error(ArgumentError, /:banner/)
    end

    it "rejects an unknown style" do
      expect { config.style(:title, :sparkly) }.to raise_error(ArgumentError, /:sparkly/)
    end
  end

  describe "#group" do
    it "collects groups in declaration order" do
      config.group("Rules", "compile", "validate")
      config.group("Returns", %w[evaluate])

      expect(config.groups).to eq([["Rules", %w[compile validate]], ["Returns", %w[evaluate]]])
    end

    it "rejects a name that is not a String" do
      expect { config.group(:rules, "compile") }.to raise_error(ArgumentError, /String/)
    end

    it "rejects a group without commands" do
      expect { config.group("Empty") }.to raise_error(ArgumentError, /no commands/)
    end
  end

  describe "#sections and #hide" do
    it "sets the order and hides what it leaves out" do
      config.sections(:options, :usage)

      expect(config.visible_sections).to eq(%i[options usage])
    end

    it "sets the order through a writer" do
      config.sections = %i[usage commands]

      expect(config.sections).to eq(%i[usage commands])
    end

    it "hides sections cumulatively without changing the order" do
      config.hide(:banner)
      config.hide(%i[examples banner])

      expect(config.hidden).to eq(%i[banner examples])
      expect(config.visible_sections.first).to eq(:usage)
    end

    it "rejects unknown sections" do
      expect { config.sections(:footer) }.to raise_error(ArgumentError, /:footer/)
      expect { config.hide(:footer) }.to raise_error(ArgumentError, /:footer/)
    end
  end

  describe "#wrap_width" do
    it "is nil when wrapping is off" do
      config.wrap = false

      expect(config.wrap_width(120)).to be_nil
    end

    it "is the terminal width minus the margin" do
      config.margin = 4

      expect(config.wrap_width(120)).to eq(116)
    end

    it "is a fixed width regardless of the margin" do
      config.width = 72
      config.margin = 4

      expect(config.wrap_width(120)).to eq(72)
    end

    it "never falls below the minimum" do
      config.margin = 50

      expect(config.wrap_width(60)).to eq(described_class::MIN_WIDTH)
    end
  end

  describe "#merge" do
    let(:global) do
      described_class.new.tap do
        it.title = "Global"
        it.width = 100
        it.heading(:usage, "Synopsis")
        it.style(:title, :red)
        it.hide(:banner)
        it.group("Global group", "one")
      end
    end

    let(:local) do
      described_class.new.tap do
        it.title = "Local"
        it.heading(:commands, "Things")
        it.style(:heading, :blue)
        it.hide(:epilogue)
        it.group("Local group", "two")
      end
    end

    let(:merged) { global.merge(local) }

    it "returns a new instance and changes neither side" do
      expect(merged).not_to be(global)
      expect([global.title, local.title]).to eq(%w[Global Local])
    end

    it "lets the other side's settings win" do
      expect([merged.title, merged.width]).to eq(["Local", 100])
    end

    it "merges headings and styles key by key" do
      expect(merged.headings).to include(usage: "Synopsis", commands: "Things")
      expect(merged.styles).to include(title: %i[red], heading: %i[blue])
    end

    it "adds up hidden sections" do
      expect(merged.hidden).to eq(%i[banner epilogue])
    end

    it "replaces groups" do
      expect(merged.groups).to eq([["Local group", %w[two]]])
    end
  end
end
