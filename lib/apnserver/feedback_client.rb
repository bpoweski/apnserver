# Feedback service

module ApnServer
  class FeedbackClient < Client
    def initialize(pem, host = 'feedback.push.apple.com', port = 2196, pass = nil)
      @pem, @host, @port, @pass = pem, host, port, pass
    end
    
    def read
      records ||= []
      while record = @ssl.read(38)
        records << record.unpack("NnH*")
      end
      records
    end
  end
end