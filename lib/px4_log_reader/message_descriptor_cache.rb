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

	class MessageDescriptorCache

		attr_reader :cache_filename

		def initialize( filename )
			@cache_filename = filename
		end

		def exist?
			return File.exist?( @cache_filename )
		end

		def read_descriptors

			message_descriptors = {}

			if File.exist?( cache_filename )
				File.open( cache_filename, 'r' ) do |input|
					begin
						while ( ( data = input.read(4) ) && ( data.length == 4 ) ) do
							descriptor_size = data.unpack('L').first
							descriptor = Marshal.load( input.read( descriptor_size ) )

							message_descriptors[ descriptor.type ] = descriptor
							end
					rescue EOFError => error
						puts "Parsed #{@message_descriptions.size} cached message descriptions"
					rescue StandardError => error
						puts "#{error.class}: #{error.message}"
						puts error.backtrace.join("\n")
					end
				end
			else
				puts "Cache file '#{cache_filename}' not found"
			end

			return message_descriptors
		end

		def write_descriptors( message_descriptors )
			if !@cache_filename.empty? && File.exist?( File.dirname( @cache_filename ) )
				File.open( @cache_filename, 'w+' ) do |output|
					message_descriptors.each do |message_type,descriptor|
						descriptor_data = Marshal.dump( descriptor )
						output.write( [ descriptor_data.size ].pack('L') )
						output.write( descriptor_data )
					end
				end
			end
		end

	end

end