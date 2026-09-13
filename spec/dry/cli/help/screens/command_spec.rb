# frozen_string_literal: true

RSpec.describe Dry::CLI::Help::Screens::Command do
  def help_for(cli, *path)
    run_cli(cli, *path, "-h").out
  end

  it "shows a command that also has subcommands both ways" do
    expect(help_for(Fixtures::SimpleCLI, "db")).to eq(<<~TEXT)
      USAGE
        mycli db [OPTIONS]
        mycli db COMMAND [OPTIONS]

      DESCRIPTION
        Show pending migrations

      SUBCOMMANDS
        migrate         Run pending migrations

      OPTIONS
        --[no-]verbose  Print full migration history
        -h, --help      Show help
    TEXT
  end

  it "marks an array argument as repeatable" do
    output = help_for(Fixtures::PackageManagerCLI, "install")

    expect(output).to include("mycli install [PACKAGES...] [OPTIONS]", "  -D, --[no-]save-dev")
    expect(output).to match(/^  PACKAGES\.\.\. +Package names to install$/)
  end

  it "prints only usage and options for a command that declares nothing" do
    cli = registry { register "bare", Class.new(Dry::CLI::Command) { def call(**) = nil } }

    expect(help_for(cli, "bare")).to eq(<<~TEXT)
      USAGE
        mycli bare [OPTIONS]

      OPTIONS
        -h, --help  Show help
    TEXT
  end

  it "orders short aliases, the option, then long aliases" do
    cli = registry do
      register "run", (Class.new(Dry::CLI::Command) do
        option :dry_run, type: :boolean, aliases: ["--dry", "-n"]
        def call(**) = nil
      end)
    end

    expect(help_for(cli, "run")).to include("  -n, --[no-]dry-run, --dry\n")
  end

  it "notes values even without a description" do
    cli = registry do
      register "set", (Class.new(Dry::CLI::Command) do
        argument :level, values: %w[low high]
        def call(**) = nil
      end)
    end

    expect(help_for(cli, "set")).to include("  LEVEL       (one of: low, high)\n")
  end

  it "keeps a long description on one line when wrapping is off" do
    long = "word " * 30
    cli = registry do
      help { wrap false }
      register "run", Class.new(Dry::CLI::Command) { desc long.strip; def call(**) = nil }
    end

    expect(help_for(cli, "run")).to include("  #{long.strip}\n")
  end

  it "wraps a long description to the terminal" do
    cli = registry do
      register "run", Class.new(Dry::CLI::Command) { desc ("word " * 30).strip; def call(**) = nil }
    end

    expect(help_for(cli, "run").lines.map(&:length).max).to be <= 81
  end

  it "hides examples when asked to" do
    Dry::CLI::Help.configure { it.hide(:examples) }

    expect(help_for(Fixtures::TaxlibrisCLI, "compile")).not_to include("EXAMPLES")
  end
end
