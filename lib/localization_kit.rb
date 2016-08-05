require 'fileutils'
require_relative './tools'
require_relative './json_streamer'
include Helpers
module LocalizationKit
	class LocalizationExtractor
		attr_reader(
			# file with localization
			:path,
			# data with localization inside
			# it stored as 'key' => localization_hash		
			:data_hash,
			# table names are first keys in hash that we read from json.
			:table_names
			)
		def initialize(path)
			if path
				@path = path
			else
				puts "#{self} can't find localization file!"
			end
		end

		def valid?
			@path && File.exists?(@path) && File.file?(@path) && MyJSONStreamer.open(@path)
		end

		def extract
			if valid?
				hash = MyJSONStreamer.open(@path).to_ruby				
				# default localization: "en"
				# delimiter is '/' sign
				Tools.flatten_hash_of_hashes(hash, "", "", "en")
			else
				{}
			end
		end

		def data_hash
			@data_hash ||= extract
		end

		# the unique keys in localizations hashes
		def collected_localization_names			
			data_hash.values.map{|element| element.keys}.flatten.uniq
		end

		# the first upcase words among all keys
		def collected_table_names
			data_hash.keys.map{|k,v| Tools.first_upcase_word(k)}.uniq
		end

		def collected_keys_names
			data_hash.keys
		end

		def localization_by_name(name)		
			data_hash.reduce({}){|h, (k,v)| h[k] = v[name]; h}
		end
	end

	def outputToLocalizationFiles(options)
	  # hash = options[:hash_of_localizations]
	  # sorted_hash_keys = options[:hash_of_localizations_sorted_keys]
	  # hash_of_files = {}
	  sorted_hash_keys.each do |key|
	    value = hash[key]
	    strings_key = toDashesFromCamel(key)
	    table_id  = firstUpcaseWord(key)
	    table_key = table_id + 'LocalizationTable'

	    unless hash_of_files.has_key?(table_key)
	      hash_of_files[table_key] =
	      {"en"=>
	        File.open(File.expand_path(table_key+'.strings',options[:local_en_directory]),"w"),
	        "ru"=>
	        File.open(File.expand_path(table_key+'.strings',options[:local_ru_directory]),"w")
	      }
	    end

	    value.each do |k,v|
	      hash_of_files[table_key][k].write(%Q(\"#{strings_key}\" = \"#{v}\";) + %Q(\n))
	    end

	  end
	end

	class LocalizationStreamer
		attr_reader(
			# the path of file where we will write localization data
			:path
			)
		def initialize(path)
			if path
				@path = path
			else 
				puts "#{self} can't find localization file!"
			end
		end

		def full_output(data)
			file = File.open(@path, "w")
			output(file, data)
		end

		def output(file, data)
			# data is a hash with key -> localization
			data.keys.sort.each do |key|
		    localized_string = data[key]
				strings_key = Tools.to_dashes(key)
		    output_data = %Q(\"#{strings_key}\" = \"#{localized_string}\";) + %Q(\n)
		    file.write(output_data)
			end
		end
	end

	class LocalizationSeeder
		attr_reader(
			# path to localization file
			:path,
			# path to output directory
			:output_directory,
			# extractor,
			:extractor
			)
		def initialize(path, output_directory)
			if path && output_directory
				@path = path
				@output_directory = output_directory
			else
				puts "#{self} can't find path: #{path} or output_directory: #{output_directory}"
			end
		end

		def localized_directory(name)
			File.join(output_directory, name + '.lproj')
		end

		def localized_table(name)
			name + 'LocalizationTable' + '.strings'
		end

		def localized_table_path(localization, name)
			File.join localized_directory(localization), localized_table(name)
		end

		def collect
			# try to create localization extractor
			@extractor = LocalizationExtractor.new path
			unless @extractor.valid?
				puts "#{self} can't create extractor at path! #{path}"
				return
			end

			# puts "collected localization names: #{@extractor.collected_localization_names}"
			@extractor.collected_localization_names.each do 
				|localization|

				# create target directory if doesn't exists				
				target_directory = localized_directory(localization)
				unless File.exists? target_directory
					FileUtils.mkdir_p target_directory
				end

				data = extractor.localization_by_name(localization)

				# we should split data by collected_table_names
				grouped_data = 
				data.reduce({}) do |hash, (k,v)| 
					table_key = Tools.first_upcase_word(k)
					hash[table_key] ||= {}
					hash[table_key][k] = v
					hash
				end

				grouped_data.each do |k,v|
					table_name = k
					table = localized_table_path(localization, table_name)				
					streamer = LocalizationStreamer.new(table)
					streamer.full_output(v)
				end
			end

		end
	end
end