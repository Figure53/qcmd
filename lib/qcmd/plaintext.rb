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

    def set_columns value
      @columns = value
    end

    def columns
      @columns || (begin
                     @columns = `stty size`.split.last.to_i
                   rescue
                     @columns = 80
                   end)
    end

    def pluralize n, word
      "#{n} #{n == 1 ? word : word + 's'}"
    end

    def word_wrap(text, options={})
      options = {
        :line_width => columns,
        :preserve_whitespace => false
      }.merge options

      unless options[:preserve_whitespace]
        text = text.gsub(/\s+/, ' ') # collapse whitespace
      end

      prefix = options[:indent] ? options[:indent] : ''

      line_width = options[:line_width]
      lines = ['']

      space = ' '
      space_size = 2
      space_left = line_width
      text.split.each do |word|
        if (word.size + space.size) >= space_left
          word       = "%s%s" % [prefix, word]
          space_left = line_width - (word.size + space_size)
          lines << ""
        else
          space_left = space_left - (word.size + space_size)
        end

        lines.last << "%s%s" % [word, space]
      end

      lines
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
    def wrapped_text *args
      options = {
        :line_width => columns
      }.merge args.extract_options!

      line = args.shift

      word_wrap(line, options)
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
