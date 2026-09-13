# frozen_string_literal: true

RSpec.describe Dry::CLI::Help::Colors do
  subject(:painter) { Class.new { include Dry::CLI::Help::Colors }.new }

  it "offers every style the specification lists" do
    listed = %i[
      black red green yellow blue magenta cyan white
      bright_black bright_red bright_green bright_yellow bright_blue bright_magenta bright_cyan bright_white
      on_black on_red on_green on_yellow on_blue on_magenta on_cyan on_white
      on_bright_black on_bright_red on_bright_green on_bright_yellow
      on_bright_blue on_bright_magenta on_bright_cyan on_bright_white
      clear bold dim italic underline inverse hidden strikethrough
    ]

    expect(described_class::STYLES).to match_array(listed)
  end

  context "when enabled" do
    before { described_class.enabled = true }

    it "decorates text with every style" do
      undecorated = described_class::STYLES.reject { painter.public_send(it, "x").start_with?("\e[") }

      expect(undecorated).to be_empty
    end

    it "decorates in one call" do
      expect(painter.red("text")).to eq("\e[31mtext\e[0m")
    end

    it "chains styles" do
      expect(painter.red.bold("text")).to eq("\e[31;1mtext\e[0m")
    end
  end

  context "when disabled" do
    before { described_class.enabled = false }

    it "returns text as given" do
      expect([painter.red("text"), painter.red.bold("text")]).to eq(%w[text text])
    end
  end

  describe ".enabled" do
    it "defaults to :auto" do
      expect(described_class.enabled).to eq(:auto)
    end

    it "rejects anything but true, false and :auto" do
      expect { described_class.enabled = "yes" }.to raise_error(ArgumentError, /"yes"/)
    end

    it "rebuilds the shared pastel when it changes" do
      before = described_class.pastel
      described_class.enabled = false

      expect(described_class.pastel).not_to be(before)
      expect(described_class.pastel).to be(described_class.pastel)
    end
  end

  describe ".enabled_for?" do
    it "passes true and false through" do
      expect([described_class.enabled_for?(true, nil), described_class.enabled_for?(false, tty_io)])
        .to eq([true, false])
    end

    it "colors a terminal when :auto" do
      expect(described_class.enabled_for?(:auto, tty_io)).to be(true)
    end

    it "does not color a pipe when :auto" do
      expect(described_class.enabled_for?(:auto, StringIO.new)).to be(false)
    end

    it "does not color something that cannot say whether it is a terminal" do
      expect(described_class.enabled_for?(:auto, Object.new)).to be(false)
    end

    it "honors NO_COLOR" do
      ENV["NO_COLOR"] = "1"

      expect(described_class.enabled_for?(:auto, tty_io)).to be(false)
    end

    it "ignores an empty NO_COLOR" do
      ENV["NO_COLOR"] = ""

      expect(described_class.enabled_for?(:auto, tty_io)).to be(true)
    end
  end
end
