module ApnServer
  module Protocol
    def post_init
      @address = Socket.unpack_sockaddr_in(self.get_peername)
      Config.logger.debug "#{Time.now} [#{address.last}:#{address.first}] CONNECT"
    end

    def unbind
      Config.logger.debug "#{Time.now} [#{address.last}:#{address.first}] DISCONNECT"
    end

    def receive_data(data)
      (@buf ||= "") << data
      if notification = ApnServer::Notification.valid?(@buf)
        Config.logger.debug "#{Time.now} [#{address.last}:#{address.first}] found valid Notification: #{notification}"
        queue.push(notification)
      else
        Config.logger.debug "#{Time.now} [#{address.last}:#{address.first}] invalid notification: #{@buf}"
      end
    end
  end
end