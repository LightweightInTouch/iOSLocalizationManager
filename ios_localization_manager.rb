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
require 'optparse'
require_relative './lib/tools'
require_relative './lib/defaults'
require_relative './lib/code_streamer'
require_relative './lib/localization_kit'
include LocalizationKit
class AppleFruitLocalizationManager

  attr_reader(
    # user options
    :options
    )

  def initialize(options = {})
    @options = options
  end

  # options computed properties
  
  def work_directory
    File.expand_path(options[:work_directory] || '.')
  end

  def source
    options[:localization_filepath] ? File.basename(options[:localization_filepath]) : Defaults.localization_source_file_template
  end

  def localization_filepath
    File.expand_path(options[:localization_filepath]) || correct_file_path(source)
  end

  def code_filepath
    correct_file_path(Defaults.code_accessor_class_name)
  end

  # necessaries
  def swift?
    options[:programming_language] =~ /s(wift)?/
  end

  def correct_file_path(file)
    File.join(work_directory, file)
  end

  def debug(string)
    stream = options[:output_stream] || $stdout
    stream.puts string
  end

  # inspect
  def inspect
    [
    "work_directory: #{work_directory}",
    "source: #{source}",
    "localization_filepath: #{localization_filepath}",
    "code_filepath: #{code_filepath}",
    "options: #{options}"
    ].join("\n")
  end

  # work
  def work!
    if options[:dry_run]
      debug("#{self} have options! #{options}")
      return
    end

    unless Dir.exists?(options[:work_directory])
      FileUtils.mkdir_p(options[:work_directory])
    end

    if options[:inspection]
      debug("#{self} have options: #{options} and #{self.inspect}")
    end

    output_to_files
  end

  def output_to_files

    seeder = LocalizationSeeder.new(localization_filepath, work_directory)
    seeder.collect

    data = seeder.extractor.collected_keys_names
    code = code_filepath
    if swift?      
      SwiftCodeStreamer.new(code).full_output data
    else
      HeadersCodeStreamer.new(code).full_output data
      SourceCodeStreamer.new(code).full_output data
    end

    puts "done at #{work_directory} \nwith file #{localization_filepath}\n "
  end

end

def MainWork (options)
  AppleFruitLocalizationManager.new(options).work!
end

# ------------------- Beginning ----------------- #
def HelpMessage(options)

  # %x[rdoc $0]
  # not ok
  puts <<-__HELP__

  #{options.help}

  put near your script

  ---------------
  Usage:
  ---------------
  In Finder

  __HELP__

end


# options parser:
options = {}


OptionParser.new do |opts|
  opts.banner = "Usage: TagsHelper.rb [options]"

  opts.on('-w','--work_directory DIRECTORY', 'Work Directory') {|v| options[:work_directory] = v}
  opts.on('-p','--language LANG', 'Programming Language') {|v| options[:programming_language] = v}
  opts.on('-f','--localization_file FILE', 'File with localization') {|v| options[:localization_filepath] = v}
  opts.on('-t', '--test', 'Test option') {|v| options[:test] = v}
  opts.on('-l', '--log_level LEVEL', 'Logger level of warning') {|v| options[:log_level] = v}
  opts.on('-o', '--output_log OUTPUT', 'Logger output stream') {|v| options[:output_stream] = v}
  opts.on('-d', '--dry_run', 'Dry run to see all options') {|v| options[:dry_run] = v}
  opts.on('-i', '--inspection', 'Inspection of all items, like tests'){|v| options[:inspection] = v}
  # help
  opts.on('-h', '--help', 'Help option') { HelpMessage(opts); exit()}
end.parse!

MainWork(options)