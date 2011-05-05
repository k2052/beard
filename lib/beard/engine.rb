class Beard
  class Engine < Temple::Engine
	
		use Beard::Parser   
		use Beard::Compiler
    generator :ArrayBuffer
	end
end