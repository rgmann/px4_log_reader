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

class TestMessageDescriptor < MiniTest::Test

	def setup
	end

	def teardown
	end

	def test_build_format_specifier

		px4_format_specifier = 'BBnNZ'
		ruby_format_specifier =
			Px4LogReader::MessageDescriptor.build_format_specifier( px4_format_specifier )

		assert_equal 'CCA4A16A64', ruby_format_specifier
	end

	def test_unpack_message

	end

	def test_descriptor_from_message

		fields = [ 0x24, 32, 'test', 'IIbMh', 'id,counts,flag,length,ord' ]

		message = Px4LogReader::LogMessage.new(
			Px4LogReader::FORMAT_MESSAGE,
			fields )

		descriptor = Px4LogReader::MessageDescriptor.new
		assert_equal nil, descriptor.type
		assert_equal nil, descriptor.name
		assert_equal nil, descriptor.length
		assert_equal nil, descriptor.format
		assert_equal nil, descriptor.format_specifier
		assert_equal true, descriptor.field_list.empty?

		descriptor.from_message( message )
		assert_equal 0x24, descriptor.type
		assert_equal 'test', descriptor.name
		assert_equal 32, descriptor.length
		assert_equal 'IIbMh', descriptor.format
		assert_equal 'LLcCs', descriptor.format_specifier
		assert_equal false, descriptor.field_list.empty?
		assert_equal 0, descriptor.field_list['id']
		assert_equal 1, descriptor.field_list['counts']
		assert_equal 2, descriptor.field_list['flag']
		assert_equal 3, descriptor.field_list['length']
		assert_equal 4, descriptor.field_list['ord']

	end

end