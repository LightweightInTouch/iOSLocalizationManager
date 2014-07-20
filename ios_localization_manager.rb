# The MIT License (MIT)

# Copyright (c) 2014, Lobanov Dmitry (lobanovdm@hotmail.com)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'rubygems'
require 'fileutils'
require 'json'
require 'pp'

def capitalizeFirstLetter(string)
  newString = string.dup
  newString[0] = string[0].upcase
  newString
end

def firstUpcaseWord(string)
  string[/^([^a-z][a-z]+)/].sub(/^_/,'')
end

def toDashesFromCamel(string)
  string.gsub(/([A-Z])/){|m| m = '_' + m.downcase}.sub(/^_/,'')
end

def flat_hash_of_hashes(hash,string = "",delimiter="",result = {},locale_key = "")

  # choose delimiter
  hash.each do |key,value|

    # string dup for avoid string-reference (oh, Ruby)
    newString = string + delimiter + capitalizeFirstLetter(key)
    # if value is string
    if value.is_a?(Hash)
      # next, it is the hash
      flat_hash_of_hashes(value,newString,delimiter,result,locale_key)
    elsif value.is_a?(String)
      unless result[newString]
        result[newString] = {locale_key => value}
      else 
        result[newString] = result[newString].merge({locale_key => value})
      end        
    end



      # # if array not empty
      # value.each do |elementOfArray|

      #   # if a string, I dont need recursion, hah
      #   if elementOfArray.is_a?(String)
      #     resultString = newString + delimiter + elementOfArray
      #     # add new object
      #     result << resultString
      #   end

      #   # if a hash, I need recursion
      #   if elementOfArray.is_a?(Hash)
      #     flat_hash_of_arrays(elementOfArray,newString,delimiter,result)
      #   end

      # end

    
  end
end

def getLocalizationHFile
	'localization.h'
end

def getLocalizationMFile
	'localization.m'
end

def getLocalizationSourceFileTemplate
  'localization.json'
end

def hashOfLocalizations(options)
  result = {}
  flat_hash_of_hashes(options[:local_en_json],"","",result,"en")
  flat_hash_of_hashes(options[:local_ru_json],"","",result,"ru")
  result
end

def outputToHFile(file,options)

  write_to_file = File.open(file,"w")  

  hash = options[:hash_of_localizations]
  hash.each do |key,value|
    stringToOutput = '+ (NSString *)get'+key+'String'+';'
    # pp stringToOutput
    write_to_file.write(stringToOutput + %Q'\n')
  end

end

def outputToMFile(file,options)
  write_to_file = File.open(file,"w")
  hash = options[:hash_of_localizations]
  hash.each do |key,value|
    strings_key = toDashesFromCamel(key)
    table_key   = firstUpcaseWord(key) + 'LocalizationTable'
    stringToOutput = '+ (NSString *)get'+key+'String' + '{' + %Q'return getStringFromTable(#{table_key},"#{strings_key}");}'

    pp stringToOutput
    write_to_file.write(stringToOutput + %Q'\n')
  end
end

def outputToFiles(options)
  write_to_h_file = File.open(getLocalizationHFile,"w")
  write_to_m_file = File.open(getLocalizationMFile,"w")  
  hash_of_files = {}  
  hash = options[:hash_of_localizations]
  pp hash
  hash.each do |key,value| 
    strings_key = toDashesFromCamel(key)
    table_key   = firstUpcaseWord(key) + 'LocalizationTable'
    stringsToOutput = '+ (NSString *)get'+key+'String'
    stringsToOutputH = stringsToOutput + ';'
    stringsToOutputM = stringsToOutput + '{' + %Q'return getStringFromTable(#{table_key},"#{strings_key}");}'

    unless hash_of_files.has_key?(table_key)
      hash_of_files[table_key] = 
      {"en"=>
        File.open(File.expand_path(table_key,options[:local_en_directory]),"w"),
        "ru"=>
        File.open(File.expand_path(table_key,options[:local_ru_directory]),"w")
      }
    end

    value.each do |k,v|
      hash_of_files[table_key][k].write(%Q(\"#{strings_key}\" = \"#{v}\";) + %Q(\n))
    end

    write_to_h_file.write(stringsToOutputH + %Q(\n))
    write_to_m_file.write(stringsToOutputM + %Q(\n))

  end
end

def MainWork (options)

  unless options.has_key?(:source)
    options[:source] = getLocalizationSourceFileTemplate()
  end



  options[:filename] = File.basename(options[:source] , '.json')

  options[:local_en] = options[:filename] + '_en.json'
  options[:local_ru] = options[:filename] + '_ru.json'

  [:local_en,:local_ru].each { |local|
    unless File.exists?(options[local])
      FileUtils.copy(options[:source],options[local])
    end  
  }

  # create localization directories
  options[:local_en_directory] = 'en.lproj'
  options[:local_ru_directory] = 'ru.lproj'
  FileUtils.mkdir_p(options[:local_en_directory])
  FileUtils.mkdir_p(options[:local_ru_directory])
  
  
  # here we have all localization files
  options[:local_en_json] = JSON.parse File.read(options[:local_en])
  options[:local_ru_json] = JSON.parse File.read(options[:local_ru])

  options[:hash_of_localizations] = hashOfLocalizations(options)
  outputToHFile(getLocalizationHFile(),options)
  outputToMFile(getLocalizationMFile(),options)
  outputToFiles(options)


end

MainWork({})