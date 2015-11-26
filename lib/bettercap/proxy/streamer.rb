=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end
require 'bettercap/logger'

module Proxy
class Streamer
  def initialize( processor )
    @processor = processor 
  end

  def rickroll( client )
    client.write "HTTP/1.1 302 Found\n"
    client.write "Location: https://www.youtube.com/watch?v=dQw4w9WgXcQ\n\n"
  end

  def html( request, response, from, to )
    buff = ''

    if response.content_length.nil?
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


  def binary( from, to, opts = {} )
    total_size = 0

    # if response|request object is available and a content length as well
    # use it to speed up data streaming with precise data size
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

  def read( sd, size )
    buffer = ''

    while size > 0
      tmp = sd.read(size)
      unless tmp.nil?
        buffer << tmp
        size -= tmp.bytesize
      end
    end

    buffer
  end

end
end


