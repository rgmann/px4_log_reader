module Px4LogReaderIncludes

	class LogMessage
		attr_reader :descriptor
		attr_reader :fields
		def initialize( descriptor, fields )
			@descriptor = descriptor
			@fields     = fields
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

		def to_s
			return to_csv_line( Time.now )
		end
	end

end