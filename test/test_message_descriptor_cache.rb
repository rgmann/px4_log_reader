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

class TestMessageDescriptorCache < MiniTest::Test

	def setup
	end

	def teardown
	end

	def test_write_read_descriptors

		cache_filename = File.join( 'test', 'test_files', 'test_cache.px4mc' )

		FileUtils.rm( cache_filename ) if File.exist? cache_filename

		# Create a couple of descriptors
		w_descriptors = {}
		descriptor = Px4LogReader::MessageDescriptor.new({
			name: 'FMT',
			type: 0x80,
			length: 89,
			format: 'BBnNZ',
			fields: [ "Type", "Length", "Name", "Format", "Labels" ] })
		w_descriptors[ descriptor.type ] = descriptor.dup

		descriptor = Px4LogReader::MessageDescriptor.new({
			name: 'ATT',
			type: 0x23,
			length: 18,
			format: 'LLBbff',
			fields: [ "sec", "usec", "valid", "offset", "latitude", "longitude" ] })
		w_descriptors[ descriptor.type ] = descriptor.dup


		cache = Px4LogReader::MessageDescriptorCache.new( cache_filename )
		assert_equal false, cache.exist?

		cache.write_descriptors( w_descriptors )
		assert_equal true, cache.exist?

		r_descriptors = cache.read_descriptors

		# assert_equal 2, r_descriptors.size
		# assert_equal [ 0x23, 0x80 ], r_descriptors.keys.sort

		w_descriptors.each do |type,w_descriptor|

			assert_equal true, r_descriptors.keys.include?( type )

			if r_descriptors.keys.include? type

				r_descriptor = r_descriptors[ type ]

				assert_equal w_descriptor.name, r_descriptor.name
				assert_equal w_descriptor.type, r_descriptor.type
				assert_equal w_descriptor.length, r_descriptor.length
				assert_equal w_descriptor.format, r_descriptor.format
				assert_equal w_descriptor.field_list.keys, r_descriptor.field_list.keys

			end

		end

		FileUtils.rm( cache_filename )

	end

end