module Px4LogReader

	def self.open_common( file, options, &block )

		reader = Reader.new( file, options )

		yield reader if block_given?

		return reader
	end

	def self.open( filename, options = {}, &block  )

		reader = nil

		if File.exist?( filename )
			reader = self.open_common( File.open( filename, 'r' ), options, block )
		end	

		return reader

	end

	def self.open!( filename, options = {}, &block )
		reader = nil

		if File.exist?( filename )
			reader = self.open_common( File.open( filename, 'r' ), options, block )
		else
			raise FileNotFoundError.new
		end	

		return reader
	end

   class Context
   	attr_reader :messages
   	def initialize
   		messages = {}
   	end
   	def find_by_name( name )
   		named_message = nil
   		@messages.values.each do |message|
   			if message.descriptor.name == name
   				named_message = message
   			end
   		end
   		return named_message
   	end
   	def find_by_type( type )
   		return @messages[ type ]
   	end
   	def set( message )
   		@messages[ message.descriptor.type ] = message.dup
   	end
   end

	class Reader   

		def initialize( file, options )

			opts = {
				cache_filename: nil,
				buffer_size_kb: 10 * 1024
			}.merge( options )

			@message_descriptors = {}
			@buffers = LogBufferArray.new
			@descriptor_cache = nil
			@context = Context.new

			@log_file = file
			# @buffers.set_file( @log_file, load_buffers: true )

			@descriptor_cache = MessageDescriptorCache.new( opts[:cache_filename] )
		end

		def descriptors
			if @log_file && @message_descriptors.empty?
				if @descriptor_cache && @descriptor_cache.exist?
					@message_descriptors = @descriptor_cache.read_descriptors
				else
					@message_descriptors = LogFile::read_descriptors( @log_file, @descriptor_cache )
				end
			end

			return @message_descriptors
		end

		def each_message( options, &block )

			opts ={
				with: [],        # white list - empty means all minus those in without list
				without: ['FMT'] # black list - includes types or names
			}.merge( options || {} )

			opts[:with].map! do |val|
				if val.class == String
					descriptor = descriptors.find { |desc| desc.name == val }
					val = descriptor.type
				end
			end

			opts[:without].map! do |val|
				if val.class == String
					descriptor = descriptors.find { |desc| desc.name == val }
					val = descriptor.type
				end
			end

			if block_given?

				loop do

					message = LogFile::read_message( @buffers, @message_descriptors )
					break if message.nil?

					# Added message to the set of latest messages.
					@context.set( message )

					if opts[:with].empty?
						if !opts[:without].include?( message.descriptor.name )
							yield message, @context
						end
					else
						if opts[:with].include?( message.descriptor.type )
							yield message, @context
						end
					end

				end

			else
				raise BlockRequiredError.new
			end

		end

		# def rewind
		# 	if @log_file

		# 	@log_file.rewind
		# 	@buffers.load_buffers

		# 	end
		# end

		# def seek( offset )
		# end

	end

end
