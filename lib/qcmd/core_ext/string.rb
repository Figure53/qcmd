if !String.new.respond_to?(:force_encoding)
  class String
    def force_encoding(*args)
      self
    end
  end
end


