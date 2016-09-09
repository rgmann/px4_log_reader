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

	def self.open_common( file, options, &block )

		reader = Reader.new( file, options )

		yield reader if block_given?

		return reader
	end

	def self.open( filename, options = {}, &block  )

		reader = nil

		if File.exist?( filename )
			reader = self.open_common( File.open( filename, 'r' ), options, &block )
		end	

		return reader

	end

	def self.open!( filename, options = {}, &block )
		reader = nil

		if File.exist?( filename )
			reader = self.open_common( File.open( filename, 'r' ), options, &block )
		else
			raise FileNotFoundError.new( filename )
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
				cache_filename: '',
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

				@message_descriptors[ FORMAT_MESSAGE.type ] = FORMAT_MESSAGE
			end

			return @message_descriptors
		end

		def each_message( options = {}, &block )

			opts ={
				with: [],        # white list - empty means all minus those in without list
				without: ['FMT'] # black list - includes types or names
			}.merge( options || {} )

			opts[:with].map! do |val|
				if val.class == String
					descriptor = descriptors.values.find { |desc| desc.name == val }
					val = descriptor.type
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

					message = LogFile::read_message( @log_file, @message_descriptors )
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
