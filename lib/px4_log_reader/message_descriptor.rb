# require 'px4_log_reader/log_message'

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
				@format_specifier = build_format_specifier( @format )
				fields = attrs[:fields]

				@fieldList = build_field_list( fields )
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

	   def unpack( io )

	   	# 1) Type (1 byte)
	   	# 2) Length (1 byte)
	   	# 3) Name (4 bytes)
	   	# 4) Field type encoding (16 bytes)
	   	# 5) Field names (64 bytes)

			@type, @length, @name, @format, fields = io.read(1+1+4+16+64).unpack('CCA4A16a64')
			@format_specifier = build_format_specifier( @format )

			if fields.empty? == false
				fields = fields.split(',')
				if fields.length != @format.length
					raise "Field count must match format length"
				else
					@field_list = build_field_list( fields )
				end
			end
	   end

	   def build_field_list( fields )
			field_list = {}
			fields.each_with_index do |field,index|
				field_list[field] = index
			end
			field_list
	   end

	   def build_format_specifier( px4_format_string )
			format_specifier = ''

			px4_format_string.chars.each do |field_format|
				case field_format.to_s
				when 'f'
					format_specifier << 'F'
				when 'q', 'Q'
					format_specifier << 'l!'
				when 'i', 'L', 'e'
					format_specifier << 'l'
				when 'I', 'E'
					format_specifier << 'L'
				when 'b'
					format_specifier << 'c'
				when 'B', 'M'
					format_specifier << 'C'
				when 'h', 'c'
					format_specifier << 's'
				when 'H', 'C'
					format_specifier << 'S'
				when 'n'
					format_specifier << 'A4'
				when 'N'
					format_specifier << 'A16'
				when 'Z'
					format_specifier << 'A64'
				else
					raise "Invalid format specifier"
				end
			end

			return format_specifier
	   end

	   def parse_message( message_data )

			@format_specifier = build_format_specifier( @format ) if @format_specifier.nil?
			fields = message_data.unpack( @format_specifier )

			@format.chars.each_with_index do |field_format,index|
				case field_format.to_s
				when 'L'
					fields[index] = fields[index] * 1.0E-7
				when 'c', 'C', 'E'
					fields[index] = fields[index] * 1.0E-2
				else
				end
			end

			return Px4LogReaderIncludes::LogMessage.new( self, fields )
	   end

	   def pack_message( fields )

	   	if fields.count != @format.length
	   		raise "Descriptor format length must match message field count"
	   	end

	   	corrected_fields = fields.dup
	   	@format.chars.each_with_index do |field_format,index|
	   		case field_format.to_s
				when 'L'
					corrected_fields[index] /= 1.0E-7
				when 'c', 'C', 'E'
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

	   def to_csv_line(timestamp_first=true)
	      fields = []
	      fields << "Timestamp" if timestamp_first
	      fields.concat( @field_list.keys )
	      return fields.join(",")
	   end

	end

end