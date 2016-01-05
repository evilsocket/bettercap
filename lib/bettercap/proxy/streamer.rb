=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'

module BetterCap
module Proxy
# Handle data streaming between clients and servers for the BetterCap::Proxy::Proxy.
class Streamer
  # Default buffer size for data streaming.
  BUFSIZE = 1024 * 16

  # Initialize the class with the given +processor+ routine.
  def initialize( processor )
    @processor = processor
  end

  # Redirect the +client+ to a funny video.
  def rickroll( client )
    client.write "HTTP/1.1 302 Found\n"
    client.write "Location: https://www.youtube.com/watch?v=dQw4w9WgXcQ\n\n"
  end

  # Perform HTML streaming for the given +request+, applying the #processor
  # to the +response+.
  # +from+ and +to+ are the two TCP endpoints.
  def html( request, response, from, to )
    buff = ''

    if response.chunked
      Logger.debug "Reading response body using chunked encoding ..."

      begin
        len = nil
        total = 0

        while true
          line = from.readline
          hexlen = line.slice(/[0-9a-fA-F]+/) or raise "Wrong chunk size line: #{line}"
          len = hexlen.hex
          break if len == 0
          begin
            Logger.debug "Reading chunk of size #{len} ..."
            tmp = read( from, len )
            Logger.debug "Read #{tmp.bytesize}/#{len} chunk."
            response << tmp
          ensure
            total += len
            from.read 2
          end
        end

      rescue Exception => e
        Logger.debug e
      end

    elsif response.content_length.nil?
      Logger.debug "Reading response body using 1024 bytes chunks ..."

      loop do
        buff = read( from, 1024 )

        break unless buff.size > 0

        response << buff
      end
    else
      Logger.debug "Reading response body using #{response.content_length} bytes buffer ..."

      buff = read( from, response.content_length )

      Logger.debug "Read #{buff.size} / #{response.content_length} bytes."

      response << buff
    end

    @processor.call( request, response )

    # Response::to_s will patch the headers if needed
    to.write response.to_s
  end

  # Perform binary streaming using the +opts+ dictionary.
  # If response|request object is available inside +opts+ and a content length
  # as well use it to speed up data streaming with precise data size
  # +from+ and +to+ are the two TCP endpoints.
  def binary( from, to, opts = {} )
    total_size = 0

    if not opts[:response].nil?
      to.write opts[:response].to_s

      total_size = opts[:response].content_length unless opts[:response].content_length.nil?
    elsif not opts[:request].nil?

      total_size = opts[:request].content_length unless opts[:request].content_length.nil?
    end

    buff = ''
    read = 0

    if total_size
      chunk_size = [ 1024, total_size ].min
    else
      chunk_size = 1024
    end

    if chunk_size > 0
      loop do
        buff = read( from, chunk_size )

        # nothing more to read?
        break unless buff.size > 0

        to.write buff

        read += buff.size

        # collect into the proper object
        if not opts[:request].nil? and opts[:request].post?
          opts[:request] << buff
        end

        # we've done reading?
        break unless read != total_size
      end
    end
  end

  private

  def consume_stream io, size
    read_timeout = 60.0
    dest = ''
    begin
      dest << io.read_nonblock(size)
    rescue IO::WaitReadable
      if IO.select([io], nil, nil, read_timeout)
        retry
      else
        raise Net::ReadTimeout
      end
    rescue IO::WaitWritable
      # OpenSSL::Buffering#read_nonblock may fail with IO::WaitWritable.
      # http://www.openssl.org/support/faq.html#PROG10
      if IO.select(nil, [io], nil, read_timeout)
        retry
      else
        raise Net::ReadTimeout
      end
    end
    dest
  end

  def read( sd, size )
    buffer = ''
    begin
      while size > 0
        tmp = consume_stream sd, [ BUFSIZE, size ].min
        unless tmp.nil? or tmp.bytesize == 0
          buffer << tmp
          size -= tmp.bytesize
        end
      end
    rescue EOFError
      ;
    end
    buffer
  end

end
end
end
