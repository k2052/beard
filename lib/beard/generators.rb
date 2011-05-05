module Temple
	module Generators 
		class String < Generator  
			
			def buffer 
				if @buffer == nil   
					options[:buffer]
				else 
					@buffer   
				end
	    end

	    def buffer=(buffer)  
				@buffer = buffer
			end     
			
			def call(exp)  
			  [preamble, compile(exp), postamble].join('') 
	    end
	
      def preamble  
      end     

      def postamble 
	      
      end

      def on_dynamic(code) 
				ev(code)    
      end   

      def ev(s)
	      "#\{#{s}}"
	    end  

      def on_block(code)   
      end
     
      def on_static(text) 
	      text
      end

	    def on_multi(*exp)
	      exp.map { |e| compile(e) }.join('')
	    end
	   
		end
	end
end