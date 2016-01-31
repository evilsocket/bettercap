# encoding: UTF-8
=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Proxy
# HTTP response parser.
class Response
  # Response content type.
  attr_reader :content_type
  # Response charset, default to UTF-8.
  attr_reader :charset
  # Response content length.
  attr_reader :content_length
  # True if this is a chunked encoded response, otherwise false.
  attr_reader :chunked
  # A list of response headers.
  attr_reader :headers
  # Response status code.
  attr_accessor :code
  # True if the parser finished to parse the headers, otherwise false.
  attr_reader :headers_done
  # Response body.
  attr_accessor :body

  # Return a 200 response object reading the file +filename+ with the specified
  # +content_type+.
  def self.from_file( filename, content_type )
    r = Response.new
    data = File.read(filename)

    r << "HTTP/1.1 200 OK"
    r << "Connection: close"
    r << "Content-Length: #{data.bytesize}"
    r << "Content-Type: #{content_type}"
    r << "\n"
    r << data

    r
  end

  # Initialize this response object state.
  def initialize
    @content_type = nil
    @charset = 'UTF-8'
    @content_length = nil
    @body = ''
    @code = nil
    @headers = []
    @headers_done = false
    @chunked = false
  end

  # Convert a webrick response to this class.
  def convert_webrick_response!(response)
    self << "HTTP/#{response.http_version} #{response.code} #{response.msg}"
    response.each do |key,value|
      self << "#{key.gsub(/\bwww|^te$|\b\w/){ $&.upcase }}: #{value}"
    end
    self << "\n"
    @code = response.code
    @body = response.body || ''
  end

  # Parse a single response +line+.
  def <<(line)
    # we already parsed the heders, collect response body
    if @headers_done
      @body << line.force_encoding( @charset )
    else
      Logger.debug "  RESPONSE LINE: '#{line.chomp}'"

      # parse the response status
      if @code.nil? and line =~ /^HTTP\/[\d\.]+\s+(.+)/
        @code = $1.chomp

      # parse the content type
      elsif line =~ /^Content-Type:\s*([^;]+).*/i
        @content_type = $1.chomp
        if line =~ /^.+;\s*charset=(.+)/i
          @charset = $1.chomp
        end

      # parse content length
      elsif line =~ /^Content-Length:\s+(\d+)\s*$/i
        @content_length = $1.to_i

      # check if we have a chunked encoding
      elsif line =~ /^Transfer-Encoding:\s*chunked.*$/i
        @chunked = true
        line = nil

      # last line, we're done with the headers
      elsif line.chomp.empty?
        @headers_done = true

      end

      @headers << line.chomp unless line.nil?
    end
  end

  # Return true if the response content type is textual, otherwise false.
  def textual?
    @content_type and ( @content_type =~ /^text\/.+/ or @content_type =~ /^application\/.+/ )
  end

  # Return the value of header with +name+ or an empty string.
  def [](name)
    @headers.each do |header|
      if header =~ /^#{name}:\s*(.+)$/i
        return $1
      end
    end
    ""
  end

  # If the header with +name+ is found, then a +value+ is assigned to it,
  # otherwise it's created.
  def []=(name, value)
    found = false
    @headers.each_with_index do |header,i|
      if header =~ /^#{name}:\s*.+$/i
        @headers[i] = "#{name}: #{value}"
        found = true
        break
      end
    end

    unless found
      @headers << "#{name}: #{value}"
    end
  end

  # Return a string representation of this response object, patching the
  # Content-Length header if the #body was modified.
  def to_s
    if textual?
      @headers.map! do |header|
        # update content length in case the body was
        # modified
        if header =~ /Content-Length:\s*(\d+)/i
          Logger.debug "Updating response content length from #{$1} to #{@body.bytesize}"

          "Content-Length: #{@body.bytesize}"
        else
          header
        end
      end
    end

    @headers.join("\n") + "\n" + @body
  end
end

end
end
