require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test

def read_default_log_filename
	log_filename = ''
	File.open( 'default_log_path.txt', 'r' ) do |input|
		log_filename = input.readline.strip
	end

	unless File.exist?( log_filename )
		raise "Failed to find '#{log_filename}'"
	end

	return log_filename
end

task :build_minor, :version do |t,args|

	Dir.glob('px4_log_reader-*.gem') do |gem_file|
		puts "Deleting '#{gem_file}'"
		FileUtils.rm gem_file
	end

	version_file = File.join( 'lib', 'px4_log_reader', 'version.rb' )
	current_version = '0.0.1'

	if File.exist?( File.expand_path( version_file ) )
		require_relative version_file
		current_version = Px4LogReader::VERSION
	end

	args.with_defaults( :version => current_version.next )
	next_version = args[:version]

	File.open( version_file, 'w+' ) do |output|
		puts "Generation '#{version_file}' for version '#{next_version}'"
		output.write "module Px4LogReader\n\tVERSION = '#{next_version}'\nend"
	end

	`gem uninstall px4_log_reader && gem build px4_log_reader.gemspec && gem install ./px4_log_reader-#{next_version}.gem`
end

task :gen_desc_cache do
	require 'px4_log_reader'

	log_filename = read_default_log_filename

	log_file = File.open( log_filename, 'r' )
	descriptors = Px4LogReader::LogFile.read_descriptors( log_file )

	cache_filename = File.join( 'test', 'test_files', 'pixhawk_descriptor_cache.px4mc' )
	cache = Px4LogReader::MessageDescriptorCache.new( cache_filename )
	cache.write_descriptors( descriptors )

end

task :dump_desc_cache do
	require 'px4_log_reader'

	cache_filename = File.join( 'test', 'test_files', 'pixhawk_descriptor_cache.px4mc' )
	cache = Px4LogReader::MessageDescriptorCache.new( cache_filename )
	descriptors = cache.read_descriptors

	descriptors.each do |type,descriptor|
		puts [descriptor.name,'%02X'%descriptor.type].concat(descriptor.field_list.keys).join(',')
	end
end

task :cut_log, :count, :skip, :filename do |t,args|
	args.with_defaults(:count => 20, :skip => 0, :filename => File.join('test','test_files','test_log.px4log'))

	require 'px4_log_reader'

	input_filename = read_default_log_filename

	cache_filename = File.join( 'test', 'test_files', 'pixhawk_descriptor_cache.px4mc' )
	cache = Px4LogReader::MessageDescriptorCache.new( cache_filename )
	message_descriptors = cache.read_descriptors


	File.open( input_filename, 'r' ) do |input|
		File.open( args[:filename], 'wb+' ) do |output|

			# Write the descriptors
			message_descriptors.each do |type,descriptor|
				Px4LogReader::LogFile.write_message( output, descriptor.to_message )
			end

			skip_count = args[:skip].to_i
			skip_count.times do
				Px4LogReader::LogFile.read_message( input, message_descriptors )
			end

			read_count = args[:count].to_i
			read_count.times do
				message = Px4LogReader::LogFile.read_message( input, message_descriptors )
				Px4LogReader::LogFile.write_message( output, message )
			end
		end
	end

end

task :dump, :filename do |t,args|
	require 'px4_log_reader'

	cache_filename = File.join( 'test', 'test_files', 'pixhawk_descriptor_cache.px4mc' )
	cache = Px4LogReader::MessageDescriptorCache.new( cache_filename )
	message_descriptors = cache.read_descriptors

	File.open( args[:filename], 'r' ) do |input|
		count = 1
		while ( message = Px4LogReader::LogFile.read_message( input, message_descriptors ) ) do
			puts "#{count}) #{message.descriptor.name}, #{'%02X'%message.descriptor.type}"
			count += 1
		end
	end
end
