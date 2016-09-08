module Px4LogReader

	class LogMessage
		attr_reader :descriptor
		attr_reader :fields
		def initialize( descriptor, fields )
			@descriptor = descriptor
			@fields     = fields
		end

		def get( index )

			index = index
			if index.class == String
				index = descriptor.field_list[ index ]
			end

			return @fields[ index ]
		end

		def pack
			return @descriptor.pack_message( @fields )
		end

		def to_s
			return to_csv_line( Time.now )
		end
	end

end