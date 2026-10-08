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
    Dry::CLI::Help.configure { wrap false }
    cli = registry do
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

  # `example [""]` is how a command says "run me with nothing at all". It used
  # to crash the whole help screen: String#split returns [] for an empty
  # string, and the render then called strip on nil.
  it "renders an empty example as the bare command line" do
    cli = registry do
      register "docs", (Class.new(Dry::CLI::Command) do
        example ["", "-o FILE # write here instead"]
        def call(**) = nil
      end)
    end

    expect(help_for(cli, "docs")).to include(<<~TEXT)
      EXAMPLES
        mycli docs
        mycli docs -o FILE  write here instead
    TEXT
  end

  it "hides examples when asked to" do
    Dry::CLI::Help.configure { it.hide(:examples) }

    expect(help_for(Fixtures::MyCLICLI, "compile")).not_to include("EXAMPLES")
  end

  describe "long help" do
    def screen(long:)
      cmd = command do
        desc "Compile one file"
        define_singleton_method(:long_description) { "Compile one file, and say why each line was kept." }
      end
      described_class.new(command: cmd, prog_name: "mycli compile", long:,
                          config: Dry::CLI::Help.config, io: StringIO.new).render
    end

    it "prints the long description when asked for it" do
      expect(screen(long: true)).to include("say why each line was kept")
    end

    it "prints the one-line description otherwise" do
      text = screen(long: false)
      expect(text).to include("Compile one file\n")
      expect(text).not_to include("say why")
    end
  end

  # kigster/dry-cli stores `example "args", "description"` as a pair, and a list
  # written the dry-cli 1.4 way as one pair holding the list.
  it "renders the kigster fork's example pairs" do
    cmd = command do
      desc "Build"
      define_singleton_method(:examples) do
        [["build", "Compile everything"], [["one.form # one file", "two.form"], ""], ["three.form", nil]]
      end
    end
    text = described_class.new(command: cmd, prog_name: "mycli build",
                               config: Dry::CLI::Help.config, io: StringIO.new).render

    expect(text).to match(/^  mycli build build +Compile everything$/)
    expect(text).to match(/^  mycli build one\.form +one file$/)
    expect(text).to match(/^  mycli build two\.form$/)
    expect(text).to match(/^  mycli build three\.form$/)
  end
end
