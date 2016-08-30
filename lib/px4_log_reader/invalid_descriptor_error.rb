module Px4LogReaderIncludes

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

end