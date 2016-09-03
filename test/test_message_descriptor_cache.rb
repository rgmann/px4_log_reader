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
		descriptor = Px4LogReaderIncludes::MessageDescriptor.new({
			name: 'FMT',
			type: 0x80,
			length: 89,
			format: 'BBnNZ',
			fields: [ "Type", "Length", "Name", "Format", "Labels" ] })
		w_descriptors[ descriptor.type ] = descriptor.dup

		descriptor = Px4LogReaderIncludes::MessageDescriptor.new({
			name: 'ATT',
			type: 0x23,
			length: 18,
			format: 'LLBbff',
			fields: [ "sec", "usec", "valid", "offset", "latitude", "longitude" ] })
		w_descriptors[ descriptor.type ] = descriptor.dup


		cache = Px4LogReaderIncludes::MessageDescriptorCache.new( cache_filename )
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