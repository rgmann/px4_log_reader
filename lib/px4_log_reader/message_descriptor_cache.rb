module Px4LogReaderIncludes

	class MessageDescriptorCache

		attr_reader :cache_filename

		def initialize( filename )
			@cache_filename = filename
		end

		def exist?
			return File.exist?( @cache_filename )
		end

		def read_descriptors

			message_descriptors = {}

         if File.exist?( cache_filename )
            File.open( cache_filename, 'r' ) do |input|
               begin
               	while ( ( data = input.read(4) ) && ( data.length == 4 ) ) do
                     descriptor_size = data.unpack('L').first
                     descriptor = Marshal.load( input.read( descriptor_size ) )

                     message_descriptors[ descriptor.type ] = descriptor
                  end
               rescue EOFError => error
                  puts "Parsed #{@message_descriptions.size} cached message descriptions"
               rescue StandardError => error
                  puts "#{error.class}: #{error.message}"
                  puts error.backtrace.join("\n")
               end
            end
         else
            puts "Cache file '#{cache_filename}' not found"
         end

         return message_descriptors
		end

		def write_descriptors( message_descriptors )
			File.open( @cache_filename, 'w+' ) do |output|
				message_descriptors.each do |message_type,descriptor|
					descriptor_data = Marshal.dump( descriptor )
					output.write( [ descriptor_data.size ].pack('L') )
					output.write( descriptor_data )
				end
			end
		end

	end

end