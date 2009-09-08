require 'rubygems'
require 'eventmachine'

module ApnServer
  
  module ProxyConnection
    def initialize(client, request)
      @client, @request = client, request
    end
    
    def post_init
      EM::enable_proxy(self, @client)
    end
    
    def connection_completed
      send_data @request
    end
    
    def proxy_target_unbound
      close_connection
    end
    
    def unbind
      @client.close_connection_after_writing
    end
  end  
  
  module ProxyServer
    def receive_data(data)
     (@buf ||= "") << data
#      if @buf =~ /\r\n\r\n/ # all http headers received
#        EM.connect("10.0.0.15", 80, ProxyConnection, self, data)
#      end
    end
  end
end



EventMachine::run do
  puts "Starting the run now: #{Time.now}"
  EventMachine::add_timer 5, proc { puts "Executing timer event: #{Time.now}" }
  EventMachine::add_timer( 10 ) { puts "Executing timer event: #{Time.now}" }  
  EventMachine::start_server "127.0.0.1", 2295, ApnServer::ProxyServer
end