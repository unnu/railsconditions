module RailsConditions
  module Operators # :nodoc:
    def |(other)
      Or.new(self, other)
    end
  
    def &(other)
      And.new(self, other)
    end
  end
end