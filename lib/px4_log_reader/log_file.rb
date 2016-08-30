
module Px4LogReaderIncludes

	module LogFile

		HEADER_MARKER = [0xA3,0x95]
	   HEADER_LENGTH = 3
	   FORMAT_DESCRIPTOR_TABLE = { FORMAT_MESSAGE.type => FORMAT_MESSAGE }.freeze

		def self.read_descriptors( buffered_io, cache_filename=nil )

			message_descriptors = {}

			while ( message_descriptor = read_descriptor( buffered_io ) ) do
				if !message_descriptors.keys.include? message_descriptor.type
					message_descriptors[ message_descriptor.type ] = message_descriptor
				end
			end

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

		def self.read_descriptor( buffered_io, skip_corrupt=true )

			message_descriptor = nil

		   	begin

				descriptor_message = read_message( buffered_io, FORMAT_DESCRIPTOR_TABLE )

				if descriptor_message

					message_descriptor = Px4LogReaderIncludes::MessageDescriptor.new
					message_descriptor.from_message( descriptor_message )

				end

			rescue Px4LogReaderIncludes::InvalidDescriptorError => error

				if skip_corrupt
					retry
				else
					raise error
				end

			rescue StandardError => e
				puts "#{e.class}: #{e.message}"
				puts e.backtrace.join("\n")
			end

			return message_descriptor
	   end

	   def self.read_message( buffered_io, message_descriptors )

			message = nil
			while message.nil? do
				message_type = read_message_header( buffered_io )

				if message_type

					message_descriptor = message_descriptors[ message_type ]

					if message_descriptor
						message_data = buffered_io.read( message_descriptor.length - HEADER_LENGTH )
						message = message_descriptor.unpack_message( message_data )
					end

				elsif message_type.nil?
					break
				end
			end

			return message
	   end

	   def self.read_message_header( buffered_io )
	      message_type = nil

	      begin

	         data = buffered_io.read(2)

	         if data && data.length == 2

	            while !data.empty? && message_type.nil? do

	            	if ( byte = buffered_io.read(1) )
		               data << byte
		            end

	               if data.unpack('CCC')[0,2] == HEADER_MARKER
	                  message_type = data.unpack('CCC').last & 0xFF
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

	      return message_type
	   end


	   def self.write_message( io, message )
	   	io.write HEADER_MARKER.pack('CC')
	   	io.write [ message.descriptor.type ].pack('C')
	   	io.write message.pack
	   end

	end

end