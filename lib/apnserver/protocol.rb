module ApnServer
  module Protocol
    
    def post_init
      @address = Socket.unpack_sockaddr_in(self.get_peername)
      puts "#{Time.now} [#{address.last}:#{address.first}] CONNECT"
    end
    
    def unbind
      puts "#{Time.now} [#{address.last}:#{address.first}] DISCONNECT"    
    end
    
    def receive_data(data)
      (@buf ||= "") << data
      if notification = ApnServer::Notification.valid?(@buf)
        queue.push(notification)
      end
    end
    
  end
end