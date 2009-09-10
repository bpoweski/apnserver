module ApnServer
  class Client
    
    attr_accessor :certificate, :key, :host, :port
    
    def initialize(certificate, key, host = 'gateway.push.apple.com', port = 2195)
      @certificate, @key, @host, @port = certificate, key, host, port
    end
    
    def connect!
      raise "The path to your pem file is not set." unless self.pem
      raise "The path to your pem file does not exist!" unless File.exist?(self.pem)
      
      @context      = OpenSSL::SSL::SSLContext.new
      @context.cert = OpenSSL::X509::Certificate.new(File.read(self.pem))
      @context.key  = OpenSSL::PKey::RSA.new(File.read(self.pem), self.pass)
      
      @sock         = TCPSocket.new(self.host, self.port)
      @ssl          = OpenSSL::SSL::SSLSocket.new(@sock, @context)
      @ssl.connect
      
      return @sock, @ssl
    end
    
    def disconnect!
      @ssl.close
      @sock.close
    end
    
    def write(bytes)
      @ssl.write(bytes)
    end
    
    def connected?
      @ssl
    end
    
  end
end