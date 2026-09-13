# frozen_string_literal: true

RSpec.describe Dry::CLI::Help::Screens::Listing do
  def help_for(cli, *path)
    run_cli(cli, *path, "-h").out
  end

  describe "a registry someone else shaped" do
    before { $PROGRAM_NAME = "hanami" }

    it "lists commands in registration order, with aliases, hiding hidden ones" do
      expect(help_for(Fixtures::HanamiLikeCLI)).to eq(<<~TEXT)
        USAGE
          hanami COMMAND [OPTIONS]

        COMMANDS
          version      Print the framework version
          db           Show pending migrations
          generate, g  Subcommands: migration

        OPTIONS
          -h, --help   Show help
      TEXT
    end

    it "lists commands alphabetically when asked to" do
      Dry::CLI::Help.configure { it.command_order = :alphabetical }

      expect(help_for(Fixtures::HanamiLikeCLI)).to include(<<~TEXT)
        COMMANDS
          db           Show pending migrations
          generate, g  Subcommands: migration
          version      Print the framework version
      TEXT
    end

    it "prints the banner above a group's listing when asked to" do
      Dry::CLI::Help.configure do
        it.title = "Hanami"
        it.banner_on_subcommands = true
      end

      expect(help_for(Fixtures::HanamiLikeCLI, "generate")).to start_with("Hanami\n\nUSAGE\n  hanami generate")
    end

    it "groups a group's commands by their full path" do
      Dry::CLI::Help.configure { it.group("Generators", "generate migration") }

      expect(help_for(Fixtures::HanamiLikeCLI, "generate")).to include(<<~TEXT)
        GENERATORS
          migration   Generate a new migration file
      TEXT
    end
  end

  describe "command groups" do
    before { $PROGRAM_NAME = "taxlibris" }

    let(:output) { help_for(Fixtures::TaxlibrisCLI).gsub(/\e\[[\d;]*m/, "") }

    it "lists ungrouped commands first, then each group in declaration order" do
      Dry::CLI::Help.configure do
        it.group("Rules", "validate", "compile")
        it.group("Nothing here", "missing")
      end

      expect(output).to include(<<~TEXT)
        COMMANDS
          evaluate    Evaluate a tax return

        RULES
          validate    Validate the rule corpus
          compile     Compile tax rules

        OPTIONS
      TEXT
      expect(output).not_to include("NOTHING HERE")
    end

    it "prints no Commands heading when every command is grouped" do
      Dry::CLI::Help.configure { it.group("All", "compile", "validate", "evaluate") }

      expect(output).to include("ALL\n  compile")
      expect(output).not_to include("COMMANDS")
    end
  end

  describe "sections" do
    let(:cli) do
      registry do
        help do
          title "Tool"
          epilogue "Read the manual."
        end
        register "run", Class.new(Dry::CLI::Command) { desc "Run it"; def call(**) = nil }
      end
    end

    it "prints the epilogue last" do
      expect(help_for(cli)).to end_with("Show help\n\nRead the manual.\n")
    end

    it "prints sections in the configured order, leaving out the rest" do
      cli.help { sections :commands, :banner }

      expect(help_for(cli)).to eq("COMMANDS\n  run         Run it\n\nTool\n")
    end

    it "hides sections" do
      cli.help { hide :banner, :usage, :options, :epilogue }

      expect(help_for(cli)).to eq("COMMANDS\n  run         Run it\n")
    end

    it "uses custom heading text and case" do
      cli.help do
        heading :commands, "available commands"
        heading_case :capitalize
      end

      expect(help_for(cli)).to include("Available commands\n  run")
    end

    it "prints the title alone when there is no description" do
      expect(help_for(cli)).to start_with("Tool\n\nUSAGE")
    end

    it "prints the description alone when there is no title" do
      cli.help do
        title nil
        description "Does things."
      end

      expect(help_for(cli)).to start_with("Does things.\n\nUSAGE")
    end
  end

  describe "edge shapes" do
    it "prints no Commands section when every command is an option" do
      cli = registry { register "--version", Class.new(Dry::CLI::Command) { desc "Show version"; def call(**) = nil } }

      expect(help_for(cli)).to eq(<<~TEXT)
        USAGE
          mycli COMMAND [OPTIONS]

        OPTIONS
          -h, --help  Show help
          --version   Show version
      TEXT
    end

    it "describes nothing for a group whose commands are all hidden" do
      hidden = Class.new(Dry::CLI::Command) { def call(**) = nil }
      cli = registry do
        register "tools" do |prefix|
          prefix.register "secret", hidden, hidden: true
        end
      end

      expect(help_for(cli)).to include("COMMANDS\n  tools\n")
    end
  end
end
