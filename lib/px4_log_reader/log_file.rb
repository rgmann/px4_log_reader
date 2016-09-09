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

	module LogFile

		HEADER_MARKER = [0xA3,0x95]
		HEADER_LENGTH = 3
		FORMAT_DESCRIPTOR_TABLE = { FORMAT_MESSAGE.type => FORMAT_MESSAGE }.freeze

		def self.read_descriptors( buffered_io, descriptor_cache=nil )

			message_descriptors = {}

			while ( message_descriptor = read_descriptor( buffered_io ) ) do
				if !message_descriptors.keys.include? message_descriptor.type
					message_descriptors[ message_descriptor.type ] = message_descriptor
				end
			end

			# If a cache filename was supplied, dump the descriptors to the cache
			if descriptor_cache
				descriptor_cache.write_descriptors( message_descriptors )
			end

			return message_descriptors
		end

		def self.read_descriptor( buffered_io, skip_corrupt=true )

			message_descriptor = nil

			begin

				descriptor_message = read_message( buffered_io, FORMAT_DESCRIPTOR_TABLE )

				if descriptor_message

					message_descriptor = Px4LogReader::MessageDescriptor.new
					message_descriptor.from_message( descriptor_message )

				end

			rescue Px4LogReader::InvalidDescriptorError => error

				if skip_corrupt
					retry
				else
					raise error
				end

			rescue StandardError => e
				puts "#{e.class}: #{e.message}"
				puts e.backtrace.join("\n")
			end

			return message_descriptor
		end

		def self.read_message( buffered_io, message_descriptors )

			message = nil
			while message.nil? do
				message_type = read_message_header( buffered_io )

				if message_type

					message_descriptor = message_descriptors[ message_type ]

					if message_descriptor
						message_data = buffered_io.read( message_descriptor.length - HEADER_LENGTH )
						message = message_descriptor.unpack_message( message_data )
					end

				elsif message_type.nil?
					break
				end
			end

			return message
		end

		def self.read_message_header( buffered_io )
			message_type = nil

			begin

				data = buffered_io.read(2)

				if data && data.length == 2

					while !data.empty? && message_type.nil? do

						if ( byte = buffered_io.read(1) )
							data << byte
						end

						if data.unpack('CCC')[0,2] == HEADER_MARKER
							message_type = data.unpack('CCC').last & 0xFF
						else
							data = data[1..-1]
						end

					end
				end

			rescue EOFError => error
				# Nothing to do.
			rescue StandardError => error
				puts error.message
				puts error.backtrace.join("\n")
			end

			return message_type
		end


		def self.write_message( io, message )
			io.write HEADER_MARKER.pack('CC')
			io.write [ message.descriptor.type ].pack('C')
			io.write message.pack
		end

	end

end