require 'strscan'  
# @todo Become more compatible with other temple filters & move mustache specific tags to later filters.   
#  It would allow us to use other Temple filters more easily.
class Beard
  class Parser
    include Temple::Mixins::Options        

    attr_reader :scanner, :result
    attr_writer :otag, :ctag
    
    #set_default_options :tabsize  => 4    

	  class SyntaxError < StandardError
	    def initialize(message, position)
	      @message = message
	      @lineno, @column, @line, _ = position
	      @stripped_line = @line.strip
	      @stripped_column = @column - (@line.size - @line.lstrip.size)
	    end

	    def to_s
	      <<-EOF
#{@message}
	Line #{@lineno}
	  #{@stripped_line}
	  #{' ' * @stripped_column}^   
EOF
	    end 
		end   
		
    SKIP_WHITESPACE = [ '#', '^', '/', '<', '>', '=', '!' ]
    ALLOWED_CONTENT = /(\w|[?!\/.-])*/
    ANY_CONTENT = [ '!', '=' ]  

    def initialize(options = {})
      @options = {}
    end   

    def otag
      @otag ||= '{{'
    end

    def ctag
      @ctag ||= '}}'
    end       

		def call(template) 			
			if template.respond_to?(:encoding)
        @encoding = template.encoding
        template = template.dup.force_encoding("BINARY")
      else
        @encoding = nil
      end

      # Keeps information about opened sections.
      @sections = []
      @result = [:multi]
      @scanner = StringScanner.new(template)

      # Scan until the end of the template.
      until @scanner.eos?
        scan_tags || scan_text
      end

      if !@sections.empty?
        # We have parsed the whole file, but there's still opened sections.
        type, pos, result = @sections.pop
        error "Unclosed section #{type.inspect}", pos
      end

      @result
		end   
		
		# Find {{mustaches}} and add them to the @result array.
    def scan_tags
      # Scan until we hit an opening delimiter.
      start_of_line      = @scanner.beginning_of_line?
      pre_match_position = @scanner.pos
      last_index         = @result.length

      return unless x = @scanner.scan(/([ \t]*)?#{Regexp.escape(otag)}/)
      padding = @scanner[1] || ''

      # Don't touch the preceding whitespace unless we're matching the start
      # of a new line.
      unless start_of_line
        @result << [:static, padding] unless padding.empty?
        pre_match_position += padding.length
        padding = ''
      end

      # Since {{= rewrites ctag, we store the ctag which should be used
      # when parsing this specific tag.
      current_ctag = self.ctag
      type = @scanner.scan(/#|\^|\/|=|!|<|>|&|\{/)
      @scanner.skip(/\s*/)

      # ANY_CONTENT tags allow any character inside of them, while
      # other tags (such as variables) are more strict.
      if ANY_CONTENT.include?(type)
        r = /\s*#{regexp(type)}?#{regexp(current_ctag)}/
        content = scan_until_exclusive(r)
      else
        content = @scanner.scan(ALLOWED_CONTENT)
      end

      # We found {{ but we can't figure out what's going on inside.
      error "Illegal content in tag" if content.empty?

      fetch = [:beard, :fetch, content.split('.')]
      prev = @result

      # Based on the sigil, do what needs to be done.
      case type
      when '#'
        block = [:multi]
        @result << [:beard, :section, fetch, block]
        @sections << [content, position, @result]
        @result = block
      when '^'
        block = [:multi]
        @result << [:beard, :inverted_section, fetch, block]
        @sections << [content, position, @result]
        @result = block
      when '/'
        section, pos, result = @sections.pop
        raw = @scanner.pre_match[pos[3]...pre_match_position] + padding
        (@result = result).last << raw << [self.otag, self.ctag]

        if section.nil?
          error "Closing unopened #{content.inspect}"
        elsif section != content
          error "Unclosed section #{section.inspect}", pos
        end
      when '!'
        # ignore comments
      when '='
        self.otag, self.ctag = content.split(' ', 2)
      when '>', '<'
        @result << [:beard, :partial, content, padding]
      when '{', '&'
        # The closing } in unescaped tags is just a hack for
        # aesthetics.
        type = "}" if type == "{"
        @result << [:beard, :utag, fetch]
      else
        @result << [:beard, :etag, fetch]
      end

      # Skip whitespace and any balancing sigils after the content
      # inside this tag.
      @scanner.skip(/\s+/)
      @scanner.skip(regexp(type)) if type

      # Try to find the closing tag.
      unless close = @scanner.scan(regexp(current_ctag))
        error "Unclosed tag"
      end

      # If this tag was the only non-whitespace content on this line, strip
      # the remaining whitespace.  If not, but we've been hanging on to padding
      # from the beginning of the line, re-insert the padding as static text.
      if start_of_line && !@scanner.eos?
        if @scanner.peek(2) =~ /\r?\n/ && SKIP_WHITESPACE.include?(type)
          @scanner.skip(/\r?\n/)
        else
          prev.insert(last_index, [:static, padding]) unless padding.empty?
        end
      end

      # Store off the current scanner position now that we've closed the tag
      # and consumed any irrelevant whitespace.
      @sections.last[1] << @scanner.pos unless @sections.empty?

      return unless @result == [:multi]
    end

    # Try to find static text, e.g. raw HTML with no {{mustaches}}.
    def scan_text
      text = scan_until_exclusive(/(^[ \t]*)?#{Regexp.escape(otag)}/)

      if text.nil?
        # Couldn't find any otag, which means the rest is just static text.
        text = @scanner.rest
        # Mark as done.
        @scanner.terminate
      end

      text.force_encoding(@encoding) if @encoding

      @result << [:static, text] unless text.empty?
    end

    # Scans the string until the pattern is matched. Returns the substring
    # *excluding* the end of the match, advancing the scan pointer to that
    # location. If there is no match, nil is returned.
    def scan_until_exclusive(regexp)
      pos = @scanner.pos
      if @scanner.scan_until(regexp)
        @scanner.pos -= @scanner.matched.size
        @scanner.pre_match[pos..-1]
      end
    end

    # Returns [lineno, column, line]
    def position
      # The rest of the current line
      rest = @scanner.check_until(/\n|\Z/).to_s.chomp

      # What we have parsed so far
      parsed = @scanner.string[0...@scanner.pos]

      lines = parsed.split("\n")

      [ lines.size, lines.last.size - 1, lines.last + rest ]
    end

    # Used to quickly convert a string into a regular expression
    # usable by the string scanner.
    def regexp(thing)
      /#{Regexp.escape(thing)}/
    end

    # Raises a SyntaxError. The message should be the name of the
    # error - other details such as line number and position are
    # handled for you.
    def error(message, pos = position)
      raise SyntaxError.new(message, pos)
    end

	end
end