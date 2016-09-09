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

class TestReader < MiniTest::Test

	def setup
	end

	def test_non_existent_log_file

		nonexistent_filename = 'nonexistent_logfile.px4log'

		exception = assert_raises Px4LogReader::FileNotFoundError do
			reader = Px4LogReader.open!( nonexistent_filename )
		end

		exception = assert_raises Px4LogReader::FileNotFoundError do
			Px4LogReader.open!( nonexistent_filename ) do |reader|
			end
		end

	end

	def test_non_existent_log_file_no_except

		nonexistent_filename = 'nonexistent_logfile.px4log'

		assert_nil Px4LogReader.open( nonexistent_filename )

		Px4LogReader.open( nonexistent_filename ) do |reader|
			assert_nil reader
		end
	end

	def test_reader

		log_file_opened = false
		log_filename = File.join( 'test', 'test_files', 'test_log.px4log' )

		Px4LogReader.open( log_filename ) do |reader|

			log_file_opened = true

			# Verify that all expected descriptors are read.
			descriptors = reader.descriptors
			assert_equal Hash, descriptors.class
			assert_equal false, descriptors.empty?

			assert_equal true, all_descriptors_found( descriptors )


			# The log file associated with this test case contains the following
			# messages in the specified order. Validate the order and context.
			#
			# 1) TIME
			# 2) STAT
			# 3) IMU
			# 4) SENS
			# 5) IMU1
			# 6) VTOL
			# 7) GPS
			#
			index = 0
			expected_message_names = ['TIME','STAT','IMU','SENS','IMU1','VTOL','GPS']
			expected_message_types = [0x81,0x0A,0x04,0x05,0x16,0x2B,0x08]

			reader.each_message do |message,context|

				expected_name = expected_message_names[ index ]
				expected_type = expected_message_types[ index ]

				assert_equal expected_name, message.descriptor.name
				assert_equal expected_type, message.descriptor.type

				context_message = context.find_by_name( expected_name )
				refute_nil context_message
				assert_equal expected_name, context_message.descriptor.name

				context_message = context.find_by_type( expected_type )
				refute_nil context_message
				assert_equal expected_type, context_message.descriptor.type

				index += 1
				assert_equal index, context.messages.size

			end

		end

		assert_equal true, log_file_opened

	end


	def test_reader_blacklist

		log_file_opened = false
		log_filename = File.join( 'test', 'test_files', 'test_log.px4log' )

		Px4LogReader.open( log_filename ) do |reader|

			log_file_opened = true

			# The log file associated with this test case contains the following
			# messages in the specified order. Validate the order and context.
			#
			# 1) TIME
			# 2) STAT
			# 3) IMU
			# 4) SENS
			# 5) IMU1
			# 6) VTOL
			# 7) GPS
			#

			index = 0
			expected_message_names = ['TIME','IMU','SENS','VTOL','GPS']
			expected_message_types = [0x81,0x04,0x05,0x2B,0x08]

			reader.each_message( { without: ['STAT','IMU1'] } ) do |message,context|

				expected_name = expected_message_names[ index ]
				expected_type = expected_message_types[ index ]

				assert_equal expected_name, message.descriptor.name
				assert_equal expected_type, message.descriptor.type

				context_message = context.find_by_name( expected_name )
				refute_nil context_message
				assert_equal expected_name, context_message.descriptor.name

				context_message = context.find_by_type( expected_type )
				refute_nil context_message
				assert_equal expected_type, context_message.descriptor.type

				index += 1
				assert_equal index, context.messages.size

			end

		end

		assert_equal true, log_file_opened
	end

	def test_reader_whitelist
		
		log_file_opened = false
		log_filename = File.join( 'test', 'test_files', 'test_log.px4log' )

		Px4LogReader.open( log_filename ) do |reader|

			log_file_opened = true

			# The log file associated with this test case contains the following
			# messages in the specified order. Validate the order and context.
			#
			# 1) TIME
			# 2) STAT
			# 3) IMU
			# 4) SENS
			# 5) IMU1
			# 6) VTOL
			# 7) GPS
			#

			index = 0
			expected_message_names = ['TIME','SENS']
			expected_message_types = [0x81,0x05]

			reader.each_message( { with: ['TIME','SENS'] } ) do |message,context|

				expected_name = expected_message_names[ index ]
				expected_type = expected_message_types[ index ]

				assert_equal expected_name, message.descriptor.name
				assert_equal expected_type, message.descriptor.type

				context_message = context.find_by_name( expected_name )
				refute_nil context_message
				assert_equal expected_name, context_message.descriptor.name

				context_message = context.find_by_type( expected_type )
				refute_nil context_message
				assert_equal expected_type, context_message.descriptor.type

				index += 1
				assert_equal index, context.messages.size

			end

		end

		assert_equal true, log_file_opened
	end


	def all_descriptors_found( descriptors )
		# TODO: Validate all descriptors?
		return true
	end

end