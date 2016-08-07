module PX4

	class LogMessage
		attr_reader :description
	   attr_reader :data
	   def initialize( description, fields )
	      @description = description
	      @fields      = fields
	   end
	   def to_csv_line(timestamp)
	      return [ timestamp ].concat( @fields ).join(',')
	   end
	   def get( index )
	      return @fields[ index ]
	   end
	end

end