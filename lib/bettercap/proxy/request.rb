=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Proxy
# HTTP request parser.
class Request
  # Patched request lines.
  attr_reader :lines
  # HTTP verb.
  attr_reader :verb
  # Request URL.
  attr_reader :url
  # Hostname.
  attr_reader :host
  # Request port.
  attr_reader :port
  # Request headers hash.
  attr_reader :headers
  # Content length.
  attr_reader :content_length
  # Request body.
  attr_reader :body

  # Initialize this object setting #port to +default_port+.
  def initialize( default_port = 80 )
    @lines  = []
    @verb   = nil
    @url    = nil
    @host   = nil
    @port   = default_port
    @headers = {}
    @content_length = 0
    @body   = nil
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

  # Parse a single request line, patch it if needed and append it to #lines.
  def <<(line)
    line = line.chomp

    Logger.debug "  REQUEST LINE: '#{line}'"

    # is this the first line '<VERB> <URI> HTTP/<VERSION>' ?
    if @url.nil? and line =~ /^(\w+)\s+(\S+)\s+HTTP\/[\d\.]+\s*$/
      @verb    = $1
      @url     = $2

      # fix url
      if @url.include? '://'
        uri = URI::parse @url
        @url = "#{uri.path}" + ( uri.query ? "?#{uri.query}" : '' )
      end

      line = "#{@verb} #{@url} HTTP/1.1"
    # get the host header value
    elsif line =~ /^Host:\s*(.*)$/
      @host = $1
      if host =~ /([^:]*):([0-9]*)$/
        @host = $1
        @port = $2.to_i
      end
    # parse content length, this will speed up data streaming
    elsif line =~ /^Content-Length:\s+(\d+)\s*$/i
      @content_length = $1.to_i
    # we don't want to have hundreds of threads running
    elsif line =~ /^Connection: keep-alive/i
      line = 'Connection: close'
    elsif line =~ /^Proxy-Connection: (.+)/i
      line = "Connection: #{$1}"
    # disable gzip, chunked, etc encodings
    elsif line =~ /^Accept-Encoding:.*/i
      line = 'Accept-Encoding: identity'
    end

    # collect headers
    if line =~ /^([^:\s]+)\s*:\s*(.+)$/i
      @headers[$1] = $2
    end

    @lines << line
  end

  # Return true if this is a POST request, otherwise false.
  def post?
    @verb == 'POST'
  end

  # Return a string representation of the HTTP request.
  def to_s
    @lines.join("\n") + "\n" + ( @body || '' )
  end
end
end
end
