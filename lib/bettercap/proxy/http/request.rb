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

# HTTP request parser.
class Request
  # HTTP method.
  attr_reader :method
  # HTTP version.
  attr_reader :version
  # Request path + query.
  attr_reader :path
  # Hostname.
  attr_reader :host
  # Request port.
  attr_accessor :port
  # Request headers hash.
  attr_reader :headers
  # Content length.
  attr_reader :content_length
  # Request body.
  attr_accessor :body
  # Client address.
  attr_accessor :client

  # Initialize this object setting #port to +default_port+.
  def initialize( default_port = 80 )
    @lines          = []
    @method         = nil
    @version        = '1.1'
    @path           = nil
    @host           = nil
    @port           = default_port
    @headers        = {}
    @content_length = 0
    @body           = nil
    @client         = ""
  end

  # Read lines from the +sock+ socket and parse them.
  # Will raise an exception if the #hostname can not be parsed.
  def read(sock)
    # read the first line
    self << sock.readline

    loop do
      line = sock.readline
      self << line

      if line.chomp == ''
        break
      end
    end

    raise "Couldn't extract host from the request." unless @host

    # keep reading the request body if needed
    if @content_length > 0
      @body = sock.read(@content_length)
    end
  end

  # Return a Request object from a +raw+ string.
  def self.parse(raw)
    req = Request.new
    lines = raw.split("\n")
    lines.each_with_index do |line,i|
      req << line
      if line.chomp == ''
        req.body = lines[i + 1..lines.size].join("\n")
        break
      end
    end
    req
  end

  # Parse a single request line, patch it if needed and append it to #lines.
  def <<(line)
    line = line.chomp

    Logger.debug "  REQUEST LINE: '#{line}'"

    # is this the first line '<VERB> <URI> HTTP/<VERSION>' ?
    if line =~ /^(\w+)\s+(\S+)\s+HTTP\/([\d\.]+)\s*$/
      @method  = $1
      @path    = $2
      @version = $3

      # fix url
      if @path.include? '://'
        uri = URI::parse @path
        @path = "#{uri.path}" + ( uri.query ? "?#{uri.query}" : '' )
      end

    # collect and fix headers
    elsif line =~ /^([^:\s]+)\s*:\s*(.+)$/i
      name = $1
      value = $2

      case name
      when 'Host'
        @host = value
        if @host =~ /([^:]*):([0-9]*)$/
          @host = $1
          @port = $2.to_i
        end
      when 'Content-Length'
        @content_length = value.to_i
      # we don't want to have hundreds of threads running
      when 'Connection'
        value = 'close'
      when 'Proxy-Connection'
        name = 'Connection'
      # disable gzip, chunked, etc encodings
      when 'Accept-Encoding'
        value = 'identity'
      end

      @headers[name] = value
    end
  end

  # Return true if this is a POST request, otherwise false.
  def post?
    @method == 'POST'
  end

  # Return a string representation of the HTTP request.
  def to_s
    raw = "#{@method} #{@path} HTTP/#{@version}\n"

    @headers.each do |name,value|
      raw << "#{name}: #{value}\n"
    end

    raw << "\n"
    raw << ( @body || '' )
    raw
  end

  # Return SCHEMA://HOST
  def base_url
    "#{port == 443 ? 'https' : 'http'}://#{@host}"
  end

  # Return the full request URL trimming it at +max_length+ characters.
  def to_url(max_length = 50)
    url = "#{base_url}#{@path}"
    unless max_length.nil?
      url = url.slice(0..max_length) + '...' unless url.length <= max_length
    end
    url
  end

  # Return the value of header with +name+ or an empty string.
  def [](name)
    ( @headers.has_key?(name) ? @headers[name] : "" )
  end

  # If the header with +name+ is found, then a +value+ is assigned to it.
  # If +value+ is null and the header is found, it will be removed.
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

    @host = value if name == 'Host'
  end
end

end
end
end
