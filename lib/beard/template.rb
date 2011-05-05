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
      compiled = "def render(ctx) context = ctx; #{compile} end"
      instance_eval(compiled, __FILE__, __LINE__ - 1)
      render(ctx)
    end

    def compile(src = @source)  
      eval(@engine.call(src))
    end
    alias_method :to_s, :compile

	end
end