# frozen_string_literal: true

RSpec.describe Dry::CLI::Help::Formatter do
  subject(:format) { described_class.new(config, StringIO.new, terminal_width: 40) }

  let(:config) { Dry::CLI::Help::Configuration.new }
  let(:row) { described_class::Row }

  describe "#width" do
    it "is the configured wrap width" do
      expect(format.width).to eq(40)
    end

    it "is nil when wrapping is off" do
      config.wrap = false

      expect(format.width).to be_nil
    end
  end

  describe "#paint" do
    it "leaves text plain when color is off" do
      expect(format.paint("text", :title)).to eq("text")
    end

    it "applies the element's styles when color is on" do
      config.color = true

      expect(format.paint("text", :title)).to eq("\e[1mtext\e[0m")
    end

    it "leaves text plain without an element" do
      config.color = true

      expect(format.paint("text", nil)).to eq("text")
    end

    it "colors a terminal when color is :auto" do
      auto = described_class.new(config, tty_io, terminal_width: 40)

      expect(auto.paint("text", :title)).to eq("\e[1mtext\e[0m")
    end
  end

  describe "#heading and #title" do
    it "upcases by default" do
      expect(format.heading(:commands)).to eq("COMMANDS")
    end

    it "capitalizes only the first letter" do
      config.heading_case = :capitalize
      config.heading(:commands, "available GitHub commands")

      expect(format.heading(:commands)).to eq("Available GitHub commands")
    end

    it "keeps text as written" do
      config.heading_case = :none

      expect(format.title("my Group")).to eq("my Group")
    end
  end

  describe "#paragraph" do
    it "wraps to the width left after the indent, and leaves blank lines bare" do
      text = "one two three four five six seven eight nine ten\n\neleven"

      expect(format.paragraph(text, indent: "    "))
        .to eq(["    one two three four five six seven", "    eight nine ten", "", "    eleven"])
    end

    it "keeps lines as written when wrapping is off" do
      config.wrap = false

      expect(format.paragraph("a very long line that would otherwise wrap somewhere"))
        .to eq(["a very long line that would otherwise wrap somewhere"])
    end
  end

  describe "#column_for" do
    def rows(*terms)
      terms.map { row.new(term: it, text: "described") }
    end

    it "is the longest term" do
      expect(format.column_for(rows("a", "abcd", "ab"))).to eq(4)
    end

    it "ignores terms with nothing beside them" do
      expect(format.column_for([*rows("ab"), row.new(term: "abcdef"), row.new(term: "abcdefg", text: "")]))
        .to eq(2)
    end

    it "is zero without rows" do
      expect(format.column_for([])).to eq(0)
    end

    it "never exceeds half the wrap width" do
      expect(format.column_for(rows("x" * 30))).to eq(20)
    end

    it "has no ceiling when wrapping is off" do
      config.wrap = false

      expect(format.column_for(rows("x" * 30))).to eq(30)
    end
  end

  describe "#definitions" do
    it "aligns descriptions two columns past the column" do
      rows = [row.new(term: "a", text: "first"), row.new(term: "abc", text: "second")]

      expect(format.definitions(rows, 3)).to eq(["  a    first", "  abc  second"])
    end

    it "hangs wrapped lines under the description column" do
      rows = [row.new(term: "run", text: "one two three four five six seven eight nine")]

      expect(format.definitions(rows, 3)).to eq(
        ["  run  one two three four five six seven", "       eight nine"]
      )
    end

    it "keeps a blank line between paragraphs bare" do
      rows = [row.new(term: "run", text: "one\n\ntwo")]

      expect(format.definitions(rows, 3)).to eq(["  run  one", "", "       two"])
    end

    it "starts the description on the next line when the term overflows the column" do
      rows = [row.new(term: "a-very-long-term", text: "described")]

      expect(format.definitions(rows, 4)).to eq(["  a-very-long-term", "        described"])
    end

    it "prints a term without a description alone" do
      expect(format.definitions([row.new(term: "bare")], 4)).to eq(["  bare"])
    end

    it "wraps descriptions no narrower than the minimum width" do
      narrow = described_class.new(config, StringIO.new, terminal_width: 20)
      text = "one two three four five six"

      expect(narrow.definitions([row.new(term: "t", text:)], 10).first.length).to be > 20
    end

    it "paints terms and descriptions with their own styles" do
      config.color = true
      rows = [row.new(term: "run", text: "go", term_style: :option, text_style: :comment)]

      expect(format.definitions(rows, 3)).to eq(["  \e[36mrun\e[0m  \e[90mgo\e[0m"])
    end
  end
end
