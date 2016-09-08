require 'minitest/autorun'
require 'px4_log_reader'

class TestLogFile < MiniTest::Test

	def setup
	end

	def teardown
	end

	def test_read_descriptors

		# log_file = open_log_file
		# descriptors = Px4LogReader::LogFile.read_descriptors( log_file )

		# puts "Found #{descriptors.count} descriptors"
		# descriptors.each do |type,descriptor|
		# 	puts "  #{descriptor.name}"
		# end

		# log_file.close

	end

	def test_read_message

		# log_file = open_log_file
		# descriptors = Px4LogReader::LogFile.read_descriptors( log_file )

		# log_file.rewind
		# message = Px4LogReader::LogFile.read_message( log_file, descriptors )
		
		# puts message.descriptor

	end


	def open_log_file
		log_file = File.open( File.join( '/Volumes/rvaughan_share/Development/px4_log_reader_test_data', '2016-07-24', '17_18_36.px4log' ), 'r' )
		log_file
	end

end