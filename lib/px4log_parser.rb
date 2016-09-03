



# class Px4LogReader

#    include PX4

#    HEADER_MARKER = [0xA3,0x95]#.pack('CC').freeze
#    HEADER_LENGTH = 3

#    FORMAT_MESSAGE = Px4LogMessageDescription.new({
#       name: 'FMT',
#       type: 0x80,
#       length: 89,
#       format: 'BBnZ',
#       fields: ["Type", "Length", "Name", "Format", "Labels"] }).freeze

#    attr_reader :message_descriptions
#    attr_reader :messages
#    attr_reader :px4_log_format

#    def initialize
#       @message_descriptions = {}
#       @messages = []
#       @px4_log_format = false
#    end

#    def parse_log( filename, cache_filename=nil )
#       @message_descriptions = {}
#       @messages = []

#       @file_size = File.size?(filename)

#       if cache_filename && File.exist?( cache_filename )
#          if File.exist?( cache_filename )
#             File.open( cache_filename, 'r' ) do |io|
#                begin
#                   loop do
#                      description_size = io.read_nonblock(4).unpack('L').first
#                      description = Marshal.load( io.read(description_size) )

#                      @message_descriptions[ description.type ] = description
#                   end
#                rescue EOFError => error
#                   puts "Parsed #{@message_descriptions.size} cached message descriptions"
#                   # @message_descriptions.each do |message_type,description|
#                   #    puts description
#                   # end
#                rescue StandardError => error
#                   puts "#{error.class}: #{error.message}"
#                   puts error.backtrace.join("\n")
#                end
#             end
#          else
#             puts "Cache file '#{cache_filename}' not found"
#          end
#       else
#          File.open( filename, 'r' ) do |io|
#             read_formats( io, cache_filename )
#          end
#       end

#       if @message_descriptions.size > 0
#          File.open( filename, 'r' ) do |io|
#             begin
#                loop do
#                   message = read_message( io )

#                   if message.nil?
#                      puts "Failed to read message"
#                      break
#                   elsif message.description.name != "FMT"
#                      @messages << message
#                   end

#                   $stdout.printf "\rReading messages %d/%d", io.pos, @file_size
#                end
#             rescue StandardError => error
#                puts "#{error.class}: #{error.message}"
#                puts error.backtrace.join("\n")
#             end
#          end
#       else
#          raise "No message descriptions found"
#       end
#       puts
#    end

#    def read_message_header( io )
#       byte = nil

#       begin

#          data = io.read(2)

#          if data && data.length == 2
#             loop do

#                data << io.read_nonblock(1)

#                # puts "#{data.unpack('CCC')[0,2]} == #{HEADER_MARKER}"
#                if data.unpack('CCC')[0,2] == HEADER_MARKER
#                   byte = data.unpack('CCC').last & 0xFF
#                   # puts "Found message header #{data.unpack('CCC')}"
#                   # puts "message_type = #{'%02X'%byte}"
#                   break
#                else
#                   data = data[1..-1]
#                end

#             end
#          end

#       rescue EOFError => error
#          # Nothing to do.
#       rescue StandardError => error
#          puts error.message
#          puts error.backtrace.join("\n")
#       end

#       return byte
#    end

#    def read_message( io )

#       message = nil
#       while message.nil? do
#          message_type = read_message_header( io )

#          if message_type && (message_type != FORMAT_MESSAGE.type)
#             message_description = @message_descriptions[ message_type ]

#             if message_description
#                message_data = io.read( message_description.length - HEADER_LENGTH )
#                message = message_description.parse_message( message_data )
#             else
#                puts "ERROR: Failed to get description for message of type '#{'0x%02X' % message_type}'"
#             end
#          elsif message_type.nil?
#             break
#          end

#          # $stdout.printf "\rReading formats %d/%d", io.pos, @file_size
#       end

#       return message
#    end

#    def read_formats( io, cache_filename )
#       loop do
#          begin
#             message_type = read_message_header( io )

#             if message_type.nil?
#                break
#             elsif message_type == FORMAT_MESSAGE.type
#                # puts "Found format message"
#                message_description = Px4LogMessageDescription.new
#                message_description.parse_from_io( io )

#                unless @message_descriptions.keys.include? message_description.type
#                   @message_descriptions[message_description.type] = message_description
#                end

#                if message_description.name == "TIME"
#                   @px4_log_format = true
#                end
#             end

#             $stdout.printf "\rReading formats %d/%d", io.pos, @file_size

#          rescue StandardError => e
#             puts "#{e.class}: #{e.message}"
#             puts e.backtrace.join("\n")
#             break
#          end
#       end
#       $stdout.puts

#       if cache_filename
#          File.open( cache_filename, 'w+' ) do |io|
#             @message_descriptions.each do |message_type,description|
#                description_data = Marshal.dump( description )
#                io.write( [ description_data.size ].pack('L') )
#                io.write( description_data )
#             end
#          end
#       end
#    end

# end


# if ARGV.size == 2
#    filename = ARGV[0]
#    output_dir = ARGV[1]
#    puts "Attempting to parse #{filename}"

#    cache_filename = File.join( 'px4_csvs', "#{File.basename( filename, '.px4log' )}.px4log_description_cache" )

#    log = Px4LogReader.new
#    log.parse_log( filename, cache_filename )

#    log.message_descriptions.each do |type,description|
#       # puts description
#       File.open(File.join(output_dir,"#{description.name.downcase}_log.csv"),"w+") do |io|
#          io.puts description.to_csv_line
#       end
#    end

#    last_timestamp = 0
#    log.messages.each do |message|
#       if message.description.name == "TIME"
#          last_timestamp = message.get(0)
#       end

#       File.open(File.join(output_dir,"#{message.description.name.downcase}_log.csv"),"a+") do |io|
#          io.puts message.to_csv_line(last_timestamp)
#       end
#    end

# else

#    puts "Specify source and destination"

# end

