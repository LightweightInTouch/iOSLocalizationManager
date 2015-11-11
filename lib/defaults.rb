module Defaults
	class << self
		def code_accessor_class_name
		  'ILMStringsManager'
		end

		def autogenerated_header 
			"// Autogenerated by ruby localization script\n\n"
		end

		def localization_source_file_template 
			'localization.json'
		end
	end
end