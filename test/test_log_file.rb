#
# Copyright (c) 2016, Robert Glissmann
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# %% license-end-token %%
# 
# Author: Robert.Glissmann@gmail.com (Robert Glissmann)
# 
# 

require 'minitest/autorun'
require 'px4_log_reader'

class TestLogFile < MiniTest::Test

	def setup
	end

	def teardown
	end

	def test_read_header

		# First, test that read_message_header returns null if the file is exhausted
		# without finding a message header.
		mock_io( rand_data( 256 ).pack('C*') ) do |writer,reader|
			assert_equal [ nil, 256 ], Px4LogReader::LogFile.read_message_header( reader )
			assert_equal 256, reader.pos
		end


		# Insert a message header with type = 0x80 into the middle of the data.
		test_data = rand_data( 256 )
		test_data.concat( Px4LogReader::LogFile::HEADER_MARKER )
		test_data.concat( [ Px4LogReader::FORMAT_MESSAGE.type ] )
		test_data.concat( rand_data( 256 ) )		
		mock_io( test_data.pack('C*') ) do |writer,reader|

			message_type, offset = Px4LogReader::LogFile.read_message_header( reader )

			assert_equal Px4LogReader::FORMAT_MESSAGE.type, message_type
			assert_equal 256 + Px4LogReader::LogFile::HEADER_LENGTH, offset

			message_type, offset = Px4LogReader::LogFile.read_message_header( reader )
			assert_nil message_type
			assert_equal true, reader.eof?
			assert_equal test_data.size, offset

		end


		# Test with a buffer that ends in a message header sync pattern.
		test_data = rand_data( 64 )
		test_data.concat( Px4LogReader::LogFile::HEADER_MARKER )
		mock_io( test_data.pack('C*') ) do |writer,reader|

			message_type, offset = Px4LogReader::LogFile.read_message_header( reader )
			assert_nil message_type
			assert_equal true, reader.eof?
			assert_equal test_data.size, offset

		end
		
	end

	def test_write_message

		fields = [ 0x24, 32, 'test', 'IIbMh', 'id,counts,flag,length,ord' ]

		message = Px4LogReader::LogMessage.new(
			Px4LogReader::FORMAT_MESSAGE,
			fields )

		mock_io do |writer,reader|
			Px4LogReader::LogFile.write_message( writer, message )

			expected_length = Px4LogReader::FORMAT_MESSAGE.length
			assert_equal expected_length, writer.pos

			header = reader.read( 3 )
			assert_equal [ 0xA3, 0x95, 0x80 ], header.unpack('C*')
		end

	end


	def open_log_file
		log_file = File.open( File.join( 'test', 'test_files', 'test_log.px4log' ), 'r' )
		log_file
	end

	# Generate array of random bytes (0-255) that does not contain any message
	# header bytes.
	def rand_data( byte_count )
		test_data = []
		byte_count.times do
			byte = 0
			loop do
				byte = rand(256)
				break unless Px4LogReader::LogFile::HEADER_MARKER.include?( byte )
			end
			test_data << byte
		end
		return test_data
	end

	def mock_io( buffer = nil )

		temp_filename = File.join( 'test', 'temp_test_data', 'mock_io.dat' )
		unless Dir.exist?( File.dirname( temp_filename ) )
			FileUtils.mkdir( File.dirname( temp_filename ) )
		end

		# Create the file.
		FileUtils.touch( temp_filename )

		# Open the file for writing and reading and writing.
		writer = File.open( temp_filename, 'wb' )
		if buffer
			writer.write( buffer )
			writer.flush
		end

		reader = File.open( temp_filename, 'rb' )

		yield writer, reader if block_given?

		reader.close
		writer.close

		if Dir.exist?( File.dirname( temp_filename ) )
			FileUtils.rm_rf( File.dirname( temp_filename ) )
		end

	end

end