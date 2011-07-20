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
      return current if current == name 
      value = find(current, name, :__missing)
      if value != :__missing
        return value
      end   
      
      @stack.each do |obj|   
        value = find(obj, name, :__missing)
        if value != :__missing
          return value
        end          
      end  
      if current.respond_to?('each')   
        current.each do |obj|    
          value = find(obj, name, :__missing)
          if value != :__missing
            return value
          end                 
        end    
      end  
      return beard.send(name.to_sym) if beard.respond_to?(name.to_sym) 
            
      return nil
    end   
    
    def find(obj, key, default = nil)
      hash = obj.respond_to?(:has_key?)

      if hash && obj.has_key?(key)
        obj[key]
      elsif hash && obj.has_key?(key.to_s)
        obj[key.to_s]
      elsif !hash && obj.respond_to?(key)
        meth = obj.method(key) rescue proc { obj.send(key) }
        if meth.arity == 1
          meth.to_proc
        else
          meth[]
        end   
      else
        default
      end
    end    
    
    def fetch_depth(names) 
      obj = nil
      names.each_with_index do |name, count|
        if obj == nil  
          obj = fetch(name)
        else      
          if obj.respond_to?('has_key?')    
            return obj[name.to_sym] if obj.has_key?(name.to_sym) 
          end   
          if obj.respond_to?(name.to_sym)    
            return obj.send(name.to_sym)
          end
        end
        if name == names.last
          return obj
        end 
      end   
    end

    def stack()
      @stack
    end      
  
    def stack=(stack)
      @stack = @stack
    end 
    
    def method_missing(name, *args, &block)    
      if current.respond_to?(name.to_sym)  
        return current.send(name.to_sym, *args, &block)
      end
      @stack.each do |obj|   
        if obj.respond_to?(name.to_sym)    
          return obj.send(name.to_sym, *args, &block)
        end   
      end 
    end 

  end
end