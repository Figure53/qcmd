module Qcmd
  module Plaintext
    def log message=nil
      if message
        puts message
      else
        puts
      end
    end

    # always output
    def print message=nil
      log(message)
    end

    def columns
      begin
        `stty size`.split.last.to_i
      rescue
        80
      end
    end

    def pluralize n, word
      "#{n} #{n == 1 ? word : word + 's'}"
    end

    def word_wrap(text, options={})
      options = {
        :line_width => columns
      }.merge options

      text.split("\n").collect do |line|
        line.length > options[:line_width] ? line.gsub(/(.{1,#{options[:line_width]}})(\s+|$)/, "\\1\n").strip : line
      end * "\n"
    end

    def ascii_qlab
      ['    .::::    .::                .::      ',
       '  .::    .:: .::                .::      ',
       '.::       .::.::         .::    .::      ',
       '.::       .::.::       .::  .:: .:: .::  ',
       '.::       .::.::      .::   .:: .::   .::',
       '  .:: .: .:: .::      .::   .:: .::   .::',
       '    .:: ::   .::::::::  .:: .:::.:: .::  ',
       '         .:                              '].map {|line|
        print centered_text(line)
      }
    end

    def joined_wrapped_text line
      wrapped_text(line).join "\n"
    end

    # turn line into lines of text of columns length
    def wrapped_text line
      line = line.gsub(/\s+/, ' ') # collapse whitespace
      word_wrap(line, :line_width => columns).split("\n")
    end

    def print_wrapped line
      print wrapped_text(line)
    end

    def right_text line
      diff = [(columns - line.size), 0].max
      "%s%s" % [' ' * diff, line]
    end

    def centered_text line, char=' '
      if line.size > columns && line.split(' ').all? {|chunk| chunk.size < columns}
        # wrap the text then center each line, then join
        return wrapped_text(line).map {|l| centered_text(l, char)}.join("\n")
      end

      diff = (columns - line.size)

      return line if diff < 0

      lpad = diff / 2
      rpad = diff - lpad

      "%s%s%s" % [char * lpad, line, char * rpad]
    end

    def split_text left, right
      diff = columns - left.size
      if (diff - right.size) < 0
        left_lines = wrapped_text(left)
        diff = columns - left_lines.last.size

        # still?
        if (diff - right.size) < 0
          diff = ''
          right = "\n" + right_text(right)
        end

        left = left_lines.join "\n"
      end
      "%s%#{diff}s" % [left, right]
    end

    def table headers, rows
      print
      columns = headers.map(&:size)

      # coerce row values to strings
      rows.each do |row|
        columns.each_with_index do |col, n|
          row[n] = row[n].to_s
        end
      end

      rows.each do |row|
        columns.each_with_index do |col, n|
          columns[n] = [col, row[n].size].max + 1
        end
      end

      row_format = columns.map {|n| "%#{n}s\t"}.join('')
      print row_format % headers
      print
      rows.each do |row|
        print row_format % row
      end
      print
    end
  end
end
