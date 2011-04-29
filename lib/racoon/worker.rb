# Racoon - A distributed APNs provider
# Copyright (c) 2011, Jeremy Tregunna, All Rights Reserved.
#
# This module contains the worker which processes notifications before sending them off
# down to the firehose.

require 'ffi-rzmq'
require 'zmqmachine'

module Racoon
  class Worker
    def initialize(reactor, address)
      @reactor = reactor
      @address = address
      @send_queue = []
    end

    def on_attach(socket)
      @socket = socket

      socket.connect(@address.to_s)
    end

    def on_writable(socket)
      unless @send_queue.empty?
        message = @send_queue.shift
        socket.send_message_string(message)
      else
        @reactor.deregister_writable(socket)
      end
    end

    def send_message(message)
      @send_queue.push(message)
      @reactor.register_writable(@socket)
    end
  end
end
