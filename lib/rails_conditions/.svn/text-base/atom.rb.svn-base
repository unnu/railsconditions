module RailsConditions
  class Atom < Proposition # :nodoc:
    
    class << self
      def get_exception_mixin(klass, condition)
        exception_mixin_name = "#{condition.to_s.camelize}Failed".to_sym
        klass.const_set(exception_mixin_name, Module.new) unless klass.const_defined?(exception_mixin_name)
        klass.const_get(exception_mixin_name)
      end
    end
    
    
    def initialize(name)
      @name = name
      @defining_class = nil
      @klass = nil
      @condition = nil
    end
    
    def propagate_defining_class(defining_class)
      @defining_class = defining_class
    end
    
    def evaluate(object, other)
      ensure_class_and_condition_assigned
      target, argument = other.kind_of?(@klass) ? [other, object] : [object, other] 
      args = target.method("#{@condition}?").arity != 0 ? [argument] : []
      target.__send__("#{@condition}?", *args) ? true : self.class.get_exception_mixin(@klass, @condition)
    end
    
    private
      def extract_class_from_condition(name)
        klass = nil
        condition = nil

        while true
          break unless name.gsub!(/_([^_]+)$/, '')
          condition = condition ? "#{$1}_#{condition}" : $1
          class_name = name.camelcase

          begin
            klass = eval(class_name)
          rescue NameError
            next
          end
          break
        end
        
        [klass, condition]
      end
      
      def ensure_class_and_condition_assigned
        unless @klass
          @klass, @condition = extract_class_from_condition(@name.to_s)
          unless @klass
            @klass = @defining_class
            @condition = @name.to_s
          end
        end
      end
      
      def parameters_info(object, method)
        params = nil
        values = nil
        arity = object.method(method).arity

        trace_func = lambda do |event, file, line, id, binding, class_name|
          if event[/call/] && class_name == object.class && id == method
            params = eval("local_variables", binding)
            values = eval("local_variables.map{|x| eval(x)}", binding)
            throw :done
          end
        end

        set_trace_func(trace_func)
        catch(:done){ object.send(method, *(0...arity)) }
        set_trace_func(nil)

        # remove parameters not direct assigning input values e.g. &block
        params.delete_if { |param| values[params.index(param)].nil? }
        params
      end
  end
end