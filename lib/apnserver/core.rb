

module ApnServer
  def post_init
    puts "-- someone connected to the echo server!"
  end
  
  def receive_data data
    send_data ">>>you sent: #{data}\r\n"
    close_connection if data =~ /quit/i
  end
  
  def unbind
    puts "-- someone disconnected from the echo server!"
  end
end

EventMachine::run do
  EventMachine::start_server "127.0.0.1", 8081, EchoServer
end