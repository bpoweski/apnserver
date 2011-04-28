# Racoon - A distributed APNs provider
# Copyright (c) 2011, Jeremy Tregunna, All Rights Reserved.
#
# This module contains the firehose which is responsible for maintaining all the open
# connections to Apple, and sending data over the right ones.

require 'digest/sha1'
require 'eventmachine'
require 'ffi-rzmq'

module Racoon
  class Firehose
    def initialize(address = "tcp://*:11555", context = ZMQ::Context.new(1))
      @connections = {}
      @context = context
      @firehose = context.socket(ZMQ::PULL)
      @address = address
    end

    def start!
      EventMachine::run do
        @firehose.bind(@address)

        apns = EventMachine.spawn do |project, bytes|
          uri = "gateway.#{project[:sandbox] ? 'sandbox.' : ''}push.apple.com"
          hash = project_hash(project)

          should_fail_in_exception_handler = false

          begin
            @connection[hash] ||= Racoon::Client.new(project[:certificate], uri)

            @connection[hash].connect! unless @connection[hash].connected?
            @connection[hash].write(bytes)
          rescue Errno::EPIPE, OpenSSL::SSL::SSLError, Errno::ECONNRESET
            @connection[hash].disconnect!
            retry unless should_fail_in_exception_handler
            should_fail_in_exception_handler = true
          end
        end

        EventMachine::PeriodicTimer.new(0.1) do
          received_message = ZMQ::Message.new
          @firehose.recv(received_message, ZMQ::NOBLOCK)
          json_string = received_message.copy_out_string
          
          if json_string and json_string != ""
            packet = Yajl::Parser.parse(json_string)

            apns.notify(packet[:project], packet[:bytes])
          end
        end
      end
    end

    private

    def project_hash(project)
      Digest::SHA1.hexdigest("#{project[:name]}-#{project[:certificate]}")
    end
  end
end