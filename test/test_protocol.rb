require File.dirname(__FILE__) + '/test_helper.rb'

class TestServer
  attr_accessor :queue
  include ApnServer::Protocol
  
  def address
    [12345, '127.0.0.1']
  end
end

class TestProtocol < Test::Unit::TestCase
  
  def setup
    @server = TestServer.new
    @server.queue = Array.new # fake out EM::Queue
  end
  
  def test_adds_notification_to_queue
    token = "12345678123456781234567812345678"
    @server.receive_data("\0\0 #{token}\0#{22.chr}{\"aps\":{\"alert\":\"Hi\"}}")
    assert_equal 1, @server.queue.size
  end
  
  def test_does_not_add_invalid_notification
    @server.receive_data('fakedata')
    assert @server.queue.empty?
  end
end
