require 'minitest/autorun'
require 'px4_log_reader'

class TestLogBuffer < MiniTest::Test

	def setup
	end

	def test_buffer_create

		buffer_size = 256
		buffer = Px4LogReaderIncludes::LogBuffer.new( buffer_size )

		assert_equal buffer_size, buffer.data.size
		assert_equal Array.new( buffer_size, 0x00 ), buffer.data
		assert_equal 0, buffer.read_position
		assert_equal 0, buffer.write_position
		assert_equal true, buffer.empty?

	end

	def test_buffer_read_write

		buffer_size = 256
		buffer = Px4LogReaderIncludes::LogBuffer.new( buffer_size )

		test_filename = './test_buffer_read_write.bin'
		generate_test_file( test_filename, buffer_size )

		test_file = File.open( test_filename,'rb+')
		
		assert_equal true, buffer.empty?

		buffer.write( test_file )
		assert_equal 0, buffer.read_position
		assert_equal 256, buffer.write_position
		assert_equal false, buffer.empty?

		test_read_1_size = 112
		data = buffer.read( test_read_1_size )
		assert_equal test_read_1_size, data.size
		assert_equal test_read_1_size, buffer.read_position
		assert_equal buffer_size, buffer.write_position
		assert_equal false, buffer.empty?

		test_read_2_size = 256
		data = buffer.read( test_read_2_size )
		assert_equal (buffer_size - test_read_1_size), data.size
		assert_equal buffer_size, buffer.read_position
		assert_equal buffer_size, buffer.write_position
		assert_equal true, buffer.empty?

		test_file.close

		FileUtils.rm test_filename

	end

	def test_buffer_array

		buffer_array = Px4LogReaderIncludes::LogBufferArray.new

		file_size = 256
		test_filename = './test_buffer_array.bin'
		generate_test_file( test_filename, file_size )

		buffer_size  = file_size
		buffer_count = 4
		buffer_array.set_file( File.open( test_filename, 'rb' ), buffer_size: buffer_size, buffer_count: buffer_count )

		assert_equal buffer_count, buffer_array.buffers.count
		assert_equal 0, buffer_array.current_buffer_index

		buffer_array.buffers.each do |buffer|
			assert_equal false, buffer.empty?
			assert_equal 0, buffer.read_position
			assert_equal (buffer_size / buffer_count), buffer.write_position
			assert_equal (buffer_size / buffer_count), buffer.data.size
		end

		file_size.times do |index|
			assert_equal index, buffer_array.read(1).unpack('C').first
		end

		FileUtils.rm test_filename

	end


	def test_buffer_array_refill
		buffer_array = Px4LogReaderIncludes::LogBufferArray.new

		file_size = 256
		test_filename = './test_buffer_array_refill.bin'
		generate_test_file( test_filename, file_size )

		buffer_size  = file_size / 2
		buffer_count = 4
		single_buffer_size = buffer_size / buffer_count
		buffer_array.set_file( File.open( test_filename, 'rb' ), buffer_size: buffer_size, buffer_count: buffer_count )

		assert_equal buffer_count, buffer_array.buffers.count
		assert_equal 0, buffer_array.current_buffer_index

		buffer_array.buffers.each do |buffer|
			assert_equal false, buffer.empty?
			assert_equal (buffer_size / buffer_count), buffer.write_position
			assert_equal (buffer_size / buffer_count), buffer.data.size
		end

		data = ''

		# Read enough data to empty the first buffer.
		data << buffer_array.read( single_buffer_size + single_buffer_size / 2 )
		assert buffer_array.buffers[0].empty?

		# Refill the empty buffer.
		buffer_array.load_empty_buffers
		assert_equal false, buffer_array.buffers[0].empty?
		data << buffer_array.read( single_buffer_size / 2 + 3 * single_buffer_size )
		assert_equal 5 * single_buffer_size, data.size

		# Verify that we cannot read any more data.
		assert_equal '', buffer_array.read( single_buffer_size )

		assert_equal true, validate_data( test_filename, data )


		FileUtils.rm test_filename
	end


	def generate_test_file( path, size )
		test_filename = './test_buffer_read_write.bin'
		File.open( path, 'wb+' ) do |io|
			value = 0
			size.times do
				io.write( [ value ].pack('C') )
				value = ( value + 1 ) % 256
			end
		end
	end

	def validate_data( path, data, max_bytes = nil )
		equal = true

		max_bytes = data.size if max_bytes.nil?

		data = data.unpack('C*')

		File.open( path, 'rb' ) do |io|
			comp_index = 0
			while ( comp_index < max_bytes ) && equal do
				begin
					byte = io.read(1).unpack('C').first
					if data[comp_index] != byte
						puts "mismatch at offset=#{comp_index}: expected '#{"0x%02X"%byte}; found '#{"0x%02X"%data[comp_index]}'"
						equal = false
					end
				rescue EOFError => error
					puts "reached EOF before end of data"
					equal = false
				end
				comp_index += 1
			end
		end

		return equal
	end

end


