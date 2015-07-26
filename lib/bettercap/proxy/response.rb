=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module Proxy

class Response
  attr_reader :content_type, :content_length, :headers, :code, :headers_done
  attr_accessor :body

  def initialize
    @content_type = nil
    @content_length = nil
    @body = ''
    @code = nil
    @headers = []
    @headers_done = false
  end

  def <<(line)
    # we already parsed the heders, collect response body
    if @headers_done
      @body += line
    else
      # parse the response status
      if @code.nil? and line =~ /^HTTP\/[\d\.]+\s+(.+)/
        @code = $1.chomp

        # parse the content type
      elsif line =~ /^Content-Type: ([^;]+).*/i
        @content_type = $1.chomp

        # parse content length
      elsif line =~ /^Content-Length:\s+(\d+)\s*$/i
        @content_length = $1.to_i

        # last line, we're done with the headers
      elsif line.chomp == ""
        @headers_done = true

      end

      @headers << line.chomp
    end
  end

  def textual? # textual?
    @content_type and ( @content_type =~ /^text\/.+/ or @content_type =~ /^application\/.+/ )
  end

  def to_s
    if textual?
      @headers.map! do |header|
        # update content length in case the body was
        # modified
        if header =~ /Content-Length:\s*(\d+)/i
          "Content-Length: #{@body.size}"
        else
          header
        end
      end
    end

    @headers.join("\n") + "\n" + @body
  end
end

end
