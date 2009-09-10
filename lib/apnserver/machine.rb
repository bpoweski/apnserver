EventMachine::run do
  puts "Starting APN Server: #{Time.now}"
  queue = EM::Queue.new
  
  EM.start_server("0.0.0.0", 22195, ApnServer) do |s|
    s.queue = queue
  end 
  
  client = Client.new($1, $2)
  
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