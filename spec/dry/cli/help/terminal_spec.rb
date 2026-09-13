# frozen_string_literal: true

RSpec.describe Dry::CLI::Help::Terminal do
  def console(winsize)
    Object.new.tap { |io| io.define_singleton_method(:winsize) { winsize } }
  end

  it "prefers COLUMNS" do
    expect(described_class.width(env: { "COLUMNS" => "120" }, console: console([24, 100]))).to eq(120)
  end

  it "reads the console when COLUMNS is missing" do
    expect(described_class.width(env: {}, console: console([24, 100]))).to eq(100)
  end

  it "ignores a COLUMNS that is not a positive number" do
    widths = %w[abc 0 -5].map { described_class.width(env: { "COLUMNS" => it }, console: console([24, 90])) }

    expect(widths).to eq([90, 90, 90])
  end

  it "falls back to 80 without a console" do
    expect(described_class.width(env: {}, console: nil)).to eq(80)
  end

  it "falls back to 80 when the console reports no width" do
    expect(described_class.width(env: {}, console: console([0, 0]))).to eq(80)
  end

  it "falls back to 80 when the console cannot be asked" do
    broken = Object.new.tap { |io| io.define_singleton_method(:winsize) { raise Errno::ENOTTY } }

    expect(described_class.width(env: {}, console: broken)).to eq(80)
  end

  it "reads the real environment and console by default" do
    expect(described_class.width).to eq(80)
  end
end
