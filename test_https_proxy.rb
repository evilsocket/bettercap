require 'openssl'
require 'socket'

sock = TCPSocket.new( '172.20.10.2', 8083 )

ctx = OpenSSL::SSL::SSLContext.new

# we need this? :P ctx.set_params(verify_mode: OpenSSL::SSL::VERIFY_PEER)

socket = OpenSSL::SSL::SSLSocket.new(sock, ctx).tap do |socket|
  socket.sync_close = true
  socket.connect

  socket.write "GET / HTTP/1.1\n" +
               "Host: www.facebook.com\n" +
               "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\n" +
               "Accept-encoding: gzip, deflate, sdch\n" +
               "Accept-language: it-IT,it;q=0.8,en-US;q=0.6,en;q=0.4,la;q=0.2\n" +
               "Cache-control: max-age=0\n" +
               "User-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.125 Safari/537.36\n" +
               "\n\n"

  while line = socket.gets # Read lines from socket
    puts line         # and print them
  end

  socket.close
end

