class Px4LogReader

   include Px4LogReaderIncludes

   

   attr_reader :message_descriptions
   attr_reader :messages
   attr_reader :px4_log_format

   def initialize
      @message_descriptors = {}
      @latest_messages = {}
      @log_buffer_array = LogBufferArray.new
      @descriptor_cache = nil
   end

   def descriptors
      descriptors = []

      if @log_file
      end

      descriptors
   end

   def open( filename, options={} )
      opts = {
         cache_filename: nil,
         buffer_size_kb: 10 * 1024
      }.merge( options )

      if opts[:cache_filename]
         @descriptor_cache = MessageDescriptorCache.new( opts[:cache_filename] )
      end

      if File.exist? filename

         @file_size = File.size?(filename)
         @log_file = File.open( filename, 'r' )

         if @descriptor_cache.exist?
            @message_descriptors = @descriptor_cache.read_descriptors
         else
            @message_descriptors = LogFile::read_descriptors( @log_file, @descriptor_cache )
         end

         @buffers.set_file( @log_file, load_buffers: true )

      else
         raise FileNotFoundError.new
      end

   end

   def each_message( options, &block )
      opts ={
         message_filter: ['FMT']
      }.merge(options || {})


      raise BlockRequiredError.new unless block_given?

      if @log_file

         loop do
            message = LogFile::read_message( @buffers, @message_descriptors )
            break if message.nil?

            # Added message to the set of latest messages.
            @latest_messages[ message.descriptor.type ] = message

            if opts[:message_filter].include?( message.descriptor.name ) == false
               yield message, @latest_messages
            end
         end

      end

   end

   def rewind
      if @log_file

         @log_file.rewind
         @buffers.load_buffers

      end
   end

   def seek( offset )
   end

end
