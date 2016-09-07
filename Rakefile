require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test

def read_default_log_filename
	log_filename = ''
	File.open( 'default_log_path.txt', 'r' ) do |input|
		log_filename = input.readline
	end

	unless File.exist? log_filename
		raise "Failed to find '#{log_filename}'"
	end

	return log_filename
end

task :gen_desc_cache do
	require 'px4_log_reader'

	log_filename = read_default_log_filename

	log_file = File.open( log_filename, 'r' )
	descriptors = Px4LogReaderIncludes::LogFile.read_descriptors( log_file )

	cache_filename = File.join( 'test', 'test_files', 'pixhawk_descriptor_cache.px4mc' )
	cache = Px4LogReaderIncludes::MessageDescriptorCache.new( cache_filename )
	cache.write_descriptors( descriptors )

end

task :cut_log, :count, :skip, :filename do |t,args|
	args.with_defaults(:count => 20, :skip => 0, :filename => File.join('test','test_files','test_log.px4log'))

	require 'px4_log_reader'

	input_filename = read_default_log_filename

	cache_filename = File.join( 'test', 'test_files', 'pixhawk_descriptor_cache.px4mc' )
	cache = Px4LogReaderIncludes::MessageDescriptorCache.new( cache_filename )
	message_descriptors = cache.read_descriptors


	File.open( input_filename, 'r' ) do |input|
		File.open( args[:filename], 'wb+' ) do |output|

			# Write the descriptors
			message_descriptors.each do |type,descriptor|
				Px4LogReaderIncludes::LogFile.write_message( output, descriptor.to_message )
			end

			skip_count = args[:skip].to_i
			skip_count.times do
				Px4LogReaderIncludes::LogFile.read_message( input, message_descriptors )
			end

			read_count = args[:count].to_i
			read_count.times do
				message = Px4LogReaderIncludes::LogFile.read_message( input, message_descriptors )
				Px4LogReaderIncludes::LogFile.write_message( output, message )
			end
		end
	end

end

task :dump, :filename do |t,args|
	require 'px4_log_reader'

	cache_filename = File.join( 'test', 'test_files', 'pixhawk_descriptor_cache.px4mc' )
	cache = Px4LogReaderIncludes::MessageDescriptorCache.new( cache_filename )
	message_descriptors = cache.read_descriptors

	File.open( args[:filename], 'r' ) do |input|
		count = 1
		while ( message = Px4LogReaderIncludes::LogFile.read_message( input, message_descriptors ) ) do
			puts "#{count}) #{message.descriptor.name}, #{'%02X'%message.descriptor.type}"
			count += 1
		end
	end
end
