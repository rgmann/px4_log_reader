module PX4

	module LogFile

		HEADER_MARKER = [0xA3,0x95]
	   HEADER_LENGTH = 3

		FORMAT_MESSAGE = MessageDescriptor.new({
	      name: 'FMT',
	      type: 0x80,
	      length: 89,
	      format: 'BBnZ',
	      fields: ["Type", "Length", "Name", "Format", "Labels"] }).freeze

		def self.read_descriptors( buffered_io, cache_filename )

			message_descriptors = {}

	      loop do
	         begin
	            message_type = read_message_header( file )

	            if message_type.nil?
	               break
	            elsif message_type == FORMAT_MESSAGE.type
	               # puts "Found format message"
	               message_descriptor = MessageDescriptor.new
	               message_descriptor.parse_from_io( file )

	               unless message_descriptors.keys.include? message_descriptor.type
	                  message_descriptors[ message_descriptor.type ] = message_descriptor
	               end

	               if message_descriptor.name == "TIME"
	                  @px4_log_format = true
	               end
	            end

	            # $stdout.printf "\rReading formats %d/%d", io.pos, @file_size

	         rescue StandardError => e
	            puts "#{e.class}: #{e.message}"
	            puts e.backtrace.join("\n")
	            break
	         end
	      end
	      # $stdout.puts

	      # If a cache filename was supplied, dump the descriptors to the cache
	      if cache_filename
	         File.open( cache_filename, 'w+' ) do |io|
	            message_descriptors.each do |message_type,description|
	               description_data = Marshal.dump( description )
	               io.write( [ description_data.size ].pack('L') )
	               io.write( description_data )
	            end
	         end
	      end

	      return message_descriptors
	   end

	   def self.read_message( buffered_io, message_descriptors )

	      message = nil
	      while message.nil? do
	         message_type = read_message_header( buffered_io )

	         if message_type && (message_type != FORMAT_MESSAGE.type)
	            message_description = message_descriptors[ message_type ]

	            if message_description
	               message_data = buffered_io.read( message_description.length - HEADER_LENGTH )
	               message = message_description.parse_message( message_data )
	            else
	               puts "ERROR: Failed to get description for message of type '#{'0x%02X' % message_type}'"
	            end
	         elsif message_type.nil?
	            break
	         end

	         # $stdout.printf "\rReading formats %d/%d", io.pos, @file_size
	      end

	      return message
	   end

	   def self.read_message_header( buffered_io )
	      byte = nil

	      begin

	         data = buffered_io.read(2)

	         if data && data.length == 2
	            loop do

	               data << buffered_io.read(1)

	               # puts "#{data.unpack('CCC')[0,2]} == #{HEADER_MARKER}"
	               if data.unpack('CCC')[0,2] == HEADER_MARKER
	                  byte = data.unpack('CCC').last & 0xFF
	                  # puts "Found message header #{data.unpack('CCC')}"
	                  # puts "message_type = #{'%02X'%byte}"
	                  break
	               else
	                  data = data[1..-1]
	               end

	            end
	         end

	      rescue EOFError => error
	         # Nothing to do.
	      rescue StandardError => error
	         puts error.message
	         puts error.backtrace.join("\n")
	      end

	      return byte
	   end

	end

end