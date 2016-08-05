module Tools
	class << self
		def capitalize_first_letter(string)
		  newString = string.dup
		  newString[0] = string[0].upcase
		  newString
		end

		def downcase_first_letter(string)
			newString = string.dup
			newString[0] = string[0].downcase
			newString
		end

		def first_upcase_word(string)
			string[/^([^a-z][a-z]+)/].sub(/^_/,'')
		end

		def without_first_word(string)
			string.sub(string[/^([^a-z][a-z]+)/],'')
		end

		# convert cases
		def to_dashes(string)
			downcase_first_letter(string).gsub(/([A-Z])/){|m| '_' + m.downcase}
		end

		def to_camel(string)
			# puts "I am here!"
			string.gsub(/(?<dash>_)(?<letter>\w)/){|_| $~[:letter].upcase}
		end

		# Hash handling
		def localization_hash?(hash)
			hash.all?{|key,value|
			  key_normal = key.is_a?(String)
			  key_correct_name = (key=~/^[a-z]{2}/) && (key.length == 2 || key.length > 2 && key =~ /[-]/)
			  value_normal = value.is_a?(String)
			  key_normal && value_normal && key_correct_name
			}
		end

		def flatten_hash_of_hashes(hash, string = "", delimiter="", locale_key = "")
			result = {}
			flat_hash_of_hashes(hash, string, delimiter, locale_key, result)
			result
		end

		def flat_hash_of_hashes(hash, string = "", delimiter="", locale_key = "", result = {})
		  # choose delimiter
		  hash.each do |key, value|
		    # string dup for avoid string-reference (oh, Ruby)
		    newString = string + delimiter + Tools.capitalize_first_letter(key)
		    # if value is string
		    if value.is_a?(Hash)
		      # next, it is the hash
		      if Tools.localization_hash?(value)
		        # if localization hash, then, put it correctly
		        result[newString] = value
		      else
		        # just a hash value, go deeper
		        flat_hash_of_hashes(value, newString, delimiter, locale_key, result)
		      end
		    elsif value.is_a?(String)
		      unless result[newString]
		        result[newString] = {locale_key => value}
		      else
		        result[newString] = result[newString].merge({locale_key => value})
		      end
		    end
		  end
		end
	end
end