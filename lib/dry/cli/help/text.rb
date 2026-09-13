# frozen_string_literal: true

module Dry
  class CLI
    module Help
      # Word wrapping for descriptions, epilogues and anything else a user writes.
      module Text
        module_function

        # Split text into lines no wider than `width`.
        #
        # Paragraphs split on blank lines and reflow, so a heredoc wraps to the
        # terminal instead of keeping the line breaks of the editor it was
        # written in. A line starting with whitespace prints verbatim, which
        # keeps indented lists and code intact. Consecutive blank lines collapse
        # to one. A word longer than `width` gets a line to itself.
        #
        # @param text [String, nil]
        # @param width [Integer, nil] nil keeps every line as written
        # @return [Array<String>] lines, with "" between paragraphs
        def lines(text, width)
          source = text.to_s.sub(/\A(?:[ \t]*\n)+/, "").rstrip
          return source.lines(chomp: true) if width.nil?

          reflow(source, width)
        end

        # @return [Array<String>]
        def reflow(source, width)
          output = []
          paragraph = []
          flush = lambda do
            output.concat(fill(paragraph.join(" "), width)) unless paragraph.empty?
            paragraph.clear
          end

          source.each_line(chomp: true) do |line|
            if line.strip.empty?
              flush.call
              output << "" unless output.last == ""
            elsif line.start_with?(" ", "\t")
              flush.call
              output << line.rstrip
            else
              paragraph << line.strip
            end
          end
          flush.call
          output
        end

        # Greedy fill of one paragraph.
        # @return [Array<String>]
        def fill(text, width)
          text.split.each_with_object([]) do |word, lines|
            if lines.empty? || lines.last.length + 1 + word.length > width
              lines << word.dup
            else
              lines.last << " " << word
            end
          end
        end
      end
    end
  end
end
