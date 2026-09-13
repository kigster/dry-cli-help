# frozen_string_literal: true

require "dry/struct"

# This gem's files sit inside `module Dry`, so an unqualified constant resolves
# there first: a bare `Struct` would become `Dry::Struct` in any host that loads
# dry-struct, which most dry-rb applications do.
RSpec.describe "A host that loads dry-struct" do
  it "still renders help" do
    expect(defined?(Dry::Struct)).to eq("constant")
    expect(run_cli(Fixtures::SimpleCLI, "deploy", "-h").out).to include("ENVIRONMENT")
  end
end
