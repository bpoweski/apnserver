require 'rubygems'
require 'eventmachine'
require 'apnserver/notification'

require 'socket'
require 'openssl'

class ApnProxyServer < EventMachine::Connection
  attr_accessor :queue
  
  def post_init
    @address = Socket.unpack_sockaddr_in(self.get_peername)
    puts "#{Time.now} [#{@address.last}:#{@address.first}] CONNECT"
  end
  
  def unbind
    puts "#{Time.now} [#{@address.last}:#{@address.first}] DISCONNECT"    
  end
  
  def receive_data(data)
    puts "#{Time.now} [#{@address.last}:#{@address.first}] RECV - #{data}"
    
     (@buf ||= "") << data
    if notification = ApnServer::Notification.valid?(@buf)
      queue.push(notification)
    end
  end
end

class ApnsClient
  
  attr_accessor :certificate, :key, :host, :port
  
  
  def intialize(certificate, key, host = 'gateway.push.apple.com', port = 2195)
    @certificate, @key, @host, @port = certificate, path, host, port
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
  

EventMachine::run do
  puts "Starting APN Server: #{Time.now}"
  queue = EM::Queue.new
  
  EM.start_server("0.0.0.0", 22195, ApnProxyServer) do |s|
    s.queue = queue
  end 
  
  client = ApnsClient.new($1, $2)
  
  EventMachine::PeriodicTimer.new(1) do
    unless queue.empty?
      size = queue.size
      size.times do 
        queue.pop do |notification|
          client.connect! unless client.connected?
          client.write(notification.to_bytes)
        end
      end
    end
  end
end