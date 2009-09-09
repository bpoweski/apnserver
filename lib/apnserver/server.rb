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
end

EventMachine::run do
  puts "Starting APN Server: #{Time.now}"
  queue = EM::Queue.new
  server = EM.start_server "0.0.0.0", 22195, ApnProxyServer do |s|
    s.queue = queue
  end 
  timer = EventMachine::PeriodicTimer.new(1) do
    unless queue.empty?
      size = queue.size
      size.times do 
        queue.pop do |notification|
          puts notification.inspect
        end
      end
    end
  end  
end