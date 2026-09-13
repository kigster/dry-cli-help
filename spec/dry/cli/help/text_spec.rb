# frozen_string_literal: true

RSpec.describe Dry::CLI::Help::Text do
  describe ".lines" do
    it "returns nothing for nil or blank text" do
      expect([described_class.lines(nil, 20), described_class.lines(" \n", 20)]).to eq([[], []])
    end

    it "wraps a paragraph at word boundaries" do
      expect(described_class.lines("one two three four five", 9)).to eq(["one two", "three", "four five"])
    end

    it "reflows the line breaks of a heredoc" do
      expect(described_class.lines("one\ntwo\nthree\n", 40)).to eq(["one two three"])
    end

    it "keeps one blank line between paragraphs" do
      expect(described_class.lines("one\n\n\n\ntwo", 40)).to eq(["one", "", "two"])
    end

    it "prints an indented line verbatim" do
      text = "Steps:\n  1. compile\n\tthe rules\nthen stop"

      expect(described_class.lines(text, 40)).to eq(["Steps:", "  1. compile", "\tthe rules", "then stop"])
    end

    it "gives a word longer than the width a line of its own" do
      expect(described_class.lines("a supercalifragilistic word", 10)).to eq(%w[a supercalifragilistic word])
    end

    it "drops leading blank lines and trailing whitespace" do
      expect(described_class.lines("\n\n  \nhello  \n\n", 40)).to eq(["hello"])
    end

    it "keeps every line as written without a width" do
      expect(described_class.lines("one\n  two\n\nthree", nil)).to eq(["one", "  two", "", "three"])
    end
  end
end
