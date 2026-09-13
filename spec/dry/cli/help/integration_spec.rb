# frozen_string_literal: true

RSpec.describe Dry::CLI::Help::Integration do
  def plain(text)
    text.gsub(/\e\[[\d;]*m/, "")
  end

  let(:taxlibris) { Fixtures::TaxlibrisCLI }

  before { $PROGRAM_NAME = "taxlibris" }

  describe "top-level help" do
    expected = <<~TEXT
      Taxlibris

      Compile, validate, and evaluate tax rules.

      USAGE
        taxlibris COMMAND [OPTIONS]

      COMMANDS
        compile     Compile tax rules
        validate    Validate the rule corpus
        evaluate    Evaluate a tax return

      OPTIONS
        -h, --help  Show help
        --version   Show version
    TEXT

    it "renders the specification's example for -h, and exits 0" do
      run = run_cli(taxlibris, "-h")

      expect([run.status, plain(run.out), run.err]).to eq([0, expected, ""])
    end

    it "renders the same for --help" do
      expect(plain(run_cli(taxlibris, "--help").out)).to eq(expected)
    end

    it "colors it when the registry asks for color" do
      expect(run_cli(taxlibris, "-h").out).to include("\e[1mTaxlibris\e[0m", "\e[1;33mUSAGE\e[0m")
    end

    it "prints to stderr and exits 1 without arguments, as dry-cli does" do
      run = run_cli(taxlibris)

      expect([run.status, run.out, plain(run.err)]).to eq([1, "", expected])
    end

    it "prints to stdout with the configured exit status without arguments" do
      cli = registry do
        help { exit_code_without_arguments 0 }
        register "run", Class.new(Dry::CLI::Command) { def call(**) = nil }
      end
      run = run_cli(cli)

      expect([run.status, run.err]).to eq([0, ""])
      expect(run.out).to include("COMMANDS\n  run")
    end

    it "suggests a command for a typo, then lists the commands, and exits 1" do
      run = run_cli(taxlibris, "compil")

      expect(run.status).to eq(1)
      expect(plain(run.err)).to start_with("I don't know how to 'compil'. Did you mean: 'compile' ?\n\n")
      expect(plain(run.err)).to end_with(expected)
    end

    it "lists the commands without a suggestion when nothing is close" do
      run = run_cli(taxlibris, "zzzzzzzz")

      expect([run.status, plain(run.err)]).to eq([1, expected])
    end
  end

  describe "command help" do
    it "renders every section a command declares, and exits 0" do
      run = run_cli(taxlibris, "compile", "-h")

      expect(run.status).to eq(0)
      expect(plain(run.out)).to eq(<<~TEXT)
        USAGE
          taxlibris compile RULES [OUTPUT] [OPTIONS]

        DESCRIPTION
          Compile tax rules

        ARGUMENTS
          RULES                    Rule file to compile (required)
          OUTPUT                   Where to write the compiled rules

        OPTIONS
          -f, --format=VALUE       Output format (one of: json, yaml; default: "json")
          --[no-]strict            Treat warnings as errors
          --force                  Overwrite the output
          --only=VALUE1,VALUE2,..  Compile only these forms
          -h, --help               Show help

        EXAMPLES
          taxlibris compile rules.form  compile one file
          taxlibris compile rules.form build/rules.json
      TEXT
    end

    it "prints the banner above command help only when asked to" do
      cli = registry do
        help { title "Tool" }
        register "run", Class.new(Dry::CLI::Command) { def call(**) = nil }
      end

      expect(run_cli(cli, "run", "-h").out).not_to include("Tool")

      cli.help { banner_on_subcommands true }

      expect(run_cli(cli, "run", "-h").out).to start_with("Tool\n\nUSAGE")
    end

    it "treats a single command passed to Dry::CLI.new as the whole program" do
      Dry::CLI::Help.configure do
        it.title = "Solo"
        it.epilogue = "Bye."
      end
      solo = command { desc "Does one thing" }

      expect(run_cli(solo, "-h").out).to start_with("Solo\n\nUSAGE\n  taxlibris [OPTIONS]").and end_with("Bye.\n")
    end
  end

  describe "a group without a command of its own" do
    let(:cli) { Fixtures::HanamiLikeCLI }

    before { $PROGRAM_NAME = "hanami" }

    it "lists the group's commands without a banner or epilogue" do
      Dry::CLI::Help.configure do
        it.title = "Hanami"
        it.epilogue = "Docs at the usual place."
      end
      run = run_cli(cli, "generate", "-h")

      expect([run.status, run.out]).to eq([0, <<~TEXT])
        USAGE
          hanami generate COMMAND [OPTIONS]

        COMMANDS
          migration   Generate a new migration file

        OPTIONS
          -h, --help  Show help
      TEXT
    end

    it "exits with the configured status when named alone" do
      expect(run_cli(cli, "generate").status).to eq(1)
    end
  end

  describe "#help on a registry" do
    it "runs a block without arguments against the configuration" do
      cli = registry { help { title "Evaluated" } }

      expect(cli.help_config.title).to eq("Evaluated")
    end

    it "yields the configuration to a block with one argument" do
      cli = registry { help { it.title = "Yielded" } }

      expect(cli.help_config.title).to eq("Yielded")
    end

    it "returns the configuration without a block" do
      cli = registry

      expect(cli.help_config).to be_nil
      expect(cli.help).to be(cli.help_config)
    end
  end
end
