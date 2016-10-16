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
		HEADER_LENGTH = HEADER_MARKER.length + 1
		FORMAT_DESCRIPTOR_TABLE = { FORMAT_MESSAGE.type => FORMAT_MESSAGE }.freeze

		@@debug = false

		def self.enable_debug( enable )
			@@debug = enable
		end

		def self.read_descriptors( file, descriptor_cache=nil, &block )

			message_descriptors = {}

			loop do

				message_descriptor, file_offset = read_descriptor( file )

				if message_descriptor
					if !message_descriptors.keys.include? message_descriptor.type
						message_descriptors[ message_descriptor.type ] = message_descriptor
						yield message_descriptor if block_given?
					end
				else
					break
				end

			end

			# If a cache filename was supplied, dump the descriptors to the cache
			if descriptor_cache
				descriptor_cache.write_descriptors( message_descriptors )
			end

			return message_descriptors
		end

		def self.read_descriptor( file, skip_corrupt=true, &block )

			message_descriptor = nil
			offset             = nil

			begin

				descriptor_message, offset = read_message( file, FORMAT_DESCRIPTOR_TABLE, true, &block )

				if descriptor_message
					message_descriptor = Px4LogReader::MessageDescriptor.new
					message_descriptor.from_message( descriptor_message )
				end

			rescue Px4LogReader::InvalidDescriptorError => error

				puts "#{error.class}: #{error.message}"
				puts error.backtrace.join("\n")

				if skip_corrupt
					retry
				else
					raise error
				end

			rescue StandardError => error
				puts "#{error.class}: #{error.message}"
				puts error.backtrace.join("\n")
			end

			return message_descriptor, offset
		end

		def self.read_message( file, message_descriptors, stop_on_no_match = false, &block )

			message = nil
			offset  = nil
			eof     = false

			while message.nil? && !eof do
				message_type, offset = read_message_header( file )
				eof                  = message_type.nil?

				if message_type

					message_descriptor = message_descriptors[ message_type ]

					yield offset if block_given?

					if message_descriptor

						message_data = file.read( message_descriptor.length - HEADER_LENGTH )
						print_data( message_data ) if @@debug
						message = message_descriptor.unpack_message( message_data )

					elsif stop_on_no_match

						# Seek back to the beginning of the header for the non-
						# matching message.
						file.seek( -1 * HEADER_LENGTH, IO::SEEK_CUR )
						break

					end
				end
			end

			return message, offset
		end

		#
		# Read the next message header from the input stream. Returns the 
		# message type and current file offset. If no header is found, the
		# returned message type is nil and the offset is the end of the file.
		#
		def self.read_message_header( file )
			message_type = nil
			offset       = nil
			drop_count 	 = 0

			begin

				data   = file.read_nonblock( HEADER_MARKER.length )
				offset = file.pos

				if data && ( data.length == HEADER_MARKER.length )

					while !data.empty? && message_type.nil? do

						if ( byte = file.read_nonblock( 1 ) )
							data << byte
						end
						offset = file.pos

						if data.length >= ( HEADER_MARKER.length + 1 )

							unpacked_data = data.unpack('C*')
							
							if unpacked_data[ 0, HEADER_MARKER.length ] == HEADER_MARKER
								message_type = unpacked_data.last & 0xFF
							else
								data = data[1..-1]
								drop_count += 1
							end
						else
							data = []
						end

					end
				end

			rescue EOFError => error
				# Nothing to do.
			rescue StandardError => error
				puts error.message
				puts error.backtrace.join("\n")
			end

			return message_type, offset
		end


		def self.write_message( io, message )
			io.write( HEADER_MARKER.pack('CC') )
			io.write( [ message.descriptor.type ].pack('C') )
			io.write( message.pack )
		end


		def self.print_data( buffer )
			text = ''
			buffer.unpack( 'C*' ).each_with_index do |byte,count|
				if (count % 16) == 0
					text << "#{count/16}: "
				end
				text << ('%02X'%byte) << ' '
				if (((count+1) % 16) == 0)
					text << "\n"
				end
			end
			puts text
		end

	end

end