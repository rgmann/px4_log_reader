module Px4LogReaderIncludes

	class LogMessage
		attr_reader :descriptor
		attr_reader :data
		def initialize( descriptor, fields )
			@descriptor = descriptor
			@fields      = fields
		end
		def to_csv_line(timestamp)
			return [ timestamp ].concat( @fields ).join(',')
		end
		def get( index )
			return @fields[ index ]
		end

		def pack
			return @descriptor.pack_message( @fields )
		end
	end

end