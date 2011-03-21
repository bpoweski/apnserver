require 'socket'
require 'apnserver/protocol'
require 'eventmachine'

module ApnServer
  class ServerConnection < EventMachine::Connection
    include Protocol
    attr_accessor :queue, :address
  end
end