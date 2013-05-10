require 'strscan'

class SexpistolParser < StringScanner

  def initialize(string)
    # step through string counting closing parens, exclude parens in string literals
    in_string_literal = false
    escape_char = false
    paren_count = 0
    string.bytes.each do |byte|
      if escape_char
        escape_char = false
        next
      end

      case byte.chr
      when '\\'
        escape_char = true
        next
      when '('
        if !in_string_literal
          paren_count += 1
        end
      when ')'
        if !in_string_literal
          paren_count -= 1
        end
      when '"'
        in_string_literal = !in_string_literal
      end
    end

    if paren_count > 0
      raise Exception, "Missing closing parentheses"
    elsif paren_count < 0
      raise Exception, "Missing opening parentheses"
    end

    super(string)
  end

  def parse
    exp = []
    while true
      case fetch_token
        when '('
          exp << parse
        when ')'
          break
        when :"'"
          case fetch_token
          when '(' then exp << [:quote].concat([parse])
          else exp << [:quote, @token]
          end
        when String, Fixnum, Float, Symbol
          exp << @token
        when nil
          break
      end
    end
    exp
  end

  def fetch_token
    skip(/\s+/)
    return nil if(eos?)

    @token =
    # Match parentheses
    if scan(/[\(\)]/)
      matched
    # Match a string literal
    elsif scan(/"([^"\\]|\\.)*"/)
      eval(matched)
    # Match a float literal
    elsif scan(/[\-\+]? [0-9]+ ((e[0-9]+) | (\.[0-9]+(e[0-9]+)?)) (\s|$)/x)
      matched.to_f
    # Match an integer literal
    elsif scan(/[\-\+]?[0-9]+ (\s|$)/x)
      matched.to_i
    # Match a comma (for comma quoting)
    elsif scan(/'/)
      matched.to_sym
    # Match a symbol
    elsif scan(/[^\(\)\s]+/)
      matched.to_sym
    # If we've gotten here then we have an invalid token
    else
      near = scan %r{.{0,20}}
      raise "Invalid character at position #{pos} near '#{near}'."
    end
  end

end
