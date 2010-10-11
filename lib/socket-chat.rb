require 'socket'

class ChatServer

    def initialize(port)
        @descriptors = []
        @serverSocket = TCPServer.new('',port)
        @serverSocket.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR , 1 )
        puts "server started on port #{port}"
        @descriptors << @serverSocket
    end

    def run
        while 1
            res = select( @descriptors, nil, nil,nil)

            if res != nil
                res[0].each do |sock|
                    if sock == @serverSocket 
                        accept_new_connection
                    else
                        if sock.eof? 
                            str = sprintf("Client left %s:%s\n", sock.peeraddr[2], sock.peeraddr[1])
                            broadcast_string( str, sock )
                            sock.close
                            @descriptors.delete(sock)
                        else
                            w = sock.gets 
                            if w.chomp == "EOF"
                                sock.close
                                @descriptors.delete(sock)
                            else 
                                str = sprintf("[%s|%s]: %s", sock.peeraddr[2], sock.peeraddr[1], w)
                                broadcast_string(str,sock)
                            end
                        end
                    end
                end
            end
        end
    end

    private

    def broadcast_string ( str, omit_sock )
        @descriptors.each do |clisock|
            if clisock != @serverSocket && clisock != omit_sock
                  clisock.write(str)
            end
        end
        print(str)

    end

    def accept_new_connection
        newsock = @serverSocket.accept
        @descriptors.push (newsock)
        newsock.write("sei connesso, write EOF to disconnect\n")
        str = sprintf("Client joined %s:%s\n",
                      newsock.peeraddr[2], newsock.peeraddr[1])
        broadcast_string( str, newsock )
    end

end

mc = ChatServer.new(2626)
mc.run
