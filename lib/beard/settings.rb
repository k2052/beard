class Beard 
		
		def self.template_path
	    @template_path ||= inheritable_config_for :template_path, '.'
	  end

	  def self.template_path=(path)
	    @template_path = File.expand_path(path)
	    @template = nil
	  end

	  def template_path
	    @template_path ||= self.class.template_path
	  end

	  def template_path=(path)
	    @template_path = File.expand_path(path)
	    @template = nil
	  end

	  # Alias for `template_path`
	  def self.path
	    template_path
	  end
	  alias_method :path, :template_path

	  # Alias for `template_path`
	  def self.path=(path)
	    self.template_path = path
	  end
	  alias_method :path=, :template_path=

	  #
	  # Template Extension
	  #

	  def self.template_extension
	    @template_extension ||= inheritable_config_for :template_extension, 'mustache'
	  end

	  def self.template_extension=(template_extension)
	    @template_extension = template_extension
	    @template = nil
	  end

	  def template_extension
	    @template_extension ||= self.class.template_extension
	  end

	  def template_extension=(template_extension)
	    @template_extension = template_extension
	    @template = nil
	  end

	  #
	  # Template Name
	  #
	  def self.template_name
	    @template_name || underscore
	  end

	  def self.template_name=(template_name)
	    @template_name = template_name
	    @template = nil
	  end

	  def template_name
	    @template_name ||= self.class.template_name
	  end

	  def template_name=(template_name)
	    @template_name = template_name
	    @template = nil
	  end

	  #
	  # Template File
	  #

	  def self.template_file
	    @template_file || "#{path}/#{template_name}.#{template_extension}"
	  end

	  def self.template_file=(template_file)
	    @template_file = template_file
	    @template = nil
	  end

	  # The template file is the absolute path of the file Mustache will
	  # use as its template. By default it's ./class_name.mustache
	  def template_file
	    @template_file || "#{path}/#{template_name}.#{template_extension}"
	  end

	  def template_file=(template_file)
	    @template_file = template_file
	    @template = nil
	  end

	  #
	  # Template
	  #
	  def self.template
	    @template ||= templateify(File.read(template_file))
	  end

	  def self.template=(template)
	    @template = templateify(template)
	  end

	  # The template can be set at the instance level.
	  def template
	    return @template if @template

	    # If they sent any instance-level options use that instead of the class's.
	    if @template_path || @template_extension || @template_name || @template_file
	      @template = templateify(File.read(template_file))
	    else
	      @template = self.class.template
	    end
	  end

	  def template=(template)
	    @template = templateify(template)
	  end

	  #
	  # Raise on context miss
	  #

	  def self.raise_on_context_miss?
	    @raise_on_context_miss
	  end

	  def self.raise_on_context_miss=(boolean)
	    @raise_on_context_miss = boolean
	  end

	  # Instance level version of `Mustache.raise_on_context_miss?`
	  def raise_on_context_miss?
	    self.class.raise_on_context_miss? || @raise_on_context_miss
	  end

	  def raise_on_context_miss=(boolean)
	    @raise_on_context_miss = boolean
	  end

	  #
	  # View Namespace
	  #.

	  def self.view_namespace
	    @view_namespace ||= inheritable_config_for(:view_namespace, Object)
	  end

	  def self.view_namespace=(namespace)
	    @view_namespace = namespace
	  end

	  #
	  # View Path
	  #

	  def self.view_path
	    @view_path ||= inheritable_config_for(:view_path, '.')
	  end

	  def self.view_path=(path)
	    @view_path = path
	  end   
	
	  def self.inheritable_config_for(attr_name, default)
	    superclass.respond_to?(attr_name) ? superclass.send(attr_name) : default
	  end 
	
end