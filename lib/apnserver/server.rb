module ApnServer
  
  class Server
    attr_accessor :client, :bind_address, :port
    
    def initialize(certificate, key, bind_address = '0.0.0.0', port = 22195)
      @queue = EM::Queue.new
      @client = ApnServer::Client.new(certificate, key)
      @bind_address, @port = bind_address, port
    end
    
    def start!
      EventMachine::run do
        puts "#{Time.now} Starting APN Server on #{bind_address}:#{port}"
        
        EM.start_server(bind_address, port, ApnServer::ServerConnection) do |s|
          s.queue = @queue
        end 
         
        EventMachine::PeriodicTimer.new(1) do
          unless @queue.empty?
            size = @queue.size
            size.times do 
              @queue.pop do |notification|
                @client.connect! unless @client.connected?
                @client.write(notification.to_bytes)
              end
            end
          end
        end
      end   
    end
  end
end
