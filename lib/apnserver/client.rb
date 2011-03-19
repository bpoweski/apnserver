require 'openssl'
require 'socket'

module ApnServer
  class Client
    attr_accessor :pem, :host, :port, :password

    def initialize(pem, host = 'gateway.push.apple.com', port = 2195, pass = nil)
      @pem, @host, @port, @password = pem, host, port, pass
    end

    def connect!
      raise "Your certificate is not set." unless self.pem

      @context      = OpenSSL::SSL::SSLContext.new
      @context.cert = OpenSSL::X509::Certificate.new(self.pem)
      @context.key  = OpenSSL::PKey::RSA.new(self.pem, self.password)

      @sock         = TCPSocket.new(self.host, self.port.to_i)
      @ssl          = OpenSSL::SSL::SSLSocket.new(@sock, @context)
      @ssl.connect

      return @sock, @ssl
    end

    def disconnect!
      @ssl.close
      @sock.close
      @ssl = nil
      @sock = nil
    end

    def write(notification)
      Config.logger.debug "#{Time.now} [#{host}:#{port}] Device: #{notification.device_token.unpack('H*')} sending #{notification.json_payload}"
      @ssl.write(notification.to_bytes)
    end

    def connected?
      @ssl
    end
  end
end