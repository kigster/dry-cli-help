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
      expect(config.heading_case).to eq(:UPPERCASE)
      expect(config.styles).to eq(described_class::STYLES)
      expect(config.sections).to eq(described_class::SECTIONS)
      expect([config.groups, config.hidden]).to eq([[], []])
    end
  end

  describe "single-value settings" do
    valid = {
      title: "MyCLI",
      description: "Compile tax rules.",
      epilogue: "See the manual.",
      color: false,
      wrap: false,
      width: 100,
      margin: 4,
      exit_code_without_arguments: 0,
      banner_on_subcommands: true,
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

  describe "#styles" do
    it "sets several elements in one block and keeps the rest" do
      config.styles do
        heading :underline, :blue
        example :magenta
      end

      expect(config.styles).to include(heading: %i[underline blue], example: %i[magenta], title: %i[bold])
    end

    it "yields the declarations to a block with one argument" do
      config.styles { it.option :red }

      expect(config.styles[:option]).to eq(%i[red])
    end

    it "prints an element plain when given no styles" do
      config.styles { example_comment }

      expect(config.styles[:example_comment]).to eq([])
    end

    it "adds up across blocks" do
      config.styles { title :red }
      config.styles { usage :blue }

      expect(config.styles).to include(title: %i[red], usage: %i[blue])
    end

    it "sets the heading case with the heading's styles" do
      config.styles { heading :bold, case: :Capitalize }

      expect([config.styles[:heading], config.heading_case]).to eq([%i[bold], :Capitalize])
    end

    it "sets the heading case alone and keeps the heading's styles" do
      config.styles { heading case: :lowercase }

      expect([config.styles[:heading], config.heading_case]).to eq([%i[bold yellow], :lowercase])
    end

    it "rejects an unknown element" do
      expect { config.styles { banner :bold } }.to raise_error(NameError, /banner/)
    end

    it "rejects an unknown style" do
      expect { config.styles { title :sparkly } }.to raise_error(ArgumentError, /:sparkly/)
    end

    it "rejects an unknown case" do
      expect { config.styles { heading case: :upcase } }.to raise_error(ArgumentError, /:upcase/)
    end

    it "rejects a case on anything but a heading" do
      expect { config.styles { title :bold, case: :lowercase } }.to raise_error(ArgumentError, /title takes no case:/)
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
end
