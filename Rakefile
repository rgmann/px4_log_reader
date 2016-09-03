require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test

task :gen_desc_cache do
	require 'px4_log_reader'

	log_file = File.open( File.join( '/Volumes/rvaughan_share/Development/px4_log_reader_test_data', '2016-07-24', '17_18_36.px4log' ), 'r' )
	descriptors = Px4LogReaderIncludes::LogFile.read_descriptors( log_file )

	cache_filename = File.join( '..', 'test', 'test_files', 'pixhawk_descriptor_cache.px4mc' )
	cache = Px4LogReaderIncludes::MessageDescriptorCache.new( cache_filename )
	cache.write_descriptors( descriptors )
end