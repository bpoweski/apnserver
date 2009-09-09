require 'socket'

require 'rubygems'
require 'eventmachine'
require 'apnserver/notification'

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

class ApnClient < EventMachine::Connection
  def post_init
    puts "Starting TLS"
    start_tls(
      :private_key_file => $1, 
      :cert_chain_file => $2, 
      :verify_peer => false
    )
  end
  
  def receive_data data
    # we won't receive anything
  end
  
  def ssl_handshake_completed
    puts get_peer_cert
  end  
  
  def unbind
    puts "#{Time.now} DISCONNECT from APNS"
  end  
end

EventMachine::run do
  puts "Starting APN Server: #{Time.now}"
  queue = EM::Queue.new
  
  EM.start_server("0.0.0.0", 22195, ApnProxyServer) do |s|
    s.queue = queue
  end 
  
  client = EM.connect('localhost', 2195, ApnClient)
  
  EventMachine::PeriodicTimer.new(1) do
    unless queue.empty?
      size = queue.size
      size.times do 
        queue.pop do |notification|
          puts notification.inspect
        end
      end
    end
  end
 
  puts client.inspect
end