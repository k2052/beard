class Beard
	class Compiler < Temple::Filter   

	  temple_dispatch :beard     
	
		def initialize(options = {})    
			@generator = Temple::Generators::String.new 
		end 
		
		# Generates a fully compiled string ready to be evaled.
	  def compile_final(exp, buffer)   
		  @generator.buffer = buffer
			@generator.call(exp)
		end

    def on_beard_utag(name)
			[:dynamic, "ctx[#{name[2].to_s.to_sym.inspect}]"]
    end
    
    # @todo Need to let Temple handle escaping
	  def on_beard_etag(name)  
		  [:dynamic, "Temple::Utils.escape_html(ctx[#{name[2].to_s.to_sym.inspect}])"]
    end

		def on_beard_section(name, content, raw, delims)    
			content = compile(content)

      tmp1, tmp2 = tmp_var(:dict), tmp_var(:dict)
      [:multi, 
	     [:block,   "context.current = ctx[#{name[2].to_s.to_sym.inspect}]"],
       [:block,   "if #{tmp1} = ctx[#{name[2].to_s.to_sym.inspect}]"],    
       [:block,   "  if #{tmp1} == true"],
       content,
       [:block,   "  elsif Proc === #{tmp1}"],
       [:block,   '  else'],
       [:block,   "    #{tmp1} = [#{tmp1}] if #{tmp1}.respond_to?(:has_key?) || !#{tmp1}.respond_to?(:map)"],
       [:block,   "    #{tmp2} = ctx"],
       [:block,   "    #{tmp1}.each {|child|"],    
       [:block,   "    context.current = child"],
			      		       content,
       [:block,   '    }'],
       [:block,   "    ctx = #{tmp2}"],
	     [:block,   "    context.current = ctx[#{name[2].to_s.to_sym.inspect}]"],
       [:block,   '  end'],      
       [:block,   'end']]
		end  
		
		def on_beard_partial(name)
      [:dynamic, ev("ctx[#{name[2].to_s.to_sym.inspect}], #{indentation.inspect})")]
    end
		   
		def on_beard_fetch(names)
      names = names.map { |n| n.to_sym }

      if names.length == 0
        "ctx[:to_s]"
      elsif names.length == 1
        "ctx[#{names.first.to_sym.inspect}]"
      else
        initial, *rest = names
        <<-compiled
          #{rest.inspect}.inject(ctx[#{initial.inspect}]) { |value, key|
            value && ctx.find(value, key)
          }
        compiled
      end
    end

		def qv(s)
      "#{s}"
    end
	 
	end
end