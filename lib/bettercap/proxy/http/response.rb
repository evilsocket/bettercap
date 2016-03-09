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
module HTTP

# HTTP response parser.
class Response
  # HTTP protocol version
  attr_accessor :version
  # Response status code.
  attr_accessor :code
  # Response status message
  attr_accessor :status
  # Response content type.
  attr_reader :content_type
  # Response charset, default to UTF-8.
  attr_reader :charset
  # Response content length.
  attr_reader :content_length
  # True if this is a chunked encoded response, otherwise false.
  attr_reader :chunked
  # A list of response headers.
  attr_accessor :headers
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

  # Return a 302 response object redirecting to +url+, setting optional +cookies+.
  def self.redirect( url, cookies = [] )
    r = Response.new

    r << "HTTP/1.1 302 Moved"
    r << "Location: #{url}"

    cookies.each do |cookie|
      r << "Set-Cookie: #{cookie}"
    end

    r << "Connection: close"
    r << "\n\n"

    r
  end

  # Initialize this response object state.
  def initialize
    @version = '1.1'
    @code = 200
    @status = 'OK'
    @content_type = nil
    @charset = 'UTF-8'
    @content_length = nil
    @body = nil
    @headers = {}
    @headers_done = false
    @chunked = false
  end

  # Convert a webrick response to this class.
  def convert_webrick_response!(response)
    self << "HTTP/#{response.http_version} #{response.code} #{response.msg}"
    response.each do |key,value|
      # sometimes webrick joins all 'set-cookie' headers
      # which might cause issues with HSTS bypass.
      if key == 'set-cookie'
        response.get_fields('set-cookie').each do |v|
          self << "Set-Cookie: #{v}"
        end
      else
        self << "#{key.gsub(/\bwww|^te$|\b\w/){ $&.upcase }}: #{value}"
      end
    end
    self << "\n"
    @code = response.code
    @body = response.body || ''
  end

  # Parse a single response +line+.
  def <<(line)
    # we already parsed the heders, collect response body
    if @headers_done
      @body = '' if @body.nil?
      @body << line.force_encoding( @charset )
    else
      chomped = line.chomp
      Logger.debug "  RESPONSE LINE: '#{chomped}'"

      # is this the first line 'HTTP/<VERSION> <CODE> <STATUS>' ?
      if chomped =~ /^HTTP\/([\d\.]+)\s+(\d+)\s+(.+)$/
        @version = $1
        @code    = $2.to_i
        @status  = $3

      # collect and fix headers
      elsif chomped =~ /^([^:\s]+)\s*:\s*(.+)$/i
        name = $1
        value = $2

        if name == 'Content-Type'
          @content_type = value
          if value =~ /^(.+);\s*charset=(.+)/i
            @content_type = $1
            @charset = $2.chomp
          end
        elsif name == 'Content-Length'
          @content_length = value.to_i
        # check if we have a chunked encoding
        elsif name == 'Transfer-Encoding' and value == 'chunked'
          @chunked = true
          name     = nil
          value    = nil
        end

        unless name.nil? or value.nil?
          if @headers.has_key?(name)
            if @headers[name].is_a?(Array)
              @headers[name] << value
            else
              @headers[name] = [ @headers[name], value ]
            end
          else
            @headers[name] = value
          end
        end
      # last line, we're done with the headers
      elsif chomped.empty?
        @headers_done = true
      end
    end
  end

  # Return true if the response content type is textual, otherwise false.
  def textual?
    @content_type and ( @content_type =~ /^text\/.+/ or @content_type =~ /^application\/.+/ )
  end

  # Return the value of header with +name+ or an empty string.
  def [](name)
    ( @headers.has_key?(name) ? @headers[name] : "" )
  end

  # If the header with +name+ is found, then a +value+ is assigned to it,
  # otherwise it's created.
  def []=(name, value)
    if @headers.has_key?(name)
      if value.nil?
        @headers.delete(name)
      else
        @headers[name] = value
      end
    elsif !value.nil?
      @headers[name] = value
    end
  end

  # Search for header +name+ and apply a gsub substitution:
  #   value.gsub( +search+, +replace+ )
  def patch_header!( name, search, replace )
    value = self[name]
    unless value.empty?
      patched = []
      if value.is_a?(Array)
        value.each do |v|
          patched << v.gsub( search, replace )
        end
      else
        patched << value.gsub( search, replace )
      end

      self[name] = patched
    end
  end

  # Return a string representation of this response object, patching the
  # Content-Length header if the #body was modified.
  def to_s
    # update content length in case the body was modified.
    if @headers.has_key?('Content-Length')
      @headers['Content-Length'] = @body.nil?? 0 : @body.bytesize
    end

    s = "HTTP/#{@version} #{@code} #{@status}\n"
    @headers.each do |name,value|
      if value.is_a?(Array)
        value.each do |v|
          s << "#{name}: #{v}\n"
        end
      else
        s << "#{name}: #{value}\n"
      end
    end
    s << "\n" + ( @body.nil?? "\n" : @body )
    s
  end
end

end
end
end
