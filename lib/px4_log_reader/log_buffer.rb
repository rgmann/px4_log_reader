module Px4LogReaderIncludes

	class LogBuffer

		attr_reader :data
		attr_reader :read_position
		attr_reader :write_position

		def initialize( size )
			@data = Array.new( size, 0x00 )
			@read_position = 0
			@write_position = 0
		end

		def reset
			@read_position = 0
			@write_position = 0
		end

		def write( file )
			while ( @write_position < @data.size ) do
				begin

					bytes = file.read( @data.size - @write_position )

					if bytes
						write_bytes( bytes.unpack('C*') )
					else
						break
					end

				rescue EOFError => error
					break
				end
			end
		end

		def read( num_bytes )
			data = ''

			if !empty?
				last_index = @read_position + num_bytes
				last_index = @data.size if last_index > @data.size

				read_count = last_index - @read_position
				data = @data[ @read_position, read_count ].pack('C*')
				@read_position += read_count
			end

			return data
		end

		def empty?
			return ( @read_position == @write_position )
		end

		protected

		def write_bytes( bytes )
			bytes.each do |byte|
				if @write_position < @data.size
					@data[ @write_position ] = byte
					@write_position += 1
				end
			end
		end
	end

	class LogBufferArray

		attr_reader :buffers
		attr_reader :current_buffer_index

		def initialize
			@buffers = []
			@active_file = nil
			@current_buffer_index = 0
		end

		def set_file( file, options = {} )

			opts = {
				buffer_count: 2,
				load_buffers: true,
				buffer_size: 1024
			}.merge( options )

			@active_file = file
			@buffer_count = opts[:buffer_count]
			@buffer_size = opts[:buffer_size] / opts[:buffer_count]

			load_buffers if opts[:load_buffers]
		end

		def load_buffers

			@buffers = []
			@buffer_count.times do
				@buffers << LogBuffer.new( @buffer_size )
			end

			@buffers.each do |buffer|
				buffer.write( @active_file )
			end
		end

		def read( num_bytes )
			data = ''

			while ( data.size < num_bytes ) do

				data << active_buffer.read( num_bytes )

				if data.length < num_bytes
					increment_buffer
					break if active_buffer.empty?
				end

			end

			return data
		end

		def load_empty_buffers
			
			inactive_buffer_index = ( @current_buffer_index + 1 ) % @buffer_count

			while ( inactive_buffer_index != @current_buffer_index ) do
				buffer = buffers[ inactive_buffer_index ]

				if buffer.empty?
					buffer.reset
					buffer.write( @active_file )
				end

				inactive_buffer_index = ( inactive_buffer_index + 1 ) % @buffer_count
			end

		end

		protected

		def active_buffer
			return @buffers[ @current_buffer_index ]
		end

		def increment_buffer
			@current_buffer_index = (@current_buffer_index + 1) % @buffer_count
		end

	end

end