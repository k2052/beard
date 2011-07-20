require 'sinatra/base'
class Beard
  module Sinatra 
    module Helpers 
      def beard(template, options={}, locals={})       
        if options.has_key?(:locals)      
          locals = locals.merge(options[:locals]) 
          options.delete(:locals)    
        end    
        
        if self.respond_to?(:settings)
          if settings.respond_to?(:beard)
            options = settings.send(:beard).merge(options)
          end   
        end 
 
        klass = beard_class(template, options)
        instance = klass.new   
 
        instance_variables.each do |name|
          instance.instance_variable_set(name, instance_variable_get(name))
 
          if !instance.respond_to?(name)
            (class << instance; self end).send(:attr_reader, name.to_s.sub('@',''))
          end
        end
 
        # Render with locals
 
        rendered = instance.render(instance.template, locals)
      end  

      def beard_class(template, options = {})
        @template_cache.fetch(:beard, template) do
          compile_beard(template, options)
        end
      end

      def compile_beard(view, options = {})
        if self.respond_to?(:settings)
          options[:templates] ||= settings.views if settings.respond_to?(:views)
        end
        options[:namespace] ||= self.class

        unless options[:namespace].to_s.include? 'Views'
          options[:namespace] = options[:namespace].const_get(:Views)
        end

        factory = Class.new(Beard) do
          self.view_namespace = options[:namespace]
          self.view_path      = options[:views]
        end

        # If we were handed :"positions.atom" or some such as the
        # template name, we need to remember the extension.
        if view.to_s.include?('.')
          view, ext = view.to_s.split('.')
        end

        klass = factory.view_class(view)  
        klass.view_namespace = options[:namespace]
        klass.view_path      = options[:views]

        if klass == Beard
          warn "No view class found for #{view} in #{factory.view_path}"
          klass = factory
          klass.template_name = view.to_s
        elsif ext
          if klass.const_defined?(ext_class = ext.capitalize)
            klass = klass.const_get(ext_class)
          else
            new_class = Class.new(klass)
            new_class.template_name = "#{view}.#{ext}"
            klass.const_set(ext_class, new_class)
            klass = new_class
          end
        end

        # Set the template path and return our class.
        klass.template_path = options[:templates] if options[:templates]
        klass
      end 
    
    end  
    
    def self.registered(app)    
      if app
       app.helpers Beard::Sinatra::Helpers
      end
    end
  end
end    

if Sinatra
  Sinatra.register Beard::Sinatra  
end