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

      def parse( string )
        string, string_literals = extract_string_literals(string)
        token_array = tokenize_string(string)
        token_array = restore_string_literals(token_array, string_literals)
        return token_array
      end
    end
  end
end
