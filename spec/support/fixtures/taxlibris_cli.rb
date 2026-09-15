# frozen_string_literal: true

require "dry/cli"

module Fixtures
  # The example from SPECIFICATION.md, extended with one command that uses
  # every feature a command screen renders.
  module MyCLICLI
    extend Dry::CLI::Registry

    class Compile < Dry::CLI::Command
      desc "Compile tax rules"

      argument :rules, required: true, desc: "Rule file to compile"
      argument :output, desc: "Where to write the compiled rules"
      option :format, values: %w[json yaml], default: "json", aliases: ["-f"], desc: "Output format"
      option :strict, type: :boolean, desc: "Treat warnings as errors"
      option :force, type: :flag, desc: "Overwrite the output"
      option :only, type: :array, desc: "Compile only these forms"

      example ["rules.form # compile one file", "rules.form build/rules.json"]

      def call(**); end
    end

    class Validate < Dry::CLI::Command
      desc "Validate the rule corpus"

      def call(**); end
    end

    class Evaluate < Dry::CLI::Command
      desc "Evaluate a tax return"

      def call(**); end
    end

    class Version < Dry::CLI::Command
      desc "Show version"

      def call(**); end
    end

    # The settings a host would make once, at boot.
    def self.configure_help
      Dry::CLI::Help.configure do
        title "MyCLI"

        description <<~TEXT
          Compile, validate, and evaluate tax rules.
        TEXT

        color true
        width :terminal
        wrap true
      end
    end

    register "compile", Compile
    register "validate", Validate
    register "evaluate", Evaluate
    register "--version", Version
  end
end
