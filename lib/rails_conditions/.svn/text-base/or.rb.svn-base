module RailsConditions
  class Or < Proposition # :nodoc: 
    
    def initialize(first, second)
      @first = first.is_a?(Symbol) ? Atom.new(first) : first
      @second = second.is_a?(Symbol) ? Atom.new(second) : second
    end
    
    def evaluate(object, other)
      if (first_result = @first.evaluate(object, other)).is_a?(Module)
        @second.evaluate(object, other)
      else 
        first_result 
      end
    end
    
    def propagate_defining_class(defining_class)
      @first.propagate_defining_class(defining_class)
      @second.propagate_defining_class(defining_class)
    end
  end
end