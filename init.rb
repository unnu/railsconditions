require 'rails_conditions'

Symbol.send :include, RailsConditions::Operators
ActiveRecord::Base.send :include, RailsConditions::Base