$LOAD_PATH.unshift 'lib'
require 'beard/version'

Gem::Specification.new do |s|
  s.name              = "beard"
  s.version           = Beard::Version
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           =
        "Beard is Mustache extended; a logic free templating system."
  s.homepage          = "http://github.com/bookworm/beard"
  s.email             = "bookworm.productions@gmail.com"
  s.authors           = [ "Ken Erickson" ]
  s.files             = %w( README.md)
  s.files            += Dir.glob("lib/**/*")
  s.description       = <<desc
A fork & refactor of Mustache that brings better context handling to the ruby implementation of the Mustache template lang. 
Uses temple.
desc
end
