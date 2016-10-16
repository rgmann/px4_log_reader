#
# Copyright (c) 2016, Robert Glissmann
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# %% license-end-token %%
# 
# Author: Robert.Glissmann@gmail.com (Robert Glissmann)
# 
# 

module Px4LogReader	

	# Attach a reader to an existing input stream.
	#
	# @param input_stream [IO] Valid input stream
	# @param options [Hash] Reader options hash
	# @param block  Optional block
	#
	def self.attach( input_stream, options, &block )

		reader = Reader.new( input_stream, options )

		yield reader if block_given?

		return reader
		
	end

	def self.open( filename, options = {}, &block  )

		reader = nil

		if File.exist?( filename )
			reader = self.attach( File.open( filename, 'rb' ), options, &block )
		end	

		return reader

	end

	def self.open!( filename, options = {}, &block )
		reader = nil

		if File.exist?( filename )
			reader = self.attach( File.open( filename, 'rb' ), options, &block )
		else
			raise FileNotFoundError.new( filename )
		end	

		return reader
	end

	# Container to hold the most recent copy of each message type
	class Context

		attr_reader :messages

		def initialize
			@messages = {}
		end

		# Query the context for the most recent copy of a message by name
		#
		# @param name [String] Message name
		#
		def find_by_name( name )
			named_message = nil
			@messages.values.each do |message|
				if message.descriptor.name == name
					named_message = message
				end
			end
			return named_message
		end

		# Query the context for the most recent copy of a message by type
		#
		# @param type [Fixnum]  Message type
		#
		def find_by_type( type )
			return @messages[ type ]
		end

		# Set the most recent copy of a message by type. Any existing message
		# is overwritten.
		#
		# @param  message [LogMessage]  Message instance
		#
		def set( message )
			@messages[ message.descriptor.type ] = message.dup
		end

	end

	class Reader

		attr_reader :progress
		attr_reader :context

		def initialize( file, options )

			opts = {
				cache_filename: '',
			}.merge( options )

			@message_descriptors = {}
			@descriptor_cache = nil
			@context = Context.new

			@log_file = file
			@progress = Progress.new( @log_file )

			@descriptor_cache = MessageDescriptorCache.new( opts[:cache_filename] )
		end

		#
		# Get the list of descriptors associated with the open PX4 log file.
		# If a valid descriptor cache was specified at startup, the descriptors
		# are loaded from the cache. Otherwise, the descriptors are parsed from
		# the open log.
		#
		# @param  [block] optional block is passed each descriptor as it is read
		# @return descriptors [Array] Array of descriptors
		#
		def descriptors( &block )
			if @log_file && @message_descriptors.empty?
				if @descriptor_cache && @descriptor_cache.exist?
					@message_descriptors = @descriptor_cache.read_descriptors
				else
					@message_descriptors = LogFile::read_descriptors( @log_file, @descriptor_cache, &block )
				end

				@message_descriptors[ FORMAT_MESSAGE.type ] = FORMAT_MESSAGE
			end

			return @message_descriptors
		end

		#
		# Iterate over all log messages. Embedded message descriptors are skipped.
		# If a "with" list is supplied, only messages in the list are passed to 
		# the caller-supplied block. If a "without" list supplied, all messages
		# except those in the list are passed to the caller-supplied block. The
		# caller must supply a block.
		#
		# @param  options [Hash] options
		# @param  block   [Block] block takes message as argument
		#
		def each_message( options = {}, &block )

			opts ={
				with: [],        # white list - empty means all minus those in without list
				without: ['FMT'] # black list - includes types or names
			}.merge( options || {} )

			opts[:with].map! do |val|
				if val.class == String
					descriptor = descriptors.values.find { |desc| desc.name == val }
					if descriptor
						val = descriptor.type
					else
						puts "Failed to find descriptor with name '#{val}'"
					end
				end
			end

			opts[:without].map! do |val|
				if val.class == String
					descriptor = descriptors.values.find { |desc| desc.name == val }

					if descriptor
						val = descriptor.type
					else
						raise "Failed to find descriptor with name '#{val}'"
					end
				end
			end

			if block_given?

				loop do

					message, offset = LogFile::read_message( @log_file, @message_descriptors )
					break if message.nil?

					# Add message to the set of latest messages.
					@context.set( message )

					if opts[:with].empty?
						if !opts[:without].include?( message.descriptor.type )
							yield message
						end
					else
						if opts[:with].include?( message.descriptor.type )
							yield message
						end
					end

				end

			else
				raise BlockRequiredError.new
			end

		end

		#
		# Seek to the specified file offset. If the offset is greater than the
		# file size, seeks to the end of the file.
		#
		# @param  offset [Fixnum]  File offset in bytes
		#
		def seek( offset )
			if @log_file
				seek_offset = offset
				seek_offset = @progress.file_size if offset > @progress.file_size
				@log_file.seek( seek_offset, IO::SEEK_SET )
			end
		end

	end

end
