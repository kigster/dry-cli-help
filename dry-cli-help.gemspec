# frozen_string_literal: true

require_relative "lib/dry/cli/help/version"

Gem::Specification.new do |spec|
  spec.name = "dry-cli-help"
  spec.version = Dry::CLI::Help::VERSION
  spec.authors = ["Konstantin Gredeskoul"]
  spec.email = ["kigster@gmail.com"]

  spec.summary = "Configurable, wrapped, colored help screens for dry-cli applications"
  spec.description = "Adds a title, description, epilogue, command groups, section ordering, " \
                     "terminal-width wrapping and ANSI colors to the help dry-cli prints, " \
                     "configured through a help block on the registry."
  spec.homepage = "https://github.com/kigster/dry-cli-help"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .rubocop.yml .plans/
                          .secrets.baseline justfile lefthook.yml docs/ examples/ CLAUDE.md])
    end
  end
  spec.require_paths = ["lib"]

  # The integration overrides Dry::CLI#help and Dry::CLI#spell_checker, and the
  # second one first appeared in 1.1.1.
  spec.add_dependency "dry-cli"
  spec.add_dependency "pastel", "~> 0.8"
end
