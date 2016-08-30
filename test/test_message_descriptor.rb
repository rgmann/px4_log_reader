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
			Px4LogReaderIncludes::MessageDescriptor.build_format_specifier( px4_format_specifier )

		assert_equal 'CCA4A16A64', ruby_format_specifier
	end

	def test_unpack_message

	end

	def test_descriptor_from_message

		fields = [ 0x24, 32, 'test', 'IIbMh', 'id,counts,flag,length,ord' ]

		message = Px4LogReaderIncludes::LogMessage.new(
			Px4LogReaderIncludes::FORMAT_MESSAGE,
			fields )

		descriptor = Px4LogReaderIncludes::MessageDescriptor.new
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