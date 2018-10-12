require 'fileutils'
require_relative './defaults'
require_relative './tools'

class CodeStreamer
	# this class will stream localization into source code files
	attr_reader(
		# the path where it should write data
		:path
		)
	def initialize(path)
		if path
			@path = path
		else
			# raise error?!
			puts "#{self} path cant be nil"
			exit(1)
		end
	end

	# file manipulations	
	def extname
		'.streamer'
	end

	def output_filepath
		item = @path
		name = File.basename(item, File.extname(item))
		dir = File.dirname(item)
		fullname = name + extname
		File.join(dir, fullname)
	end

	def output_file
		File.open(output_filepath, "w")
	end

	# data
	def code_class_name
		Defaults.code_accessor_class_name
	end

	# output
	def full_output(array)
		file = output_file
		prepend_output(file, array)
		output(file, array)
		append_output(file, array)
	end

	def prepend_output(file, array)
		file.write(Defaults.autogenerated_header)
	end

	def output(file, array)

	end

	def append_output(file, array)

	end
end

class HeadersCodeStreamer < CodeStreamer

	def extname
		'.h'
	end

	def prepend_output(file, array)
	  super
	  file.write("\n\#import <Foundation/Foundation.h>\n")
	  file.write("\#import <UIKit/UIKit.h>\n\n")

	  array.map{ |k| Tools.first_upcase_word(k) }.uniq.each do |key|
	    table_key = key + 'LocalizationTable'
	    file.write("static NSString* #{table_key} = " + %Q(\@"#{table_key}";) + "\n")
	  end

	  file.write("\n@interface #{code_class_name} : NSObject\n\n")
	end

	def output(file, array)
	  old_pragma_key = nil
	  array.each do |key|

	    table_id  = Tools.first_upcase_word(key)
	    method_signature = '+ (NSString *)get' + key + 'String'

	    if (old_pragma_key != table_id)
	      old_pragma_key = table_id
	      file.write(%Q(\n#pragma mark - #{old_pragma_key}\n))
	    end
	    
	    file.write(method_signature + ';' + %Q(\n))
	  end
	end

	def append_output(file, hash)
		file.write("\n@end\n")
	end
end

class SourceCodeStreamer < CodeStreamer
	def extname
		'.m'
	end
	def prepend_output(file, array)
		super
	  file.write "\#import " + %Q("#{code_class_name}.h") + "\n\n"
	  file.write "@implementation #{code_class_name}\n\n"

	  file.write %Q(NSString* getStringFromTable(NSString* tableName, NSString* key, NSBundle* bundle){return NSLocalizedStringFromTableInBundle(key, tableName, bundle, @"");}\n)
	  file.write %Q(NSString* getStringFromTableWithClass(NSString* tableName, NSString* key, Class class){return getStringFromTable(tableName, key, [NSBundle bundleForClass:class]);}\n)
	end
	def output(file, array)
		array.each do |key|
	    strings_key = Tools.to_dashes(key)
	    table_id  = Tools.first_upcase_word(key)
	    table_key = table_id + 'LocalizationTable'
	    method_signature = '+ (NSString *)get' + key + 'String'
	    method_body = %Q({return getStringFromTableWithClass(#{table_key}, \@"#{strings_key}", self);})
	    file.write(method_signature + method_body + %Q(\n))
	  end
	end
	def append_output(file, array)
		file.write("\n@end\n")
	end
end

class SwiftCodeStreamer < CodeStreamer
	def extname
		'.swift'
	end

	def prepend_output(file, array)
		super
		# next, we should add class and their methods
		file.write("import Foundation \n")
		file.write(%Q'class #{code_class_name} {\n\n')

		# add common functions
		file.write(%Q'static func getStringFromTable(tableName: String, key: String) -> String {return NSLocalizedString(key, tableName: tableName, value:"", comment:"")}\n')
		file.write("\n")
		# add common localization strings (table names)
		array.collect{ |k| Tools.first_upcase_word(k) }.uniq.each do |key|
			table_key = key + 'LocalizationTable'
			file.write("static var #{table_key} : String = " + %Q'"#{table_key}"' + "\n")
		end
		file.write("\n")
	end

	def output(file, array)
	  array.each do |key|
	    strings_key = Tools.to_dashes(key)
	    table_id  = Tools.first_upcase_word(key)
	    table_key = table_id + 'LocalizationTable'
	    function_name = 'get' + key + 'String'
	    method_signature = 'static func ' + function_name + '()' + ' -> String '
	    method_body = %Q({ return getStringFromTable(#{table_key},key:"#{strings_key}")})
	    file.write(method_signature + method_body + %Q(\n))
	  end
	end

	def append_output(file, array)
		file.write(%Q'\n\n}\n\n')
	end
end
class ClassSwiftCoderStreamer < CodeStreamer
	def extname 
		'.swift'
	end
	def arrayToHashWithTableNames(array)
		# convert:
		# someBigWord -> Some: [{'key':bigWord, 'string':'some_big_word' }]
		array.reduce({}){|hash, element|
			hash[Tools.first_upcase_word(element)] ||= []
			hash[Tools.first_upcase_word(element)] += [{key: Tools.without_first_word(element), string: Tools.to_dashes(element)}]
			hash
		}
	end
	def prepend_output(file, array)
		keys_hash = arrayToHashWithTableNames(array)
		# convert array into something more appropriate.
		super
		file.write("import Foundation \n")
		file.write(%Q'class #{code_class_name} {\n\n')
		
		# add common functions
		file.write(%Q'static func getStringFromTable(tableName: String, key: String) -> String {return NSLocalizedString(key, tableName: tableName, value:"", comment:"")}\n')
		file.write("\n")

		# unnecessary due to classes
		# add common localization strings (table names)
		array.collect{ |k| Tools.first_upcase_word(k) }.uniq.each do |key|
			table_key = key + 'LocalizationTable'
			file.write("static let #{table_key} = " + %Q'"#{table_key}"' + "\n")
		end
		file.write("\n")
	end

	def output(file, array)
		keys_hash = arrayToHashWithTableNames(array)

		keys_hash.each do |k, v|
		    table_id  = k
		    table_key = table_id + 'LocalizationTableStrings'

		    current_class_name = table_id + 'Strings'
		    class_declaration = %Q'class #{current_class_name} {\n\n'
		    class_ending = %Q'\n\n}\n\n'
		    file.write(class_declaration)

		    v.sort{|a,b| a[:key]<=>b[:key]}.each do |hash|
				key = hash[:key]
				strings_key = hash[:string]

			    #function_name = 'get' + key + 'String'
			    function_name = key
			    method_signature = 'static func ' + function_name + '()' + ' -> String '
			    method_body = %Q({ return getStringFromTable(#{table_key},key:"#{strings_key}")})
			    file.write(method_signature + method_body + %Q(\n))
		    end
		    file.write(class_ending)
		end
	end

	def append_output(file, array)
		file.write(%Q'\n\n}\n\n')
	end
end