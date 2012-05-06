#--
# Copyright (c) 2007 Norman Timmler and Tammo Freese
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module RailsConditions
  
  VERSION = '0.1.0'
  
  # This exception is thrown if a condition called by the bang method failed. If a precondition
  # failed, the precodition exception mixin is included in the exception. 
  class Failed < Exception; end
  
  
  # Include RailsConditions::Base into any class to make the condition macro available. By default
  # it is included in all ActiveRecord models.
  #
  #   class Foo
  #     include RailsConditions::Base
  #     condition :bar do
  #       @bar
  #     end
  #   end
  module Base # :nodoc:
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.__send__(:class_variable_set, :@@rails_conditions, {})
      
      class << base
        def const_missing_with_exception_mixin_generation(class_id)
          if class_id.to_s =~ /^(.+)Failed$/
            RailsConditions::Atom.get_exception_mixin(self, $1)
          else
            const_missing_without_exception_mixin_generation(class_id)
          end
        end
        alias_method_chain :const_missing, :exception_mixin_generation
      end
    end

    module ClassMethods
      
      # See README.txt[link:files/README_txt.html]
      def condition(condition_name, options = {}, &block)
        
        predicate_method_name = "#{condition_name}?"
        bang_method_name = "#{condition_name}!"
        
        # Register condition
        
        condition = case options[:if]
          when nil
            Atom.new(condition_name)
          when Symbol
            Atom.get_exception_mixin(self, condition_name)
            Atom.new(options[:if])
          else
            Atom.get_exception_mixin(self, condition_name)
            options[:if]
        end
        
        condition.propagate_defining_class(self)
        class_variable_get(:@@rails_conditions)[condition_name] = condition
        
        # Define predicate method if not already defined
        if options[:if]
          class_eval <<-"end_eval", __FILE__, __LINE__
            def #{predicate_method_name}(other = nil)
              not @@rails_conditions[:#{condition_name}].evaluate(self, other).is_a?(Module)
            end
          end_eval
        elsif block
          define_method(predicate_method_name, &block)
        else
          # predicate method has to be defined later in the code
          # no chance to check this here
        end
        
        # Define bang method
        class_eval <<-"end_eval", __FILE__, __LINE__
          def #{bang_method_name}(other = nil)
            if (mod = @@rails_conditions[:#{condition_name}].evaluate(self, other)).is_a?(Module)
              exception = RailsConditions::Failed.new
              exception.extend mod
              exception.extend #{Atom.get_exception_mixin(self, condition_name)}
              raise exception
            else
              true
            end
          end
        end_eval
        
        if options[:negated]
          class_eval <<-"end_eval", __FILE__, __LINE__
            condition options[:negated].to_sym do |*args|
              @@rails_conditions[:#{condition_name}].evaluate(self, args.first).is_a?(Module)
            end
          end_eval
        end
      end
    end
  end
end
