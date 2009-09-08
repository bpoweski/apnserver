require 'rubygems'
require 'eventmachine'
require 'apnserver/notification'

module ApnServer
  def post_init
    puts "++ [] connect"
  end
  
  def unbind
    puts "-- [] disconnect"
  end
  
  def receive_data(data)
    puts "receive: #{data}"
    (@buf ||= "") << data
    if Notification.valid?(@buf)
      puts "send valid request"
    end
    #      if @buf =~ /\r\n\r\n/ # all http headers received
    #        EM.connect("10.0.0.15", 80, ProxyConnection, self, data)
    #      end
  end
end



EventMachine::run do
  puts "Starting the run now: #{Time.now}"
  #  EventMachine::add_timer 5, proc { puts "Executing timer event: #{Time.now}" }
  #  EventMachine::add_timer( 10 ) { puts "Executing timer event: #{Time.now}" }  
  EM.start_server "0.0.0.0", 10000, ApnServer
end