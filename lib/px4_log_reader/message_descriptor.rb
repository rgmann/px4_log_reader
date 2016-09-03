
module Px4LogReaderIncludes

	class MessageDescriptor

	   attr_reader :name
	   attr_reader :type
	   attr_reader :length
	   attr_reader :format
	   attr_reader :field_list
	   attr_reader :format_specifier

	   def initialize(attrs={})
			if attrs.keys.uniq.sort == [:name,:type,:length,:format,:fields].uniq.sort
				@name = attrs[:name]
				@type = attrs[:type]
				@length = attrs[:length]
				@format = attrs[:format]
				@format_specifier = MessageDescriptor.build_format_specifier( @format )
				fields = attrs[:fields]

				@field_list = MessageDescriptor.build_field_list( fields )
			elsif attrs.size > 0
				raise "Missing attributes"
			else
				@name = nil
				@type = nil
				@length = nil
				@format = nil

				@field_list = {}
			end
	   end

		def from_message( message )

			if message.descriptor.type != 0x80

				raise InvalidDescriptorError.new(
					'Invalid descriptor type for format specifier message' )

			elsif message.fields.count != 5

				raise InvalidDescriptorError.new(
					"Invalid field count for format specifier message: expected 5 fields, found #{message.fields.count}" )

			end

			@type, @length, @name, @format, fields_string = message.fields

			@format_specifier = MessageDescriptor.build_format_specifier( @format )

			unless fields_string.empty?

				fields = fields_string.split(',')

				if fields.length != @format.length
					raise InvalidDescriptorError.new(
						"Field count must match format length: expected #{@format.length}; found #{fields.length}")
				else
					@field_list = MessageDescriptor.build_field_list( fields )
				end

			end
			
	   end

		class << self

			def build_field_list( fields )
				field_list = {}
				fields.each_with_index do |field,index|
					field_list[field] = index
				end
				field_list
			end

			def build_format_specifier( px4_format_string )
				format_specifier = ''

				px4_format_string.unpack('C*').each do |field_format|
					case field_format
					when 0x66 # 'f'
						format_specifier << 'F'
					when 0x71, 0x51 # 'q', 'Q'
						format_specifier << 'l!'
					when 0x69, 0x4C, 0x65 # 'i', 'L', 'e'
						format_specifier << 'l'
					when 0x49, 0x45 # 'I', 'E'
						format_specifier << 'L'
					when 0x62 # 'b'
						format_specifier << 'c'
					when 0x42, 0x4D # 'B', 'M'
						format_specifier << 'C'
					when 0x68, 0x63 # 'h', 'c'
						format_specifier << 's'
					when 0x48, 0x43 # 'H', 'C'
						format_specifier << 'S'
					when 0x6E # 'n'
						format_specifier << 'A4'
					when 0x4E # 'N'
						format_specifier << 'A16'
					when 0x5A # 'Z'
						format_specifier << 'A64'
					else
						raise InvalidDescriptorError.new(
							"Invalid format specifier: '#{ '0x%02X' % field_format }' in #{px4_format_string}")
					end
				end

				return format_specifier
			end
		end

		def unpack_message( message_data )

			if @format_specifier.nil?
				@format_specifier = MessageDescriptor.build_format_specifier( @format )
			end

			fields = message_data.unpack( @format_specifier )

			@format.unpack('C*').each_with_index do |field_format,index|
				case field_format
				when 0x4C # 'L'
					fields[index] = fields[index] * 1.0E-7
				when 0x63, 0x43, 0x45 # 'c', 'C', 'E'
					fields[index] = fields[index] * 1.0E-2
				else
				end
			end

			if fields.nil? || fields.empty?
				raise "No fields"
			end

			return LogMessage.new( self, fields )
		end

		def pack_message( fields )

			if fields.count != @format.length
				raise "Descriptor format length must match message field count"
			end

			corrected_fields = fields.dup
			@format.unpack('C*').each_with_index do |field_format,index|
				case field_format
				when 0x4C # 'L'
					corrected_fields[index] /= 1.0E-7
				when 0x63, 0x43, 0x45 # 'c', 'C', 'E'
					corrected_fields[index] /= 1.0E-2
				else
				end
	   	end

	   	return corrected_fields.pack( @format_specifier )
	   end

	   def to_s
			puts "#{@name}( #{@type} ):"
			puts "   length = #{@length}"
			puts "   format = #{@format}"
			@field_list.each do |name,index|
				puts "   field#{index} = #{name}"
			end
		end

	end

	#
	# Message descriptor for format messages
	#
	FORMAT_MESSAGE = Px4LogReaderIncludes::MessageDescriptor.new({
		name: 'FMT',
		type: 0x80,
		length: 89,
		format: 'BBnNZ',
		fields: [ "Type", "Length", "Name", "Format", "Labels" ] }).freeze

end