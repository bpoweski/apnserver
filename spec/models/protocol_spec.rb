require 'spec_helper'

describe "TestProtocol" do
  before(:each) do
    @server = TestServer.new
    @server.queue = Array.new # fake out EM::Queue
  end

  it "adds_notification_to_queue" do
    token = "12345678123456781234567812345678"
    @server.receive_data("\0\0 #{token}\0#{22.chr}{\"aps\":{\"alert\":\"Hi\"}}")
    @server.queue.size.should == 1
  end

  it "does_not_add_invalid_notification" do
    @server.receive_data('fakedata')
    @server.queue.should be_empty
  end
end
