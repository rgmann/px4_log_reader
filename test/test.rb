if ARGV.size == 2
   filename = ARGV[0]
   output_dir = ARGV[1]
   puts "Attempting to parse #{filename}"

   cache_filename = File.join( 'px4_csvs', "#{File.basename( filename, '.px4log' )}.px4log_description_cache" )

   log = Px4LogReader.new
   log.parse_log( filename, cache_filename )

   log.message_descriptions.each do |type,description|
      # puts description
      File.open(File.join(output_dir,"#{description.name.downcase}_log.csv"),"w+") do |io|
         io.puts description.to_csv_line
      end
   end

   last_timestamp = 0
   log.messages.each do |message|
      if message.description.name == "TIME"
         last_timestamp = message.get(0)
      end

      File.open(File.join(output_dir,"#{message.description.name.downcase}_log.csv"),"a+") do |io|
         io.puts message.to_csv_line(last_timestamp)
      end
   end

else

   puts "Specify source and destination"

end