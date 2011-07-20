class Beard 
  class Template
    attr_reader :source, :path   
    attr_writer :source
          
    # @param [String] Template source file  
    # @param [String] Path to the template file, for partials you know.
    def initialize(source, path = nil)  
      @source  = source
      @path    = path 
      @engine  = Beard::Engine.new 
    end     
    
    def render(context)   
      ctx = context
      eval(compile)
    end

    def compile(src = @source)     
      @engine.call(src)
    end
    alias_method :to_s, :compile

  end
end