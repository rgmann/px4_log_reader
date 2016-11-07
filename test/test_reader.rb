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
			# 1: LPOS
			# 2: GPOS
			# 3: BATT
			# 4: PWR
			# 5: EST0
			# 6: EST1
			# 7: EST2
			# 8: EST3
			# 9: CTS
			# 10: ATT
			# 11: TIME
			# 12: IMU
			# 13: SENS
			# 14: IMU1
			# 15: ATSP
			# 16: ARSP
			# 17: OUT0
			# 18: ATTC
			#
			index = 0
			expected_messages = [
				['LPOS',0x06],
				['GPOS',0x10],
				['BATT',0x14],
				['PWR',0x18],
				['EST0',0x20],
				['EST1',0x21],
				['EST2',0x22]]

			reader.each_message do |message|

				break if index >= expected_messages.size

				expected_name = expected_messages[ index ][0]
				expected_type = expected_messages[ index ][1]

				assert_equal expected_name, message.descriptor.name
				assert_equal expected_type, message.descriptor.type

				context_message = reader.context.find_by_name( expected_name )
				refute_nil context_message
				assert_equal expected_name, context_message.descriptor.name

				context_message = reader.context.find_by_type( expected_type )
				refute_nil context_message
				assert_equal expected_type, context_message.descriptor.type

				index += 1
				assert_equal index, reader.context.messages.size

			end

		end

		assert_equal true, log_file_opened

	end


	def test_reader_blacklist

		log_file_opened = false
		log_filename = File.join( 'test', 'test_files', 'test_log.px4log' )

		Px4LogReader.open( log_filename ) do |reader|

			log_file_opened = true

			# See test_reader for the un-filtered list of messages. This test
			# expects the same list, minus the GPOS and EST1 messages.

			index = 0
			expected_messages = [
				['LPOS',0x06],
				['BATT',0x14],
				['PWR',0x18],
				['EST0',0x20],
				['EST2',0x22]]

			reader.each_message( { without: ['GPOS','EST1'] } ) do |message|

				break if index >= expected_messages.size

				expected_name = expected_messages[ index ][0]
				expected_type = expected_messages[ index ][1]

				assert_equal expected_name, message.descriptor.name
				assert_equal expected_type, message.descriptor.type

				context_message = reader.context.find_by_name( expected_name )
				refute_nil context_message
				assert_equal expected_name, context_message.descriptor.name

				context_message = reader.context.find_by_type( expected_type )
				refute_nil context_message
				assert_equal expected_type, context_message.descriptor.type

				index += 1

			end

		end

		assert_equal true, log_file_opened
	end

	def test_reader_whitelist
		
		log_file_opened = false
		log_filename = File.join( 'test', 'test_files', 'test_log.px4log' )

		Px4LogReader.open( log_filename ) do |reader|

			log_file_opened = true

			# See test_reader for the un-filtered list of messages. This test
			# expects just the GPOS and PWR messages.

			index = 0
			expected_messages = [
				['GPOS',0x10],
				['PWR',0x18]]

			reader.each_message( { with: ['GPOS','PWR'] } ) do |message|

				break if index >= expected_messages.size

				expected_name = expected_messages[ index ][0]
				expected_type = expected_messages[ index ][1]

				assert_equal expected_name, message.descriptor.name
				assert_equal expected_type, message.descriptor.type

				context_message = reader.context.find_by_name( expected_name )
				refute_nil context_message
				assert_equal expected_name, context_message.descriptor.name

				context_message = reader.context.find_by_type( expected_type )
				refute_nil context_message
				assert_equal expected_type, context_message.descriptor.type

				index += 1

			end

		end

		assert_equal true, log_file_opened
	end


	def all_descriptors_found( descriptors )
		# TODO: Validate all descriptors?
		return true
	end

end