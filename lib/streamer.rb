module Helpers
  require 'json'
  require 'yaml'
  # this class help us to create objects or read them from anything
  # simple usage:
  # my_string = 'string'
  # streamer = MyStreamer.open(my_string, parser: '.json') # or nil if not valid stream
  # streamer.write([])
  # streamer.save!
  # puts my_string # my_string must be '\[\]'
  # with file
  # streamer = MyStreamer.open(file) # or nil if not valid filestream
  # streamer['item'] = new_item
  # streamer.save
  # see file content here

  class Parser
    class << self
      def extname(file)
        File.extname(file)
      end
      def by_extname(name)
        case name
        when '.json'
          JSONParser.new
        when '.yml', '.yaml'
          YAMLParser.new
        end
      end
      def by_filename(file)
        by_extname extname(file)
      end
    end
    def load_file(file)
      nil
    end
    def parse(string)
      nil
    end
    def to_format(object)
      nil
    end
    class JSONParser < Parser
      def load_file(file)
        JSON.load(file)
      end
      def parse(string)
        JSON.parse(string)
      end
      def to_format(object)
        JSON.pretty_generate(object)
      end
    end
    class YAMLParser < Parser
      def load_file(file)
        YAML.load(file)
      end
      def parse(string)
        YAML.load(string)
      end
      def to_format(object)
        object.to_yaml
      end
    end
  end
  class MyStreamer

    attr_reader(
      # stream is "where we read it", string or file
      :stream_outsider,
      # rubish_insider - help us to manipulate stream. history example in accessors
      :rubish_insider,
      # formatter. this class should incapsulate all logic with conversions between formats.
      :parser
      )

    class << self
      def extname(stream)

      end
      def open(stream = nil, options = {})
        item = new(stream, options)
        item.valid? ? item : nil
      end
    end

    def initialize(stream = nil, options = {})
      # first one, if string or not
      if stream && stream.is_a?(String)
        begin
          # file, try to open it
          if File.file? stream
            @parser = Helpers::Parser.by_extname(options[:parser]) || Helpers::Parser.by_filename(stream)
            File.open(stream, 'r') do |infile|
              @rubish_insider = @parser.load_file(infile)
            end

          # try to read it as string
          # so, load it
          else
            @rubish_insider = @parser.parse(stream)
          end
          # save stream here
          # preinit here for insider (accessors needs)
          @stream_outsider = stream
          @rubish_insider ||= {}
        rescue
          # error
          puts "#{self}: can't open stream to read! #{stream}!"
        end
      else
        # error
        puts "#{self}: stream cannot be opened, not a stream! #{stream}"
      end
    end

    # ------------------ Validation ------------------ #
    def valid?
      @stream_outsider && @rubish_insider
    end

    # ------------------ Getters/Setters ------------------ #
    # added key_path support
    def [](key)
      @rubish_insider[key]
    end

    def []=(key,value)
      @rubish_insider[key] = value
    end

    def write(object)
      @rubish_insider = object
    end
    # ------------------ Saving ------------------ #
    def save
      formatted_string = self.to_format
      if File.file? @stream_outsider
        begin
          File.open(@stream_outsider,'w') do |file|
            file.puts formatted_string
          end
        rescue
          # error
          puts "#{self}: can't write to stream in save #{self.inspect}"
        end
      else
        formatted_string
      end
    end

    def save!
      result = save
      unless File.file?(@stream_outsider)
        # string, ok, replace it with result
        if result && result.is_a?(String) && @stream_outsider && @stream_outsider.is_a?(String)
          @stream_outsider.replace(result)
        else
          # error
          puts "#{self}: can't write result #{result} to stream in bang save #{self.inspect}"
        end
      end

    end

    # ------------------ Class Transform ------------------ #
    def to_s
      "my #{@parser} streamer"
    end

    def inspect
      {
        stream_outsider: @stream_outsider,
        rubish_insider: @rubish_insider
      }
    end

    def to_ruby
      @rubish_insider
    end

    def to_format
      @parser.to_format(@rubish_insider)
    end

  end
end
