module Qcmd
  module Parser
    class << self
      # adapted from https://gist.github.com/612311
      # by Aaron Gough

      def extract_string_literals( string )
        string_literal_pattern = /"([^"\\]|\\.)*"/
        string_replacement_token = "___+++STRING_LITERAL+++___"
        # Find and extract all the string literals
        string_literals = []
        string.gsub(string_literal_pattern) {|x| string_literals << x}
        # Replace all the string literals with our special placeholder token
        string = string.gsub(string_literal_pattern, string_replacement_token)
        # Return the modified string and the array of string literals
        return [string, string_literals]
      end

      def tokenize_string( string )
        string = string.gsub("(", " ( ")
        string = string.gsub(")", " ) ")
        token_array = string.split(" ")
        return token_array
      end

      def restore_string_literals( token_array, string_literals )
        return token_array.map do |x|
          if(x == '___+++STRING_LITERAL+++___')
            # Since we've detected that a string literal needs to be
            # replaced we will grab the first available string from the
            # string_literals array
            string_literals.shift
          else
            # This is not a string literal so we need to just return the
            # token as it is
            x
          end
        end
      end

      # A helper method to take care of the repetitive stuff for us
      def is_match?( string, pattern)
        match = string.match(pattern)
        return false unless match
        # Make sure that the matched pattern consumes the entire token
        match[0].length == string.length
      end

      # Detect a symbol
      def is_symbol?( string )
        # Anything other than parentheses, single or double quote and commas
        return is_match?( string, /[^\"\'\,\(\)]+/ )
      end

      # Detect an integer literal
      def is_integer_literal?( string )
        # Any number of numerals optionally preceded by a plus or minus sign
        return is_match?( string, /[\-\+]?[0-9]+/ )
      end

      def is_float_literal?( string )
        # Any number of numerals optionally preceded by a plus or minus sign
        return is_match?( string, /[\-\+]?[0-9]+(\.[0-9]*)?/ )
      end

      # Detect a string literal
      def is_string_literal?( string )
        # Any characters except double quotes
        # (except if preceded by a backslash), surrounded by quotes
        return is_match?( string, /"([^"\\]|\\.)*"/)
      end

      def convert_tokens( token_array )
        converted_tokens = []
        token_array.each do |t|
          converted_tokens << t.to_i and next if( is_integer_literal?(t) )
          converted_tokens << t.to_f and next if( is_float_literal?(t) )
          converted_tokens << t.to_s and next if( is_symbol?(t) )
          converted_tokens << eval(t) and next if( is_string_literal?(t) )
          # If we haven't recognized the token by now we need to raise
          # an exception as there are no more rules left to check against!
          raise Exception, "Unrecognized token: #{t}"
        end
        return converted_tokens
      end

      def parse( string )
        string, string_literals = extract_string_literals(string)
        token_array = tokenize_string(string)
        token_array = restore_string_literals(token_array, string_literals)
        token_array = convert_tokens(token_array)
        return token_array
      end
    end
  end
end
