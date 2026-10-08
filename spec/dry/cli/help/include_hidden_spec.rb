# frozen_string_literal: true

RSpec.describe "--help-include-hidden" do
  let(:deploy) do
    command do
      desc "Deploy the application"
      option :force, type: :boolean, aliases: ["-f"], desc: "Skip confirmation"
      option :trace, type: :boolean, default: false, hidden: true, desc: "Print every step"
    end
  end

  let(:cli) do
    deploy_command = deploy
    registry do
      register "deploy", deploy_command
      register "secret", (Class.new(Dry::CLI::Command) { def call(**) = nil }), hidden: true
    end
  end

  describe "a listing" do
    it "leaves hidden commands out of plain help" do
      expect(run_cli(cli, "-h").out).not_to include("secret")
    end

    it "lists hidden commands, marked, and exits 0" do
      run = run_cli(cli, "--help-include-hidden")

      expect([run.status, run.err]).to eq([0, ""])
      expect(run.out).to include(<<~TEXT)
        COMMANDS
          deploy      Deploy the application
          secret      (hidden)
      TEXT
    end

    it "marks a hidden command after its description" do
      expect(run_cli(Fixtures::SimpleCLI, "--help-include-hidden").out)
        .to include("  secret      Internal maintenance command (hidden)\n")
    end

    it "lists the hidden commands of a group" do
      cli = registry do
        register "db" do |prefix|
          prefix.register "drop", (Class.new(Dry::CLI::Command) { desc "Drop it"; def call(**) = nil }), hidden: true
        end
      end

      expect(run_cli(cli, "db", "--help-include-hidden").out).to include("  drop        Drop it (hidden)\n")
      expect(run_cli(cli, "db", "-h").out).not_to include("drop")
    end
  end

  describe "a command's help" do
    it "leaves hidden options out of plain help" do
      expect(run_cli(cli, "deploy", "-h").out).not_to include("trace")
    end

    it "lists hidden options, marked, and exits 0" do
      run = run_cli(cli, "deploy", "--help-include-hidden")

      expect(run.status).to eq(0)
      expect(run.out).to end_with(<<~TEXT)
        OPTIONS
          -f, --[no-]force  Skip confirmation
          --[no-]trace      Print every step (hidden; default: false)
          -h, --help        Show help
      TEXT
    end

    it "works alongside -h, wherever the flag stands" do
      expected = run_cli(cli, "deploy", "--help-include-hidden").out

      expect(run_cli(cli, "deploy", "-h", "--help-include-hidden").out).to eq(expected)
      expect(run_cli(cli, "--help-include-hidden", "deploy").out).to eq(expected)
    end

    it "works for a CLI that is a single command" do
      expect(run_cli(deploy, "--help-include-hidden").out).to include("--[no-]trace")
    end
  end

  it "is left to the command after --" do
    received = nil
    cli = registry do
      register "run", (Class.new(Dry::CLI::Command) do
        argument :rest, type: :array
        define_method(:call) { |**args| received = args }
      end)
    end
    run = run_cli(cli, "run", "--", "--help-include-hidden")

    expect([run.status, run.out]).to eq([0, ""])
    expect(received.values.flatten).to include("--help-include-hidden")
  end

  it "does not carry over to the next call" do
    cli_object = Dry::CLI.new(cli)
    out = StringIO.new
    [["--help-include-hidden"], ["-h"]].each do |arguments|
      cli_object.call(arguments:, **streams(out, StringIO.new))
    rescue SystemExit
      nil
    end

    expect(out.string.scan("secret").size).to eq(1)
  end
end
