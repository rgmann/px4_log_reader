module Px4LogReader

	class Error < StandardError

		def initialize( message='' )
			super( message )
		end

	end

	class InvalidDescriptorError < Error

		def initialize( message )
			super( message )
		end

	end

	class FileNotFoundError < Error
		def initialize( filename )
			super( "Failed to find '#{filename}'" )
		end
	end

end