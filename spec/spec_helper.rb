# frozen_string_literal: true

ENV["RUBYOPT"] = "-W0"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rspec/its"
require "stringio"

# A full run enforces 100% line and branch coverage. A run limited to some
# files measures only when COVERAGE is set, and never fails on the minimum.
full_run = ARGV.empty?

if full_run || ENV["COVERAGE"]
  require "simplecov"
  require "coverage/badge"

  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage line: 100, branch: 100 if full_run
    cover "lib/**/*.rb"
    skip "/spec/"
    # The gemspec requires this before SimpleCov starts, under `bundle exec`,
    # so no run can ever measure it. It holds one constant.
    skip "lib/dry/cli/help/version.rb"
    self.formatters = SimpleCov::Formatter::MultiFormatter.new(
      [
        SimpleCov::Formatter::HTMLFormatter,
        Coverage::Badge::Formatter
      ]
    )
  end

  SimpleCov.at_exit do
    SimpleCov.result.format!
    puts "Coverage: #{SimpleCov.result.covered_percent.round(2)}%"
    FileUtils.mkdir_p("docs/img")
    FileUtils.mv("coverage/badge.svg", "docs/img/badge.svg")
  end
end

require "dry-cli-help"

PROJECT_ROOT = File.expand_path("..", __dir__)

Dir[File.join(__dir__, "support", "**", "*.rb")].each { require it }

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.include CLIHelpers

  # Help settings and the color switch are process-wide, and COLUMNS decides
  # every wrap width, so each example starts from the same place.
  config.around do |example|
    columns = ENV.fetch("COLUMNS", nil)
    no_color = ENV.fetch("NO_COLOR", nil)
    program = $PROGRAM_NAME
    ENV["COLUMNS"] = "80"
    ENV.delete("NO_COLOR")
    $PROGRAM_NAME = "mycli"
    example.run
  ensure
    ENV["COLUMNS"] = columns
    ENV["NO_COLOR"] = no_color
    $PROGRAM_NAME = program
    Dry::CLI::Help.reset!
    Dry::CLI::Help::Colors.enabled = :auto
  end
end
