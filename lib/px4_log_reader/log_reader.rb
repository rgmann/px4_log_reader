class Px4LogReader

   include Px4LogReaderIncludes

   

   attr_reader :message_descriptions
   attr_reader :messages
   attr_reader :px4_log_format

   def initialize
      @message_descriptors = {}
      @latest_messages = {}
      @log_buffer_array = LogBufferArray.new
   end

   def get_packet_descriptors( filename, cache_filename = nil )

      message_descriptors = {}

      if cache_filename && File.exist?( cache_filename )
         if File.exist?( cache_filename )
            File.open( cache_filename, 'r' ) do |io|
               begin
                  loop do
                     descriptor_size = io.read_nonblock(4).unpack('L').first
                     descriptor = Marshal.load( io.read(descriptor_size) )

                     message_descriptors[ description.type ] = description
                  end
               rescue EOFError => error
                  puts "Parsed #{@message_descriptions.size} cached message descriptions"
                  # @message_descriptions.each do |message_type,description|
                  #    puts description
                  # end
               rescue StandardError => error
                  puts "#{error.class}: #{error.message}"
                  puts error.backtrace.join("\n")
               end
            end
         else
            puts "Cache file '#{cache_filename}' not found"
         end
      else
         File.open( filename, 'r' ) do |io|
            message_descriptors = read_descriptors( io, cache_filename )
         end
      end

      return message_descriptors
   end

   def open( filename, options={} )
      opts = {
         cache_filename: nil,
         buffer_size_kb: 10 * 1024
      }.merge( options )

      if File.exist? filename

         @file_size = File.size?(filename)
         @message_descriptor = get_packet_descriptors( filename, cache_filename )

         @log_file = File.open( filename, 'r' )

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
