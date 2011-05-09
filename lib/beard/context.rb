class Beard
	class ContextMiss < RuntimeError;  end
	
	class Context  
		           
		def initialize(beard)   
			@stack = []
      @beard = beard 
			@current = {}
    end   

    def partial(name, indentation = '')
      part = beard.partial(name).to_s.gsub(/^/, indentation)
      result = beard.render(part, self)
    end   

    def beard
      @beard
    end  

    def push(new)
      @stack.unshift(new)
      self
    end
    alias_method :update, :push

    def pop
      @stack.shift
      self
    end

    def []=(name, value)
      push(name => value)
    end

    def [](name)
      fetch(name)
    end  

    def current()
			@current
		end  
		
		def current=(current)  
			@current = current    
		end

    def fetch(name)
			if current.respond_to?('has_key?')
				return current[name] if current.has_key?(name.to_sym) 
			end   
			if current.respond_to?(name.to_sym)  
				return current.send(name.to_sym)
			end
	    @stack.each do |obj| 
				if obj.respond_to?('has_key?')    
					return obj[name] if obj.has_key?(name.to_sym) 
				end   
				if obj.respond_to?(name.to_sym)    
					return obj.send(name.to_sym)
				end 
				return beard.send(name.to_sym) if beard.respond_to?(name.to_sym) 
			end 
			return nil
		end

    def stack()
			@stack
		end      
	
		def stack=(stack)
			@stack = @stack
		end  

	end
end