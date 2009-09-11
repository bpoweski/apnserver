require 'socket'
require 'apnserver/protocol'

module ApnServer
  class ServerConnection < EventMachine::Connection
    include Protocol
    attr_accessor :queue, :address
  end
end