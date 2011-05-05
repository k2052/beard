require 'temple' 
require 'beard/template'   
require 'beard/context' 
require 'beard/settings'  
require 'beard/parser' 
require 'beard/generators'
require 'beard/compiler' 
require 'beard/engine'    

class Beard

	  def self.render(*args)   
	    new.render(*args)
	  end

	  class << self
	    alias_method :to_html, :render
	    alias_method :to_text, :render
	  end

	  def render(data = template, ctx = {})   
	    if data.respond_to?('[]')
	      ctx = data
	      tpl = templateify(template)
	    elsif data.is_a? Symbol
	      self.template_name = data
	      tpl = templateify(template)
	    else
	      tpl = templateify(data)
	    end  
	    
	    return tpl.render(context) if ctx == {}

	    begin
	      context.push(ctx)  
	      tpl.render(context)
	    ensure
	      context.pop
	    end
	  end

	  alias_method :to_html, :render
	  alias_method :to_text, :render

	  # Context accessors.
	  #
 
	  def [](key)
	    context[key.to_sym]
	  end

	  def []=(key, value)
	    context[key.to_sym] = value
	  end
	
	  def context
	    @context ||= Beard::Context.new(self)
	  end   
	  
		def context=(context)
			@context = context
		end

	  def self.render_file(name, context = {})
	    render(partial(name), context)
	  end

	  def render_file(name, context = {})
	    self.class.render_file(name, context)
	  end

	  def self.partial(name)
	    File.read("#{template_path}/#{name}.#{template_extension}")
	  end

	  def partial(name)
	    self.class.partial(name)
	  end

	  #
	  # Private API
	  #   
	
	  def self.view_class(name)
	    if name != classify(name.to_s)
	      name = classify(name.to_s)
	    end

	    # Emptiness begets emptiness.
	    if name.to_s == ''
	      return Beard
	    end

	    file_name = underscore(name)
	    name = "#{view_namespace}::#{name}"

	    if const = const_get!(name)
	      const
	    elsif File.exists?(file = "#{view_path}/#{file_name}.rb")
	      require "#{file}".chomp('.rb')
	      const_get!(name) || Beard
	    else
	      Beard
	    end
	  end
	
	  def self.const_get!(name)
	    name.split('::').inject(Object) do |klass, name|
	      klass.const_get(name)
	    end
	  rescue NameError
	    nil
	  end

	  def self.compiled?
	    @template.is_a? Beard::Template
	  end

	  def compiled?
	    (@template && @template.is_a?(Beard::Template)) || self.class.compiled?
	  end
	
	  def self.classify(underscored)
	    underscored.split('/').map do |namespace|
	      namespace.split(/[-_]/).map do |part|
	        part[0] = part[0].chr.upcase; part
	      end.join
	    end.join('::')
	  end

	  def self.underscore(classified = name)
	    classified = name if classified.to_s.empty?
	    classified = superclass.name if classified.to_s.empty?

	    string = classified.dup.split("#{view_namespace}::").last

	    string.split('::').map do |part|
	      part[0] = part[0].chr.downcase
	      part.gsub(/[A-Z]/) { |s| "_#{s.downcase}"}
	    end.join('/')
	  end

	  def self.templateify(obj)
	    if obj.is_a?(Template)
	      obj
	    else
	      Beard::Template.new(obj.to_s)
	    end
	  end

	  def templateify(obj)
	    self.class.templateify(obj)
	  end

	  def respond_to?(methodname)
		  methodname = methodname.to_s.split(/\s+/).first
		  super methodname
		end        
end      