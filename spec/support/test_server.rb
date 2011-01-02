class TestServer
  attr_accessor :queue
  include ApnServer::Protocol

  def address
    [12345, '127.0.0.1']
  end
end