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

	class MockFileIO

		attr_reader :buffer

		def initialize
			@buffer = ''
		end

		def reset
			@buffer = ''
		end

		def read( byte_count = nil )
			data = nil

			if byte_count >= @buffer.size
				data = @buffer.dup
				@buffer = ''
			else
				data = @buffer[ 0, byte_count ].dup
				@buffer = @buffer[ byte_count .. -1 ]
			end

			data
		end

		def read_nonblock( byte_count = nil )
			return read( byte_count )
		end

		def write( data )
			@buffer << data
		end

	end

	def test_read_header

		# First, test that read_message_header returns null if the file is exhausted
		# without finding a message header.
		mock_io = MockFileIO.new
		mock_io.write( rand_data( 256 ).pack('C*') )

		assert_nil Px4LogReader::LogFile.read_message_header( mock_io )
		assert_equal true, mock_io.buffer.empty?


		# Insert a message header with type = 0x80 into the middle of the data.
		mock_io = MockFileIO.new

		test_data = rand_data( 256 )
		test_data.concat( Px4LogReader::LogFile::HEADER_MARKER )
		test_data.concat( [ Px4LogReader::FORMAT_MESSAGE.type ] )
		test_data.concat( rand_data( 256 ) )
		mock_io.write( test_data.pack('C*') )

		assert_equal Px4LogReader::FORMAT_MESSAGE.type, Px4LogReader::LogFile.read_message_header( mock_io )
		assert_equal 256, mock_io.buffer.size

		assert_nil Px4LogReader::LogFile.read_message_header( mock_io )
		assert_equal true, mock_io.buffer.empty?


		# Test with a buffer that ends in a message header sync pattern.
		mock_io = MockFileIO.new

		test_data = rand_data( 64 )
		test_data.concat( Px4LogReader::LogFile::HEADER_MARKER )
		mock_io.write( test_data.pack('C*') )

		assert_nil Px4LogReader::LogFile.read_message_header( mock_io )
		assert_equal true, mock_io.buffer.empty?
		
	end

	def test_write_message

		mock_io = MockFileIO.new

		fields = [ 0x24, 32, 'test', 'IIbMh', 'id,counts,flag,length,ord' ]

		message = Px4LogReader::LogMessage.new(
			Px4LogReader::FORMAT_MESSAGE,
			fields )

		Px4LogReader::LogFile.write_message( mock_io, message )

		expected_length = Px4LogReader::FORMAT_MESSAGE.length + Px4LogReader::LogFile::HEADER_MARKER.length + 1
		assert_equal expected_length, mock_io.buffer.length 
		assert_equal [ 0xA3, 0x95, 0x80 ], mock_io.buffer[0,3].unpack('C*')

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

end