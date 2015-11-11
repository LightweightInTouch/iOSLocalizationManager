module Helpers
	require 'json'
	# this class help us to create json objects or read them from anything
	# simple usage:
	# my_string = 'string'
	# streamer = MyJSONStreamer.open(my_string) # or nil if not valid stream
	# streamer.write([])
	# streamer.save!
	# puts my_string # my_string must be '\[\]'
	# with file
	# streamer = MyJSONStreamer.open(file) # or nil if not valid filestream
	# streamer['item'] = new_item
	# streamer.save
	# see file content here
	class MyJSONStreamer

		attr_reader(
			# stream is "where we read it", string or file
			:stream_outsider,
			# rubish_insider - help us to manipulate stream. history example in accessors
			:rubish_insider
			)

		class << self
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

						File.open(stream, 'r') do |infile|
							@rubish_insider = JSON.load(infile)
						end

					# try to read it as string
					# so, load it
					else
						@rubish_insider = JSON.parse(stream)
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
			json_string = self.to_json
			if File.file? @stream_outsider
				begin
					File.open(@stream_outsider,'w') do
						|file|
						file.puts json_string
					end
				rescue
					# error
					puts "#{self}: can't write to stream in save #{self.inspect}"
				end
			else
				json_string
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
			'my json streamer'
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

		def to_json
			@rubish_insider ? JSON.pretty_generate(@rubish_insider) : '{}'
		end

	end
end