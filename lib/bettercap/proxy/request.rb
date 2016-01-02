=begin

BETTERCAP

Author : Simone 'evilsocket' Margaritelli
Email  : evilsocket@gmail.com
Blog   : http://www.evilsocket.net/

This project is released under the GPL 3 license.

=end

module BetterCap
module Proxy
class Request
  attr_reader :lines, :verb, :url, :host, :port, :content_length

  def initialize( default_port = 80 )
    @lines  = []
    @verb   = nil
    @url    = nil
    @host   = nil
    @port   = default_port
    @content_length = 0
  end

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
  end

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

      @lines << line
    end

    def post?
      @verb == 'POST'
    end

    def to_s
      @lines.join("\n") + "\n"
    end
  end
end
end
